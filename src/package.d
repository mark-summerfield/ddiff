// Copyright © 2020 Mark Summerfield. All rights reserved.
module ddiff;

import std.container.rbtree: RedBlackTree;
import std.range: ElementType, front, isForwardRange;
import std.typecons: Tuple;

auto spans(R)(R a, R b, EqualSpan equalSpan=EqualSpan.Drop) if (
        isForwardRange!R && // R is a range that can be iterated repeatedly
        is(typeof(R.init.front == R.init.front)) // Elements support ==
        ) {
    auto diff = new Diff!R(a, b);
    return diff.spans(equalSpan);
}

struct Span(E) {
    Tag tag;
    E[] a;
    E[] b;

    string toString() const pure @safe {
        import std.format: format;

        char char4tag(Tag tag) {
            final switch (tag) {
            case Tag.Equal: return '=';
            case Tag.Insert: return '+';
            case Tag.Delete: return '-';
            case Tag.Replace: return '%';
            }
        }

        auto stag = char4tag(tag);
        if (tag == Tag.Equal)
            return format!"%s «%s»"(stag, a);
        return format!"%s «%s» → «%s»"(stag, a, b);
    }
}

enum EqualSpan { Drop, Keep }

enum Tag { Equal, Insert, Delete, Replace }

private alias Quad = Tuple!(int, "aStart", int, "aEnd",
                            int, "bStart", int, "bEnd");

private struct Match {
    int aStart;
    int bStart;
    int length;

    int opCmp(const Match other) const {
        return (aStart == other.aStart) ? (
                    (bStart == other.bStart) ? length - other.length
                                             : bStart - other.bStart)
                    : aStart - other.aStart;
    }
}

private class Diff(R) if (
        isForwardRange!R && // R is a range that can be iterated repeatedly
        is(typeof(R.init.front == R.init.front)) // Elements support ==
        ) {
    import std.conv: to;
    import std.math: floor;

    alias E = ElementType!R;

    private R a;
    private R b;
    private int[][E] b2j;

    private this(R a, R b) {
        this.a = a;
        this.b = b;
        chainB();
    }

    private final void chainB() {
        foreach (i, element; b)
            b2j[element] ~= i.to!int;
        auto popular = new RedBlackTree!E;
        auto len = b.length;
        if (len > 200) {
            auto popularLen = to!int(floor((to!double(len) / 100.0))) + 1;
            foreach (element, quad; b2j)
                if (quad.length > popularLen)
                    popular.insert(element);
            foreach (element; popular)
                b2j.remove(element);
        }
    }

    private final Match[] matches() {
        import std.algorithm: sort;
        import std.array: back, empty;
        import std.range.primitives: popBack;

        immutable aLen = a.length.to!int;
        immutable bLen = b.length.to!int;
        Quad[] quads = [Quad(0, aLen, 0, bLen)];
        Match[] matches;
        while (!quads.empty) {
            auto quad = quads.back();
            quads.popBack();
            auto match = longestMatch(quad);
            auto i = match.aStart;
            auto j = match.bStart;
            auto k = match.length;
            if (k > 0) {
                matches ~= match;
                if (quad.aStart < i && quad.bStart < j)
                    quads ~= Quad(quad.aStart, i, quad.bStart, j);
                if (i + k < quad.aEnd && j + k < quad.bEnd)
                    quads ~= Quad(i + k, quad.aEnd, j + k, quad.bEnd);
            }
        }
        sort(matches);
        int aStart;
        int bStart;
        int length;
        Match[] nonAdjacent;
        foreach (match; matches) {
            if (aStart + length == match.aStart &&
                    bStart + length == match.bStart)
                length += match.length;
            else {
                if (length)
                    nonAdjacent ~= Match(aStart, bStart, length);
                aStart = match.aStart;
                bStart = match.bStart;
                length = match.length;
            }
        }
        if (length)
            nonAdjacent ~= Match(aStart, bStart, length);
        nonAdjacent ~= Match(aLen, bLen, 0);
        return nonAdjacent;
    }

    private final Match longestMatch(Quad quad) {
        Match match;
        int bestI = quad.aStart;
        int bestJ = quad.bStart;
        int bestSize;
        int[int] j2Len;
        for (int i = quad.aStart; i < quad.aEnd; i++) {
            int[int] newJ2Len;
            if (auto indexes = a[i] in b2j) {
                foreach (j; *indexes) {
                    if (j < quad.bStart)
                        continue;
                    if (j >= quad.bEnd)
                        break;
                    int k = j2Len.get(j - 1, 0) + 1;
                    newJ2Len[j] = k;
                    if (k > bestSize) {
                        bestI = i - k + 1;
                        bestJ = j - k + 1;
                        bestSize = k;
                    }
                }
            }
            j2Len = newJ2Len;
        }
        while (bestI > quad.aStart && bestJ > quad.bStart &&
                a[bestI - 1] == b[bestJ - 1]) {
            bestI--;
            bestJ--;
            bestSize++;
        }
        while (bestI + bestSize < quad.aEnd &&
                bestJ + bestSize < quad.bEnd &&
                a[bestI + bestSize] == b[bestJ + bestSize])
            bestSize++;
        return Match(bestI, bestJ, bestSize);
    }

    private final Span!E[] spans(EqualSpan equalSpan) {
        Span!E[] spans;
        int i;
        int j;
        foreach (match; matches()) {
            auto span = Span!E(Tag.Equal, a[i .. match.aStart],
                                          b[j .. match.bStart]);
            if (i < match.aStart && j < match.bStart)
                span.tag = Tag.Replace;
            else if (i < match.aStart)
                span.tag = Tag.Delete;
            else if (j < match.bStart)
                span.tag = Tag.Insert;
            if (span.tag != Tag.Equal)
                spans ~= span;
            i = match.aStart + match.length;
            j = match.bStart + match.length;
            if (match.length && equalSpan == EqualSpan.Keep)
                spans ~= Span!E(Tag.Equal, a[match.aStart .. i],
                                           b[match.bStart .. j]);
        }
        return spans;
    }
}

unittest {
    import std.algorithm: map;
    import std.array: array, join, split;
    import std.format: format;
    import std.stdio: write, writeln;
    import std.uni: isWhite;

    struct Test(T) {
        T a;
        T b;
        EqualSpan equalSpan;
        string[] expected;
    }

    bool check(T)(int n, T s, string[] e) {
        assert(s.length == e.length, format("#%s length", n));
        for (int i = 0; i < s.length; i++)
            assert(s[i].toString == e[i], format("#%s span", n));
        return true;
    }

    writeln("unittests for ddiff");

    int n;

    write("Test #", ++n, ": Drop ");
    {
        auto s = spans("one two three four".array,
                       "one too tree four".array);
        auto e = ["% «w» → «o»", "- «h» → «»"];
        if (check(n, s, e))
            writeln("OK");
    }
    write("         Keep ");
    {
        auto s = spans("one two three four".array,
                       "one too tree four".array, EqualSpan.Keep);
        auto e = ["= «one t»", "% «w» → «o»", "= «o t»", "- «h» → «»",
                  "= «ree four»"];
        if (check(n, s, e))
            writeln("OK");
    }

    write("Test #", ++n, ": Drop ");
    {
        auto s = spans(
            "the quick brown fox jumped over the lazy dogs".split!isWhite,
            "the quick red fox jumped over the very busy dogs"
            .split!isWhite);
        auto e = ["% «[\"brown\"]» → «[\"red\"]»",
                  "% «[\"lazy\"]» → «[\"very\", \"busy\"]»"];
        if (check(n, s, e))
            writeln("OK");
    }
    write("         Keep ");
    {
        auto s = spans(
            "the quick brown fox jumped over the lazy dogs".split!isWhite,
            "the quick red fox jumped over the very busy dogs"
            .split!isWhite, EqualSpan.Keep);
        auto e = ["= «[\"the\", \"quick\"]»",
                  "% «[\"brown\"]» → «[\"red\"]»",
                  "= «[\"fox\", \"jumped\", \"over\", \"the\"]»",
                  "% «[\"lazy\"]» → «[\"very\", \"busy\"]»",
                  "= «[\"dogs\"]»"];
        if (check(n, s, e))
            writeln("OK");
    }

}

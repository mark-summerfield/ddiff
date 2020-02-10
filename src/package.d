// Copyright © 2020 Mark Summerfield. All rights reserved.
module ddiff;

import std.container.rbtree: RedBlackTree;
import std.range: ElementType, front, isForwardRange;
import std.typecons: Tuple;

struct Span(E) {
    Tag tag;
    E[] a;
    E[] b;
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

auto spans(R)(R a, R b, EqualSpan equalSpan=EqualSpan.Drop) if (
        isForwardRange!R && // R is a range that can be iterated repeatedly
        is(typeof(R.init.front == R.init.front)) // Elements support ==
        ) {
    auto diff = new Diff!R(a, b);
    return diff.spans(equalSpan);
}

unittest {
    import std.algorithm: map;
    import std.array: array, join;
    import std.stdio: writeln;

    writeln("unittest for the ddiff library.");

    string strForSpan(S)(S span) const pure @safe {
        import std.format: format;

        char char4tag(Tag tag) {
            final switch (tag) {
            case Tag.Equal: return '=';
            case Tag.Insert: return '+';
            case Tag.Delete: return '-';
            case Tag.Replace: return '%';
            }
        }

        auto stag = char4tag(span.tag);
        if (span.tag == Tag.Equal)
            return format!"%s \"%s\""(stag, span.a);
        return format!"%s \"%s\" → \"%s\""(stag, span.a, span.b);
    }

    auto a1 = "one two three four";
    auto b1 = "one too tree four";
    writeln(a1);
    writeln(b1);
    auto s1 = spans(a1.array, b1.array);
    writeln("TODO drop");
    writeln(join(map!(s => strForSpan(s))(s1), '\n'));
    s1 = spans(a1.array, b1.array, EqualSpan.Keep);
    writeln("TODO keep");
    writeln(join(map!(s => strForSpan(s))(s1), '\n'));

    auto a2 = ["Tulips are yellow,", "Violets are blue,", "Agar is sweet,",
               "As are you."];
    auto b2 = ["Roses are red,", "Violets are blue,", "Sugar is sweet,",
               "And so are you."];
    writeln(a2);
    writeln(b2);
    auto s2 = spans(a2, b2);
    writeln("TODO drop");
    writeln(join(map!(s => strForSpan(s))(s2), '\n'));
    s2 = spans(a2, b2, EqualSpan.Keep);
    writeln("TODO keep");
    writeln(join(map!(s => strForSpan(s))(s2), '\n'));
}

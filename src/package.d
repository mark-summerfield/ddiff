// Copyright © 2020 Mark Summerfield. All rights reserved.
module ddiff;

import std.container.rbtree: RedBlackTree;
import std.range: ElementType, front, isForwardRange;
import std.typecons: Tuple;

struct Span {
    Tag tag;
    size_t aStart;
    size_t bStart;
    size_t aEnd;
    size_t bEnd;
}

enum EmptySpan { Drop, Keep }

enum Tag: string {
    Equal = "equal",
    Insert = "insert",
    Delete = "delete",
    Replace = "replace",
}

private alias Quad = Tuple!(size_t, "aStart", size_t, "aEnd",
                            size_t, "bStart", size_t, "bEnd");

private struct Match {
    size_t aStart;
    size_t bStart;
    size_t length;
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
    private size_t[][E] b2j;

    private this(R a, R b) {
        this.a = a;
        this.b = b;
        chainB();
    }

    private final void chainB() {
        foreach (i, element; b)
            b2j[element] ~= i;
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
        import std.array: back, empty;
        import std.range.primitives: popBack;

        immutable aLen = a.length;
        immutable bLen = b.length;
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
        // TODO
        return matches;
    }

    private final Match longestMatch(Quad quad) {
        Match match;

        return match;
    }

    final Span[] spans(EmptySpan emptySpan) {
        Span[] spans;
        // TODO
        return spans;
    }
}

auto spans(R)(R a, R b, EmptySpan emptySpan=EmptySpan.Drop) if (
        isForwardRange!R && // R is a range that can be iterated repeatedly
        is(typeof(R.init.front == R.init.front)) // Elements support ==
        ) {
    auto diff = new Diff!R(a, b);
    return diff.spans(emptySpan);
}

unittest {
    import std.array;
    import std.stdio: writeln;

    writeln("unittest for the ddiff library.");

    auto a1 = "one two three four";
    auto b1 = "one too tree four";
    auto s1 = spans(a1.array, b1.array);
    writeln("TODO", s1);

    auto a2 = ["Tulips are yellow,", "Violets are blue,", "Agar is sweet,",
               "As are you."];
    auto b2 = ["Roses are red,", "Violets are blue,", "Sugar is sweet,",
               "And so are you."];
    auto s2 = spans(a2, b2);
    writeln("TODO", s2);
}

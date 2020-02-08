// Copyright © 2020 Mark Summerfield. All rights reserved.
module diffslice;

import std.range: ElementType, front, isForwardRange;

struct Match {
    size_t aStart;
    size_t bStart;
    size_t length;
}

enum Tag: string {
    Equal = "equal",
    Insert = "insert",
    Delete = "delete",
    Replace = "replace",
}

struct Span {
    Tag tag;
    size_t aStart;
    size_t bStart;
    size_t aEnd;
    size_t bEnd;
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
        int[E] popular; // key = element, value = 0 (used as a set)
        auto len = b.length;
        if (len > 200) {
            auto popularLen = to!int(floor((to!double(len) / 100.0))) + 1;
            foreach (element, indexes; b2j)
                if (indexes.length > popularLen)
                    popular[element] = 0;
            foreach (element; popular.byKey)
                b2j.remove(element);
        }
    }

    final Match[] matches() {
        immutable aLen = a.length;
        immutable bLen = b.length;
        size_t[] queue; // =[(0, aLen, 0, bLen)] i.e., list of 1 x 4-tuple
        Match[] matches;
        // TODO
        return matches;
    }

    final Span[] spans() {
        Span[] spans;
        // TODO
        return spans;
    }
}

auto matches(R)(R a, R b) if (
        isForwardRange!R && // R is a range that can be iterated repeatedly
        is(typeof(R.init.front == R.init.front)) // Elements support ==
        ) {
    auto diff = new Diff!R(a, b);
    return diff.matches();
}

auto spans(R)(R a, R b) if (
        isForwardRange!R && // R is a range that can be iterated repeatedly
        is(typeof(R.init.front == R.init.front)) // Elements support ==
        ) {
    auto diff = new Diff!R(a, b);
    return diff.spans();
}

unittest {
    import std.array;
    import std.stdio: writeln;

    writeln("unittest for the diffslice library.");

    auto a1 = "one two three four";
    auto b1 = "one too tree four";
    auto m1 = matches(a1.array, b1.array);
    writeln("TODO matches", m1);
    auto s1 = spans(a1.array, b1.array);
    writeln("TODO spans", s1);

    auto a2 = ["Tulips are yellow,", "Violets are blue,", "Agar is sweet,",
               "As are you."];
    auto b2 = ["Roses are red,", "Violets are blue,", "Sugar is sweet,",
               "And so are you."];
    auto m2 = matches(a2, b2);
    writeln("TODO matches", m2);
    auto s2 = spans(a2, b2);
    writeln("TODO spans", s2);
}

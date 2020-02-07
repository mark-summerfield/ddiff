// Copyright © 2020 Mark Summerfield. All rights reserved.
module diffrange;

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

class Diff(T) if (
        isForwardRange!T && // T is a range
        is(typeof(T.init.front == T.init.front)) // Elements support ==
        ) {
    import std.conv: to;
    import std.math: floor;

    alias E = ElementType!T;

    T a;
    T b;
    size_t[][E] b2j;

    this(T a, T b) {
        this.a = a;
        this.b = b;
        chainB();
    }

    private final void chainB() {
        foreach (i, element; b)
            b2j[element] ~= i;
        auto len = b.length;
        int[E] popular; // key = element, value = 0 (used as a set)
        if (len > 200) {
            auto popularLen = to!int(floor((to!double(len) / 100.0))) + 1;
            foreach (element, indexes; b2j)
                if (indexes.length > popularLen)
                    popular[element] = 0;
            foreach (element; popular.byKey)
                b2j.remove(element);
        }
    }
}

auto differ(T)(T a, T b) if (
        isForwardRange!T && // T is a range
        is(typeof(T.init.front == T.init.front)) // Elements support ==
        ) {
    return new Diff!T(a, b);
}

unittest {
    import std.array;
    import std.stdio: writeln;

    writeln("unittest for the diffrange library.");
    auto d1 = differ("one two three four".array, "one too tree four".array);
    auto a = ["Tulips are yellow,", "Violets are blue,", "Agar is sweet,",
              "As are you."];
    auto b = ["Roses are red,", "Violets are blue,", "Sugar is sweet,",
              "And so are you."];
    auto d2 = differ(a, b);
}

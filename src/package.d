// Copyright © 2020 Mark Summerfield. All rights reserved.
module diffrange;

import std.range: ElementType, front, isForwardRange;

struct Match {
    size_t aStart;
    size_t bStart;
    size_t length;
}

enum Tag : string {
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
        // TODO
    }
}

auto differ(T)(T a, T b) { return Diff!T(a, b); }

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

// Copyright © 2020 Mark Summerfield. All rights reserved.
module diffrange;

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

class Diff(T, E) {
    T a;
    T b;
    size_t[][E] b2j;

    this(T a, T b) {
        this.a = a;
        this.b = b;
        chainB();
    }

    void chainB() {
        foreach (i, element; b)
            b2j[element] ~= i;
        // TODO
    }
}

unittest {
    import std.stdio: writeln;

    writeln("unittest for the diffrange library.");
    auto a = ["Tulips are yellow,", "Violets are blue,", "Agar is sweet,",
              "As are you."];
    auto b = ["Roses are red,", "Violets are blue,", "Sugar is sweet,",
              "And so are you."];
    auto diff = Diff(a, b);
}

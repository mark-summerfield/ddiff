// Copyright © 2020 Mark Summerfield. All rights reserved.

unittest {
    import ddiff: EqualSpan, diff;
    import std.algorithm: map;
    import std.array: array, join, split;
    import std.datetime.stopwatch: AutoStart, StopWatch;
    import std.format: format;
    import std.range: empty;
    import std.stdio: write, writeln;
    import std.string: splitLines;
    import std.uni: isWhite;

    void check(T)(const string name, const T diffs,
                  const string[] expected) {
        write(name);
        assert(diffs.length == expected.length, format("%s length", name));
        for (int i = 0; i < diffs.length; i++)
            assert(diffs[i].toString == expected[i], format("%s span",
                                                            name));
        writeln(" OK");
    }

    auto watch = StopWatch(AutoStart.yes);

    writeln("unittests for ddiff");
    {
        auto diffs = diff("one two three four".array,
                          "one too tree four".array);
        auto expected = [`< w |> o`, `- h`];
        check("Test #1", diffs, expected);
    }
    {
        auto diffs = diff("one two three four".array,
                          "one too tree four".array, EqualSpan.Keep);
        auto expected = [`= one t`, `< w |> o`, `= o t`, `- h`,
                         `= ree four`];
        check("Test #2 (keep)", diffs, expected);
    }
    {
        auto diffs = diff(
            "the quick brown fox jumped over the lazy dogs".split!isWhite,
            "the quick red fox jumped over the very busy dogs"
            .split!isWhite);
        auto expected = [`< ["brown"] |> ["red"]`,
                         `< ["lazy"] |> ["very", "busy"]`];
        check("Test #3", diffs, expected);
    }
    {
        auto diffs = diff(
            "the quick brown fox jumped over the lazy dogs".split!isWhite,
            "the quick red fox jumped over the very busy dogs"
            .split!isWhite, EqualSpan.Keep);
        auto expected = [`= ["the", "quick"]`,
                         `< ["brown"] |> ["red"]`,
                         `= ["fox", "jumped", "over", "the"]`,
                         `< ["lazy"] |> ["very", "busy"]`,
                         `= ["dogs"]`];
        check("Test #4 (keep)", diffs, expected);
    }
    {
        auto diffs = diff("qabxcd".array, "abycdf".array);
        auto expected = [`- q`, `< x |> y`, `+ f`];
        check("Test #5", diffs, expected);
    }
    {
        auto diffs = diff("private Thread currentThread;".array,
                          "private volatile Thread currentThread;".array,
                          EqualSpan.Keep);
        auto expected = [`= privat`, `+ e volatil`,
                         `= e Thread currentThread;`];
        check("Test #6 (keep)", diffs, expected);
    }
    {
        auto diffs = diff("private Thread currentThread;".array,
                          "private volatile Thread currentThread;".array);
        auto expected = [`+ e volatil`];
        check("Test #7", diffs, expected);
    }
    {
        auto diffs = diff("foo\nbar\nbaz\nquux".split!isWhite,
                          "foo\nbaz\nbar\nquux".split!isWhite);
        auto expected = [`+ ["baz"]`, `- ["baz"]`];
        check("Test #8", diffs, expected);
    }
    {
        auto diffs = diff(
            splitLines("Tulips are yellow,\nViolets are blue,\n" ~
                       "Agar is sweet,\nAs are you."),
            splitLines("Roses are red,\nViolets are blue,\n" ~
                       "Sugar is sweet,\nAnd so are you."));
        auto expected = [
            `< ["Tulips are yellow,"] |> ["Roses are red,"]`,
            `< ["Agar is sweet,", "As are you."] ` ~
            `|> ["Sugar is sweet,", "And so are you."]`];
        check("Test #9 (lines)", diffs, expected);
    }
    {
        auto diffs = diff("qabxcd".array, "abycdf".array);
        auto expected = [`- q`, `< x |> y`, `+ f`];
        check("Test #10", diffs, expected);
    }
    {
        auto diffs = diff("the quick brown fox".split!isWhite,
                          "".split!isWhite);
        auto expected = [`- ["the", "quick", "brown", "fox"]`];
        check("Test #11", diffs, expected);
    }
    {
        auto diffs = diff("".split!isWhite,
                          "the quick brown fox".split!isWhite);
        auto expected = [`+ ["the", "quick", "brown", "fox"]`];
        check("Test #12", diffs, expected);
    }
    {
        auto diffs = diff("abc".array, "".array);
        auto expected = [`- abc`];
        check("Test #13", diffs, expected);
    }
    {
        auto diffs = diff("".array, "abc".array);
        auto expected = [`+ abc`];
        check("Test #14", diffs, expected);
    }
    {
        write("Test #15");
        auto diffs = diff("".array, "".array);
        writeln(diffs.empty ? " OK" : "FAIL");
    }
    {
        auto diffs = diff("quebec alpha bravo x-ray yankee".split!isWhite,
                          "alpha bravo yankee charlie".split!isWhite);
        auto expected = [`- ["quebec"]`, `- ["x-ray"]`, `+ ["charlie"]`];
        check("Test #16", diffs, expected);
    }
    {
        auto diffs = diff([1, 2, 3, 4, 5, 6], [2, 3, 5, 7]);
        auto expected = [`- [1]`, `- [4]`, `< [6] |> [7]`];
        check("Test #17 (ints)", diffs, expected);
    }

    struct Item {
        int offset;
        string name;

        bool opEquals(const Item other) const {
            return name == other.name && offset == other.offset;
        }

        int opCmp(const Item other) const {
            import std.algorithm: cmp;

            return (name == other.name) ? offset - other.offset
                                        : cmp(name, other.name);

        }

        string toString() const {
            return format("Item(%s, \"%s\")", offset, name);
        }
    }
    {
        auto diffs = diff([Item(1, "A"), Item(2, "B"), Item(3, "C"),
                           Item(4, "D"), Item(5, "E"), Item(6, "F"),
                           Item(7, "G")],
                          [Item(1, "A"), Item(3, "C"), Item(2, "B"),
                           Item(4, "D"), Item(5, "E"), Item(7, "G")]);
        auto expected = [`+ [Item(3, "C")]`, `- [Item(3, "C")]`,
                         `- [Item(6, "F")]`];
        check("Test #18", diffs, expected);
    }
    {
        auto diffs = diff([Item(2, "quebec"), Item(4, "alpha"),
                           Item(6, "bravo"), Item(7, "x-ray")],
                          [Item(4, "alpha"), Item(6, "bravo"),
                           Item(5, "tango"), Item(7, "hotel")]);
        auto expected = [
            `- [Item(2, "quebec")]`,
            `< [Item(7, "x-ray")] |> [Item(5, "tango"), Item(7, "hotel")]`];
        check("Test #19", diffs, expected);
    }

    writeln(watch.peek);
}

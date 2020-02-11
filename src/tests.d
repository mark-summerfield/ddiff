// Copyright © 2020 Mark Summerfield. All rights reserved.

unittest {
    import ddiff: EqualSpan, diffs;
    import std.algorithm: map;
    import std.array: array, join, split;
    import std.format: format;
    import std.range: empty;
    import std.stdio: write, writeln;
    import std.uni: isWhite;

    bool check(T)(const string name, const T spans,
                  const string[] expected) {
        assert(spans.length == expected.length, format("%s length", name));
        for (int i = 0; i < spans.length; i++)
            assert(spans[i].toString == expected[i], format("%s span",
                                                            name));
        return true;
    }

    writeln("unittests for ddiff");
    {
        auto name = "Test #1";
        write(name);
        auto spans = diffs("one two three four".array,
                           "one too tree four".array);
        auto expected = [`< w |> o`, `- h`];
        if (check(name, spans, expected))
            writeln(" OK");
    }
    {
        auto name = "Test #2 (keep)";
        write(name);
        auto spans = diffs("one two three four".array,
                           "one too tree four".array, EqualSpan.Keep);
        auto expected = [`= one t`, `< w |> o`, `= o t`, `- h`,
                         `= ree four`];
        if (check(name, spans, expected))
            writeln(" OK");
    }
    {
        auto name = "Test #3";
        write(name);
        auto spans = diffs(
            "the quick brown fox jumped over the lazy dogs".split!isWhite,
            "the quick red fox jumped over the very busy dogs"
            .split!isWhite);
        auto expected = [`< ["brown"] |> ["red"]`,
                         `< ["lazy"] |> ["very", "busy"]`];
        if (check(name, spans, expected))
            writeln(" OK");
    }
    {
        auto name = "Test #4 (keep)";
        write(name);
        auto spans = diffs(
            "the quick brown fox jumped over the lazy dogs".split!isWhite,
            "the quick red fox jumped over the very busy dogs"
            .split!isWhite, EqualSpan.Keep);
        auto expected = [`= ["the", "quick"]`,
                         `< ["brown"] |> ["red"]`,
                         `= ["fox", "jumped", "over", "the"]`,
                         `< ["lazy"] |> ["very", "busy"]`,
                         `= ["dogs"]`];
        if (check(name, spans, expected))
            writeln(" OK");
    }
    {
        auto name = "Test #5";
        write(name);
        auto spans = diffs("qabxcd".array, "abycdf".array);
        auto expected = [`- q`, `< x |> y`, `+ f`];
        if (check(name, spans, expected))
            writeln(" OK");
    }
    {
        auto name = "Test #6 (keep)";
        write(name);
        auto spans = diffs("private Thread currentThread;".array,
                           "private volatile Thread currentThread;".array,
                           EqualSpan.Keep);
        auto expected = [`= privat`, `+ e volatil`,
                         `= e Thread currentThread;`];
        if (check(name, spans, expected))
            writeln(" OK");
    }
    {
        auto name = "Test #7";
        write(name);
        auto spans = diffs("private Thread currentThread;".array,
                           "private volatile Thread currentThread;".array);
        auto expected = [`+ e volatil`];
        if (check(name, spans, expected))
            writeln(" OK");
    }
    {
        auto name = "Test #8";
        write(name);
        auto spans = diffs("foo\nbar\nbaz\nquux".split!isWhite,
                           "foo\nbaz\nbar\nquux".split!isWhite);
        auto expected = [`+ ["baz"]`, `- ["baz"]`];
        if (check(name, spans, expected))
            writeln(" OK");
    }
    {
        auto name = "Test #9 (ints)";
        write(name);
        auto spans = diffs([1, 2, 3, 4, 5, 6], [2, 3, 5, 7]);
        auto expected = [`- [1]`, `- [4]`, `< [6] |> [7]`];
        if (check(name, spans, expected))
            writeln(" OK");
    }
    {
        auto name = "Test #10";
        write(name);
        auto spans = diffs("qabxcd".array, "abycdf".array);
        auto expected = [`- q`, `< x |> y`, `+ f`];
        if (check(name, spans, expected))
            writeln(" OK");
    }
    {
        auto name = "Test #11";
        write(name);
        auto spans = diffs("the quick brown fox".split!isWhite,
                           "".split!isWhite);
        auto expected = [`- ["the", "quick", "brown", "fox"]`];
        if (check(name, spans, expected))
            writeln(" OK");
    }
    {
        auto name = "Test #12";
        write(name);
        auto spans = diffs("".split!isWhite,
                           "the quick brown fox".split!isWhite);
        auto expected = [`+ ["the", "quick", "brown", "fox"]`];
        if (check(name, spans, expected))
            writeln(" OK");
    }
    {
        auto name = "Test #13";
        write(name);
        auto spans = diffs("abc".array, "".array);
        auto expected = [`- abc`];
        if (check(name, spans, expected))
            writeln(" OK");
    }
    {
        auto name = "Test #14";
        write(name);
        auto spans = diffs("".array, "abc".array);
        auto expected = [`+ abc`];
        if (check(name, spans, expected))
            writeln(" OK");
    }
    {
        auto name = "Test #15";
        write(name);
        auto spans = diffs("".array, "".array);
        writeln(spans.empty ? " OK" : "FAIL");
    }
    {
        auto name = "Test #16";
        write(name);
        auto spans = diffs("quebec alpha bravo x-ray yankee".split!isWhite,
                           "alpha bravo yankee charlie".split!isWhite);
        auto expected = [`- ["quebec"]`, `- ["x-ray"]`, `+ ["charlie"]`];
        if (check(name, spans, expected))
            writeln(" OK");
    }

    struct Item {
        int offset;
        string name;

        bool opEquals(const Item other) const {
            return name == other.name && offset == other.offset;
        }

        string toString() const {
            return format("Item(%s, \"%s\")", offset, name);
        }
    }
    /*
    {
        auto name = "Test #17";
        write(name);
        auto spans = diffs([Item(1, "A"), Item(2, "B"), Item(3, "C"),
                            Item(4, "D"), Item(5, "E"), Item(6, "F"),
                            Item(7, "G")],
                           [Item(1, "A"), Item(3, "C"), Item(2, "B"),
                            Item(4, "D"), Item(5, "E"), Item(7, "G")]);
        auto expected = [`+ Item(3, "C")`, `- Item(3, "C")`,
                         `- Item(6, "F")`];
        if (check(name, spans, expected))
            writeln(" OK");
    }
    */
}

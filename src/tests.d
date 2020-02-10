// Copyright © 2020 Mark Summerfield. All rights reserved.

unittest {
    import ddiff: EqualSpan, spans;
    import std.algorithm: map;
    import std.array: array, join, split;
    import std.format: format;
    import std.stdio: write, writeln;
    import std.uni: isWhite;

    bool check(T)(const string name, const T s, const string[] e) {
        assert(s.length == e.length, format("%s length", name));
        for (int i = 0; i < s.length; i++)
            assert(s[i].toString == e[i], format("%s span", name));
        return true;
    }

    writeln("unittests for ddiff");
    {
        auto name = "Test #1";
        write(name);
        auto s = spans("one two three four".array,
                       "one too tree four".array);
        auto e = [`% <w> → <o>`, `- <h> → <>`];
        if (check(name, s, e))
            writeln(" OK");
    }
    {
        auto name = "Test #2 (keep)";
        write(name);
        auto s = spans("one two three four".array,
                       "one too tree four".array, EqualSpan.Keep);
        auto e = [`= <one t>`, `% <w> → <o>`, `= <o t>`, `- <h> → <>`,
                  `= <ree four>`];
        if (check(name, s, e))
            writeln(" OK");
    }
    {
        auto name = "Test #3";
        write(name);
        auto s = spans(
            "the quick brown fox jumped over the lazy dogs".split!isWhite,
            "the quick red fox jumped over the very busy dogs"
            .split!isWhite);
        auto e = [`% <["brown"]> → <["red"]>`,
                  `% <["lazy"]> → <["very", "busy"]>`];
        if (check(name, s, e))
            writeln(" OK");
    }
    {
        auto name = "Test #4 (keep)";
        write(name);
        auto s = spans(
            "the quick brown fox jumped over the lazy dogs".split!isWhite,
            "the quick red fox jumped over the very busy dogs"
            .split!isWhite, EqualSpan.Keep);
        auto e = [`= <["the", "quick"]>`,
                  `% <["brown"]> → <["red"]>`,
                  `= <["fox", "jumped", "over", "the"]>`,
                  `% <["lazy"]> → <["very", "busy"]>`,
                  `= <["dogs"]>`];
        if (check(name, s, e))
            writeln(" OK");
    }
    {
        auto name = "Test #5";
        write(name);
        auto s = spans("qabxcd".array, "abycdf".array);
        auto e = [`- <q> → <>`, `% <x> → <y>`, `+ <> → <f>`];
        if (check(name, s, e))
            writeln(" OK");
    }
    {
        auto name = "Test #6 (keep)";
        write(name);
        auto s = spans("private Thread currentThread;".array,
                       "private volatile Thread currentThread;".array,
                       EqualSpan.Keep);
        auto e = [`= <privat>`, `+ <> → <e volatil>`,
                  `= <e Thread currentThread;>`];
        if (check(name, s, e))
            writeln(" OK");
    }
    {
        auto name = "Test #7";
        write(name);
        auto s = spans("private Thread currentThread;".array,
                       "private volatile Thread currentThread;".array);
        auto e = [`+ <> → <e volatil>`];
        if (check(name, s, e))
            writeln(" OK");
    }
    // TODO nim test04 ...
}

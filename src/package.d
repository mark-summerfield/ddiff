/**
 * This module implements the Python difflib module's sequence matcher and
 * provides a diff() function.
 *
 * The function takes two slicable forward ranges of < and == comparable
 * objects (e.g., two slices of strings, two strings, two slices of ints,
 * two slices of "items") and diffs them using a slightly simplified
 * version of the Python difflib's sequence matcher algorithm. The
 * function returns a (possibly empty) slice of Diff structs, each with a
 * tag (equal, insert, delete, replace) and the two relevant subslices.
 *
 * See tests.d for some examples including Test #17, #18 and #19.
 *
 * Authors: Mark Summerfield, mark@qtrac.eu
 * License: Apache 2.0
 * Copyright: © 2020 Mark Summerfield. All rights reserved.
*/
module qtrac.ddiff;

import std.range: ElementType, front, hasSlicing, isForwardRange;
import std.typecons: Tuple;

/**
 * Iterates two slices and diffs them.
 * Params:
 *  a = a forward sliceable range
 *  b = a forward sliceable range
 *  equalSpan = an EqualSpan
 * Elements from a and b must be comparable for equality.
 * If equalSpan is Drop (the default), then only Diff structs with Insert,
 * Delete, or Replace tags will be returned; otherwise Diff structs
 * covering all the input will be returned, so will additionally include
 * Diff structs with Equal tags.
 * Returns: A slice of Diff structs.
*/
auto diff(R)(R a, R b, EqualSpan equalSpan=EqualSpan.Drop) if (
        isForwardRange!R && // R is a range that can be iterated repeatedly
        hasSlicing!R &&
        is(typeof(R.init.front == R.init.front)) && // Elements support ==
        is(typeof(R.init.front < R.init.front)) // Elements support <
        ) {
    auto diff = new Differ!R(a, b);
    return diff.diff(equalSpan);
}

/**
 * A difference with a tag to specify what the difference is and the two
 * relevant subslices.
*/
struct Diff(E) {
    Tag tag; /// What kind of difference this is.
    E[] a; /// The relevant subslice of the original `a` slice.
    E[] b; /// The relevant subslice of the original `b` slice.

    /**
     * This method is primarily for testing.
     * Returns: a string indicating the difference.
    */
    string toString() const {
        import std.format: format;

        final switch (tag) {
        case Tag.Equal: return format!"= %s"(a);
        case Tag.Insert: return format!"+ %s"(b);
        case Tag.Delete: return format!"- %s"(a);
        case Tag.Replace: return format!"< %s |> %s"(a, b);
        }
    }
}

/**
 * Used to tell the diff() function whether to include Diff structs in
 * its output slice that have all possible tags, including the Equal tag
 * (Keep), or only difference tags, Insert, Delete, Replace (Drop).
*/
enum EqualSpan { Drop, Keep }

/**
 * What kind of difference the Diff struct represents.
*/
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

private class Differ(R) if (
        isForwardRange!R && // R is a range that can be iterated repeatedly
        hasSlicing!R &&
        is(typeof(R.init.front == R.init.front)) && // Elements support ==
        is(typeof(R.init.front < R.init.front)) // Elements support <
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

    private void chainB() {
        import aaset: AAset;
        import std.algorithm: each, filter;
        import std.range: iota, zip;

        each!(t => b2j[t[0]] ~= t[1].to!int)(zip(b, iota(b.length)));
        AAset!E popular;
        auto len = b.length;
        if (len > 200) {
            immutable minLen = to!int(floor((to!double(len) / 100.0))) + 1;
            each!(kv => popular.add(kv.key))(
                filter!(kv => kv.value.length > minLen)(b2j.byKeyValue));
            each!(element => b2j.remove(element))(popular);
        }
    }

    private Match[] matches() {
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

    private Match longestMatch(Quad quad) {
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
                    immutable k = j2Len.get(j - 1, 0) + 1;
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

    private Diff!E[] diff(EqualSpan equalSpan) {
        Diff!E[] diffs;
        int i;
        int j;
        foreach (match; matches()) {
            auto diff = Diff!E(Tag.Equal, a[i .. match.aStart],
                                          b[j .. match.bStart]);
            if (i < match.aStart && j < match.bStart)
                diff.tag = Tag.Replace;
            else if (i < match.aStart)
                diff.tag = Tag.Delete;
            else if (j < match.bStart)
                diff.tag = Tag.Insert;
            if (diff.tag != Tag.Equal)
                diffs ~= diff;
            i = match.aStart + match.length;
            j = match.bStart + match.length;
            if (match.length && equalSpan == EqualSpan.Keep)
                diffs ~= Diff!E(Tag.Equal, a[match.aStart .. i],
                                           b[match.bStart .. j]);
        }
        return diffs;
    }
}

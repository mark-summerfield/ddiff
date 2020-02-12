# ddiff

A D implementation of the Python difflib module's sequence matcher.

ddiff is a library for finding the differences between two sequences.

The sequences can be of lines, strings (e.g., words), characters,
bytes, or of any custom “item” type so long as it implements `==`
and `<`.

# Examples

For example, this code:
```d
auto diffs = diff(
    "the quick brown fox jumped over the lazy dogs".split!isWhite,
    "the quick red fox jumped over the very busy dogs".split!isWhite,
    EqualSpan.Keep);
foreach (diff; diffs)
    writeln(diff.toString());
```
produces this output:
```
= ["the", "quick"]
< ["brown"] |> ["red"]
= ["fox", "jumped", "over", "the"]
< ["lazy"] |> ["very", "busy"]
= ["dogs"]
```
By default the third argument is `EqualSpan.Drop`, in which case the output
from the above would be:
```
< ["brown"] |> ["red"]
< ["lazy"] |> ["very", "busy"]
```

The `Diff.toString()` method is really just for testing. Each `Diff`
struct has a `Tag` indicating the kind of difference (`Equal`, `Insert`,
`Delete`, `Replace`) and (in `a` and `b`), the relevant subslices of the
two input ranges.

See also `src/tests.d`.

# License

ddiff is free open source software (FOSS) licensed under the 
Apache License, Version 2.0.

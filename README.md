# dirtydeeds

Quick and dirty partial application of calls with possible typed arguments.

```nim
import dirtydeeds, sequtils

assert @[1, 2, 3].map(deed _ * 7) == @[7, 14, 21]
assert @["A", "B", "C"].map(deed "foo" & (_: string)) == @["fooA", "fooB", "fooC"]
assert @['a', 'f', 'A', '0', 'c'].filter(deed contains({'a'..'z'}, _)) == @['a', 'f', 'c']
```

More uses in tests. Note that this is currently only for partial application,
things like `_ + (_ - 1)` will not work.

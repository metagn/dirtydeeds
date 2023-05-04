when (compiles do: import nimbleutils/bridge):
  import nimbleutils/bridge
else:
  import unittest
import sequtils, algorithm

import dirtydeeds

test "basic cases":
  check @[1, 2, 3].map(deed _ * 7) == @[7, 14, 21]
  check @["A", "B", "C"].map(deed "foo" & (_: string)) == @["fooA", "fooB", "fooC"]
  check @['a', 'f', 'A', '0', 'c'].filter(deed contains({'a'..'z'}, _)) == @['a', 'f', 'c']
  let a = deed (_: int) + (_: int)
  check a(3, 4) == 7
  proc foo[T](a, b: T, x: proc (a, b: T): T): T = x(a, b)
  proc foo[T](a: T, x: proc (a: T): T): T = x(a)
  check foo(3, 4, deed _ + _) == 7
  let max0 = deed max(0, _: int)
  let max0left = deed max(_: int, 0)
  check max0(7) == 7
  check max0(-7) == 0
  check max0left(7) == 7
  check max0left(-7) == 0
  check foo(7, deed max(0, _)) == 7
  check foo(-7, deed max(0, _)) == 0
  check foo(7, deed max(_, 0)) == 7
  check foo(-7, deed max(_, 0)) == 0
  let b = deed (_(a): int) + a
  check b(12) == 24
  check foo(7, deed _(a) + a * 2) == 21
  var s = @[5, 3, 4, 1, 9, 2]
  s.sort(deed _ - _)
  check s == @[1, 2, 3, 4, 5, 9]
  s.sort(deed (_ a; _ b; b - a))
  check s == @[9, 5, 4, 3, 2, 1]
  let maxDefault0 = deed max(_: int, (_: int) = 0)
  check maxDefault0(7) == 7
  check maxDefault0(-7) == 0
  check maxDefault0(1, 7) == 7
  check maxDefault0(-1, -7) == -1

test "declaration":
  proc foo {.deed.} = (_: string) & (_: char | string)
  check foo("abc", 'd') == "abcd"
  check foo("abc", "def") == "abcdef"
  proc bar {.deed.} = max[_ T](_: T, _: T)
  check bar(1, 2) == 2
  check bar(-1, -2) == -1
  # only works after 2.0
  #template baz {.deed.} = toSeq _

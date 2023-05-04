# Package

version       = "0.1.0"
author        = "metagn"
description   = "macro for partially applied calls"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 1.0.0"

when (compiles do: import nimbleutils):
  import nimbleutils

task tests, "run tests for multiple backends":
  when declared(runTests):
    runTests(backends = {c, js, nims})
  else:
    echo "tests task not implemented, need nimbleutils"

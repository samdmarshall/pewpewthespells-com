version = "0.1"
author = "Samantha Marshall"
description = "website stack"
license = "BSD 3-Clause"

bin = @["rite", "ritual"]

skipFiles = @["rite.nim", "ritual.nim", "incantation.nim"]

requires "nim >= 0.15.0"
requires "yaml >= 0.9.0"
requires "jester >= 0.1.1"


task clean, "clean up from build":
  exec "rm -rd nimcache/ rite ritual"

import streams
import unittest

import "../src/incantation.nim"

let stream = newFileStream("t_incantation-junit.xml", fmWrite)
let junit = newJUnitOutputFormatter(stream)
addOutputFormatter(junit)

suite "incantation tests":
  test "":
    assert(true)

stream.flush()
junit.close()


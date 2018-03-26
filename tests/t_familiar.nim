import streams
import unittest

import "../src/familiar.nim"

let stream = newFileStream("t_familiar-junit.xml", fmWrite)
let junit = newJUnitOutputFormatter(stream)
addOutputFormatter(junit)

suite "familiar tests":
  test "":
    assert(true)

stream.flush()
junit.close()

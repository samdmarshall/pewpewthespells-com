import streams
import unittest

import "../src/familiar.nim"

let stream = newFileStream("t_familiar-junit.xml", fmWrite)
let junit = newJUnitOutputFormatter(stream)
addOutputFormatter(junit)

suite "familiar":
  test "plain text requested by header":
    assert(true)

  test "plain text requested by user-agent":
    assert(true)

stream.flush()
junit.close()

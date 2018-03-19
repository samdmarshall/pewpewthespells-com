import streams
import unittest

import "../src/feed.nim"

let stream = newFileStream("t_feed-junit.xml", fmWrite)
let junit = newJUnitOutputFormatter(stream)
addOutputFormatter(junit)

suite "feed tests":
  test "":
    assert(true)

stream.flush()
junit.close()

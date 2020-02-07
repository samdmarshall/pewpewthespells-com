import streams
import unittest

import "../src/feed.nim"

let stream = newFileStream("t_feed-junit.xml", fmWrite)
let junit = newJUnitOutputFormatter(stream)
addOutputFormatter(junit)

suite "feed":
  test "generate feed contents":
    assert(true)

  test "find items for feed":
    assert(true)

stream.flush()
junit.close()

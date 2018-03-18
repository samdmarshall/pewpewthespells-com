import streams
import unittest

var stream = newFileStream("../junit.xml", fmWrite)
var junit = newJUnitOutputFormatter(stream)
addOutputFormatter(junit)

suite "pewpewthespells.com test suite":
  test "compiles!":
    assert(true)

stream.flush()
junit.close()

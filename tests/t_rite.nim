import streams
import unittest

suite "pewpewthespells.com test suite":
  var stream = newFileStream("../junit.xml", fmWrite)
  var junit = newJUnitOutputFormatter(stream)
  addOutputFormatter(junit)

  test "compiles!":
    assert(true)


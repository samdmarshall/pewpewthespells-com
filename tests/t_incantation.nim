import streams
import unittest

import "../src/incantation.nim"

let stream = newFileStream("t_incantation-junit.xml", fmWrite)
let junit = newJUnitOutputFormatter(stream)
addOutputFormatter(junit)

let config = initSite("assets/sitemap.toml")

suite "incantation tests":
  test "rules init":
    let rules = config.rules()
    check(rules.len == 3)

  test "rule input":
    let rules = config.rules()
    check(rules[0].input == ".md")
    check(rules[1].input == ".md")
    check(rules[2].input == ".md")

  test "rule output":
    let rules = config.rules()
    check(rules[0].output == ".html")
    check(rules[1].output == ".pdf")
    check(rules[2].output == ".txt")

  test "base url":
    check(config.baseUrl() == "https://pewpewthespells.com/")

  test "root directory":
    check(config.getRoot() == "assets/../../content/site/")

  test "export directory":
    check(config.exportDir() == "/var/www/pewpewthespells.com/public_html/")

  test "validate configuration":
    check(config.validate())

stream.flush()
junit.close()


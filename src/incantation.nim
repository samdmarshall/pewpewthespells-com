import os
import parseopt
import strutils

# imports from third party libraries
import parsetoml

# defining types for the sitemap file

type
  SiteMap* = object
    data: TomlValueRef
    path: string

  Rule* = object
    status*: bool
    input*: string
    output*: string
    command*: string

  LoadError* = object of Exception

proc validate*(sitemap: SiteMap): bool =
  if not sitemap.data.hasKey("root"):
    return false
  if not sitemap.data["root"].hasKey("directory"):
    return false
  if not sitemap.data.hasKey("export"):
    return false
  let export_directory = sitemap.data["export"].hasKey("directory")
  let export_base_url = sitemap.data["export"].hasKey("base_url")
  let export_rss = sitemap.data["export"].hasKey("rss")
  if not export_directory or not export_base_url or not export_rss:
    return false
  if not sitemap.data.hasKey("rules"):
    return false
  return true

proc sitemapRoot*(sitemap: SiteMap): string =
  return sitemap.path.parentDir()

proc initSite*(path: string): SiteMap {.raises: [OSError, IOError, Defect, TomlError, KeyError, Exception].} =
  if not path.fileExists():
    raise newException(OSError, "File path does not exist!")
  {.gcsafe.}:
    let table = parsefile(path)
    let map = SiteMap(data: table, path: path)
    let is_valid = map.validate()
    if not is_valid:
      raise newException(IOError, "Unable to parse contents of sitemap file!")
    return map

proc rules*(sitemap: SiteMap, disabled: seq[string] = @[]): seq[Rule] =
  var rules = newSeq[Rule]()
  var rule_data = sitemap.data["rules"]
  assert(rule_data.kind == TomlValueKind.Array)
  var defined_rules = rule_data.arrayVal
  for current_rule in defined_rules:
    assert(current_rule.kind == TomlValueKind.Table)
    let value = current_rule.tableVal
    let name = "$#2$#" % [value["input"].getStr().strip(true, false, {'.'}), value["output"].getStr().strip(true, false, {'.'})]
    let enabled = name notin disabled
    let rule = Rule(status: enabled, input: value["input"].getStr(), output: value["output"].getStr(), command: value["command"].getStr())
    rules.add(rule)
  return rules

proc getRule*(sitemap: SiteMap, name: string): Rule =
  for rule in sitemap.rules():
    let rule_name = "$#2$#" % [rule.input.strip(true, false, {'.'}), rule.output.strip(true, false, {'.'})]
    if name == rule_name:
      result = rule
      break

proc exportDir*(sitemap: SiteMap): string =
  let dir = sitemap.data["export"]["directory"].getStr()
  if dir.startsWith("/"):
    return dir
  else:
    return sitemap.sitemapRoot().joinPath(dir)

proc baseUrl*(sitemap: SiteMap): string =
  return sitemap.data["export"]["base_url"].getStr()

proc getRoot*(sitemap: SiteMap): string =
  return sitemap.sitemapRoot().joinPath(sitemap.data["root"]["directory"].getStr())

proc getRssFeedDir*(sitemap: SiteMap): string =
  return sitemap.exportDir().joinPath(sitemap.data["export"]["rss"].getStr())

proc getSitemapFile*(): string =
  for kind, key, value in getopt():
    case kind
    of cmdArgument:
      return key.expandTilde().expandFilename()
    else:
      discard


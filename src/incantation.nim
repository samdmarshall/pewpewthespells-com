import os
import strutils
import streams
import parseopt

# imports from third party libraries
import parsetoml

# defining types for the sitemap file

type
  SiteMap* = object
    data: TomlValueRef
    path: string

  Rule* = object
    input*: string
    output*: string
    command*: string


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

proc initSite*(path: string): SiteMap =
  if path.fileExists():
    let table = parsefile(path)
    let map = SiteMap(data: table, path: path)
    if map.validate():
      return map
  echo "Unable to load sitemap file!"
  quit(QuitFailure)

proc rules*(sitemap: SiteMap): seq[Rule] =
  var defined_rules = sitemap.data["rules"].arrayVal
  var rules = newSeq[Rule]()
  for current_rule in defined_rules:
    let value = current_rule.tableVal
    let rule = Rule(input: value["input"].getStr(),
        output: value["output"].getStr(), command: value["command"].getStr())
    rules.add(rule)
  return rules

proc exportDir*(sitemap: SiteMap): string =
  let dir = sitemap.data["export"]["directory"].getStr()
  if dir.startsWith("/"):
    return dir
  else:
    return sitemap.sitemapRoot().joinPath(dir)

proc baseUrl*(sitemap: SiteMap): string =
  return sitemap.data["export"]["base_url"].getStr()

proc getRoot*(sitemap: SiteMap): string =
  return sitemap.sitemapRoot().joinPath(sitemap.data["root"][
      "directory"].getStr())

proc getRssFeedDir*(sitemap: SiteMap): string =
  return sitemap.exportDir().joinPath(sitemap.data["export"]["rss"].getStr())

proc getSitemapFile*(): string =
  for kind, key, value in getopt():
    case kind
    of cmdArgument:
      return key.expandTilde().expandFilename()
    else:
      discard

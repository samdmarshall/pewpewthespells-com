import os
import streams
import parseopt

# imports from third party libraries
import parsetoml

# defining types for the sitemap file
##

type
  SiteMap* = object
    data: TomlTableRef
    path: string

  Rule* = object
    input*: string
    output*: string
    command*: string

proc sitemapRoot(sitemap: SiteMap): string =
  let (dir, _, _) = splitFile(sitemap.path)
  return dir

proc initSite*(path: string): SiteMap =
  if path.fileExists():
    return SiteMap(data: parseFile(path), path: path)
  else:
    echo "Unable to load sitemap file!"
    quit(QuitFailure)

proc rules*(sitemap: SiteMap): seq[Rule] =
  var defined_rules = sitemap.data.getValueFromFullAddr("rules").arrayVal
  var rules = newSeq[Rule]()
  for current_rule in defined_rules:
    let value = current_rule.tableVal
    let rule = Rule(input: value.getString("input"), output: value.getString("output"), command: value.getString("command"))
    rules.add(rule)
  return rules

proc exportDir*(sitemap: SiteMap): string =
  return sitemap.sitemapRoot().joinPath(sitemap.data.getString("export.directory"))

proc baseUrl*(sitemap: SiteMap): string =
  return sitemap.data.getString("export.base_url")

proc getRoot*(sitemap: SiteMap): string =
  return sitemap.sitemapRoot().joinPath(sitemap.data.getString("root.directory"))

proc getSitemapFile*(): string =
  for kind, key, value in getopt():
    case kind
    of cmdArgument:
      return key.expandTilde().expandFilename()
    else:
      discard

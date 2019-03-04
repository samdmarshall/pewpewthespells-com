# =======
# imports
# =======
import os
import sequtils
import strutils

import "incantation.nim"
import "feed.nim"
import "familiar.nim"

# ================
# global constants
# ================
const RuleInputFileTag = "%input%"
const RuleOutputFileTag = "%output%"
const RuleSelfDirTag = "%self%"
const DefaultPermissions = {fpUserRead, fpUserWrite, fpGroupRead,
    fpOthersRead}

# =========
# Functions
# =========

proc filterRules(rules: seq[Rule], ext: string): seq[Rule] =
  var applicable_rules = newSeq[Rule]()
  for rule in rules:
    if rule.input == ext:
      applicable_rules.add(rule)
  return applicable_rules

proc isStale(input_path: string, output_path: string): bool =
  let is_exported = fileExists(output_path)
  if not is_exported:
    return true
  let is_up_to_date = output_path.fileNewer(input_path)
  return not (is_exported and is_up_to_date)

proc processDirectory(sitemap: SiteMap, dir_path: string) =
  var all_rules = sitemap.rules()
  for kind, path in walkDir(dir_path):
    var exit_code = 0
    let (_, _, ext) = path.splitFile()
    var relative_path = path
    removePrefix(relative_path, sitemap.getRoot())
    let export_path = sitemap.exportDir().joinPath(relative_path)
    case kind
    of pcFile:
      let applicable_rules = filterRules(all_rules, ext)
      if len(applicable_rules) > 0:
        for rule in applicable_rules:
          let (out_dir, out_name, _) = export_path.splitFile()
          let export_path_ext = out_dir.joinPath(out_name & rule.output)
          var output_export_path = export_path_ext
          removePrefix(output_export_path, sitemap.exportDir())
          if isStale(path, export_path_ext):
            var command_template = rule.command
            command_template = command_template.replace(RuleInputFileTag, path)
            command_template = command_template.replace(RuleOutputFileTag, export_path_ext)
            command_template = command_template.replace(RuleSelfDirTag, sitemap.sitemapRoot())
            echo "Generating '" & output_export_path & "'..."
            exit_code = execShellCmd(command_template)
            export_path_ext.setFilePermissions(DefaultPermissions)
          else:
            echo "Skipping '" & output_export_path & "'..."
      else:
        if isStale(path, export_path):
          echo "Copying '" & relative_path & "'..."
          copyFile(path, export_path)
          export_path.setFilePermissions(DefaultPermissions)
        else:
          echo "Skipping '" & relative_path & "'..."
    of pcDir:
      if not dirExists(export_path):
        echo "Creating '" & relative_path & "/'..."
        createDir(export_path)
        export_path.setFilePermissions(DefaultPermissions)
      processDirectory(sitemap, path)
    else:
      discard
    if exit_code != 0:
      echo "Error in processing '" & relative_path & "', aborting..."
      quit(QuitFailure)

# ===========================================
# this is the entry-point, there is no main()
# ===========================================

when isMainModule:
  let sitemap_file_path = getSitemapFile()
  let sitemap = initSite(sitemap_file_path)
  let website_root = sitemap.exportDir()
  echo "Exporting to: " & website_root

  createDir(website_root)

  let feed_items = rssFeedContents(sitemap.getRssFeedDir())
  let feed_contents = generateRssFeedXml(sitemap.base_url, website_root, feed_items)

  block:
    let rss_feed_path = website_root / "feed.xml"
    let file = open(rss_feed_path, fmReadWrite)
    file.write(feed_contents)
    file.close()
    rss_feed_path.setFilePermissions(DefaultPermissions)

  processDirectory(sitemap, sitemap.getRoot())

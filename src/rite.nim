# =======
# imports
# =======
import os
import parseopt
import sequtils
import strutils

import "feed.nim"
import "calendar.nim"
import "familiar.nim"
import "incantation.nim"

# ================
# global constants
# ================
const RuleInputFileTag = "%input%"
const RuleOutputFileTag = "%output%"
const RuleSelfDirTag = "%self%"
const DefaultPermissions = {fpUserRead, fpUserWrite, fpGroupRead, fpOthersRead}

# =========
# Functions
# =========

proc filterRules(rules: seq[Rule], ext: string): seq[Rule] =
  var applicable_rules = newSeq[Rule]()
  for rule in rules:
    if rule.input == ext and rule.status:
      applicable_rules.add(rule)
  return applicable_rules

proc isStale(input_path: string, output_path: string): bool =
  let is_exported = fileExists(output_path)
  if not is_exported:
    return true
  let is_up_to_date = output_path.fileNewer(input_path)
  return not (is_exported and is_up_to_date)

proc processDirectory(sitemap: SiteMap, dir_path: string, disabled_rules: seq[string]) =
  var all_rules = sitemap.rules(disabled_rules)
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
      processDirectory(sitemap, path, disabled_rules)
    else:
      discard
    if exit_code != 0:
      raise newException(OSError, "Error in processing '" & relative_path & "', aborting...")

# ===========================================
# this is the entry-point, there is no main()
# ===========================================

proc main() =
  let sitemap_file_path = getSitemapFile()
  let sitemap = initSite(sitemap_file_path)
  let website_root = sitemap.exportDir()
  echo "Exporting to: " & website_root

  createDir(website_root)

  var disabled_rules = newSeq[string]()
  var disable_rss_feed = false
  var disable_certificate_ics = false

  var rule_names = newSeq[string]()
  for rule in sitemap.rules():
    rule_names.add "$#2$#" % [rule.input.strip(true, false, {'.'}), rule.output.strip(true, false, {'.'})]

  var parser = initOptParser()
  for kind, key, value in parser.getopt():
    case kind
    of cmdArgument: discard
    of cmdLongOption, cmdShortOption:
      case key
      of "disable":
        case value
        of "rss-feed":
          disable_rss_feed = true
        of "certificate-ics":
          disable_certificate_ics = true
        else: discard
      of "disable-rule":
        if value in rule_names:
          disabled_rules.add(value)
    else: discard

  block RssFeed:
    if disable_rss_feed: break
    let feed_items = rssFeedContents(sitemap.getRssFeedDir())
    let feed_contents = generateRssFeedXml(sitemap.base_url, website_root, feed_items)
    let rss_feed_path = website_root / "feed.xml"
    echo "Creating '$#'..." % [rss_feed_path]
    let file = open(rss_feed_path, fmReadWrite)
    file.write(feed_contents)
    file.close()
    rss_feed_path.setFilePermissions(DefaultPermissions)

  block CertificateCalendar:
    if disable_certificate_ics: break
    let calendar_contents = getCertificateExpiryCalendar()
    let certificate_calendar_path = website_root / "calendar.ics"
    echo "Creating '$#'..." % [certificate_calendar_path]
    let file = open(certificate_calendar_path, fmReadWrite)
    file.write(calendar_contents)
    file.close()
    certificate_calendar_path.setFilePermissions(DefaultPermissions)

  processDirectory(sitemap, sitemap.getRoot(), disabled_rules)


when isMainModule:
  main()

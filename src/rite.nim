# =======
# imports
# =======
import os
import sequtils
import strutils

import "incantation.nim"

# ================
# global constants
# ================
const RuleInputFileTag = "%input%"
const RuleOutputFileTag = "%output%"

# =========
# Functions
# =========

proc processDirectory(sitemap: SiteMap, dir_path: string) =
  for kind, path in walkDir(dir_path):
    var exit_code = 0
    let (_, _, ext) = path.splitFile()
    var relative_path = path
    removePrefix(relative_path, sitemap.getRoot())
    let export_path = sitemap.exportDir().joinPath(relative_path)
    case kind
    of pcFile:
      let applicable_rules = sitemap.rules().filter(proc (rule: Rule): bool = rule.input == ext)
      if len(applicable_rules) > 0:
        for rule in applicable_rules:
          let (out_dir, out_name, _) = export_path.splitFile()
          let export_path_ext = out_dir.joinPath(out_name & rule.output)
          var output_export_path = export_path_ext
          removePrefix(output_export_path, sitemap.exportDir())
          var command_template = rule.command
          command_template = command_template.replace(RuleInputFileTag, path)
          command_template = command_template.replace(RuleOutputFileTag, export_path_ext)
          echo "Generating '" & output_export_path & "'..."
          exit_code = execShellCmd(command_template)
      else:
        copyFile(path, export_path)
    of pcDir:
      createDir(export_path)
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
  createDir(sitemap.exportDir().expandFilename())
  processDirectory(sitemap, sitemap.getRoot())

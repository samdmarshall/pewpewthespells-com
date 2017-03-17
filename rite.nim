# imports from standard library
##
import os
import sequtils
import strutils

import "incantation.nim"

type
  website_file = object
    file: sitemap_website_file
    rules: seq[sitemap_generation_rule]

  processed_file_result = object
    successful_status: bool
    exported_files: seq[string]

# global constants
##
const RuleInputFileTag = "%input%"
const RuleOutputFileTag = "%output%"
const RuleOutputDirTag = "%output_dir%"
const RuleSelfDirTag = "%self%"

#
##
proc getWebsiteFileFullPath(sitemap_file_path: string, relative_path: string): string =
  let website_relative_file_path = relative_path
  let website_base_path = sitemap_file_path.parentDir()
  return website_base_path.joinPath(website_relative_file_path)

proc getRawFileExtension(path: string): string =
  let (_, _, ext) = path.splitFile()
  return ext.strip(chars={'.'})

#
##
proc fileRequiresProcessing(website_file_full_path: string, export_extensions: seq[string]): bool =
  let file_extension = website_file_full_path.getRawFileExtension()
  return not (file_extension in export_extensions)

#
##
proc getExportBasePath(sitemap_data: sitemap, sitemap_file_path: string): string =
  let website_base_path = sitemap_file_path.parentDir()
  let export_path = sitemap_data.export_dir
  result = website_base_path.joinPath(export_path)

#
##
proc getExportPath(sitemap_data: sitemap, sitemap_file_path: string, relative_path: string): string =
  let full_export_base_path = sitemap_data.getExportBasePath(sitemap_file_path)
  return full_export_base_path.joinPath(relative_path)

# process a file based on the rules
##
proc processFile(sitemap_data: sitemap, sitemap_file_path: string, file_item: website_file): processed_file_result =
  var exit_code: int = 1
  var files_as_input: seq[string] = @[]
  var files_as_output: seq[string] = @[]
  let website_full_path = sitemap_file_path.getWebsiteFileFullPath(file_item.file.name)
  files_as_input.add(website_full_path)
  for desired_export_format in file_item.file.export_as.split(';'):
    let (dir, name, _) = file_item.file.name.splitFile()
    let export_item_relative_path = dir.joinPath(name & "." & desired_export_format)
    let export_item_name = sitemap_data.getExportPath(sitemap_file_path, export_item_relative_path)
    let export_item_name_dir = export_item_name.parentDir()
    os.createDir(export_item_name_dir)
    let applicable_rules = filter(file_item.rules, proc(rule: sitemap_generation_rule): bool = desired_export_format == rule.export_as)
    for rule in applicable_rules:
      let applicable_inputs = filter(files_as_input, proc(file: string): bool = getRawFileExtension(file) == rule.import_as)
      if applicable_inputs.len > 0:
        var exec_command = rule.cmd
        exec_command = exec_command.replace(RuleInputFileTag, applicable_inputs[0])
        exec_command = exec_command.replace(RuleOutputFileTag, export_item_name)
        exec_command = exec_command.replace(RuleOutputDirTag, sitemap_data.getExportBasePath(sitemap_file_path))
        exec_command = exec_command.replace(RuleSelfDirTag, sitemap_file_path.parentDir())
        exit_code = execShellCmd(exec_command)
        files_as_input.add(export_item_name)
    if applicable_rules.len == 0:
      let src = files_as_input[0]
      let dest = export_item_name
      copyFile(src, dest)
      exit_code = 0
    files_as_output.add(export_item_name)
    files_as_input = files_as_input.deduplicate()
  return processed_file_result(successful_status: exit_code == 0, exported_files: files_as_output)

# ===========================================
# this is the entry-point, there is no main()
# ===========================================

when isMainModule:
  let sitemap_file_path = getSitemapFile()
  let sitemap_data = initWebsite(sitemap_file_path)

  for website_file_item in sitemap_data.files:
    let website_full_file_path = sitemap_file_path.getWebsiteFileFullPath(website_file_item.name)
    let website_file_export_formats = website_file_item.export_as.split(';')
    var processing_rules_to_apply = newSeq[sitemap_generation_rule]()
    if fileRequiresProcessing(website_full_file_path, website_file_export_formats):
      for export_file_format in website_file_export_formats:
        let found_rules = sequtils.filter(sitemap_data.rules, proc (rule: sitemap_generation_rule): bool = export_file_format == rule.export_as)
        processing_rules_to_apply.add(found_rules)
    let processed_file = website_file(file: website_file_item, rules: processing_rules_to_apply)
    let output = sitemap_data.processFile(sitemap_file_path, processed_file)
    if output.successful_status:
      for item in output.exported_files:
        let path = item.expandFileName()
        echo("generating '" & path & "'...")
    else:
      echo("failure in generation!!")
      break

# imports from standard library
##
import os
import streams
import sequtils
import strutils
import parseopt2

# imports from third party libraries
##
import yaml

# defining types for the sitemap file
##

type sitemap_generation_rule = object
  import_as: string
  export_as: string
  cmd: string

type sitemap_website_file = object
  name: string
  export_as: string
  update: bool

type sitemap = object
  export_dir: string
  rules: seq[sitemap_generation_rule]
  files: seq[sitemap_website_file]

type website_file = object
  file: sitemap_website_file
  rules: seq[sitemap_generation_rule]

type processed_file_result = object
  successful_status: bool
  exported_files: seq[string]

# global constants
##
const RuleInputFileTag = "%input%"
const RuleOutputFileTag = "%output%"
const RuleOutputDirTag = "%output_dir%"
const RuleSelfDirTag = "%self%"

# global variables
##
var sitemap_data: sitemap
var sitemap_file_path: string = ""
var should_upload: bool = false

#
##
proc getWebsiteFileFullPath(relative_path: string): string =
  let website_relative_file_path = relative_path
  let website_base_path = sitemap_file_path.parentDir()
  result = website_base_path.joinPath(website_relative_file_path)

proc getRawFileExtension(path: string): string =
  let (_, _, ext) = path.splitFile()
  result = ext.strip(chars={'.'})

#
##
proc fileRequiresProcessing(website_file_full_path: string, export_extensions: seq[string]): bool =
  let file_extension = getRawFileExtension(website_file_full_path)
  result = not (file_extension in export_extensions)

#
##
proc getExportBasePath(): string =
  let website_base_path = os.parentDir(sitemap_file_path)
  let export_path = sitemap_data.export_dir
  result = os.joinPath(website_base_path, export_path)

#
##
proc getExportPath(relative_path: string): string =
  let full_export_base_path = getExportBasePath()
  result = os.joinPath(full_export_base_path, relative_path)

# process a file based on the rules
##
proc processFile(file_item: website_file): processed_file_result =
  var exit_code: int = 1
  var files_as_input: seq[string] = @[]
  var files_as_output: seq[string] = @[]
  let website_full_path = getWebsiteFileFullPath(file_item.file.name)
  files_as_input.add(website_full_path)
  for desired_export_format in file_item.file.export_as.split(';'):
    let (dir, name, _) = file_item.file.name.splitFile()
    let export_item_relative_path = dir.joinPath(name & "." & desired_export_format)
    let export_item_name = getExportPath(export_item_relative_path)
    let export_item_name_dir = export_item_name.parentDir()
    os.createDir(export_item_name_dir)
    let applicable_rules = filter(file_item.rules, proc(rule: sitemap_generation_rule): bool = desired_export_format == rule.export_as)
    for rule in applicable_rules:
      let applicable_inputs = filter(files_as_input, proc(file: string): bool = getRawFileExtension(file) == rule.import_as)
      if applicable_inputs.len > 0:
        var exec_command = rule.cmd
        exec_command = exec_command.replace(RuleInputFileTag, applicable_inputs[0])
        exec_command = exec_command.replace(RuleOutputFileTag, export_item_name)
        exec_command = exec_command.replace(RuleOutputDirTag, getExportBasePath())
        exec_command = exec_command.replace(RuleSelfDirTag, sitemap_file_path.parentDir())
        echo("Running '" & exec_command & "'...")
        exit_code = execShellCmd(exec_command)
        files_as_input.add(export_item_name)
    if applicable_rules.len == 0:
      let src = files_as_input[0]
      let dest = export_item_name
      echo("Copying " & src & " to " & dest & "..")
      copyFile(src, dest)
      exit_code = 0
    files_as_output.add(export_item_name)
    files_as_input = files_as_input.deduplicate()
  result = processed_file_result(successful_status: exit_code == 0, exported_files: files_as_output)

#
##
proc filterUploadableFiles(uploadable_website_file: website_file): seq[string] =
  result = @[]
  let process_result = processFile(uploadable_website_file)
  if not process_result.successful_status:
      echo("error in processing file: " & uploadable_website_file.file.name & "!")
  else:
    result = process_result.exported_files

# ===========================================
# this is the entry-point, there is no main()
# ===========================================

for kind, key, value in getopt():
  case kind
  of cmdArgument:
    let expanded_path: string = os.expandTilde(key)
    sitemap_file_path = os.expandFilename(expanded_path)
  else:
    discard

if sitemap_file_path.fileExists():
  let sitemap_file_descriptor = newFileStream(sitemap_file_path)
  yaml.serialization.load(sitemap_file_descriptor, sitemap_data)
  sitemap_file_descriptor.close()

let website_files_to_check = filter(sitemap_data.files, proc(file: sitemap_website_file): bool = file.update)
var website_files_to_process: seq[website_file] = @[]

for website_file_item in website_files_to_check:
  let website_full_file_path = getWebsiteFileFullPath(website_file_item.name)
  let website_file_export_formats = website_file_item.export_as.split(';')
  var processing_rules_to_apply = newSeq[sitemap_generation_rule]()
  if fileRequiresProcessing(website_full_file_path, website_file_export_formats):
    for export_file_format in website_file_export_formats:
      let found_rules = sequtils.filter(sitemap_data.rules, proc (rule: sitemap_generation_rule): bool = export_file_format == rule.export_as)
      processing_rules_to_apply.add(found_rules)
  let processed_file = website_file(file: website_file_item, rules: processing_rules_to_apply)
  website_files_to_process.add(processed_file)

# iterate over the contents of the website that should be updated
for item in website_files_to_process:
  discard filterUploadableFiles(item)


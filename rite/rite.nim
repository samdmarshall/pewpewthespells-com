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

type sitemap_server = object
  user: string
  host: string
  path: string

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
  server: sitemap_server
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

# get the name of the program that is being run
##
proc progName(): string =
  result = os.extractFilename(os.getAppFilename())

# define the usage for "--help"
##
proc usage =
  echo("usage: " & progName() & " [--help|-h] [-v|--version] ")

# define the version number
##
proc versionInfo =
  echo(progName() & " v0.1")

#
##
proc getWebsiteFileFullPath(relative_path: string): string =
  let website_relative_file_path = relative_path
  let website_base_path = os.parentDir(sitemap_file_path)
  result = os.joinPath(website_base_path, website_relative_file_path)

proc getRawFileExtension(path: string): string =
  let (_, _, ext) = os.splitFile(path)
  result = strutils.strip(ext, chars={'.'})

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
  for desired_export_format in strutils.split(file_item.file.export_as, ';'):
    let (dir, name, _) = os.splitFile(file_item.file.name)
    let export_item_relative_path = os.joinPath(dir, name & "." & desired_export_format)
    let export_item_name = getExportPath(export_item_relative_path)
    let export_item_name_dir = os.parentDir(export_item_name)
    os.createDir(export_item_name_dir)
    let applicable_rules = sequtils.filter(file_item.rules, proc(rule: sitemap_generation_rule): bool = desired_export_format == rule.export_as)
    for rule in applicable_rules:
      let applicable_inputs = sequtils.filter(files_as_input, proc(file: string): bool = getRawFileExtension(file) == rule.import_as)
      if applicable_inputs.len > 0:
        var exec_command = rule.cmd
        exec_command = strutils.replace(exec_command, RuleInputFileTag, applicable_inputs[0])
        exec_command = strutils.replace(exec_command, RuleOutputFileTag, export_item_name)
        exec_command = strutils.replace(exec_command, RuleOutputDirTag, getExportBasePath())
        exec_command = strutils.replace(exec_command, RuleSelfDirTag, os.parentDir(sitemap_file_path))
        echo("Running '" & exec_command & "'...")
        exit_code = os.execShellCmd(exec_command)
        files_as_input.add(export_item_name)
    if applicable_rules.len == 0:
      let src = files_as_input[0]
      let dest = export_item_name
      echo("Copying " & src & " to " & dest & "..")
      os.copyFile(src, dest)
      exit_code = 0
    files_as_output.add(export_item_name)
    files_as_input = sequtils.deduplicate(files_as_input)
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

for kind, key, value in parseopt2.getopt():
  case kind
  of cmdLongOption, cmdShortOption:
    case key
    of "upload":
      should_upload = true
    of "help", "h":
      usage()
    of "version", "v":
      versionInfo()
    else: discard
  of cmdArgument:
    let expanded_path: string = os.expandTilde(key)
    sitemap_file_path = os.expandFilename(expanded_path)
  else: discard

if os.fileExists(sitemap_file_path):
  let sitemap_file_descriptor = streams.newFileStream(sitemap_file_path)
  yaml.serialization.load(sitemap_file_descriptor, sitemap_data)
  sitemap_file_descriptor.close()

let website_files_to_check = filter(sitemap_data.files, proc(file: sitemap_website_file): bool = file.update)
var website_files_to_process: seq[website_file] = @[]

for website_file_item in website_files_to_check:
  let website_full_file_path = getWebsiteFileFullPath(website_file_item.name)
  let website_file_export_formats = strutils.split(website_file_item.export_as, ';')
  var processing_rules_to_apply = newSeq[sitemap_generation_rule]()
  if fileRequiresProcessing(website_full_file_path, website_file_export_formats):
    for export_file_format in website_file_export_formats:
      let found_rules = sequtils.filter(sitemap_data.rules, proc (rule: sitemap_generation_rule): bool = export_file_format == rule.export_as)
      processing_rules_to_apply.add(found_rules)
  let processed_file = website_file(file: website_file_item, rules: processing_rules_to_apply)
  website_files_to_process.add(processed_file)

# clear any existing cached directory first, then create the export 
# directory now we have a list of what should be exported.
##
let export_base_path = getExportBasePath()
let export_path_is_defined = export_base_path.len > 0
if export_path_is_defined:
  os.removeDir(export_base_path)
  os.createDir(export_base_path)

# iterate over the contents of the website that should be updated
let seqs_of_files_to_upload: seq[seq[string]] = sequtils.map(website_files_to_process, filterUploadableFiles)
let files_to_upload: seq[string] = sequtils.concat(seqs_of_files_to_upload)

if should_upload and export_path_is_defined:
  for file_path in files_to_upload:
    let relative_path = strutils.replace(file_path, export_base_path, "")
    let scp_command = "scp "&file_path&" "&sitemap_data.server.user&"@"&sitemap_data.server.host&":"&sitemap_data.server.path&relative_path
    let exit_code = os.execShellCmd(scp_command)
    discard exit_code
  # removing the export directory now we are done
  ##
  os.removeDir(getExportBasePath())

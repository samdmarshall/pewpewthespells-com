import os
import streams
import parseopt2

# imports from third party libraries
##
import yaml

# defining types for the sitemap file
##

type 
  sitemap_generation_rule* = object
    import_as*: string
    export_as*: string
    cmd*: string

  sitemap_website_file* = object
    name*: string
    export_as*: string
    update*: bool

  sitemap* = object
    export_dir*: string
    rules*: seq[sitemap_generation_rule]
    files*: seq[sitemap_website_file]


proc initWebsite*(path: string): sitemap =
  var sitemap_data: sitemap
  if path.fileExists():
    let sitemap_file_descriptor = newFileStream(path)
    yaml.serialization.load(sitemap_file_descriptor, sitemap_data)
    sitemap_file_descriptor.close()
  return sitemap_data

proc getSitemapFile*(): string =
  for kind, key, value in getopt():
    case kind
    of cmdArgument:
      return key.expandTilde().expandFilename()
    else:
      discard

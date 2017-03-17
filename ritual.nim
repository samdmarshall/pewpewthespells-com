# =======
# Imports
# =======

import os
import asyncdispatch

import jester

import "incantation.nim"

# ===========
# Entry Point
# ===========

let sitemap_file_path = getSitemapFile()
let sitemap_data = initWebsite(sitemap_file_path)

let (content_root, _, _) = sitemap_file_path.splitFile()
let website_root = content_root.joinPath(sitemap_data.export_dir)

settings:
  staticDir = expandFilename(website_root)

routes:
  get "/":
    pass() # pass directly onto the static hosted content

runForever()

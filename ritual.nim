# =======
# Imports
# =======

import os
import strutils
import asyncdispatch

import jester
import parsetoml

import "incantation.nim"
import "ritual-src/init.nim"
import "ritual-src/feed.nim"

# =========
# Functions
# =========


# ===========
# Entry Point
# ===========

let sitemap_file_path = getSitemapFile()
var sitemap = initSite(sitemap_file_path)

let (content_root, _, _) = sitemap_file_path.splitFile()
let website_root = content_root.joinPath(sitemap.exportDir())
echo website_root

if not website_root.existsDir():
  echo("website root doesn't exist, please generate it using `rite` first!")
  quit(QuitFailure)

let feed_items = rssFeedContents(website_root)
echo feed_items

let feed_contents = generateRssFeedXml(sitemap.base_url, feed_items)

settings:
  staticDir = website_root

routes:
  get "/feed.xml":
    resp feed_contents
  get "/":
    pass() # pass directly onto the static hosted content

runForever()

# =======
# Imports
# =======

import os
import re
import times
import ospaths
import sequtils
import strutils
import asyncdispatch

import jester
import parsetoml

import "incantation.nim"
import "feed.nim"
import "familiar.nim"

# =========
# Functions
# =========

proc transDayOfVisibility(): bool =
  let today = now()
  return (today.month == mMar and today.monthday == 31)

# ===========
# Entry Point
# ===========

let sitemap_file_path = getSitemapFile()
var sitemap = initSite(sitemap_file_path)

let website_root = sitemap.exportDir()

if not website_root.existsDir():
  echo("website root doesn't exist, please generate it using `rite` first!")
  quit(QuitFailure)

let feed_items = rssFeedContents(sitemap.getRssFeedDir())
let feed_contents = generateRssFeedXml(sitemap.base_url, website_root, feed_items)

settings:
  staticDir = website_root

routes:
  get "/feed.xml":
    resp feed_contents
  get "/keybase.txt":
    pass()
  get "/.well_known/keybase.txt":
    pass()
  get re"^\/.*":
    if transDayOfVisibility():
      redirect("https://wewantto.live")
    if request.path == "/":
      redirect("/index.html")
    else:
      var file = request.path 
      if wantsPlainTextContent(request):
        file = request.path.changeFileExt("txt")
      let requested_path = website_root & file
      if existsFile(requested_path):
        sendFile(requested_path)
      else:
        resp Http404

runForever()

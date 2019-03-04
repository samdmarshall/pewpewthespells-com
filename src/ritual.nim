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

# =============
# Configuration
# =============

settings:
  appName = "pewpewthespells-com"
  staticDir = initSite(getSitemapFile()).exportDir()

routes:
  get "/feed.xml":
    sendfile(getTempDir() / "ritual.rss")
  get re"^\/.*":
    if transDayOfVisibility():
      redirect("https://wewantto.live")
    if request.path == "/":
      redirect("/index.html")
    else:
      var file = request.path
      if wantsPlainTextContent(request):
        file = request.path.changeFileExt("txt")
      let requested_path = request.getStaticDir() & file
      if existsFile(requested_path):
        sendFile(requested_path)
      else:
        resp Http404

# ===========
# Entry Point
# ===========

when isMainModule:
  let sitemap = initSite(getSitemapFile())
  let website_root = sitemap.exportDir()
  if website_root.existsDir():
    let feed_items = rssFeedContents(sitemap.getRssFeedDir())
    let feed_contents = generateRssFeedXml(sitemap.base_url, website_root,
        feed_items)
    let feed_file_path = getTempDir() / "ritual.rss"
    feed_file_path.writeFile(feed_contents)
    runForever()
  else:
    quit(QuitFailure)

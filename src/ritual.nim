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

proc getSitemap(): SiteMap =
  let path = getSitemapFile()
  return initSite(path)

proc rssFeed(req: Request): string =
  let sitemap = getSitemap()
  let feed_items = rssFeedContents(sitemap.getRssFeedDir())
  let feed_contents = generateRssFeedXml(sitemap.base_url,
      req.getStaticDir(),
      feed_items)
  return feed_contents

proc checkInit(): bool =
  let website_root = getSitemap().exportDir()
  return website_root.existsDir()

# =============
# Configuration
# =============

settings:
  staticDir = initSite(getSitemapFile()).exportDir()

routes:
#  get "/feed.xml":
#    resp rssFeed(request)
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
      let requested_path = request.getStaticDir() & file
      if existsFile(requested_path):
        sendFile(requested_path)
      else:
        resp Http404

# ===========
# Entry Point
# ===========

when isMainModule:
  if checkInit():
    runForever()
  quit(QuitFailure)

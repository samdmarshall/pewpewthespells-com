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
  staticDir = initSite(getSitemapFile()).exportDir()

routes:
  get re"^\/.*":
    if transDayOfVisibility():
      redirect("https://wewantto.live")
    if request.path.endsWith("/"):
      redirect(request.path & "index.html")
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
    runForever()
  else:
    quit(QuitFailure)

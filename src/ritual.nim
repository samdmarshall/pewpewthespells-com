
# =======
# Imports
# =======

import os
import re
import net
import times
import ospaths
import sequtils
import strutils
import asyncdispatch

import jester

import "incantation.nim"
import "familiar.nim"

# =========
# Functions
# =========

proc transDayOfVisibility(): bool =
  let today = now()
  result = (today.month == mMar and today.monthday == 31)

# ====================
# Supplimental Routers
# ====================

# Router to provide the corresponding "index.html" as page contents for directory urls
router indexPage:
  get "/":
    sendFile request.settings.staticDir / request.path / "index.html"

# Router for calling out the keybase.txt file locations
router keybase:
  get "/keybase.txt":
    sendFile request.settings.staticDir / request.path

# Router for subscription-based addresses (RSS Feeds and iCalendar files)
router subscriptions:
  get "/feed.xml":
    sendFile request.settings.staticDir / request.path
  get "/calendar.ics":
    sendFile request.settings.staticDir / request.path

# ==============
# Primary Router
# ==============

# Router that contains all others
router pewpewthespells:

  #[ === Keybase Proofs === ]#
  extend keybase, ""             # https://pewpewthespells.com
  extend keybase, "/.well-known" # http://pewpewthespells.com

  #[ === Subscriptions === ]#
  extend subscriptions, ""

  #[ === Pre-request Hook === ]#
  before:
    if transDayOfVisibility():
      sendFile request.settings.staticDir / "tdov.html"

  #[ === Provide Directories as pages === ]#
  extend indexPage, ""
  extend indexPage, "/blog"
  extend indexPage, "/conf"

  #[ === Legacy Pages === ]#
  get "/ramble.html": redirect "/blog/"
  get "/confs.html":  redirect "/conf/"
  get "/re.html":     redirect "/blog/re.html"

  #[ === Catch-All === ]#
  get re".*\.html$":
    let origin = parseIpAddress(request.ip)
    let userAgent = request.headers
    let meth = request.reqMethod

    let original_file = request.settings.staticDir / request.path
    var requested_file =
      if wantsPlainTextContent(request):
        original_file.changeFileExt("txt")
      else:
        original_file

    if existsFile(requested_file):
      sendFile requested_file
    elif existsFile(original_file):
      sendFile original_file
    else:
      resp Http404

# ===========
# Entry Point
# ===========

when isMainModule:
  let path = getSitemapFile()
  let sitemap = initSite(path)
  let config = newSettings(staticDir = sitemap.exportDir())
  var website = initJester(pewpewthespells, settings=config)
  website.serve()

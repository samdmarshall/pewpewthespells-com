# =======
# Imports
# =======

import os
import asyncdispatch

import jester

# ===========
# Entry Point
# ===========

settings:
  staticDir = expandFilename(getAppDir().joinPath("../content/public/"))

routes:
  get "/":
    pass() # pass directly onto the static hosted content

runForever()

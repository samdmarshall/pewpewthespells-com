version = "0.1"
author = "Samantha Marshall"
description = "website stack"
license = "BSD 3-Clause"

bin = @["rite", "ritual"]

skipFiles = @["rite.nim", "ritual.nim"]

requires "nim >= 0.15.0"
requires "yaml >= 0.9.0"
requires "jester >= 0.1.1"


task tools, "build the tools":
  exec "nim compile rite.nim"
  exec "nim compile ritual.nim"

task clean, "clean up from build":
  exec "rm -rd nimcache/ rite ritual"

before clean:
  exec "nimble stop"
  
task serve, "start running the webserver":
  exec "ngnix -c nginx/config"

task stop, "stop running the webserver":
  exec "killall ritual || true"
  exec "killall nginx || true"


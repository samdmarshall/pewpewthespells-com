version = "0.2"
author = "Samantha Marshall"
description = "website stack"
license = "BSD 3-Clause"

bin = @["ritual", "rite"]
srcDir = "src/"
skipFiles = @["feed.nim", "incantation.nim", "ritual.nim", "rite.nim", "familiar.nim"]

requires "jester 0.2.0"
requires "parsetoml 0.2.0"

when defined(nimdistros):
   import distros
   if detectOs(Ubuntu):
      foreignDep "libssl-dev"
   else:
      foreignDep "openssl"

task clean, "clean up from build":
  exec "rm rite ritual"
  withDir "src/":
    exec "rm -rd nimcache/"
  withDir "tests/":
    exec "rm -rd nimcache/"
    exec "rm t_rite"

task config, "install necessary configuration files":
  echo "sudo cp ./configuration/lib/systemd/service/ritual.service /lib/systemd/system/"
  echo "sudo cp ./configuration/etc/init/ritual.conf /etc/init/"
  echo "sudo cp ./configuration/etc/nginx/nginx.conf /etc/nginx/"

task unconfig, "removes the configuration files":
  echo "rm /lib/systemd/system/ritual.service /etc/init/ritual.conf /etc/nginx/nginx.conf"

task test, "run unit tests":
  withDir "tests":
    exec "nim c -r t_rite.nim"

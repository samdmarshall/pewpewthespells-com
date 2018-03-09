version = "0.1"
author = "Samantha Marshall"
description = "website stack"
license = "BSD 3-Clause"

bin = @["rite", "ritual"]
skipFiles = @["rite.nim", "ritual.nim", "incantation.nim"]

requires "nim 0.17.0"
requires "jester 0.1.1"
requires "parsetoml"


task clean, "clean up from build":
  exec "rm -rd nimcache/ rite ritual"

task config, "install necessary configuration files":
  exec "cp ./lib/systemd/service/ritual.service /lib/systemd/service/"
  exec "cp ./etc/init/ritual.conf /etc/init/"
  exec "cp ./etc/nginx/nginx.conf /etc/nginx/"

task unconfig, "removes the configuration files":
  exec "rm /lib/systemd/service/ritual.service /etc/init/ritual.conf /etc/nginx/nginx.conf"

version = "0.1"
author = "Samantha Marshall"
description = "website stack"
license = "BSD 3-Clause"

bin = @["ritual", "rite"]
srcDir = "src/"

requires "jester"
requires "parsetoml"

task clean, "clean up from build":
  exec "rm -rd nimcache/ rite ritual"

task config, "install necessary configuration files":
  exec "cp ./configuration/lib/systemd/service/ritual.service /lib/systemd/service/"
  exec "cp ./configuration/etc/init/ritual.conf /etc/init/"
  exec "cp ./configuration/etc/nginx/nginx.conf /etc/nginx/"

task unconfig, "removes the configuration files":
  exec "rm /lib/systemd/service/ritual.service /etc/init/ritual.conf /etc/nginx/nginx.conf"

version = "0.2.1"
author = "Samantha Demi"
description = "pewpewthespells.com website stack"
license = "BSD 3-Clause"

bin = @["ritual", "rite"]
srcDir = "src/"
skipFiles = @["feed.nim", "incantation.nim", "ritual.nim", "rite.nim", "familiar.nim"]

requires "jester >= 0.2.0"
requires "parsetoml >= 0.3.2"

#[ -------------------------------------- ]#
#[               Build Tasks              ]#
#[ -------------------------------------- ]#

import strutils
import ospaths
import distros

if detectOs(Ubuntu):
  foreignDep "libssl-dev"
else:
  foreignDep "openssl"

task clean, "clean up from build":
  rmFile("rite")   #[ executable ]#
  rmFile("ritual") #[ executable ]# 
  rmDir("report/") #[ test results directory ]#
  withDir "src/":
    rmDir("nimcache/")
  withDir "tests/":
    rmDir("nimcache/")
    rmFile("t_rite") #[ executable ]#      

task config, "install necessary configuration files":
  echo "Please run the following commands:"
  echo "  sudo cp "&thisDir()&"/configuration/lib/systemd/service/ritual.service /lib/systemd/system/"
  echo "  sudo cp "&thisDir()&"/configuration/etc/init/ritual.conf /etc/init/"
  echo "  sudo cp "&thisDir()&"/configuration/etc/nginx/nginx.conf /etc/nginx/"

task unconfig, "removes the configuration files":
  echo "Please run the following commands:"
  echo "  sudo rm /lib/systemd/system/ritual.service /etc/init/ritual.conf /etc/nginx/nginx.conf"

task test, "run unit tests":
  withDir "tests":
    for file in listFiles("."):
      if endsWith(file, ".nim"):
        exec "nim c -r " & file
  mkDir("report/")
  for file in listFiles("tests/"):
    if endsWith(file, "-junit.xml"):
      let path = joinPath("report/", extractFilename(file))
      mvFile(file, path)

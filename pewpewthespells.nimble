import strutils
import os
import distros

packageName = "pewpewthespells"
version     = "0.2.2"
author      = "Samantha Demi"
description = "pewpewthespells.com website stack"
license     = "BSD 3-Clause"

bin      = @["ritual", "rite"]
binDir   = "build/"

srcDir   = "src/"

skipDirs = @["tests/"]

#[ -------------------------------------- ]#
#[              Dependencies              ]#
#[ -------------------------------------- ]#

requires "jester >= 0.4.1"
requires "parsetoml >= 0.5.0"
requires "uuids >= 0.1.10"

foreignDep "openssl"
foreignDep "nginx"
foreignDep "node"
foreignDep "yarn"

#[ -------------------------------------- ]#
#[               Build Tasks              ]#
#[ -------------------------------------- ]#

task danger, "run danger on the repo":
  let (_, code) = gorgeEx "yarn --silent check"
  if code != 0:
    exec "yarn install"
  exec "yarn exec danger local --verbose"

task clean, "clean up from build":
  rmDir "build"
  rmDir "report"
  withDir "tests":
    rmFile "t_feed"
    rmFile "t_familiar"
    rmFile "t_incantation"

after install:
  echoForeignDeps()
  echo "Please run the following commands:"
  echo "  sudo cp " & thisDir() / "/configuration/lib/systemd/service/ritual.service /lib/systemd/system/"
  echo "  sudo cp " & thisDir() / "/configuration/etc/init/ritual.conf /etc/init/"
  echo "  sudo cp " & thisDir() / "/configuration/etc/nginx/nginx.conf /etc/nginx/"

after uninstall:
  echo "Please run the following commands:"
  echo "  sudo rm /lib/systemd/system/ritual.service /etc/init/ritual.conf /etc/nginx/nginx.conf"

after test:
  mkDir"report"
  for file in listFiles("."):
    if endsWith(file, "-junit.xml"):
      var filename = extractFilename(file)
      echo "Moving test results file '" & filename & "' -> report/ "
      mvFile file, "report" / filename

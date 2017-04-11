#!/usr/bin/env sh
#make-run.sh
#make sure a process is always running.

export DISPLAY=:0 #needed if you are running a simple gui app.

process=ritual

if ps ax | grep -v grep | grep $process > /dev/null
then
    exit
else
    service stop ritual
    service start ritual
fi

exit

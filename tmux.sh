#!/bin/sh
if $(netstat -lp 2> /dev/null| grep -q X) ; then
  echo 'X already started'
else
  tmux start-server
fi

tmux new-session -d -s chrome-driver
tmux send-keys -t chrome-driver:0 'export DISPLAY=:0' C-m
tmux send-keys -t chrome-driver:0 './chromedriver' C-m

tmux new-session -d -s selenium
tmux send-keys -t selenium:0 '/usr/bin/xrandr -s 1280x800' C-m
tmux send-keys -t selenium:0 'export DISPLAY=:0' C-m

# NOTE options for java runtime.
tmux send-keys -t selenium:0 'java -Xmn512M -Xms1G -Xmx1G -jar selenium-server-standalone.jar' C-m
tmux send-keys -t selenium:0 'for cnt in {0..10}; do wget -O- http://127.0.0.1:4444/wd/hub; sleep 120; done' C-m


#!/bin/bash
# Runs inside the container: the game on a virtual display, shared over VNC
# on port 5900. VNC shows the whole 1280x1024 virtual screen: the game picks
# its scale from the screen size and centers its window, and the window
# changes size (versus mode is wider), so there's no fixed area to crop to.
set -u
mkdir -p /work/save
export XDG_DATA_HOME=/work/save
Xvfb :1 -screen 0 1280x1024x24 -nolisten tcp &
export DISPLAY=:1
sleep 1
love /work/game &
game=$!
x11vnc -display :1 -rfbport 5900 -passwd "${VNC_PASSWORD:-love}" -forever -shared \
	-quiet -bg -o /tmp/x11vnc.log
wait $game

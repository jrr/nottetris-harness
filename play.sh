#!/bin/bash
# Plays the game by hand over VNC: the game runs in the same Linux container
# as the scenarios, and macOS Screen Sharing connects to it.
#
#   ./play.sh [--love VERSION] [--game DIR]
#   ./play.sh --stop
#
# VERSION and DIR default as in run.sh. The VNC password is "love"; the port
# only listens on localhost. No sound. The container stops when the game quits.
set -u
cd "$(dirname "$0")"
ROOT=$(pwd)
LOVE=$(cat expected/love-version 2>/dev/null)
GAME=$ROOT/game
NAME=nottetris-play
while [ $# -gt 0 ]; do
	case $1 in
		--love) LOVE=$2; shift 2 ;;
		--game) GAME=$(cd "$2" && pwd); shift 2 ;;
		--stop) docker rm -f $NAME > /dev/null 2>&1; exit 0 ;;
		*) echo "unknown argument: $1" >&2; exit 1 ;;
	esac
done

docker build -q -f "docker/love-$LOVE.Dockerfile" -t "nottetris-love:$LOVE" docker > /dev/null || exit 1
docker build -q -f docker/play.Dockerfile --build-arg "LOVE=$LOVE" -t "nottetris-play:$LOVE" docker > /dev/null || exit 1
docker rm -f $NAME > /dev/null 2>&1
docker run -d --rm --name $NAME -p 127.0.0.1:5900:5900 -v "$GAME:/work/game:ro" \
	"nottetris-play:$LOVE" harness-play > /dev/null || exit 1

for _ in $(seq 50); do
	nc -z 127.0.0.1 5900 2> /dev/null && break
	sleep 0.2
done
echo "LÖVE $LOVE running $GAME"
echo "VNC on localhost:5900, password: love. Stop with ./play.sh --stop"
open vnc://localhost:5900

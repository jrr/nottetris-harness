#!/bin/bash
# Plays the game by hand. The game runs in the same Linux container image as
# the scenarios, shown either over VNC (default) or in a browser with sound;
# or with --mac, in LÖVE's own macOS build.
#
#   ./play.sh [--web | --mac] [--love VERSION] [--game DIR] [--ref REF]
#   ./play.sh --stop
#
# VERSION, DIR and REF work as in run.sh: --ref release-2011-06-20 plays the
# original release on the LÖVE version it was made for. Everything listens on
# localhost only.
#
# VNC: macOS Screen Sharing opens on the game (password "love"). No sound.
# Stops when the game quits.
#
# --web: Selkies (https://github.com/selkies-project/selkies) runs a display
# and sound server in its own container and streams them to a browser tab;
# the game's container draws and plays into them through shared sockets, so
# the version images need nothing extra. Plain HTTP and no login, since it is
# only reachable from this machine. The game starts once the page has
# connected: Selkies only creates the sound output it streams when a browser
# connects. Downloads a 2.4 GB image the first time.
#
# --mac: runs the game in LÖVE's macOS build for VERSION, installed by mise
# (see mise.toml; `mise install` once). Native window and sound, and Intel-only
# versions run under Rosetta. Not for 0.7.2, whose build can't run on current
# macOS. Saves go where that LÖVE version keeps them on macOS, not into the
# containers' throwaway save directories.
set -u
cd "$(dirname "$0")"
ROOT=$(pwd)
. lib/ref.sh
LOVE=$(cat expected/love-version 2>/dev/null)
GAME=$ROOT/game
WEB=0
MAC=0
REF=
LOVE_GIVEN=
SELKIES=ghcr.io/selkies-project/selkies/base:2.0.0-ubuntu26.04

stop() {
	docker rm -f nottetris-play nottetris-web > /dev/null 2>&1
	docker volume rm nottetris-web-x11 nottetris-web-run > /dev/null 2>&1
}

while [ $# -gt 0 ]; do
	case $1 in
		--love) LOVE=$2; LOVE_GIVEN=1; shift 2 ;;
		--game) GAME=$(cd "$2" && pwd); shift 2 ;;
		--ref) REF=$2; shift 2 ;;
		--web) WEB=1; shift ;;
		--mac) MAC=1; shift ;;
		--stop) stop; exit 0 ;;
		*) echo "unknown argument: $1" >&2; exit 1 ;;
	esac
done

wait_for() { # seconds, command...
	local tries=$(($1 * 5))
	shift
	for _ in $(seq $tries); do
		"$@" > /dev/null 2>&1 && return 0
		sleep 0.2
	done
	return 1
}

if [ -n "$REF" ]; then
	GAME=$(extract_ref "$GAME" "$REF") || exit 1
	[ -n "$LOVE_GIVEN" ] || LOVE=$(game_love "$GAME")
	echo "Playing $REF"
fi

if [ $MAC -eq 1 ]; then
	if [ "$LOVE" = 0.7.2 ]; then
		echo "LÖVE 0.7.2's macOS build is 32-bit and can't run on current macOS: use ./play.sh or ./play.sh --web" >&2
		exit 1
	fi
	app=$(mise where "github:love2d/love@$LOVE" 2> /dev/null)/love.app
	if [ ! -x "$app/Contents/MacOS/love" ]; then
		echo "LÖVE $LOVE isn't installed: run mise install (and add $LOVE to mise.toml if it isn't there)" >&2
		exit 1
	fi
	echo "LÖVE $LOVE (macOS) running $GAME"
	exec "$app/Contents/MacOS/love" "$GAME"
fi

docker build -q -f "docker/love-$LOVE.Dockerfile" -t "nottetris-love:$LOVE" docker > /dev/null || exit 1
stop

if [ $WEB -eq 0 ]; then
	docker build -q -f docker/play.Dockerfile --build-arg "LOVE=$LOVE" -t "nottetris-play:$LOVE" docker > /dev/null || exit 1
	docker run -d --rm --name nottetris-play -p 127.0.0.1:5900:5900 -v "$GAME:/work/game:ro" \
		"nottetris-play:$LOVE" harness-play > /dev/null || exit 1
	wait_for 10 nc -z 127.0.0.1 5900
	echo "LÖVE $LOVE running $GAME"
	echo "VNC on localhost:5900, password: love. Stop with ./play.sh --stop"
	open vnc://localhost:5900
	exit 0
fi

# Selkies runs as uid 1000 and needs to own its runtime directory.
docker run --rm --user 0 --entrypoint sh -v nottetris-web-x11:/x -v nottetris-web-run:/r "$SELKIES" \
	-c 'chmod 1777 /x && chown 1000:1000 /r && chmod 700 /r' || exit 1
docker run -d --init --name nottetris-web --shm-size=1g --ipc=shareable -p 127.0.0.1:8080:8080 \
	-e SELKIES_ENABLE_BASIC_AUTH=false -e SELKIES_ENABLE_HTTPS=false \
	-v nottetris-web-x11:/tmp/.X11-unix -v nottetris-web-run:/tmp/runtime-ubuntu \
	"$SELKIES" > /dev/null || exit 1
if ! wait_for 60 curl -sf http://127.0.0.1:8080/; then
	echo "Selkies didn't start; see: docker logs nottetris-web" >&2
	exit 1
fi
echo "LÖVE $LOVE, $GAME"
echo "Playing at http://localhost:8080. Stop with ./play.sh --stop"
open http://localhost:8080
echo "Waiting for the browser to connect..."
if ! wait_for 600 docker exec nottetris-web sh -c 'wpctl status | grep -q "output Audio/Sink"'; then
	echo "No browser connected within 10 minutes" >&2
	exit 1
fi
docker run -d --rm --name nottetris-play --ipc=container:nottetris-web \
	-v nottetris-web-x11:/tmp/.X11-unix -v nottetris-web-run:/tmp/runtime-ubuntu -v "$GAME:/work/game:ro" \
	-e DISPLAY=:20 -e ALSOFT_DRIVERS=pulse -e SDL_AUDIODRIVER=pulse -e PULSE_SINK=output \
	-e PULSE_SERVER=unix:/tmp/runtime-ubuntu/pulse/native -e XDG_DATA_HOME=/tmp/save \
	"nottetris-love:$LOVE" sh -c 'mkdir -p /tmp/save && exec love /work/game' > /dev/null || exit 1
echo "Game started."

#!/bin/bash
# Runs inside the container: plays /work/game under a virtual display, then
# collects whatever the harness wrote to the save directory into /work/files,
# writing every screenshot as a PNG the same way, so identical frames give
# identical files whichever LÖVE version took them. (0.7.2 writes TGAs, upside
# down; 0.8 writes PNGs with its own encoder; 0.10's carry a gAMA chunk, which
# ImageMagick would otherwise keep as colour metadata.)
#   harness-entry [timeout-seconds]
set -u
if [ ! -f /work/game/main.lua ]; then
	echo "harness-entry: no game at /work/game" >&2
	exit 125
fi
mkdir -p /work/save /work/files
export XDG_DATA_HOME=/work/save
timeout "${1:-300}" xvfb-run -a -s "-screen 0 1280x1024x24" love /work/game
code=$?
PNG_OPTS="-strip -define png:exclude-chunks=date,time,gAMA,cHRM,sRGB,iCCP"
save=$(find /work/save/love -mindepth 1 -maxdepth 1 -type d 2>/dev/null | head -1)
if [ -n "$save" ]; then
	for f in "$save"/*; do
		[ -f "$f" ] || continue
		case $f in
			*.tga) convert "$f" -flip $PNG_OPTS "/work/files/$(basename "${f%.tga}").png" ;;
			*.png) convert "$f" $PNG_OPTS "/work/files/$(basename "$f")" ;;
			*) cp "$f" /work/files/ ;;
		esac
	done
fi
exit $code

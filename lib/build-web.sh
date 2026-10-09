#!/bin/sh
# Build out/web/: the game playable in a browser, in 2dengine's love.js player
# (https://github.com/2dengine/love.js): LÖVE 11.5 compiled to WebAssembly,
# running plain Lua 5.1 rather than LuaJIT. The player runs the .love as is,
# so this just puts it next to the player's files, pinned to a commit, with
# our own page (lib/love-js-index.html). The player's docs ask for
# cross-origin isolation headers, but it runs fine on a plain static server
# without them, which is all GitHub Pages is. Used by `mise run web` and the
# pages workflow.
#
#   lib/build-web.sh
set -e
commit=9355186de22db13bd88bf2a0db75d2925647d036
cd "$(dirname "$0")/.."
player=out/love.js-2dengine-$commit
if [ ! -d "$player" ]; then
	rm -rf "$player.tmp" && mkdir -p "$player.tmp"
	curl -fsSL "https://codeload.github.com/2dengine/love.js/tar.gz/$commit" | tar -xz -C "$player.tmp" --strip-components=1
	mv "$player.tmp" "$player"
fi
rm -rf out/web && mkdir out/web
cp -R "$player"/11.5 "$player"/lua "$player"/player.js "$player"/style.css "$player"/nogame.love out/web/
cp lib/love-js-index.html out/web/index.html
# main.lua has to be at the zip's root, hence zipping from inside game/
(cd game && zip -9 -qr ../out/web/nottetris.love . -x '.git*' '*.DS_Store')
echo out/web

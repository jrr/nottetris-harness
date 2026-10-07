#!/bin/bash
# Plays scenarios headless against one LÖVE version and compares the output
# (screenshots, state dumps and the game's own save files) to a baseline.
#
#   ./run.sh [--love 0.7.2] [--game DIR] [--update] [scenario...]
#
# DIR defaults to game/, the jrr/nottetris2 submodule; pass another checkout
# to test work in progress there.
#
# Output for each scenario lands in out/<love>/<scenario>/: log.txt and
# files/ (PNG screenshots and text dumps). --update copies files/ and their
# checksums to expected/<love>/<scenario>/ as the new baseline; normal runs
# compare checksums, and the baseline files are there to look at when they
# differ.
set -u
cd "$(dirname "$0")"
ROOT=$(pwd)
LOVE=0.7.2
GAME=$ROOT/game
UPDATE=0
SCENARIOS=()
while [ $# -gt 0 ]; do
	case $1 in
		--love) LOVE=$2; shift 2 ;;
		--game) GAME=$(cd "$2" && pwd); shift 2 ;;
		--update) UPDATE=1; shift ;;
		*) SCENARIOS+=("${1%.lua}"); shift ;;
	esac
done
if [ ${#SCENARIOS[@]} -eq 0 ]; then
	SCENARIOS=($(ls scenarios | sed 's/\.lua$//'))
fi
IMAGE=nottetris-love:$LOVE

docker build -q -f "docker/love-$LOVE.Dockerfile" -t "$IMAGE" docker > /dev/null || exit 1

run_one() {
	local name=$1
	local dest=$ROOT/out/$LOVE/$name
	# A fresh path per run: Docker Desktop can show a container a stale view
	# of a directory that was deleted and recreated at the same path.
	local work
	work=$(mktemp -d "$ROOT/out/.run-$name.XXXXXX")
	mkdir -p "$work/game"
	rsync -a --exclude .git "$GAME"/ "$work/game/"
	cp lua/*.lua "$work/game/"
	cp "scenarios/$name.lua" "$work/game/harness_scenario.lua"
	printf '\nrequire "harness_main"\n' >> "$work/game/main.lua"
	docker run --rm -v "$work:/work" "$IMAGE" harness-entry > "$work/log.txt" 2>&1
	local code=$?
	rm -rf "$work/game" "$work/save"
	(cd "$work/files" && shasum *) > "$work/checksums.txt" 2>/dev/null
	mkdir -p "$(dirname "$dest")" && rm -rf "$dest" && mv "$work" "$dest"
	work=$dest
	grep '^\[harness\] \(ok\|FAILED\)' "$work/log.txt" | sed 's/^\[harness\] /  /'
	if [ $code -ne 0 ]; then
		echo "FAIL $name (exit $code)"
		grep -A12 'ERROR\|TIMEOUT\|FAILED' "$work/log.txt" | head -20
		return 1
	fi
	local baseline=expected/$LOVE/$name
	local expected=$baseline/checksums.txt
	if [ $UPDATE -eq 1 ]; then
		rm -rf "$baseline" && mkdir -p "$baseline"
		cp "$work"/files/* "$work/checksums.txt" "$baseline/"
		echo "UPDATED $name"
	elif [ ! -f "$expected" ]; then
		echo "NO BASELINE $name (rerun with --update to accept out/$LOVE/$name/files)"
	elif diff -q "$expected" "$work/checksums.txt" > /dev/null; then
		echo "PASS $name"
	else
		echo "DIFF $name (compare $baseline/ with out/$LOVE/$name/files/)"
		diff "$expected" "$work/checksums.txt" | grep '^[<>]'
		return 1
	fi
}

status=0
pids=()
for s in "${SCENARIOS[@]}"; do
	run_one "$s" > "$ROOT/out/.$s.result" 2>&1 &
	pids+=($!)
done
for i in "${!pids[@]}"; do
	wait "${pids[$i]}" || status=1
	cat "$ROOT/out/.${SCENARIOS[$i]}.result"
	rm -f "$ROOT/out/.${SCENARIOS[$i]}.result"
done
exit $status

#!/bin/bash
# Plays scenarios headless against one LÖVE version and compares the output
# (screenshots, state dumps and the game's own save files) to a baseline.
#
#   ./run.sh [--love VERSION] [--game DIR] [--ref REF] [--update] [scenario...]
#
# VERSION defaults to the one the baselines were made with
# (expected/love-version). DIR defaults to game/, the jrr/nottetris2
# submodule; pass another checkout to test work in progress there.
#
# --ref plays the game as it was at a tag, branch or commit of DIR's repo,
# on the LÖVE version it asks for in conf.lua (unless --love says otherwise).
# The baselines are only for the current game, so these runs only check that
# nothing errors and every expect step passes: e.g. that the latest harness
# still works with --ref release-2011-06-20.
#
# Output for each scenario lands in out/<love or ref>/<scenario>/: log.txt and
# files/ (PNG screenshots and text dumps). --update copies files/ and their
# checksums to expected/<scenario>/ as the new baseline; normal runs compare
# checksums, and the baseline files are there to look at when they differ.
#
# Baselines keep the same paths across LÖVE versions, so a commit that moves
# them to a new version shows every screenshot as a before/after image diff.
set -u
cd "$(dirname "$0")"
ROOT=$(pwd)
. lib/ref.sh
BASELINE_LOVE=$(cat expected/love-version 2>/dev/null)
LOVE=$BASELINE_LOVE
GAME=$ROOT/game
UPDATE=0
REF=
LOVE_GIVEN=
SCENARIOS=()
while [ $# -gt 0 ]; do
	case $1 in
		--love) LOVE=$2; LOVE_GIVEN=1; shift 2 ;;
		--game) GAME=$(cd "$2" && pwd); shift 2 ;;
		--ref) REF=$2; shift 2 ;;
		--update) UPDATE=1; shift ;;
		*) SCENARIOS+=("${1%.lua}"); shift ;;
	esac
done
ALL=0
if [ ${#SCENARIOS[@]} -eq 0 ]; then
	SCENARIOS=($(ls scenarios | sed 's/\.lua$//'))
	ALL=1
fi
OUT=$LOVE
if [ -n "$REF" ]; then
	if [ $UPDATE -eq 1 ]; then
		echo "--update only makes baselines for the current game, not a --ref" >&2
		exit 1
	fi
	GAME=$(extract_ref "$GAME" "$REF") || exit 1
	[ -n "$LOVE_GIVEN" ] || LOVE=$(game_love "$GAME")
	OUT=ref-$(basename "$GAME" | sed 's/^\.ref-//; s/\.[^.]*$//')
	echo "$REF on LÖVE $LOVE: checking behavior only, not baselines"
elif [ -z "$LOVE" ]; then
	echo "No baselines yet: pass --love VERSION" >&2
	exit 1
elif [ "$LOVE" != "$BASELINE_LOVE" ]; then
	if [ $UPDATE -eq 1 ] && [ $ALL -eq 0 ]; then
		echo "Baselines are from LÖVE $BASELINE_LOVE: moving them to $LOVE means updating every scenario, so don't name any" >&2
		exit 1
	fi
	[ $UPDATE -eq 1 ] || echo "Note: baselines are from LÖVE $BASELINE_LOVE, running $LOVE"
fi
IMAGE=nottetris-love:$LOVE

docker build -q -f "docker/love-$LOVE.Dockerfile" -t "$IMAGE" docker > /dev/null || exit 1

run_one() {
	local name=$1
	local dest=$ROOT/out/$OUT/$name
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
	local baseline=expected/$name
	local expected=$baseline/checksums.txt
	if [ -n "$REF" ]; then
		echo "PASS $name (behavior only)"
	elif [ $UPDATE -eq 1 ]; then
		rm -rf "$baseline" && mkdir -p "$baseline"
		cp "$work"/files/* "$work/checksums.txt" "$baseline/"
		echo "UPDATED $name"
	elif [ ! -f "$expected" ]; then
		echo "NO BASELINE $name (rerun with --update to accept out/$OUT/$name/files)"
	elif diff -q "$expected" "$work/checksums.txt" > /dev/null; then
		echo "PASS $name"
	else
		echo "DIFF $name (compare $baseline/ with out/$OUT/$name/files/)"
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
if [ $UPDATE -eq 1 ] && [ $status -eq 0 ]; then
	echo "$LOVE" > expected/love-version
fi
exit $status

# Sourced by run.sh and play.sh: --ref, playing the game as it was at a git
# ref (a tag such as release-2011-06-20, a branch or a commit) of a game repo,
# and the LÖVE version a game asks for.

# extract_ref REPO REF: copies the game's files at REF into a fresh directory
# under out/ and prints its path. Fetches from the repo's origin if REF isn't
# known locally. A branch with no local copy means origin's: the game/
# submodule's clone has local copies of few branches.
extract_ref() {
	local repo=$1 ref=$2 safe dest
	safe=$(echo "$ref" | tr -c 'A-Za-z0-9._\n-' '_')
	if ! git -C "$repo" rev-parse -q --verify "$ref^{commit}" > /dev/null; then
		git -C "$repo" fetch -q --tags origin 2> /dev/null
	fi
	if ! git -C "$repo" rev-parse -q --verify "$ref^{commit}" > /dev/null; then
		if git -C "$repo" rev-parse -q --verify "origin/$ref^{commit}" > /dev/null; then
			ref=origin/$ref
		else
			echo "No such ref in $repo: $ref" >&2
			return 1
		fi
	fi
	# A fresh path each time, as in run.sh: Docker Desktop can show a container
	# a stale view of a directory deleted and recreated at the same path.
	mkdir -p "$ROOT/out"
	rm -rf "$ROOT/out/.ref-$safe".*
	dest=$(mktemp -d "$ROOT/out/.ref-$safe.XXXXXX")
	git -C "$repo" archive "$ref" | tar -x -C "$dest" || return 1
	echo "$dest"
}

# game_love DIR: the LÖVE version a game asks for in its conf.lua (t.version,
# which games set from 0.8 on), or 0.7.2 if it doesn't say.
game_love() {
	local version
	version=$(sed -n 's/.*t\.version *= *"\([0-9.]*\)".*/\1/p' "$1/conf.lua" 2> /dev/null | head -1)
	echo "${version:-0.7.2}"
}

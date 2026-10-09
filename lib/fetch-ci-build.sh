#!/bin/sh
# Download LÖVE's macOS build of an unreleased version from its CI, for
# ./play.sh --mac, which looks in builds/<version>/ when mise doesn't have the
# version (mise only installs releases). Needs gh, logged in: CI artifacts
# aren't public, and GitHub deletes them after 90 days.
#
#   lib/fetch-ci-build.sh 12.0 b7daef0f7    # the commit docker/love-12.0.Dockerfile pins
set -e
[ $# -eq 2 ] || { echo "usage: $0 VERSION COMMIT" >&2; exit 1; }
version=$1 commit=$(gh api "repos/love2d/love/commits/$2" -q .sha)
cd "$(dirname "$0")/.."
run=$(gh run list -R love2d/love --commit "$commit" --workflow continuous-integration \
	--status success -L 1 --json databaseId -q '.[0].databaseId')
[ -n "$run" ] || { echo "no successful CI run for $commit" >&2; exit 1; }
rm -rf "builds/$version" && mkdir -p "builds/$version"
gh run download "$run" -R love2d/love -n love-macos -D "builds/$version"
(cd "builds/$version" && unzip -q love-macos.zip && rm love-macos.zip)
echo "$commit" > "builds/$version/commit"
"builds/$version/love.app/Contents/MacOS/love" --version

# LÖVE versions

Notes on the releases between Not Tetris 2's engine (0.7.2) and today,
focused on what matters for porting this game and for the harness.

Sources: LÖVE's `changes.txt` at the 11.5 tag (release dates from 0.10.0 on),
tagged commit dates for older releases, the bundled Box2D's `b2_version` at
each tag, and the macOS release builds' binaries (`lipo -archs`). Entries
marked *unverified* are from memory or inference; check them when we get
there.

## Releases

Only the first release of each line breaks compatibility; the point releases
(0.9.1, 11.3, …) mostly fix bugs, with a few deprecations.

| Version | Codename | Released | Box2D | macOS build | Runs natively on Apple Silicon |
|---|---|---|---|---|---|
| 0.7.2 | Game Slave | 2011-04 | 2.0.1 | i386 + PowerPC | no, and not under Rosetta either (32-bit) |
| 0.8.0 | Rubber Piggy | 2012-04 | 2.2.1 | i386 + x86_64 | no; Rosetta might work (*unverified*) |
| 0.9.0 – 0.9.2 | Baby Inspector | 2013-12 – 2015-02 | 2.3.0 | x86_64 | no; Rosetta (*unverified*) |
| 0.10.0 – 0.10.2 | Super Toast | 2015-12 – 2016-10 | 2.3.2 | x86_64 | no; Rosetta (*unverified*) |
| 11.0 – 11.3 | Mysterious Mysteries | 2018-04 – 2019-10 | 2.3.2 | x86_64 | no; Rosetta (*unverified*) |
| 11.4 | Mysterious Mysteries | 2022-01-02 | 2.3.2 | x86_64 + arm64 | yes |
| 11.5 | Mysterious Mysteries | 2023-12-03 | 2.3.2 | x86_64 + arm64 | yes (current stable) |
| 12.0 | – | unreleased | – | – | in development on `main` |

Official Linux binaries were Ubuntu .deb packages for i386/amd64 (armhf from
0.10.2), then x86_64 AppImages from 11.0. None are arm64. The harness builds
LÖVE from source in an arm64 Linux container instead, so the macOS column only
matters for playing the game by hand. Building from source is verified for
0.7.2 (on Ubuntu 16.04).

## Breaking changes that touch this game

The changelog lists far more; these are the ones the game's code or the
harness actually hits.

### 0.8.0

- **Box2D 2.0 → 2.2**, the biggest change for this game. Physics behaves
  differently, and the API changed: shapes are attached to bodies through
  fixtures, and `newWorld` no longer takes world bounds (*details
  unverified*; the changelog only says "Updated Box2D to version 2.2.1").
  The game builds every piece from `newRectangleShape(body, …)` and
  `newPolygonShape(body, …)`, uses `shape:setData`, and calls
  `newWorld(0, -720, 960, 1200, 0, 500, true)` with bounds. Verified so far:
  on 0.8.0 the game's first `newPolygonShape(body, …)` fails with "Number of
  vertices must be a multiple of two", so shapes no longer take a body.
- `love.event.quit` added (verified); `love.event.push("q")` goes away later
  (*unverified when*). The game uses `push("q")`.
- `ImageData:encode(filename)` writes a real PNG straight to the save
  directory and returns nothing (harness screenshots; verified by the probe).
- `love._version` becomes a string, `"0.8.0"` (verified).
- The menus render pixel-identically to 0.7.2 (verified by the boot
  scenario).
- `love.timer.sleep` takes seconds; `love.run` order changes.
- `require` with a `.lua` extension removed.

### 0.9.0

- Window functions move from `love.graphics` to `love.window`; `t.screen`
  becomes `t.window` in `conf.lua`. The game calls `love.graphics.setMode` 9
  times and reads `love.graphics.getModes()` to size itself.
- `love.keypressed(key, unicode)` becomes `(key, isrepeat)`; text input moves
  to the new `love.textinput`. The high score name entry uses `unicode`.
- `love.timer.getMicroTime` removed; `getTime` becomes high-resolution.
- `love.filesystem.mkdir` and `enumerate` renamed; the save directory is now
  created automatically.
- SDL 1.2 → SDL2 (the macOS build bundles `SDL2.framework` from 0.9).

### 0.10.0

- `love.keypressed(key, scancode, isrepeat)`; the space key is `"space"`
  instead of `" "`. The name entry whitelist includes space.
- Mouse buttons become numbers.
- `ImageData:encode(format, filename)` returns a FileData (harness).
- ImageFonts no longer treat separator pixels as spacing. The game draws its
  text with image fonts, so text layout may shift.
- Requires OpenGL 2.1.

### 11.0

- **Colors are 0–1 instead of 0–255.** Every `setColor` and
  `setBackgroundColor` call changes.
- `love.audio.newSource` needs an explicit type (`"static"` / `"stream"`), and
  the audio API changed "drastically"; `love.audio.pause` and `resume`
  (both used by the game) are among the changes.
- `love.graphics.newScreenshot` removed; `captureScreenshot` is asynchronous
  (harness).
- `love.errhand` renamed to `love.errorhandler` (harness).
- `love.filesystem.exists` deprecated in favour of `getInfo`.

### 11.4

- Builds that bundle LuaJIT moved to 2.1, which drops `math.mod`. The game
  calls `math.mod` 9 times (gameA, gameBmulti, rocket). Replace with `%`.

## Lua runtime

The 0.7.2 and 0.8.0 builds in the harness run plain Lua 5.1 (the probe
reports `jit` as nil). Later releases bundle LuaJIT on most platforms. When
that started, and whether our source builds use it, is *unverified*; the
probe reports it for each version.

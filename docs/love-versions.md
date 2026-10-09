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
0.7.2, 0.8.0, 0.9.2, 0.10.2, 11.3, 11.4 and 11.5 (on Ubuntu 16.04).

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
  becomes `t.window` in `conf.lua` (verified: `love.graphics.setMode` and
  `getModes` are gone). The game calls `love.graphics.setMode` 10 times and
  reads `love.graphics.getModes()` to size itself. `love.graphics.getWidth`
  and `getHeight` stay.
- A `conf.lua` that still sets `t.screen.*` stops 0.9.2 before `main.lua`
  runs, and it hangs on its error screen without printing anything, so a
  harness run just times out (verified).
- `love.keypressed(key, unicode)` becomes `(key, isrepeat)`, `keyreleased`
  gets just the key, and typed text arrives separately in the new
  `love.textinput(text)` (verified with pushed events). The high score name
  entry uses `unicode`.
- `love.timer.getMicroTime` removed (verified); `getTime` becomes
  high-resolution.
- `ImageData:encode(filename)` still writes a PNG and returns nothing, but
  takes the format from the name's extension: `encode("png")` is an error
  (harness; verified).
- `love.getVersion()` added (verified on 0.9.2; the changelog says 0.9.1).
- `love.filesystem.mkdir` and `enumerate` renamed; the save directory is now
  created automatically.
- SDL 1.2 → SDL2 (the macOS build bundles `SDL2.framework` from 0.9).

### 0.10.0

- A game whose `conf.lua` asks for an older `t.version` gets a modal
  compatibility warning before `main.lua` runs. Under the harness nobody can
  dismiss it, so every run times out with an empty log (verified).
- `love.keypressed(key, scancode, isrepeat)`; the space key is `"space"`
  instead of `" "`, though `textinput` still gets `" "` (verified with
  pushed events). The game never uses the space key, and the name entry
  takes space through `textinput`.
- Mouse buttons become numbers.
- `ImageData:encode(format, filename)` writes the file and returns a
  FileData; 0.8's `encode(filename)` is an error (harness; verified). Its
  PNGs carry a `gAMA` chunk, which the harness strips so identical frames
  give identical files across versions.
- ImageFonts no longer add a pixel between glyphs: text comes out 1 pixel
  per character narrower (verified). The game prints its menu selections
  over text baked into the menu images, so the old text showed past the end
  of the new; `newImageFont`'s new `extraspacing` argument of 1 restores the
  old layout pixel for pixel.
- The window flag `fsaa` is renamed `msaa`, and fullscreen defaults to
  `fullscreentype = "desktop"` instead of 0.9's `"normal"` (verified).
- Requires OpenGL 2.1 (Mesa's software renderer is fine).

### 11.0

Checked on 11.3, the last release before 11.4's LuaJIT change.

- As on 0.10, a `conf.lua` with an older `t.version` gets the compatibility
  warning and hangs harness runs (verified).
- **Colors are 0–1 instead of 0–255.** Every `setColor` and
  `setBackgroundColor` call changes; values above 1 are clamped (verified).
  So do ImageData's `getPixel` and `setPixel`, which the game uses to tint
  and cut pieces (verified). Two of the game's colours render one level
  higher in green than on 0.10.2 (the source images are a level lower
  still); nothing else in the screenshots changes (verified).
- `World:update` steps Box2D with 8 velocity and 3 position iterations by
  default, where every earlier version used 8 and 6 (verified in LÖVE's
  source). Pieces settle differently; `world:update(dt, 8, 6)` gives
  exactly 0.10.2's physics (verified).
- `newImageFont` no longer takes an Image, only a filename, ImageData or
  Rasterizer; the filter is set on the Font instead (verified).
- `love.audio.newSource` needs an explicit type (`"static"` / `"stream"`)
  (verified). `love.audio.resume` is gone; `love.audio.pause()` returns the
  sources it paused, to pass to `love.audio.play` (verified).
- `love.graphics.newScreenshot` removed. `captureScreenshot(filename)` writes
  a PNG once the frame is presented, before the next update (harness;
  verified).
- `love.errhand` renamed to `love.errorhandler` (harness; verified).
- Key events are unchanged from 0.10 (verified).
- `love.filesystem.exists` deprecated in favour of `getInfo`; both exist on
  11.3, but calling a deprecated function prints a warning across the bottom
  of the game's window (verified).
- The macOS build is still Intel-only.

### 11.4

- Builds that bundle LuaJIT moved to 2.1, which drops `math.mod` and
  `string.gfind`. LÖVE 11.4 adds both back as aliases, so the game's 9
  `math.mod` calls (gameA, gameBmulti, rocket) keep working (verified).
- The harness's 11.4 image is the first built with LuaJIT (below).
- `love.timer.getTime` starts at 0 (the harness replaces it anyway).
- Built against plain Lua, 11.4 renders every scenario byte for byte like
  11.3 (verified).

### 11.5

- No API changes the game or harness hit. LuaJIT is updated (fixing
  `pairs` behaviour) and the JIT compiler is off by default on Apple
  Silicon. Every scenario renders byte for byte like 11.4 (verified).

## Lua runtime

0.9 onwards prefer LuaJIT, and LÖVE's own builds bundle it on most
platforms. Ubuntu 16.04 has no arm64 LuaJIT package, so the harness's images
up to 11.3 are built `--with-lua=lua5.1` (the probe reports `jit` as nil).
From 11.4 the images build LuaJIT 2.1 from source, from the v2.1 branch as
it was at that LÖVE version's release, so the harness runs what players
run.

The difference that shows is `math.random`: LuaJIT has its own generator,
so the same seed deals different pieces than plain Lua does (verified:
moving 11.4 from plain Lua to LuaJIT changes the pieces in every game
scenario; the menus are unchanged). Expect checks don't depend on which
pieces come.

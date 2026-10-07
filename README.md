# nottetris-harness

Plays [Not Tetris 2](https://github.com/jrr/nottetris2) headless from scripted
scenarios on any LÖVE version, saving screenshots and game state. It's for
porting the game, released on LÖVE 0.7.2, to newer engine versions one step
at a time, with something that checks every step.

The game itself is not modified: the harness is added to a copy of it at run
time.

## Running

Needs Docker. Each LÖVE version's image builds from source on first use, which takes a few minutes.

```
git clone --recursive https://github.com/jrr/nottetris-harness && cd nottetris-harness
./run.sh                      # every scenario, compared to the baselines
./run.sh gameA                # one scenario
./run.sh --game ../nottetris2 # another checkout of the game
./run.sh --update             # accept the current output as the baseline
```

Each scenario's output goes to `out/<love>/<scenario>/`: `log.txt`, and
`files/` with PNG screenshots, `state.txt` dumps and the game's own save files.
A scenario fails if the game errors, times out, or an `expect` step fails.
Otherwise it passes when the output's checksums match `expected/<scenario>/`.

## Playing by hand

```
./play.sh                     # same LÖVE version and game as run.sh
./play.sh --love 0.7.2 --game ../nottetris2
./play.sh --stop
```

The game runs in the same Linux container as the scenarios, with a VNC
server sharing its screen, and macOS Screen Sharing opens on it (password
`love`; the port only listens on localhost). No sound. This works for
versions that have no macOS build that runs on Apple Silicon, 0.7.2 included.

## Layout

| Path | |
|---|---|
| `game/` | submodule: jrr/nottetris2, `main` branch |
| `docker/love-<version>.Dockerfile` | LÖVE built for Xvfb and software rendering |
| `docker/entry.sh` | runs in the container: play the game, collect its save files |
| `docker/play.*` | VNC layer on top of any version's image, for `play.sh` |
| `lua/harness_main.lua` | fixed clock, seed and keyboard; plays the scenario steps |
| `lua/harness_compat.lua` | everything that differs between LÖVE versions |
| `scenarios/*.lua` | the scenarios; step format at the top of `harness_main.lua` |
| `expected/` | baselines, and `love-version`, the version they were made with |
| `probe/` | reports which APIs a LÖVE version has |

## Reviewing a port

Physics changes between engine versions (Box2D 2.0 in LÖVE 0.7.2, 2.2 in 0.8,
2.3 from 0.9), so screenshots won't match across versions, and they don't need
to. Between versions, the `expect` steps are the automated check. The
screenshots are for a person to judge.

Baselines keep the same paths across versions, so moving them to a new
version shows every screenshot as a before/after image diff on GitHub:

1. A game PR on jrr/nottetris2, e.g. `port-0.8` into `main`.
2. A harness PR from a branch with the same name. It points `game/` at the
   game branch, adds what the new version needs (below) and runs
   `./run.sh --love 0.8.0 --update`.
3. The game PR links to the harness PR. Its "Files changed" tab shows the
   screenshots before and after.

Merge both once the pictures look right, then point `game/` back at `main`.

## Adding a LÖVE version

1. `docker/love-<version>.Dockerfile`, starting from the 0.7.2 one.
2. Run the probe against it (command at the top of `probe/main.lua`) and
   record what it finds there.
3. Teach `harness_compat.lua` the version's differences. It refuses to run on
   versions it hasn't been checked against.
4. Run the scenarios. Expect failures until the game is ported too.

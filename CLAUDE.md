# CLAUDE.md — chessengine

Guidance for Claude Code (and other AI coding tools) working in this repo. README.md explains the project for users.

## What this is

A MAME plugin (Lua) that turns emulated dedicated chess computers into UCI/XBoard engines. [picochess](https://github.com/JohanSjoblom/picochess) uses it for its retro engines. Current as of MAME 0.289.

- `init.lua` — plugin core: UCI loop on stdin, board tracking, moves, FEN setup, history replay, and the calls into the interface hooks. A change here affects every machine, so test several different machines after touching it.
- `interfaces/<system>.lua` — one file per MAME set, loaded at machine reset. A clone without its own file uses its parent's. The hooks (`setup_machine`, `start_play`, `is_selected`, `select_piece`, `set_pos`, `edit_game`, promotion functions, `setlevel`/`get_options`/`set_option`, `show_info`, `game_over`, `resigned`, `ignore_late_go`) are described in [docs/MACHINES.md](docs/MACHINES.md#plugin-core-initlua).
- `docs/` — MACHINES.md, per-maker pages in `docs/machines/` and `machines.html` (served by GitHub Pages). These files are generated; don't edit them by hand.

Related repos:
- [mame_for_picochess](https://github.com/RandyR99/mame_for_picochess) — picochess launch scripts, `.uci` level files and `retro.ini`.
- [picochess_mame_artwork](https://github.com/RandyR99/picochess_mame_artwork) — MAME artwork (layouts and photos) for these machines.
- [MAME](https://github.com/mamedev/mame) (use the tag of the targeted release, e.g. `mame0289`) — drivers in `src/mame/<maker>/`, stock layouts with output names in `src/mame/layout/`, Lua API in `src/frontend/mame/luaengine*.cpp` and `docs/source/luascript/`.

## Rules

- Commit and push only after the maintainer's OK. Work one MAME driver (`.cpp`) at a time, with one commit per driver. Docs rebuilds go in their own commit.
- LF line endings, UTF-8, English identifiers.
- Interfaces run in a sandbox: `machine`, `emu`, `send_input`, the `sb_*` sensor-board helpers, `pairs`, `ipairs`, `string`, `math`. There is no `table`, `os`, `io` or `manager` (use `machine`, e.g. `machine.time:as_double()`).
- MAME Lua API: read outputs with `machine.devices[":"]:output(name):get()` (wrap it in a local helper such as `led_on()` or `digit()`), and read RAM through the CPU program space (`machine.devices[":maincpu"].spaces["program"]:read_u8(addr)`). Don't use `output:get_value` or `emu.item`.
- Syntax check: `luac5.4 -p init.lua interfaces/*.lua`.
- Check each change against the machine's original manual: levels, setup, castling and promotion rules.

## Testing

Run a machine headless with the plugin and talk UCI to it:

```sh
SDL_VIDEODRIVER=dummy mame -video none -sound none -plugin chessengine <system>
# uci / setoption name speed value 500 / isready / position ... / go ...
```

- Set `SDL_VIDEODRIVER=dummy` on headless runs, or MAME opens windows.
- An alternate plugin folder given with `-pluginspath` needs MAME's `plugins/boot.lua` copied into it, or the plugin silently doesn't load.
- Stop leftover MAME processes by PID or by exact name (`pgrep -x`). Never use `pkill -f`, which can match unrelated processes.
- A good test set for each interface:
  - a game from the start position
  - a FEN setup with each side to move, and a FEN followed by a player move
  - player castling, and machine en passant
  - player and machine promotion, including underpromotion
  - a late `go`
  - `show_info` output that doesn't interfere with move entry

  Check every bestmove for legality.

## Known pitfalls

- Slow machines miss sensor-board events that come too fast. If the from-square LED stays lit and no reply comes, add `emu.wait(...)` after the board presses before suspecting the logic.
- A power-on LED sweep or self-test can swallow the first key presses. Check the boot wait in `setup_machine`.
- The MAME 6522 VIA reset leaves its IRQ asserted, which causes an intermittent hang after a RESET button. Write `0x7f` to the IER first (see `arb_sargon25.lua`).
- Lua probes must use `emu.register_periodic`, because frame notifiers stop in headless runs.
- Set the `ignore_late_go` flag for machines that start thinking by themselves when `go` arrives late.

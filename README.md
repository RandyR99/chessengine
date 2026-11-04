# chessengine

A MAME plugin that turns emulated dedicated chess computers into UCI (or XBoard) chess engines. It is the plugin [picochess](https://github.com/JohanSjoblom/picochess) uses for its retro engines: about 430 machines from Fidelity, Mephisto, Novag, Saitek, SciSys and others, each playing with its original ROM.

This version is ported to **MAME 0.289**.

## How it works

The plugin reads UCI commands on stdin and keeps its own copy of the board. For each machine an interface file in `interfaces/` translates between UCI and the machine's hardware:

- the player's move is entered by pressing the squares on the emulated sensor board, or keys on keypad machines
- the machine's move is read from its board LEDs, LCD or display, or from RAM
- positions (FEN), game histories, levels, promotions and live search info go through the machine's own setup modes, keys or memory

At machine reset `init.lua` loads `interfaces/<system>.lua`, or the parent set's file when a clone has none of its own.

## Usage

Put this repository in MAME's `plugins/` folder as `plugins/chessengine` (MAME also needs its standard `plugins/boot.lua`). Then start a machine with the plugin:

```sh
mame <system> -plugin chessengine -video none
```

and talk UCI to it on stdin/stdout (`uci`, `isready`, `ucinewgame`, `position ...`, `go`, `stop`, `quit`). Levels and machine options appear as UCI options. picochess does all of this through the scripts and `.uci` level files in [mame_for_picochess](https://github.com/RandyR99/mame_for_picochess).

The ROMs are not included.

`kblitz` (Kasparov Blitz) needs MAME 0.290, or 0.289 with the `ioport.cpp` fix for analog `set_value` overrides, to turn its dials.

## Machines

**[docs/MACHINES.md](docs/MACHINES.md)** lists every machine: whether it supports position setup, history replay, live info and pondering, its levels and Elo, its known limits, and the commits that changed it. It also describes the `init.lua` changes made during the 0.289 port and the hooks an interface can provide.

The same overview as an interactive page, with search and filters: **[MAME Chess Machines](https://randyr99.github.io/chessengine/machines.html)**.

## Writing an interface

An interface is a Lua file that returns a table of functions. The main hooks are `setup_machine`, `start_play`, `is_selected` and `select_piece` (reading and entering moves), `set_pos` (FEN setup), `edit_game` (history replay), the promotion functions, `setlevel`/`get_options`/`set_option`, and optionally `show_info`, `game_over`, `resigned` and the `ignore_late_go` flag. See [docs/MACHINES.md](docs/MACHINES.md#plugin-core-initlua) for what each one does, and the interfaces of similar machines for examples. Interfaces run in a sandbox with `machine`, `emu`, `send_input`, the `sb_*` sensor-board helpers, `pairs`, `ipairs`, `string` and `math`, but no `table`, `os` or `io`.

## Credits

- **Sandro Ronco** wrote the plugin and the first interfaces.
- **Franz Huber** updated them for his CB-Emu program (MessChess and MessNew) and added many interfaces.
- **Guido Marquardt** extended the interfaces' functionality for his Mysticum project.
- **Randy Reade** updated the plugin and the interfaces for MAME 0.289, working with Claude (Anthropic).

Licence: BSD 3-Clause.

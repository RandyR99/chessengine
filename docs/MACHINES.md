# MAME chess machines in picochess

Every machine in picochess `retro.ini` after the port of the chessengine interfaces to MAME 0.289: what works, known limits, levels, and the commits that reported each change. Generated 2026-11-06 from chessengine `5c87fda` and mame_for_picochess `993d593`.

| Machines | Interface files | MAME drivers | FEN setup | History replay | Live info | Ponder |
|---:|---:|---:|---:|---:|---:|---:|
| 431 | 284 | 133 | 413 | 399 | 185 | 216 |

**Machines by manufacturer** (feature table and details per machine):

| Manufacturer | Machines | FEN setup | History | Live info | With known limits |
|---|---:|---:|---:|---:|---:|
| [Chafitz/Applied Concepts](machines/chafitz-applied-concepts.md) | 13 | 13 | 6 | 1 | 7 |
| [CXG](machines/cxg.md) | 22 | 21 | 18 | 8 | 6 |
| [Elektor](machines/elektor.md) | 4 | 0 | 0 | 0 | 4 |
| [Fidelity](machines/fidelity.md) | 100 | 98 | 98 | 33 | 32 |
| [Mephisto](machines/mephisto.md) | 119 | 119 | 119 | 96 | 41 |
| [Novag](machines/novag.md) | 59 | 59 | 54 | 23 | 13 |
| [Saitek](machines/saitek.md) | 47 | 43 | 47 | 14 | 31 |
| [SciSys](machines/scisys.md) | 19 | 19 | 19 | 2 | 12 |
| [Tasc](machines/tasc.md) | 4 | 4 | 4 | 4 | 0 |
| [VEB](machines/veb.md) | 8 | 5 | 5 | 1 | 5 |
| [Various](machines/various.md) | 36 | 32 | 29 | 3 | 18 |

## Legend and general limits

**Columns**

- **FEN**: the interface can set up a position (`set_pos`). Without it the machine plays from the start position only.
- **History**: the interface can replay a game's moves into the machine (`edit_game`), so a game can continue after takebacks or a restart. picochess sees it as `edit` in the engine name and then sends the move history with Set Pos and Read Game.
- **Info**: live depth, score and main line while the machine thinks (`show_info`), read without key presses.
- **Ponder**: `ponder/brain = y` in retro.ini: the machine thinks on the player's time (measured from a non-book position, not taken from the manual).
- **Levels**: entries in the machine's .uci file, fastest to slowest. **Elo** comes from CB-Emu Programs.txt.
- **Limits**: number of known limits; open a machine below its table for the list, the interface chain, levels, notes and commits.

**General limits** (almost every machine, not repeated per machine)

- **En passant right after a position setup**: the player can't capture e.p. as the first move after a FEN, because a setup can't tell the machine the last move. It works when the double step is in the move history.
- **Impossible positions**: most machines refuse to set up positions such as a king on a corner square with no way in, or a king on its own pawn's promotion square. The machine then never sends a move.
- **Game end**: picochess ends mate, stalemate, insufficient material, fivefold repetition and the 75-move rule itself. For a machine that stops silently in a repeated position, the plugin sends `bestmove 0000` after a timeout.

**Test names used in notes and commits**

| Test | What it checks |
|---|---|
| ep_p | Player captures en passant right after a FEN (e.p. square only in the FEN); fails on almost all machines. |
| ep_p2, ep_ps, ep, ep2, ep3, ep_w | En passant after real moves, by the player and by the machine. |
| ur_b2, ub_b2, up_* | Underpromotion by the player (rook, bishop, knight; with and without capture). ur_b2 ends in mate, so "no move" is correct there. |
| promo_* | Promotions by machine and player, also inside a replayed history. |
| kn_k, ka_* | Dead draws (K+minor vs K, bare kings). |
| kc_*, kp_*, a8_br, bk_h1 | Positions machines refuse to set up; a refusal counts as a pass. |
| chk_b, chk_w, only1, only2, ss_g3 | Forced and lost positions; some ROMs resign here. |
| rep3 | Threefold repetition: the machine must end the game, not stall. |
| start, black, black_a3, fen_w, fen_b, castle* | Basic play from the start, as Black, out of book (a2a3), from FENs, castling. |
| neg, info | Live info: machine Black a queen down must show about −9 (score from the machine's side). |
| game10, r70 | Long replays of real games (history replay stress). |


## Plugin core (init.lua)

`init.lua` is the chessengine plugin itself (Sandro Ronco's MAME plugin, as used by picochess). It talks UCI (or xboard) on stdin/stdout, keeps its own copy of the board, and drives the emulated machine through a per-machine interface file: pressing sensor-board squares and keys for the player's moves, and reading the machine's moves from its LEDs and displays. At machine reset it loads `interfaces/<system>.lua`, or the parent set's file when a clone has none. An interface can build on another with `load_interface("name")`.

The interface files were ported to MAME 0.289 (output values through `machine.devices[":"]:output(name)` in place of the removed `output:get_value`). `init.lua` needed no API port, but gained these changes during the port. Each new hook is opt-in, so interfaces that don't use it behave as before.

| Commit | Date | Change |
|---|---|---|
| 2b25951 | 2026-10-08 | Error message when an interface uses a port or key mask that doesn't exist. |
| 0c71ed8 | 2026-10-09 | The promotion piece from `test_promotion()` is lowercased (`bestmove b7b8R` kept the board from recording the promotion). |
| 755f7da | 2026-10-15 | MAME exits cleanly on `quit`: the stdin reader thread no longer blocks MAME's exit or loops on EOF (hang / segfault). |
| c3997da | 2026-10-26 | `interface.ignore_late_go`: a `go` that arrives after the machine already answered the last position on its own is ignored (it made the machine move for the other side). Set on 160 interfaces. |
| 6f4c493 | 2026-10-29 | `interface.game_over()`: true on the machine's turn → `bestmove 0000` once; picochess scores the result. Used by tchess, slc1, poly880s, prisma, smondial2, sexperta/sfortea family, zircon2, mentor16. |
| b642b74 | 2026-10-29 | Threefold repetition: init.lua counts positions; a machine silent in a repeated position for longer than twice its longest move (at least 30 s emulated) gets `bestmove 0000`. 98 of 239 machines claimed the draw silently. |
| 9452bd9 | 2026-10-30 | `interface.resigned()`: polled on the player's turn, because a resign sign shown with the machine's move can be gone by its next turn (smondial2 `rESG`). |
| 3e53188 | 2026-10-30 | `format_info()`: `show_info()` returns `{depth, seldepth, score, mate, pv}` (old strings still work) and init.lua writes the info line the way python-chess parses it: empty fields left out, castling notations converted, pv cut at its first illegal move. New `interface.info_every`. |
| 506d638 | 2026-10-30 | `show_info` runs every 10 s of emulated time (or `info_every`) instead of every 500 ticks; key-pressing show_info switched off (a press could hide the machine's move). |
| 542b983 | 2026-10-30 | `depth 0` (before the first iteration) is left out of the info line. |
| da0d4a3 | 2026-11-01 | Chessmate sets (ccmk2, ccmk2a, chmate) run setup and game edits unthrottled; the talking machines stay throttled (unthrottled speech plays partly sped up). |
| f0b8554 | 2026-11-01 | Set Pos / Read Game: a replayed history leaves the machine in edit mode and idle until `go` (a player move arriving first is keyed in as part of the history), so it no longer moves for the player; generalizes Johan's MM V fix. The id name reports `edit` (e.g. `(pos+edit+info)`), which picochess uses to decide whether Set Pos sends the history. Talking machines in one `keep_throttled` table; dead `sc80`/`sparc` code removed. |
| 021277d | 2026-11-01 | `interface.no_soft_reset` replaces the name list that skips the soft reset on `ucinewgame`; clones inherit it (avrmaxg hung in a second game). |
| 9aee91d | 2026-11-04 | The player's underpromotion goes in through the position setup on queen-only machines (`interface.setup_underpromotion`). |
| 346cb87 | 2026-11-05 | Sound is muted while the machine runs unthrottled (`sound.system_mute`), for all interfaces: speech and beeps are garbled at that speed. |

**Interface hooks used by init.lua**

| Hook | Role |
|---|---|
| `setup_machine()` | After boot: wait until the machine is ready, set options (sound, display modes, info display). |
| `start_play(init)`, `stop_play()` | Make the machine move; interrupt a search where possible. |
| `is_selected(x, y)`, `select_piece(x, y, event)` | Read the machine's move from LEDs/display; enter the player's move. |
| `set_pos(mode)` | Set up a FEN position (board rebuild, keypad or RAM). Absent = start position only. |
| `edit_game(on)` | Replay a game history (Multi-Move, Monitor or Referee mode). |
| `test_promotion`, `get_promotion`, `promote`, `promote_special` | Machine's promotion piece; player's promotion. |
| `setlevel`, `get_options`, `set_option` | Levels and options (the .uci file holds the level strings). |
| `show_info()`, `info_every` | Live search info while the machine thinks. |
| `show_pv_after_move_emu` / `_player` | Older info hooks, kept only where show_info needs them (ccmk5, risc2500, super9cc). |
| `game_over()`, `resigned()` | Game end and resignation → `bestmove 0000`. |
| `ignore_late_go` | Flag for machines that answer the player's move on their own. |
| `setup_underpromotion` | Flag for queen-only machines: the player's underpromotion goes in through the position setup. |
| `no_soft_reset` | Flag for machines that hang after a soft reset on `ucinewgame` (avrmax, kblitz, fphantom, cphantom families). |

## Player underpromotion

Most older machines promote to a queen by themselves and can't take another piece as a move. On machines with a position setup, the plugin plays the move on its own board, restarts the machine and sets up the resulting position, then the machine plays on. The same happens when a move list with an underpromotion is replayed. Tested in picochess, including selecting moves before and after the underpromotion and continuing the game. The level is kept. picochess keeps the game and its own clocks. Limits on the machine's side:

- **Machine clock**: the machine's own clock restarts with each setup, on game and tournament levels. It can show a clock counting down that doesn't match picochess.
- **Castling**: castling rights are not passed on, so the machine may refuse castling afterwards.
- **Machine memory**: its own move list, takeback and repetition count start fresh.
- **Refused positions**: a machine that treats the position as impossible doesn't take it, and picochess gets no move.
- **No position setup**: the player's underpromotion can't be entered at all (see each machine's limits).

## Open items

- **Game history from a custom FEN** fails on cc3, electrio, pmicrodx and triomphe; fex68k can't replay a history.

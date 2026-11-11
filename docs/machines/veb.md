# VEB

MAME chess machines in picochess, part of the [machine overview](../MACHINES.md) (columns and general limits explained there).

| System | Name | Year | Elo | Levels | FEN | History | Info | Ponder | Limits |
|---|---|---:|---:|---:|:-:|:-:|:-:|:-:|---:|
| `chessmst` | VEB ChessMaster | 1984 | 1150 | 7 | ✓ | ✓ | – | – |  |
| `chessmsta` | VEB ChessMaster G-5003-500 | 1984 | 1100 | 7 | ✓ | ✓ | – | – |  |
| `chessmstdm` | VEB ChessMaster Diamond PM10 Openings | 1987 | 1190 | 8 | ✓ | ✓ | ✓ | – |  |
| `sc2` | VEB Schachcomputer SC2 | 1981 | 700 | 7 | ✓ | ✓ | – | – | 1 |
| `sc2a` | VEB Schachcomputer SC2 (rev. 0) | 1981 | 700 | 7 | ✓ | ✓ | – | – | 1 |
| `lc80e` | VEB Schachcomputer SC80 | 1984 | 700 | 5 | – | – | – | – | 3 |
| `poly880s` | Poly-Computer 880 SC1 | 1983 | 700 | 7 | – | – | – | – | 3 |
| `slc1` | VEB Schachcomputer SLC1 | 1989 | 700 | 7 | – | – | – | – | 5 |

<details><summary><code>chessmst</code> VEB ChessMaster</summary>

- MAME set `chessmst` (Chess-Master (model G-5003-501)), driver `ddr/chessmst.cpp`
- script runs `mess chessmst`
- interface `chessmst.lua`
- retro.ini: elo 1150, levels 7, ponder/brain n

**Levels:** 5s move; 12s move; 23s move; 70s move; 3m move; 5m move; Analysis

**Commits**

- [26c26de](https://github.com/RandyR99/chessengine/commit/26c26de) 2026-11-04 chessengine: interfaces: player's underpromotion through the position setup on 45 more machines
- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [2281abb](https://github.com/RandyR99/mame_for_picochess/commit/2281abb) 2026-10-17 mame_for_picochess: levels: 5 s minimum per move in all non-Fidelity/H+G .uci files; risc2500 family
- [4f9015e](https://github.com/RandyR99/chessengine/commit/4f9015e) 2026-10-11 chessengine: chessmst: port to MAME 0.289, fix level range, re-enable set_pos
- [d550b19](https://github.com/RandyR99/mame_for_picochess/commit/d550b19) 2026-10-11 mame_for_picochess: chessmst, chessmsta: same levels from Levels.txt, fix Elo and chessmsta name

</details>

<details><summary><code>chessmsta</code> VEB ChessMaster G-5003-500</summary>

- MAME set `chessmsta` (Chess-Master (model G-5003-500)), driver `ddr/chessmst.cpp`, clone of `chessmst`
- script runs `mess chessmsta`
- interface `chessmsta.lua` → `chessmst.lua`
- retro.ini: elo 1100, levels 7, ponder/brain n

**Levels:** 5s move; 12s move; 23s move; 70s move; 3m move; 5m move; Analysis

**Commits**

- [2281abb](https://github.com/RandyR99/mame_for_picochess/commit/2281abb) 2026-10-17 mame_for_picochess: levels: 5 s minimum per move in all non-Fidelity/H+G .uci files; risc2500 family
- [d550b19](https://github.com/RandyR99/mame_for_picochess/commit/d550b19) 2026-10-11 mame_for_picochess: chessmst, chessmsta: same levels from Levels.txt, fix Elo and chessmsta name

</details>

<details><summary><code>chessmstdm</code> VEB ChessMaster Diamond PM10 Openings</summary>

- MAME set `chessmstdm` (Chess-Master Diamond), driver `ddr/chessmstdm.cpp`
- script runs `mess chessmstdm -cart pm10`
- interface `chessmstdm.lua`
- retro.ini: elo 1190, levels 8, ponder/brain n

**retro.ini comment:** Loads the PM10 openings cartridge

**Levels:** 5s move; 10s move; 20s move; 30s move; 60s move; 90s move; 2m move; 40 moves/2h

**Commits**

- [5d7a2a4](https://github.com/RandyR99/chessengine/commit/5d7a2a4) 2026-10-31 chessengine: show_info: chessmstdm sends the evaluation and the best move, without key presses.
- [506d638](https://github.com/RandyR99/chessengine/commit/506d638) 2026-10-30 chessengine: show_info: no key presses during the machine's search. 16 interfaces read their info by pressing keys (INFO, page keys, CL) while the machine thinks; a press…
- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [d4eed72](https://github.com/RandyR99/mame_for_picochess/commit/d4eed72) 2026-10-20 mame_for_picochess: uci: short tournament headings ('40/2h', '60/5m') as '40 moves/2h', units h/m
- [2281abb](https://github.com/RandyR99/mame_for_picochess/commit/2281abb) 2026-10-17 mame_for_picochess: levels: 5 s minimum per move in all non-Fidelity/H+G .uci files; risc2500 family
- [6a829f2](https://github.com/RandyR99/chessengine/commit/6a829f2) 2026-10-11 chessengine: chessmstdm: port to MAME 0.289, fix edit_game, re-enable set_pos

</details>

<details><summary><code>sc2</code> VEB Schachcomputer SC2</summary>

**Known limits**

- Castling rights from the FEN aren't passed on: the machine castles whenever king and rook are on their home squares.

- MAME set `sc2` (Schachcomputer SC 2 (rev. E)), driver `ddr/sc2.cpp`
- script runs `mess sc2`
- interface `sc2.lua`
- retro.ini: elo 700, levels 7, ponder/brain n

**Levels:** 5s move; 8s move; 40s move; 60s move; 150s move; 4.5m move; 10m move

**Commits**

- [26c26de](https://github.com/RandyR99/chessengine/commit/26c26de) 2026-11-04 chessengine: interfaces: player's underpromotion through the position setup on 45 more machines
- [2281abb](https://github.com/RandyR99/mame_for_picochess/commit/2281abb) 2026-10-17 mame_for_picochess: levels: 5 s minimum per move in all non-Fidelity/H+G .uci files; risc2500 family
- [cffddda](https://github.com/RandyR99/mame_for_picochess/commit/cffddda) 2026-10-13 mame_for_picochess: Convert CRLF line endings to LF
- [9f577dc](https://github.com/RandyR99/chessengine/commit/9f577dc) 2026-10-12 chessengine: sc2: add set_pos and edit_game via problem mode
- [55c235d](https://github.com/RandyR99/chessengine/commit/55c235d) 2026-10-12 chessengine: sc2: port to MAME 0.289

</details>

<details><summary><code>sc2a</code> VEB Schachcomputer SC2 (rev. 0)</summary>

**Known limits**

- Castling rights from the FEN aren't passed on: the machine castles whenever king and rook are on their home squares.

- MAME set `sc2a` (Schachcomputer SC 2), driver `ddr/sc2.cpp`, clone of `sc2`
- script runs `mess sc2a`
- interface `sc2.lua`
- retro.ini: elo 700, levels 7, ponder/brain n

**Levels:** 5s move; 8s move; 40s move; 1m move; 150s move; 270s move; 10m move

**Commits**

- [26c26de](https://github.com/RandyR99/chessengine/commit/26c26de) 2026-11-04 chessengine: interfaces: player's underpromotion through the position setup on 45 more machines
- [c189a33](https://github.com/RandyR99/mame_for_picochess/commit/c189a33) 2026-10-27 mame_for_picochess: Revisit phase 2 step 1: 35 .uci files to conventions (Level n headings from PicoTimeControl, easiest to hardest within per-move/game/tournament groups, tourn…
- [2281abb](https://github.com/RandyR99/mame_for_picochess/commit/2281abb) 2026-10-17 mame_for_picochess: levels: 5 s minimum per move in all non-Fidelity/H+G .uci files; risc2500 family
- [9f577dc](https://github.com/RandyR99/chessengine/commit/9f577dc) 2026-10-12 chessengine: sc2: add set_pos and edit_game via problem mode
- [55c235d](https://github.com/RandyR99/chessengine/commit/55c235d) 2026-10-12 chessengine: sc2: port to MAME 0.289
- [19805d9](https://github.com/RandyR99/mame_for_picochess/commit/19805d9) 2026-10-12 mame_for_picochess: Move vetted poly880s and sc2a into retro.ini
- [26ac50d](https://github.com/RandyR99/mame_for_picochess/commit/26ac50d) 2026-10-12 mame_for_picochess: Add sc2a (Schachcomputer SC 2 rev. 0) to retro_additions

</details>

<details><summary><code>lc80e</code> VEB Schachcomputer SC80</summary>

**Known limits**

- No history replay: a takeback or a resumed game can't be passed to the machine.
- No position setup: plays from the start position only.
- Promotes only to a queen; a player underpromotion can't be entered.

- MAME set `lc80e` (Lerncomputer LC 80 (export)), driver `ddr/lc80.cpp`, clone of `lc80`
- script runs `mess lc80e`
- interface `lc80e.lua` → `lc80.lua`
- retro.ini: elo 700, levels 5, ponder/brain n

**Levels:** 5s move; 10s move; 15s move; 30s move; 1m move

**Commits**

- [c189a33](https://github.com/RandyR99/mame_for_picochess/commit/c189a33) 2026-10-27 mame_for_picochess: Revisit phase 2 step 1: 35 .uci files to conventions (Level n headings from PicoTimeControl, easiest to hardest within per-move/game/tournament groups, tourn…
- [2281abb](https://github.com/RandyR99/mame_for_picochess/commit/2281abb) 2026-10-17 mame_for_picochess: levels: 5 s minimum per move in all non-Fidelity/H+G .uci files; risc2500 family
- [625d02a](https://github.com/RandyR99/chessengine/commit/625d02a) 2026-10-13 chessengine: Convert CRLF line endings to LF
- [703f917](https://github.com/RandyR99/chessengine/commit/703f917) 2026-10-12 chessengine: lc80: port to MAME 0.289, report unsupported underpromotion

</details>

<details><summary><code>poly880s</code> Poly-Computer 880 SC1</summary>

**Known limits**

- No history replay: a takeback or a resumed game can't be passed to the machine.
- No position setup: plays from the start position only.
- Resigns lost positions (I LOSE, display flashes): the plugin sends bestmove 0000.

- MAME set `poly880s` (Poly-Computer 880 (SC1)), driver `ddr/poly880.cpp`, clone of `poly880`
- script runs `mess poly880s`
- interface `poly880s.lua`
- retro.ini: elo 700, levels 7, ponder/brain n

**Levels:** 5s move; 15s move; 1m20s move; 2m10s move; 3m move; 6m move; 20m move

**Commits**

- [26c26de](https://github.com/RandyR99/chessengine/commit/26c26de) 2026-11-04 chessengine: interfaces: player's underpromotion through the position setup on 45 more machines
- [6f4c493](https://github.com/RandyR99/chessengine/commit/6f4c493) 2026-10-29 chessengine: Game end: optional interface.game_over() - when it returns true on the machine's turn, init.lua sends 'bestmove 0000' once (reset by the next 'position'); pi…
- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [bd0c81b](https://github.com/RandyR99/chessengine/commit/bd0c81b) 2026-10-12 chessengine: poly880s: add interface (from MessChess sc880.lua, MAME 0.289)
- [7364ca9](https://github.com/RandyR99/mame_for_picochess/commit/7364ca9) 2026-10-12 mame_for_picochess: slc1, poly880s: levels from the SCC-8 manual, drop postal level
- [19805d9](https://github.com/RandyR99/mame_for_picochess/commit/19805d9) 2026-10-12 mame_for_picochess: Move vetted poly880s and sc2a into retro.ini
- [c50bfb9](https://github.com/RandyR99/mame_for_picochess/commit/c50bfb9) 2026-10-12 mame_for_picochess: Add Poly-Computer 880 SC1 (poly880s)

</details>

<details><summary><code>slc1</code> VEB Schachcomputer SLC1</summary>

**Known limits**

- No history replay: a takeback or a resumed game can't be passed to the machine.
- No position setup: plays from the start position only.
- Promotes only to a queen; a player underpromotion can't be entered.
- Resigns lost positions (I LOSE, display flashes): the plugin sends bestmove 0000.
- Facing mate on the next move it often gives up silently; after 10 s without activity the plugin treats this as a resignation.

- MAME set `slc1` (Schach- und Lerncomputer SLC 1), driver `ddr/slc1.cpp`
- script runs `mess slc1`
- interface `slc1.lua`
- retro.ini: elo 700, levels 7, ponder/brain n

**Test notes**

- slc1: facing mate on the next move it often gives up silently (blank display, board reset + input cursor, or flashing the player's move) - game_over() = busy LED off &gt; 10 s on its turn (a4241dc, 2026-10-30).

**Levels:** 5s move; 15s move; 1m20s move; 2m10s move; 3m move; 6m move; 20m move

**Commits**

- [26c26de](https://github.com/RandyR99/chessengine/commit/26c26de) 2026-11-04 chessengine: interfaces: player's underpromotion through the position setup on 45 more machines
- [a4241dc](https://github.com/RandyR99/chessengine/commit/a4241dc) 2026-10-30 chessengine: slc1: facing mate on the next move the machine often gives up without a move and without its 'I LOSE' 09-flash - the display stays blank, shows only the inpu…
- [6f4c493](https://github.com/RandyR99/chessengine/commit/6f4c493) 2026-10-29 chessengine: Game end: optional interface.game_over() - when it returns true on the machine's turn, init.lua sends 'bestmove 0000' once (reset by the next 'position'); pi…
- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [0c65ec9](https://github.com/RandyR99/chessengine/commit/0c65ec9) 2026-10-12 chessengine: slc1: port to MAME 0.289, report unsupported underpromotion
- [7364ca9](https://github.com/RandyR99/mame_for_picochess/commit/7364ca9) 2026-10-12 mame_for_picochess: slc1, poly880s: levels from the SCC-8 manual, drop postal level
- [c50bfb9](https://github.com/RandyR99/mame_for_picochess/commit/c50bfb9) 2026-10-12 mame_for_picochess: Add Poly-Computer 880 SC1 (poly880s)

</details>

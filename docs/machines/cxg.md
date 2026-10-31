# CXG

MAME chess machines in picochess, part of the [machine overview](../MACHINES.md) (columns and general limits explained there).

| System | Name | Year | Elo | Levels | FEN | History | Info | Ponder | Limits |
|---|---|---:|---:|---:|:-:|:-:|:-:|:-:|---:|
| `ch2001` | CXG Chess 2001 | 1984 | 1660 | 9 | ✓ | ✓ | – | – | 1 |
| `ch3008` | CXG Chess 3008 | 1987 | 1650 | 9 | ✓ | ✓ | – | – |  |
| `scpchess` | CXG Sensor Computachess | 1985 | 840 | 7 | ✓ | – | – | – | 2 |
| `scpchessa` | CXG Sensor Computachess | 1981 | 840 | 6 | ✓ | – | – | – | 4 |
| `scprof` | CXG Sphinx Chess Professor | 1989 | 1695 | 5 | ✓ | ✓ | – | – |  |
| `scmder` | CXG Sphinx Commander | 1989 | 1880 | 10 | ✓ | ✓ | – | – |  |
| `cpchess2` | CXG Computachess II | 1982 | 1090 | 5 | – | – | – | – | 2 |
| `enterp` | CXG Enterprise S | 1984 | 1310 | 5 | ✓ | ✓ | – | – | 1 |
| `pchess` | CXG Pocket Chess | 1986 | 1085 | 4 | ✓ | – | – | – | 1 |
| `sdtor` | CXG Sphinx Dominator v2.05 | 1989 | 1940 | 10 | ✓ | ✓ | – | – |  |
| `sdtora` | CXG Sphinx Dominator v2.04 | 1989 | 1940 | 10 | ✓ | ✓ | – | – |  |
| `sjunior` | CXG Sphinx Junior | 1988 | 1085 | 4 | ✓ | ✓ | – | – |  |
| `sphinx40` | CXG Sphinx40 | 1987 | 1720 | 17 | ✓ | ✓ | ✓ | – |  |
| `sgalaxy` | CXG Sphinx Galaxy v2.03 | 1988 | 1940 | 10 | ✓ | ✓ | – | – |  |
| `sgalaxya` | CXG Sphinx Galaxy v2.00 | 1988 | 1940 | 10 | ✓ | ✓ | – | – |  |
| `sgalaxyb` | CXG Sphinx Galaxy v1.03 | 1988 | 1940 | 10 | ✓ | ✓ | – | – |  |
| `senterp` | CXG Super Enterprise 210 | 1986 | 1660 | 10 | ✓ | ✓ | – | – |  |
| `senterpc` | CXG Super Enterprise 210.C | 1986 | 1660 | 10 | ✓ | ✓ | – | – |  |
| `slegend` | CXG Sphinx Legend | 1992 | 1775 | 10 | ✓ | ✓ | ✓ | – |  |
| `sroyal` | CXG Sphinx Royal | 1988 | 980 | 3 | ✓ | ✓ | – | – |  |
| `granada` | CXG Sphinx Granada | 1988 | 980 | 3 | ✓ | ✓ | – | – |  |
| `supra` | CXG Sphinx Supra | 1988 | 980 | 3 | ✓ | ✓ | – | – |  |

<details><summary><code>ch2001</code> CXG Chess 2001</summary>

**Known limits**

- Castling as the first move after a position setup fails (Set Up grants no castling rights; castling in a replayed history works).

- MAME set `ch2001` (Chess 2001), driver `newcrest/chess2001.cpp`
- script runs `mess ch2001`
- interface `ch2001.lua`
- retro.ini: elo 1660, levels 9, ponder/brain n

**Levels:** 5s move; 6s move; 15s move; 30s move; 45s move; 1m move; 105s move; 165s move; 210s move

**Commits**

- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [2281abb](https://github.com/RandyR99/mame_for_picochess/commit/2281abb) 2026-10-17 mame_for_picochess: levels: 5 s minimum per move in all non-Fidelity/H+G .uci files; risc2500 family
- [b859c98](https://github.com/RandyR99/chessengine/commit/b859c98) 2026-10-13 chessengine: ch2001: port to MAME 0.289 output proxies
- [a0b69ca](https://github.com/RandyR99/mame_for_picochess/commit/a0b69ca) 2026-10-13 mame_for_picochess: Add ch3008 (CXG Chess 3008); tidy ch2001 levels

</details>

<details><summary><code>ch3008</code> CXG Chess 3008</summary>

- MAME set `ch3008` (Chess 3008), driver `newcrest/chess3008.cpp`
- script runs `mess ch3008`
- interface `ch3008.lua`
- retro.ini: elo 1650, levels 9, ponder/brain n

**Levels:** 5s move; 10s move; 30s move; 1m move; 5m move; 10m move; 5m game; 10m game; 30m game

**Commits**

- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [1668b8a](https://github.com/RandyR99/mame_for_picochess/commit/1668b8a) 2026-10-13 mame_for_picochess: Move ch3008 from retro_additions.ini to retro.ini
- [7aa15ac](https://github.com/RandyR99/chessengine/commit/7aa15ac) 2026-10-13 chessengine: ch3008: new interface from CB-Emu MessNew, ported to MAME 0.289
- [a0b69ca](https://github.com/RandyR99/mame_for_picochess/commit/a0b69ca) 2026-10-13 mame_for_picochess: Add ch3008 (CXG Chess 3008); tidy ch2001 levels

</details>

<details><summary><code>scpchess</code> CXG Sensor Computachess</summary>

**Known limits**

- No history replay: a takeback or a resumed game can't be passed to the machine.
- No castling-rights tracking in the ROM: it castles whenever its king is home, even without the rook.

- MAME set `scpchess` (Sensor Computachess (1985 version)), driver `newcrest/computachess.cpp`
- script runs `mess scpchess`
- interface `scpchess.lua` → `scpchessa.lua`
- retro.ini: elo 840, levels 7, ponder/brain n

**Levels:** 8s move; 13s move; 20s move; 25s move; 30s move; 35s move; 45s move

**Commits**

- [e2edc7a](https://github.com/RandyR99/chessengine/commit/e2edc7a) 2026-10-13 chessengine: scpchess/scpchessa: port to MAME 0.289, swap to match 0.289 sets, enable set_pos
- [4a1f3a8](https://github.com/RandyR99/mame_for_picochess/commit/4a1f3a8) 2026-10-13 mame_for_picochess: scpchess/scpchessa: .uci levels from measured think times; add to retro_additions
- [6fdc56c](https://github.com/RandyR99/mame_for_picochess/commit/6fdc56c) 2026-10-13 mame_for_picochess: Move scpchess and scpchessa to retro.ini (scpchessa ROM bug noted in comments)

</details>

<details><summary><code>scpchessa</code> CXG Sensor Computachess</summary>

**Known limits**

- No history replay: a takeback or a resumed game can't be passed to the machine.
- No castling-rights tracking in the ROM: it castles whenever its king is home, even without the rook.
- ROM bug: in one known position (as Black) it plays d2-d4 for White and never moves; the 1985 version doesn't.
- Can stall when a 'go' arrives seconds after the position (not seen with picochess's normal timing).

- MAME set `scpchessa` (Sensor Computachess (1981 version)), driver `newcrest/computachess.cpp`, clone of `scpchess`
- script runs `mess scpchessa`
- interface `scpchessa.lua`
- retro.ini: elo 840, levels 6, ponder/brain n

**retro.ini comment:** ROM bug: in rnbqk2r/pppp1ppp/8/2b1p3/4n3/P7/RPPP1PPP/1NBQKBNR b (as Black) it plays d2-d4 for White and never sends a move. Not fixable in the plugin; the 1985 version (scpchess) does not have it.

**Levels:** 9s move; 12s move; 20s move; 25s move; 30s move; 35s move

**Commits**

- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [e2edc7a](https://github.com/RandyR99/chessengine/commit/e2edc7a) 2026-10-13 chessengine: scpchess/scpchessa: port to MAME 0.289, swap to match 0.289 sets, enable set_pos
- [4a1f3a8](https://github.com/RandyR99/mame_for_picochess/commit/4a1f3a8) 2026-10-13 mame_for_picochess: scpchess/scpchessa: .uci levels from measured think times; add to retro_additions
- [6fdc56c](https://github.com/RandyR99/mame_for_picochess/commit/6fdc56c) 2026-10-13 mame_for_picochess: Move scpchess and scpchessa to retro.ini (scpchessa ROM bug noted in comments)

</details>

<details><summary><code>scprof</code> CXG Sphinx Chess Professor</summary>

- MAME set `scprof` (Sphinx Chess Professor), driver `newcrest/professor.cpp`
- script runs `mess scprof`
- interface `scprof.lua`
- retro.ini: elo 1695, levels 5, ponder/brain n

**Levels:** 5s move; 10s move; 30s move; 1m move; 3m move

**Commits**

- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [2281abb](https://github.com/RandyR99/mame_for_picochess/commit/2281abb) 2026-10-17 mame_for_picochess: levels: 5 s minimum per move in all non-Fidelity/H+G .uci files; risc2500 family
- [625d02a](https://github.com/RandyR99/chessengine/commit/625d02a) 2026-10-13 chessengine: Convert CRLF line endings to LF
- [923e543](https://github.com/RandyR99/chessengine/commit/923e543) 2026-10-13 chessengine: scprof: port to MAME 0.289 output proxies

</details>

<details><summary><code>scmder</code> CXG Sphinx Commander</summary>

- MAME set `scmder` (Sphinx Commander (v2.00)), driver `newcrest/dominator.cpp`
- script runs `mess scmder`
- interface `scmder.lua` → `sdtor.lua`
- retro.ini: elo 1880, levels 10, ponder/brain n

**Levels:** 5s move; 10s move; 30s move; 1m move; 3m move; 1m game; 5m game; 10m game; 15m game; 40 moves/1.5h

**Commits**

- [e2aa330](https://github.com/RandyR99/mame_for_picochess/commit/e2aa330) 2026-10-20 mame_for_picochess: uci: tournament headings as '40 moves/2h' instead of '40 moves in 2h'
- [14de866](https://github.com/RandyR99/mame_for_picochess/commit/14de866) 2026-10-13 mame_for_picochess: newcrest: new engines, .uci levels from the level picker, retro.ini fixes
- [4dc4a63](https://github.com/RandyR99/chessengine/commit/4dc4a63) 2026-10-13 chessengine: sdtor/sgalaxy/scmder: port to MAME 0.289, fix scmder move entry

</details>

<details><summary><code>cpchess2</code> CXG Computachess II</summary>

**Known limits**

- No history replay: a takeback or a resumed game can't be passed to the machine.
- No position setup: with a written position the ROM plays king moves into check or never moves (it keeps more state than the board).

- MAME set `cpchess2` (Computachess II), driver `newcrest/computachess2.cpp`
- script runs `mess cpchess2`
- interface `cpchess2.lua`
- retro.ini: elo 1090, levels 5, ponder/brain n

**Levels:** 5s move; 10s move; 15s move; 3m move; 10m move

**Commits**

- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [14de866](https://github.com/RandyR99/mame_for_picochess/commit/14de866) 2026-10-13 mame_for_picochess: newcrest: new engines, .uci levels from the level picker, retro.ini fixes
- [4d53174](https://github.com/RandyR99/chessengine/commit/4d53174) 2026-10-13 chessengine: cpchess2: port to MAME 0.289 output proxies, stable level bar

</details>

<details><summary><code>enterp</code> CXG Enterprise S</summary>

**Known limits**

- Promotes only to a queen; a player underpromotion can't be entered.

- MAME set `enterp` (Enterprise "S"), driver `saitek/companion2.cpp`
- script runs `mess enterp`
- interface `enterp.lua`
- retro.ini: elo 1310, levels 5, ponder/brain n

**Levels:** 5s move; 10s move; 30s move; 1m move; 10m move

**Commits**

- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [8b0248b](https://github.com/RandyR99/mame_for_picochess/commit/8b0248b) 2026-10-26 mame_for_picochess: modular_tm.cpp (TM / 68030 modules): port32t .uci = Portorose 10 levels (TURN 08 = 40 moves/2h, verified), other 7 = Berlin Pro 11 levels; retro: new lyon32t…
- [2281abb](https://github.com/RandyR99/mame_for_picochess/commit/2281abb) 2026-10-17 mame_for_picochess: levels: 5 s minimum per move in all non-Fidelity/H+G .uci files; risc2500 family
- [98dd217](https://github.com/RandyR99/mame_for_picochess/commit/98dd217) 2026-10-15 mame_for_picochess: compan2, enterp: new engines; compan levels = 6
- [ba03af4](https://github.com/RandyR99/chessengine/commit/ba03af4) 2026-10-15 chessengine: compan2, enterp: new interfaces from MessChess, ported to MAME 0.289

</details>

<details><summary><code>pchess</code> CXG Pocket Chess</summary>

**Known limits**

- No history replay: a takeback or a resumed game can't be passed to the machine.

- MAME set `pchess` (Pocketchess (CXG)), driver `newcrest/pchess.cpp`
- script runs `mess pchess`
- interface `pchess.lua`
- retro.ini: elo 1085, levels 4, ponder/brain n

**Levels:** 10s move; 15s move; 20s move; 25s move

**Commits**

- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [14de866](https://github.com/RandyR99/mame_for_picochess/commit/14de866) 2026-10-13 mame_for_picochess: newcrest: new engines, .uci levels from the level picker, retro.ini fixes
- [7ec86df](https://github.com/RandyR99/chessengine/commit/7ec86df) 2026-10-13 chessengine: pchess: port to MAME 0.289 (output proxies, RAM via data space)

</details>

<details><summary><code>sdtor</code> CXG Sphinx Dominator v2.05</summary>

- MAME set `sdtor` (Sphinx Dominator (v2.05)), driver `newcrest/dominator.cpp`
- script runs `mess sdtor`
- interface `sdtor.lua`
- retro.ini: elo 1940, levels 10, ponder/brain n

**Levels:** 5s move; 10s move; 30s move; 1m move; 3m move; 1m game; 5m game; 10m game; 15m game; 40 moves/1.5h

**Commits**

- [506d638](https://github.com/RandyR99/chessengine/commit/506d638) 2026-10-30 chessengine: show_info: no key presses during the machine's search. 16 interfaces read their info by pressing keys (INFO, page keys, CL) while the machine thinks; a press…
- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [e2aa330](https://github.com/RandyR99/mame_for_picochess/commit/e2aa330) 2026-10-20 mame_for_picochess: uci: tournament headings as '40 moves/2h' instead of '40 moves in 2h'
- [14de866](https://github.com/RandyR99/mame_for_picochess/commit/14de866) 2026-10-13 mame_for_picochess: newcrest: new engines, .uci levels from the level picker, retro.ini fixes
- [4dc4a63](https://github.com/RandyR99/chessengine/commit/4dc4a63) 2026-10-13 chessengine: sdtor/sgalaxy/scmder: port to MAME 0.289, fix scmder move entry

</details>

<details><summary><code>sdtora</code> CXG Sphinx Dominator v2.04</summary>

- MAME set `sdtora` (Sphinx Dominator (v2.04)), driver `newcrest/dominator.cpp`, clone of `sdtor`
- script runs `mess sdtora`
- interface `sdtor.lua`
- retro.ini: elo 1940, levels 10, ponder/brain n

**Levels:** 5s move; 10s move; 30s move; 1m move; 3m move; 1m game; 5m game; 10m game; 15m game; 40 moves/1.5h

**Commits**

- [506d638](https://github.com/RandyR99/chessengine/commit/506d638) 2026-10-30 chessengine: show_info: no key presses during the machine's search. 16 interfaces read their info by pressing keys (INFO, page keys, CL) while the machine thinks; a press…
- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [d6815c6](https://github.com/RandyR99/mame_for_picochess/commit/d6815c6) 2026-10-27 mame_for_picochess: Revisit phase 2 step 2: 50 missing working sets added (scripts, _art, .uci from the parent, retro entries; all smoke-tested): borisa, conca, concglapa, sdtor…
- [4dc4a63](https://github.com/RandyR99/chessengine/commit/4dc4a63) 2026-10-13 chessengine: sdtor/sgalaxy/scmder: port to MAME 0.289, fix scmder move entry

</details>

<details><summary><code>sjunior</code> CXG Sphinx Junior</summary>

- MAME set `sjunior` (Sphinx Junior), driver `newcrest/junior.cpp`
- script runs `mess sjunior`
- interface `sjunior.lua`
- retro.ini: elo 1085, levels 4, ponder/brain n

**Levels:** 5s move; 10s move; 15s move; 20s move

**Commits**

- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [d2c9012](https://github.com/RandyR99/chessengine/commit/d2c9012) 2026-10-13 chessengine: sjunior: port to MAME 0.289 (output proxies, RAM via data space)
- [14de866](https://github.com/RandyR99/mame_for_picochess/commit/14de866) 2026-10-13 mame_for_picochess: newcrest: new engines, .uci levels from the level picker, retro.ini fixes

</details>

<details><summary><code>sphinx40</code> CXG Sphinx40</summary>

- MAME set `sphinx40` (Sphinx 40), driver `newcrest/sphinx40.cpp`
- script runs `mess sphinx40`
- interface `sphinx40.lua`
- retro.ini: elo 1720, levels 17, ponder/brain n

**Levels:** 5s move; 10s move; 15s move; 20s move; 30s move; 45s move; 60s move; 75s move; 90s move; 105s move; 2m move; 135s move; 2.5m move; 165s move; 185s move; 225s move; Analysis

**Commits**

- [0e72b41](https://github.com/RandyR99/chessengine/commit/0e72b41) 2026-10-31 chessengine: show_info: sphinx40 sends the best move so far, read from RAM without key presses (the Analysis key reader was off: a press could land just as the move appea…
- [506d638](https://github.com/RandyR99/chessengine/commit/506d638) 2026-10-30 chessengine: show_info: no key presses during the machine's search. 16 interfaces read their info by pressing keys (INFO, page keys, CL) while the machine thinks; a press…
- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [2281abb](https://github.com/RandyR99/mame_for_picochess/commit/2281abb) 2026-10-17 mame_for_picochess: levels: 5 s minimum per move in all non-Fidelity/H+G .uci files; risc2500 family
- [ab915a9](https://github.com/RandyR99/chessengine/commit/ab915a9) 2026-10-13 chessengine: sphinx40: port to MAME 0.289 output proxies

</details>

<details><summary><code>sgalaxy</code> CXG Sphinx Galaxy v2.03</summary>

- MAME set `sgalaxy` (Sphinx Galaxy (v2.03)), driver `newcrest/dominator.cpp`
- script runs `mess sgalaxy`
- interface `sgalaxy.lua`
- retro.ini: elo 1940, levels 10, ponder/brain n

**Levels:** 5s move; 10s move; 30s move; 1m move; 3m move; 1m game; 5m game; 10m game; 15m game; 40 moves/1.5h

**Commits**

- [4827d0e](https://github.com/RandyR99/chessengine/commit/4827d0e) 2026-10-29 chessengine: sgalaxy, sgalaxyb: show_info disabled - its INFO press every ~10 s landed when the machine finished its move on the default level (10 s), so the machine took…
- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [e2aa330](https://github.com/RandyR99/mame_for_picochess/commit/e2aa330) 2026-10-20 mame_for_picochess: uci: tournament headings as '40 moves/2h' instead of '40 moves in 2h'
- [14de866](https://github.com/RandyR99/mame_for_picochess/commit/14de866) 2026-10-13 mame_for_picochess: newcrest: new engines, .uci levels from the level picker, retro.ini fixes
- [4dc4a63](https://github.com/RandyR99/chessengine/commit/4dc4a63) 2026-10-13 chessengine: sdtor/sgalaxy/scmder: port to MAME 0.289, fix scmder move entry

</details>

<details><summary><code>sgalaxya</code> CXG Sphinx Galaxy v2.00</summary>

- MAME set `sgalaxya` (Sphinx Galaxy (v2.00)), driver `newcrest/dominator.cpp`, clone of `sgalaxy`
- script runs `mess sgalaxya`
- interface `sgalaxy.lua`
- retro.ini: elo 1940, levels 10, ponder/brain n

**Levels:** 5s move; 10s move; 30s move; 1m move; 3m move; 1m game; 5m game; 10m game; 15m game; 40 moves/1.5h

**Commits**

- [4827d0e](https://github.com/RandyR99/chessengine/commit/4827d0e) 2026-10-29 chessengine: sgalaxy, sgalaxyb: show_info disabled - its INFO press every ~10 s landed when the machine finished its move on the default level (10 s), so the machine took…
- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [e2aa330](https://github.com/RandyR99/mame_for_picochess/commit/e2aa330) 2026-10-20 mame_for_picochess: uci: tournament headings as '40 moves/2h' instead of '40 moves in 2h'
- [14de866](https://github.com/RandyR99/mame_for_picochess/commit/14de866) 2026-10-13 mame_for_picochess: newcrest: new engines, .uci levels from the level picker, retro.ini fixes
- [4dc4a63](https://github.com/RandyR99/chessengine/commit/4dc4a63) 2026-10-13 chessengine: sdtor/sgalaxy/scmder: port to MAME 0.289, fix scmder move entry

</details>

<details><summary><code>sgalaxyb</code> CXG Sphinx Galaxy v1.03</summary>

- MAME set `sgalaxyb` (Sphinx Galaxy (v1.03)), driver `newcrest/dominator.cpp`, clone of `sgalaxy`
- script runs `mess sgalaxyb`
- interface `sgalaxyb.lua` → `sgalaxy.lua`
- retro.ini: elo 1940, levels 10, ponder/brain n

**Levels:** 10s move; 30s move; 1m move; 3m move; 10m move; 1m game; 5m game; 10m game; 15m game; 40 moves/1.5h

**Commits**

- [4827d0e](https://github.com/RandyR99/chessengine/commit/4827d0e) 2026-10-29 chessengine: sgalaxy, sgalaxyb: show_info disabled - its INFO press every ~10 s landed when the machine finished its move on the default level (10 s), so the machine took…
- [e2aa330](https://github.com/RandyR99/mame_for_picochess/commit/e2aa330) 2026-10-20 mame_for_picochess: uci: tournament headings as '40 moves/2h' instead of '40 moves in 2h'
- [14de866](https://github.com/RandyR99/mame_for_picochess/commit/14de866) 2026-10-13 mame_for_picochess: newcrest: new engines, .uci levels from the level picker, retro.ini fixes

</details>

<details><summary><code>senterp</code> CXG Super Enterprise 210</summary>

- MAME set `senterp` (Super Enterprise (model 210)), driver `newcrest/senterprise.cpp`
- script runs `mess senterp`
- interface `senterp.lua`
- retro.ini: elo 1660, levels 10, ponder/brain n

**Levels:** 5s move; 10s move; 30s move; 1m move; 1m game; 3m game; 5m game; 10m game; 15m game; 40 moves/1.5h

**Commits**

- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [e2aa330](https://github.com/RandyR99/mame_for_picochess/commit/e2aa330) 2026-10-20 mame_for_picochess: uci: tournament headings as '40 moves/2h' instead of '40 moves in 2h'
- [f4afb96](https://github.com/RandyR99/chessengine/commit/f4afb96) 2026-10-13 chessengine: senterp/senterpc: new interfaces from CB-Emu MessChess, ported to MAME 0.289
- [14de866](https://github.com/RandyR99/mame_for_picochess/commit/14de866) 2026-10-13 mame_for_picochess: newcrest: new engines, .uci levels from the level picker, retro.ini fixes

</details>

<details><summary><code>senterpc</code> CXG Super Enterprise 210.C</summary>

- MAME set `senterpc` (Super Enterprise (model 210.C)), driver `newcrest/senterprise.cpp`, clone of `senterp`
- script runs `mess senterpc`
- interface `senterpc.lua` → `senterp.lua`
- retro.ini: elo 1660, levels 10, ponder/brain n

**Levels:** 5s move; 10s move; 30s move; 1m move; 1m game; 3m game; 5m game; 10m game; 15m game; 40 moves/1.5h

**Commits**

- [e2aa330](https://github.com/RandyR99/mame_for_picochess/commit/e2aa330) 2026-10-20 mame_for_picochess: uci: tournament headings as '40 moves/2h' instead of '40 moves in 2h'
- [14de866](https://github.com/RandyR99/mame_for_picochess/commit/14de866) 2026-10-13 mame_for_picochess: newcrest: new engines, .uci levels from the level picker, retro.ini fixes
- [f4afb96](https://github.com/RandyR99/chessengine/commit/f4afb96) 2026-10-13 chessengine: senterp/senterpc: new interfaces from CB-Emu MessChess, ported to MAME 0.289

</details>

<details><summary><code>slegend</code> CXG Sphinx Legend</summary>

- MAME set `slegend` (Sphinx Legend), driver `newcrest/legend.cpp`
- script runs `mess slegend`
- interface `slegend.lua` → `kchal.lua`
- retro.ini: elo 1775, levels 10, ponder/brain n

**Levels:** 5s move; 10s move; 30s move; 1m move; 3m move; 2m game; 5m game; 10m game; 15m game; 40 moves/2h

**Commits**

- [e2aa330](https://github.com/RandyR99/mame_for_picochess/commit/e2aa330) 2026-10-20 mame_for_picochess: uci: tournament headings as '40 moves/2h' instead of '40 moves in 2h'
- [14de866](https://github.com/RandyR99/mame_for_picochess/commit/14de866) 2026-10-13 mame_for_picochess: newcrest: new engines, .uci levels from the level picker, retro.ini fixes
- [9844e5a](https://github.com/RandyR99/chessengine/commit/9844e5a) 2026-10-13 chessengine: kchal: rework for this plugin and MAME 0.289; add slegend

</details>

<details><summary><code>sroyal</code> CXG Sphinx Royal</summary>

- MAME set `sroyal` (Sphinx Royal), driver `newcrest/royal.cpp`
- script runs `mess sroyal`
- interface `sroyal.lua`
- retro.ini: elo 980, levels 3, ponder/brain n

**Levels:** 10s move; 30s move; 1m move

**Commits**

- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [14de866](https://github.com/RandyR99/mame_for_picochess/commit/14de866) 2026-10-13 mame_for_picochess: newcrest: new engines, .uci levels from the level picker, retro.ini fixes
- [88d94c4](https://github.com/RandyR99/chessengine/commit/88d94c4) 2026-10-13 chessengine: sroyal: new interface from CB-Emu MessNew, ported to MAME 0.289

</details>

<details><summary><code>granada</code> CXG Sphinx Granada</summary>

- MAME set `granada` (Sphinx Granada), driver `newcrest/royal.cpp`, clone of `sroyal`
- script runs `mess granada`
- interface `sroyal.lua`
- retro.ini: elo 980, levels 3, ponder/brain n

**Levels:** 10s move; 30s move; 1m move

**Commits**

- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [d6815c6](https://github.com/RandyR99/mame_for_picochess/commit/d6815c6) 2026-10-27 mame_for_picochess: Revisit phase 2 step 2: 50 missing working sets added (scripts, _art, .uci from the parent, retro entries; all smoke-tested): borisa, conca, concglapa, sdtor…
- [88d94c4](https://github.com/RandyR99/chessengine/commit/88d94c4) 2026-10-13 chessengine: sroyal: new interface from CB-Emu MessNew, ported to MAME 0.289

</details>

<details><summary><code>supra</code> CXG Sphinx Supra</summary>

- MAME set `supra` (Sphinx Supra), driver `newcrest/royal.cpp`, clone of `sroyal`
- script runs `mess supra`
- interface `sroyal.lua`
- retro.ini: elo 980, levels 3, ponder/brain n

**Levels:** 10s move; 30s move; 1m move

**Commits**

- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [d6815c6](https://github.com/RandyR99/mame_for_picochess/commit/d6815c6) 2026-10-27 mame_for_picochess: Revisit phase 2 step 2: 50 missing working sets added (scripts, _art, .uci from the parent, retro entries; all smoke-tested): borisa, conca, concglapa, sdtor…
- [88d94c4](https://github.com/RandyR99/chessengine/commit/88d94c4) 2026-10-13 chessengine: sroyal: new interface from CB-Emu MessNew, ported to MAME 0.289

</details>

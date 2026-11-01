# SciSys

MAME chess machines in picochess, part of the [machine overview](../MACHINES.md) (columns and general limits explained there).

| System | Name | Year | Elo | Levels | FEN | History | Info | Ponder | Limits |
|---|---|---:|---:|---:|:-:|:-:|:-:|:-:|---:|
| `ccmk5` | SciSys Chess Champion MK5 | 1981 | 1465 | 8 | ✓ | ✓ | ✓ | – | 1 |
| `ccmk6` | SciSys Chess Champion MK6 | 1982 | 1385 | 8 | ✓ | ✓ | ✓ | – |  |
| `compan` | SciSys Chess Companion | 1982 | 1250 | 5 | ✓ | ✓ | – | – |  |
| `compan2` | SciSys Chess Companion II | 1983 | 1265 | 6 | ✓ | ✓ | – | – | 1 |
| `expchess` | SciSys Explorer Chess | 1983 | 1265 | 6 | ✓ | ✓ | – | – | 1 |
| `compan3` | SciSys Kasparov Companion III | 1986 | 1535 | 9 | ✓ | ✓ | – | – |  |
| `exechess` | SciSys Executive Chess | 1981 | 1185 | 7 | ✓ | ✓ | – | – | 1 |
| `intchess` | SciSys / Intelligent Games Intelligent Chess | 1980 | 1180 | 9 | ✓ | ✓ | – | – | 1 |
| `chesstrvi` | SciSys Intercontinental Traveler | 1982 | 1010 | 5 | ✓ | ✓ | – | – | 2 |
| `smchess` | SciSys Mini Chess | 1981 | 730 | 2 | ✓ | ✓ | – | – | 1 |
| `schess` | SciSys Sensor Chess | 1981 | 1325 | 7 | ✓ | ✓ | – | – | 2 |
| `schessa` | SciSys Sensor Chess Strong | 1981 | 1310 | 7 | ✓ | ✓ | – | – | 2 |
| `schessc` | SciSys Sensor Chess HMSS | 1982 | 1335 | 7 | ✓ | ✓ | – | – | 2 |
| `sstar28k` | SciSys Superstar 28K | 1983 | 1570 | 9 | ✓ | ✓ | – | – |  |
| `ssystem4` | SciSys Chess Champion Super System IV | 1980 | 1300 | 7 | ✓ | ✓ | – | – | 1 |
| `t1850` | Tandy 1850 Deluxe Table Chess | 1986 | 1535 | 9 | ✓ | ✓ | – | – |  |
| `tschess` | SciSys Travel Sensor Chess | 1982 | 845 | 4 | ✓ | ✓ | – | – | 2 |
| `turbo16k` | SciSys Kasparov Turbo 16K | 1986 | 1615 | 9 | ✓ | ✓ | – | – |  |
| `turbos24k` | SciSys Turbo S-24K | 1986 | 1600 | 10 | ✓ | ✓ | – | ✓ |  |

<details><summary><code>ccmk5</code> SciSys Chess Champion MK5</summary>

**Known limits**

- ROM bug: hangs when its only legal moves are promotions (stack runaway); ccmk6 is fine.

- MAME set `ccmk5` (Chess Champion: Mark V), driver `saitek/mark5.cpp`
- script runs `mess ccmk5`
- interface `ccmk5.lua`
- retro.ini: elo 1465, levels 8, ponder/brain n

**retro.ini comment:** ROM bug: hangs when its only legal moves are promotions (king boxed in by the queen, e.g. k7/2Q5/8/8/8/8/p7/4K3 b). Not fixable in the plugin; ccmk6 does not have it.

**Test notes**

- ccmk5, ccmk6 (saitek/mark5.cpp) \| ccmk5.lua UNCOMMITTED; .uci committed f170747 \| ccmk5 80 ok, ccmk6 82 ok, 0 illegal \| ep_p; illegal FENs refused; OPEN ccmk5 only: machine promotion as its 2nd move after FEN (chk_b g2g1q, chk_w g7g8q) -&gt; no bestmove (ccmk6 fine, ccmk5 first-move promotion fine) \| port (program-space RAM, output proxies) + 2 old level bugs fixed (cur_level=nil -&gt; levels never applied; digit string vs number -&gt; levels with 6-9 crashed) \| 8 levels (5-600 s, TOURN 40/90)
- ccmk5 (2026-10-17): ROM hangs when its only legal moves are promotions (stack runaway); ccmk6 fine. Noted in retro.ini.

**Levels:** 5s move; 10s move; 30s move; 1m move; 3m move; 5m move; 10m move; 40 moves/1.5h

**Commits**

- [6a076b4](https://github.com/RandyR99/chessengine/commit/6a076b4) 2026-10-31 chessengine: show_info audit of show_pv_after_move_emu/_player (called every 500 ticks by init.lua; tested with and without each). ccmk5 (Analysis), risc2500 (Down) and s…
- [542b983](https://github.com/RandyR99/chessengine/commit/542b983) 2026-10-30 chessengine: show_info: Novag, stratos and ccmk5 send only values read in the current search. sexperta/sfortea, nsnova/supremo and cfortea already read the score with the…
- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [e2aa330](https://github.com/RandyR99/mame_for_picochess/commit/e2aa330) 2026-10-20 mame_for_picochess: uci: tournament headings as '40 moves/2h' instead of '40 moves in 2h'
- [0179a1e](https://github.com/RandyR99/chessengine/commit/0179a1e) 2026-10-17 chessengine: ccmk5: port to MAME 0.289 (output proxies, program-space RAM); fix levels never applied after setup and digits 6-9 crash
- [81b907a](https://github.com/RandyR99/mame_for_picochess/commit/81b907a) 2026-10-17 mame_for_picochess: ccmk5: note the ROM hang when only promotions are legal
- [f170747](https://github.com/RandyR99/mame_for_picochess/commit/f170747) 2026-10-16 mame_for_picochess: intchess 9 levels; leonardo family 10 levels, leonardoa/b in retro.ini; ccmk5/ccmk6 8 levels (seconds per move, TOURN 40/90)

</details>

<details><summary><code>ccmk6</code> SciSys Chess Champion MK6</summary>

- MAME set `ccmk6` (Chess Champion: Mark VI/Philidor), driver `saitek/mark5.cpp`, clone of `ccmk5`
- script runs `mess ccmk6`
- interface `ccmk6.lua` → `ccmk5.lua`
- retro.ini: elo 1385, levels 8, ponder/brain n

**Test notes**

- ccmk5, ccmk6 (saitek/mark5.cpp) \| ccmk5.lua UNCOMMITTED; .uci committed f170747 \| ccmk5 80 ok, ccmk6 82 ok, 0 illegal \| ep_p; illegal FENs refused; OPEN ccmk5 only: machine promotion as its 2nd move after FEN (chk_b g2g1q, chk_w g7g8q) -&gt; no bestmove (ccmk6 fine, ccmk5 first-move promotion fine) \| port (program-space RAM, output proxies) + 2 old level bugs fixed (cur_level=nil -&gt; levels never applied; digit string vs number -&gt; levels with 6-9 crashed) \| 8 levels (5-600 s, TOURN 40/90)

**Levels:** 5s move; 10s move; 30s move; 1m move; 3m move; 5m move; 10m move; 40 moves/1.5h

**Commits**

- [e2aa330](https://github.com/RandyR99/mame_for_picochess/commit/e2aa330) 2026-10-20 mame_for_picochess: uci: tournament headings as '40 moves/2h' instead of '40 moves in 2h'
- [0179a1e](https://github.com/RandyR99/chessengine/commit/0179a1e) 2026-10-17 chessengine: ccmk5: port to MAME 0.289 (output proxies, program-space RAM); fix levels never applied after setup and digits 6-9 crash
- [f170747](https://github.com/RandyR99/mame_for_picochess/commit/f170747) 2026-10-16 mame_for_picochess: intchess 9 levels; leonardo family 10 levels, leonardoa/b in retro.ini; ccmk5/ccmk6 8 levels (seconds per move, TOURN 40/90)

</details>

<details><summary><code>compan</code> SciSys Chess Companion</summary>

- MAME set `compan` (Chess Companion), driver `saitek/companion.cpp`
- script runs `mess compan`
- interface `compan.lua`
- retro.ini: elo 1250, levels 5, ponder/brain n

**Levels:** 5s move; 10s move; 30s move; 1m move; 3m move

**Commits**

- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [2281abb](https://github.com/RandyR99/mame_for_picochess/commit/2281abb) 2026-10-17 mame_for_picochess: levels: 5 s minimum per move in all non-Fidelity/H+G .uci files; risc2500 family
- [84f9fe9](https://github.com/RandyR99/mame_for_picochess/commit/84f9fe9) 2026-10-15 mame_for_picochess: compan: 6 levels from measured think times (machine levels are 1-8, the old file sent 0-6)
- [9dc2f03](https://github.com/RandyR99/chessengine/commit/9dc2f03) 2026-10-15 chessengine: compan: port to MAME 0.289, re-enable set_pos (board RAM via program space)
- [98dd217](https://github.com/RandyR99/mame_for_picochess/commit/98dd217) 2026-10-15 mame_for_picochess: compan2, enterp: new engines; compan levels = 6

</details>

<details><summary><code>compan2</code> SciSys Chess Companion II</summary>

**Known limits**

- Promotes only to a queen; a player underpromotion can't be entered.

- MAME set `compan2` (Chess Companion II), driver `saitek/companion2.cpp`
- script runs `mess compan2`
- interface `compan2.lua`
- retro.ini: elo 1265, levels 6, ponder/brain n

**Levels:** 5s move; 15s move; 1m move; 2m move; 3m move; 8m move

**Commits**

- [9f15c7d](https://github.com/RandyR99/chessengine/commit/9f15c7d) 2026-10-29 chessengine: expchess (Explorer Chess): new interface on top of compan2 - 12 buttons with other ports; Set Up = 2nd F + a piece key, New Game clears the board in set up,…
- [6832820](https://github.com/RandyR99/mame_for_picochess/commit/6832820) 2026-10-29 mame_for_picochess: New engines expchess (SciSys Explorer Chess), fex68km4a (Excel 68020 Mach IV set 2), feagpriv (Elite Private Line, EAG 6081 conversion): scripts, _art, .uci…
- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [2281abb](https://github.com/RandyR99/mame_for_picochess/commit/2281abb) 2026-10-17 mame_for_picochess: levels: 5 s minimum per move in all non-Fidelity/H+G .uci files; risc2500 family
- [ba03af4](https://github.com/RandyR99/chessengine/commit/ba03af4) 2026-10-15 chessengine: compan2, enterp: new interfaces from MessChess, ported to MAME 0.289
- [98dd217](https://github.com/RandyR99/mame_for_picochess/commit/98dd217) 2026-10-15 mame_for_picochess: compan2, enterp: new engines; compan levels = 6

</details>

<details><summary><code>expchess</code> SciSys Explorer Chess</summary>

**Known limits**

- Promotes only to a queen; a player underpromotion can't be entered.

- MAME set `expchess` (Explorer Chess), driver `saitek/companion2.cpp`, clone of `compan2`
- script runs `mess expchess`
- interface `expchess.lua` → `compan2.lua`
- retro.ini: elo 1265, levels 6, ponder/brain n

**Test notes**

- expchess: own interface (12-button Explorer keys), = compan2 results. fex68km4a: loads fex68km4. feagpriv: EAG program + A/S keys, 111/113.

**Levels:** 5s move; 15s move; 1m move; 2m move; 3m move; 8m move

**Commits**

- [6832820](https://github.com/RandyR99/mame_for_picochess/commit/6832820) 2026-10-29 mame_for_picochess: New engines expchess (SciSys Explorer Chess), fex68km4a (Excel 68020 Mach IV set 2), feagpriv (Elite Private Line, EAG 6081 conversion): scripts, _art, .uci…
- [9f15c7d](https://github.com/RandyR99/chessengine/commit/9f15c7d) 2026-10-29 chessengine: expchess (Explorer Chess): new interface on top of compan2 - 12 buttons with other ports; Set Up = 2nd F + a piece key, New Game clears the board in set up,…

</details>

<details><summary><code>compan3</code> SciSys Kasparov Companion III</summary>

- MAME set `compan3` (Kasparov Companion III), driver `saitek/turbo16k.cpp`, clone of `turbo16k`
- script runs `mess compan3`
- interface `compan3.lua` → `turbo16k.lua`
- retro.ini: elo 1535, levels 9, ponder/brain n

**Test notes**

- turbo16k, compan3, t1850 (saitek/turbo16k.cpp) \| 4053c46 / 765f1f0 \| 56/58, 0 illegal \| ep_p, ur_b2 \| NEW interfaces from MessChess; Multi Move LED 3.5 check as above; boot wait 8 -&gt; 11 s (board ignored until ~9.5 s); t1850 = SX4A, 16 levels (no level 0; MessChess cycled 17) \| 9 levels (t1850 times assumed from the 17-level manual)

**Levels:** 5s move; 10s move; 15s move; 30s move; 1m move; 2m move; 6m move; 5m game; 40 moves/2h

**Commits**

- [e2aa330](https://github.com/RandyR99/mame_for_picochess/commit/e2aa330) 2026-10-20 mame_for_picochess: uci: tournament headings as '40 moves/2h' instead of '40 moves in 2h'
- [4053c46](https://github.com/RandyR99/chessengine/commit/4053c46) 2026-10-19 chessengine: turbo16k family: port conquist to MAME 0.289; new turbo16k, compan3, t1850 (from MessChess); verify Multi Move LED in edit_game; boot wait 11 s; t1850 has 16…
- [765f1f0](https://github.com/RandyR99/mame_for_picochess/commit/765f1f0) 2026-10-19 mame_for_picochess: turbo16k family: conquist/tmate 8 levels; new turbo16k, compan3, t1850

</details>

<details><summary><code>exechess</code> SciSys Executive Chess</summary>

**Known limits**

- Castling and en passant as the first move after a position setup aren't possible.

- MAME set `exechess` (Executive Chess), driver `saitek/exechess.cpp`
- script runs `mess exechess`
- interface `exechess.lua`
- retro.ini: elo 1185, levels 7, ponder/brain n

**Test notes**

- exechess (saitek/exechess.cpp) \| 635882d / 1be06ee \| 79 ok, 0 illegal \| castling/e.p. first after FEN, player underpromotion, illegal FENs refused \| get_module was "Senator Chess" (German name) -&gt; "Executive Chess"; set_pos via keypad CS mode works \| 7 levels from NL manual (same table as cp2000)

**Levels:** 5s move; 10s move; 30s move; 2m move; 5m move; 20m move; 40m move

**Commits**

- [e98fc39](https://github.com/RandyR99/mame_for_picochess/commit/e98fc39) 2026-10-29 mame_for_picochess: retro.ini: ponder/brain = y for 32 sets measured to think on the player's time (Phase 3 ponder check, RAM activity during the player's turn from a non-book p…
- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [635882d](https://github.com/RandyR99/chessengine/commit/635882d) 2026-10-16 chessengine: exechess: port to MAME 0.289 (output proxies), module name Executive Chess
- [1be06ee](https://github.com/RandyR99/mame_for_picochess/commit/1be06ee) 2026-10-16 mame_for_picochess: exechess 7 levels; gk2000 family 11 levels, new gk2000a, gk2000 is the 1997 version; kblitz needs MAME 0.290

</details>

<details><summary><code>intchess</code> SciSys / Intelligent Games Intelligent Chess</summary>

**Known limits**

- Castling can't be the first move after a position setup (Brett Frei clears the castling rights).

- MAME set `intchess` (Intelligent Chess), driver `saitek/intchess.cpp`
- script runs `mess intchess`
- interface `intchess.lua`
- retro.ini: elo 1180, levels 9, ponder/brain n

**Test notes**

- intchess (saitek/intchess.cpp) \| 3318a19 / f170747 \| 89 ok, 0 illegal \| castling first after FEN (manual: Brett Frei clears castling rights permanently), ep_p, player underpromotion \| output port; 6522 VIA reset workaround (IER 0x280e = 0x7f before RESET) \| 9 levels (10s-30m per move, DE manual = Levels.txt)

**Levels:** 10s move; 20s move; 40s move; 1m move; 2m move; 3m move; 5m move; 10m move; 30m move

**Commits**

- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [f170747](https://github.com/RandyR99/mame_for_picochess/commit/f170747) 2026-10-16 mame_for_picochess: intchess 9 levels; leonardo family 10 levels, leonardoa/b in retro.ini; ccmk5/ccmk6 8 levels (seconds per move, TOURN 40/90)
- [3318a19](https://github.com/RandyR99/chessengine/commit/3318a19) 2026-10-16 chessengine: intchess: port to MAME 0.289 (output proxies), 6522 VIA reset workaround

</details>

<details><summary><code>chesstrvi</code> SciSys Intercontinental Traveler</summary>

**Known limits**

- Player castling as the first move after a position setup is rejected (no castling rights after setup).
- Promotes only to a queen; a player underpromotion can't be entered.

- MAME set `chesstrvi` (Chess Intercontinental Traveler), driver `saitek/chesstrv.cpp`
- script runs `mess chesstrvi`
- interface `chesstrvi.lua` → `chesstrv.lua`
- retro.ini: elo 1010, levels 5, ponder/brain n

**Levels:** 5s move; 15s move; 1m move; 3m move; 10m move

**Commits**

- [8b0248b](https://github.com/RandyR99/mame_for_picochess/commit/8b0248b) 2026-10-26 mame_for_picochess: modular_tm.cpp (TM / 68030 modules): port32t .uci = Portorose 10 levels (TURN 08 = 40 moves/2h, verified), other 7 = Berlin Pro 11 levels; retro: new lyon32t…
- [2281abb](https://github.com/RandyR99/mame_for_picochess/commit/2281abb) 2026-10-17 mame_for_picochess: levels: 5 s minimum per move in all non-Fidelity/H+G .uci files; risc2500 family
- [bcd2acc](https://github.com/RandyR99/mame_for_picochess/commit/bcd2acc) 2026-10-15 mame_for_picochess: chessac/schachak 10 levels, chesstrv/chesstrvi 6 levels; chesstrvi added to retro.ini

</details>

<details><summary><code>smchess</code> SciSys Mini Chess</summary>

**Known limits**

- Promotes only to a queen; a player underpromotion can't be entered.

- MAME set `smchess` (Mini Chess), driver `saitek/minichess.cpp`
- script runs `mess smchess`
- interface `smchess.lua`
- retro.ini: elo 730, levels 2, ponder/brain n

**Test notes**

- smchess: castling rights nibble 0x8b (1 WK, 2 WQ, 4 BK, 8 BQ), trusted without rook check; queen-only promotion.

**Levels:** 5s move; 10s move

**Commits**

- [e98fc39](https://github.com/RandyR99/mame_for_picochess/commit/e98fc39) 2026-10-29 mame_for_picochess: retro.ini: ponder/brain = y for 32 sets measured to think on the player's time (Phase 3 ponder check, RAM activity during the player's turn from a non-book p…
- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [c189a33](https://github.com/RandyR99/mame_for_picochess/commit/c189a33) 2026-10-27 mame_for_picochess: Revisit phase 2 step 1: 35 .uci files to conventions (Level n headings from PicoTimeControl, easiest to hardest within per-move/game/tournament groups, tourn…
- [9e8f6af](https://github.com/RandyR99/chessengine/commit/9e8f6af) 2026-10-17 chessengine: smchess: port to MAME 0.289 (output proxies, MCU data-space RAM); re-enable set_pos with castling rights
- [4776c08](https://github.com/RandyR99/mame_for_picochess/commit/4776c08) 2026-10-17 mame_for_picochess: smchess: levels = 2

</details>

<details><summary><code>schess</code> SciSys Sensor Chess</summary>

**Known limits**

- Promotes only to a queen; a player underpromotion can't be entered.
- Classic, Strong and Hyper modules: after a position setup with the machine in check they start searching and then go idle.

- MAME set `schess` (Sensor Chess), driver `saitek/schess.cpp`
- script runs `mess schess -cart classic`
- interface `schess.lua`
- retro.ini: elo 1325, levels 7, ponder/brain n

**Levels:** 5s move; 15s move; 30s move; 1m move; 150s move; 6m move; Analysis

**Commits**

- [e98fc39](https://github.com/RandyR99/mame_for_picochess/commit/e98fc39) 2026-10-29 mame_for_picochess: retro.ini: ponder/brain = y for 32 sets measured to think on the player's time (Phase 3 ponder check, RAM activity during the player's turn from a non-book p…
- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [cd4344b](https://github.com/RandyR99/mame_for_picochess/commit/cd4344b) 2026-10-18 mame_for_picochess: schess: fix module loading for MAME 0.289; add Strong Play and Hyper Modern engines
- [6617fe0](https://github.com/RandyR99/chessengine/commit/6617fe0) 2026-10-18 chessengine: schess: port to MAME 0.289 (output proxies); slow board input, wait out check display
- [2281abb](https://github.com/RandyR99/mame_for_picochess/commit/2281abb) 2026-10-17 mame_for_picochess: levels: 5 s minimum per move in all non-Fidelity/H+G .uci files; risc2500 family
- [625d02a](https://github.com/RandyR99/chessengine/commit/625d02a) 2026-10-13 chessengine: Convert CRLF line endings to LF

</details>

<details><summary><code>schessa</code> SciSys Sensor Chess Strong</summary>

**Known limits**

- Promotes only to a queen; a player underpromotion can't be entered.
- Classic, Strong and Hyper modules: after a position setup with the machine in check they start searching and then go idle.

- MAME set `schess` (Sensor Chess), driver `saitek/schess.cpp`
- script runs `mess schess -cart strong`
- interface `schess.lua`
- retro.ini: elo 1310, levels 7, ponder/brain n

**Levels:** 5s move; 15s move; 30s move; 1m move; 150s move; 6m move; Analysis

**Commits**

- [e98fc39](https://github.com/RandyR99/mame_for_picochess/commit/e98fc39) 2026-10-29 mame_for_picochess: retro.ini: ponder/brain = y for 32 sets measured to think on the player's time (Phase 3 ponder check, RAM activity during the player's turn from a non-book p…
- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [cd4344b](https://github.com/RandyR99/mame_for_picochess/commit/cd4344b) 2026-10-18 mame_for_picochess: schess: fix module loading for MAME 0.289; add Strong Play and Hyper Modern engines
- [6617fe0](https://github.com/RandyR99/chessengine/commit/6617fe0) 2026-10-18 chessengine: schess: port to MAME 0.289 (output proxies); slow board input, wait out check display
- [2281abb](https://github.com/RandyR99/mame_for_picochess/commit/2281abb) 2026-10-17 mame_for_picochess: levels: 5 s minimum per move in all non-Fidelity/H+G .uci files; risc2500 family
- [625d02a](https://github.com/RandyR99/chessengine/commit/625d02a) 2026-10-13 chessengine: Convert CRLF line endings to LF

</details>

<details><summary><code>schessc</code> SciSys Sensor Chess HMSS</summary>

**Known limits**

- Promotes only to a queen; a player underpromotion can't be entered.
- Classic, Strong and Hyper modules: after a position setup with the machine in check they start searching and then go idle.

- MAME set `schess` (Sensor Chess), driver `saitek/schess.cpp`
- script runs `mess schess -cart hyper`
- interface `schess.lua`
- retro.ini: elo 1335, levels 7, ponder/brain n

**Levels:** 5s move; 15s move; 30s move; 1m move; 150s move; 6m move; Analysis

**Commits**

- [e98fc39](https://github.com/RandyR99/mame_for_picochess/commit/e98fc39) 2026-10-29 mame_for_picochess: retro.ini: ponder/brain = y for 32 sets measured to think on the player's time (Phase 3 ponder check, RAM activity during the player's turn from a non-book p…
- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [cd4344b](https://github.com/RandyR99/mame_for_picochess/commit/cd4344b) 2026-10-18 mame_for_picochess: schess: fix module loading for MAME 0.289; add Strong Play and Hyper Modern engines
- [6617fe0](https://github.com/RandyR99/chessengine/commit/6617fe0) 2026-10-18 chessengine: schess: port to MAME 0.289 (output proxies); slow board input, wait out check display
- [2281abb](https://github.com/RandyR99/mame_for_picochess/commit/2281abb) 2026-10-17 mame_for_picochess: levels: 5 s minimum per move in all non-Fidelity/H+G .uci files; risc2500 family
- [625d02a](https://github.com/RandyR99/chessengine/commit/625d02a) 2026-10-13 chessengine: Convert CRLF line endings to LF

</details>

<details><summary><code>sstar28k</code> SciSys Superstar 28K</summary>

- MAME set `sstar28k` (Superstar 28K), driver `saitek/superstar.cpp`
- script runs `mess sstar28k`
- interface `sstar28k.lua`
- retro.ini: elo 1570, levels 9, ponder/brain n

**Test notes**

- sstar28k, tstar432, tstar432a, tstar432b (saitek/superstar.cpp) \| 0a9d108 / e4ba17f \| 55/58 each (all non-illegal tests), 0 illegal \| ep_p, ur_b2 \| output proxies; set-up start position taken as new game -&gt; New Game + rotate on Move (simultano-style); tstar432/a launched with -rom kso; tstar432a = Superstar 36K ROM at 4 MHz (new retro entry); tstar432b has no entry (1-byte book diff) \| tstar432/a 10 levels (old tstar432.uci was off by two), sstar28k 9; b7 = exactly 10 s

**Levels:** 5s move; 10s move; 20s move; 1m move; 6m move; 10m move; 5m game; 60m game; 40 moves/2h

**Commits**

- [e98fc39](https://github.com/RandyR99/mame_for_picochess/commit/e98fc39) 2026-10-29 mame_for_picochess: retro.ini: ponder/brain = y for 32 sets measured to think on the player's time (Phase 3 ponder check, RAM activity during the player's turn from a non-book p…
- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [e2aa330](https://github.com/RandyR99/mame_for_picochess/commit/e2aa330) 2026-10-20 mame_for_picochess: uci: tournament headings as '40 moves/2h' instead of '40 moves in 2h'
- [e4ba17f](https://github.com/RandyR99/mame_for_picochess/commit/e4ba17f) 2026-10-19 mame_for_picochess: superstar: fix tstar432 levels (were off by two), new 10-level sets for tstar432/tstar432a, sstar28k 9 levels; add tstar432a to retro.ini
- [0a9d108](https://github.com/RandyR99/chessengine/commit/0a9d108) 2026-10-19 chessengine: sstar28k, tstar432: port to MAME 0.289 (output proxies); New Game for a start-position FEN

</details>

<details><summary><code>ssystem4</code> SciSys Chess Champion Super System IV</summary>

**Known limits**

- Promotions inside a replayed history become queens (game edit takes no piece).

- MAME set `ssystem4` (Chess Champion: Super System IV), driver `saitek/ssystem3.cpp`
- script runs `mess ssystem4`
- interface `ssystem4.lua` → `ssystem3.lua`
- retro.ini: elo 1300, levels 7, ponder/brain n

**Levels:** 5s move; 10s move; 30s move; 1m move; 3m move; 5m move; 10m move

**Commits**

- [46765bb](https://github.com/RandyR99/chessengine/commit/46765bb) 2026-10-18 chessengine: ssystem3, ssystem4: port to MAME 0.289 (output proxies); fix promotions in game edit
- [2281abb](https://github.com/RandyR99/mame_for_picochess/commit/2281abb) 2026-10-17 mame_for_picochess: levels: 5 s minimum per move in all non-Fidelity/H+G .uci files; risc2500 family

</details>

<details><summary><code>t1850</code> Tandy 1850 Deluxe Table Chess</summary>

- MAME set `t1850` (1850 Deluxe Table Chess (model 60-2199)), driver `saitek/turbo16k.cpp`
- script runs `mess t1850`
- interface `t1850.lua`
- retro.ini: elo 1535, levels 9, ponder/brain n

**retro.ini comment:** SX4A program (Radio Shack 60-2199): 16 levels, no level 0; level times taken from the 17-level 1850 manual (60-2201A)

**Test notes**

- turbo16k, compan3, t1850 (saitek/turbo16k.cpp) \| 4053c46 / 765f1f0 \| 56/58, 0 illegal \| ep_p, ur_b2 \| NEW interfaces from MessChess; Multi Move LED 3.5 check as above; boot wait 8 -&gt; 11 s (board ignored until ~9.5 s); t1850 = SX4A, 16 levels (no level 0; MessChess cycled 17) \| 9 levels (t1850 times assumed from the 17-level manual)

**Levels:** 5s move; 10s move; 15s move; 30s move; 1m move; 2m move; 6m move; 5m game; 40 moves/2h

**Commits**

- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [e2aa330](https://github.com/RandyR99/mame_for_picochess/commit/e2aa330) 2026-10-20 mame_for_picochess: uci: tournament headings as '40 moves/2h' instead of '40 moves in 2h'
- [4053c46](https://github.com/RandyR99/chessengine/commit/4053c46) 2026-10-19 chessengine: turbo16k family: port conquist to MAME 0.289; new turbo16k, compan3, t1850 (from MessChess); verify Multi Move LED in edit_game; boot wait 11 s; t1850 has 16…
- [765f1f0](https://github.com/RandyR99/mame_for_picochess/commit/765f1f0) 2026-10-19 mame_for_picochess: turbo16k family: conquist/tmate 8 levels; new turbo16k, compan3, t1850

</details>

<details><summary><code>tschess</code> SciSys Travel Sensor Chess</summary>

**Known limits**

- No castling-rights tracking in the ROM: it castles whenever its king is home, even without the rook.
- Promotes only to a queen; a player underpromotion can't be entered.

- MAME set `tschess` (Travel Sensor Chess), driver `saitek/tschess.cpp`
- script runs `mess tschess`
- interface `tschess.lua`
- retro.ini: elo 845, levels 4, ponder/brain n

**Test notes**

- tschess (saitek/tschess.cpp) \| (pending) \| 59/65, 3 illegal = ROM phantom castling \| ep_p; no castling-rights tracking (castles e8g8 with no rook, same engine as scpchess); queen-only promotion \| NEW interface (ported from MessChess); setlevel reads the level LED while LEVEL is held (MessChess RAM 0xc9 was a scratch byte); 1 s wait after each board event (400 kHz MCU missed fast replays) \| 4 levels (10/15/20/30 s, estimated: L1/2 ~13 s, L3/4 ~20 s measured)

**Levels:** 10s move; 15s move; 20s move; 30s move

**Commits**

- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [b187063](https://github.com/RandyR99/chessengine/commit/b187063) 2026-10-19 chessengine: tschess: new interface (from MessChess, ported to MAME 0.289); level via LED, slow-board waits
- [b62aa45](https://github.com/RandyR99/mame_for_picochess/commit/b62aa45) 2026-10-19 mame_for_picochess: tschess: new engine (SciSys Travel Sensor Chess), 4 levels

</details>

<details><summary><code>turbo16k</code> SciSys Kasparov Turbo 16K</summary>

- MAME set `turbo16k` (Kasparov Turbo 16K), driver `saitek/turbo16k.cpp`
- script runs `mess turbo16k`
- interface `turbo16k.lua`
- retro.ini: elo 1615, levels 9, ponder/brain n

**Test notes**

- turbo16k, compan3, t1850 (saitek/turbo16k.cpp) \| 4053c46 / 765f1f0 \| 56/58, 0 illegal \| ep_p, ur_b2 \| NEW interfaces from MessChess; Multi Move LED 3.5 check as above; boot wait 8 -&gt; 11 s (board ignored until ~9.5 s); t1850 = SX4A, 16 levels (no level 0; MessChess cycled 17) \| 9 levels (t1850 times assumed from the 17-level manual)

**Levels:** 5s move; 10s move; 15s move; 30s move; 1m move; 2m move; 6m move; 5m game; 40 moves/2h

**Commits**

- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [e2aa330](https://github.com/RandyR99/mame_for_picochess/commit/e2aa330) 2026-10-20 mame_for_picochess: uci: tournament headings as '40 moves/2h' instead of '40 moves in 2h'
- [4053c46](https://github.com/RandyR99/chessengine/commit/4053c46) 2026-10-19 chessengine: turbo16k family: port conquist to MAME 0.289; new turbo16k, compan3, t1850 (from MessChess); verify Multi Move LED in edit_game; boot wait 11 s; t1850 has 16…
- [765f1f0](https://github.com/RandyR99/mame_for_picochess/commit/765f1f0) 2026-10-19 mame_for_picochess: turbo16k family: conquist/tmate 8 levels; new turbo16k, compan3, t1850

</details>

<details><summary><code>turbos24k</code> SciSys Turbo S-24K</summary>

- MAME set `turbos24k` (Kasparov Turbo S-24K), driver `saitek/turbos24k.cpp`
- script runs `mess turbos24k`
- interface `turbos24k.lua`
- retro.ini: elo 1600, levels 10, ponder/brain y

**Test notes**

- turbos24k (saitek/turbos24k.cpp) \| committed 2026-10-19 \| 56/58, 0 illegal \| ep_p, ur_b2 \| output proxies only; no nvram file written (cold boot); ponders on the player's time (manual 2.7) -&gt; ponder/brain y \| 10 levels (leonardo set; old .uci had 40/2h before game levels, no 10s)

**Levels:** 5s move; 10s move; 30s move; 1m move; 3m move; 5m game; 10m game; 15m game; 30m game; 40 moves/2h

**Commits**

- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [e2aa330](https://github.com/RandyR99/mame_for_picochess/commit/e2aa330) 2026-10-20 mame_for_picochess: uci: tournament headings as '40 moves/2h' instead of '40 moves in 2h'
- [048b693](https://github.com/RandyR99/chessengine/commit/048b693) 2026-10-19 chessengine: turbos24k: port to MAME 0.289 (output proxies)
- [467c230](https://github.com/RandyR99/mame_for_picochess/commit/467c230) 2026-10-19 mame_for_picochess: turbos24k: 10 levels (leonardo set), ponder/brain = y

</details>

# Tasc

MAME chess machines in picochess, part of the [machine overview](../MACHINES.md) (columns and general limits explained there).

| System | Name | Year | Elo | Levels | FEN | History | Info | Ponder | Limits |
|---|---|---:|---:|---:|:-:|:-:|:-:|:-:|---:|
| `tascr30g` | Tasc R30 with Gideon | 1993 | 2320 | 9 | ✓ | ✓ | ✓ | – |  |
| `tascr30b` | Tasc R30 with King 2.23 TM | 1993 | 2380 | 9 | ✓ | ✓ | ✓ | – |  |
| `tascr30` | Tasc R30 with King 2.5 | 1995 | 2370 | 9 | ✓ | ✓ | ✓ | – |  |
| `tascr30a` | Tasc R30 with King 2.20 | 1993 | 2365 | 9 | ✓ | ✓ | ✓ | – |  |

<details><summary><code>tascr30g</code> Tasc R30 with Gideon</summary>

- MAME set `tascr30g` (ChessSystem R30 (Gideon 3.1, prototype)), driver `chess/tasc.cpp`, clone of `tascr30`
- script runs `mess tascr30g`
- interface `tascr30g.lua` → `tascr30.lua`
- retro.ini: elo 2320, levels 9, ponder/brain n

**Levels:** 5s move; 10s move; 30s move; 5m game; 10m game; 15m game; 30m game; 60m game; 40 moves/2h

**Commits**

- [c189a33](https://github.com/RandyR99/mame_for_picochess/commit/c189a33) 2026-10-27 mame_for_picochess: Revisit phase 2 step 1: 35 .uci files to conventions (Level n headings from PicoTimeControl, easiest to hardest within per-move/game/tournament groups, tourn…
- [d4eed72](https://github.com/RandyR99/mame_for_picochess/commit/d4eed72) 2026-10-20 mame_for_picochess: uci: short tournament headings ('40/2h', '60/5m') as '40 moves/2h', units h/m
- [2281abb](https://github.com/RandyR99/mame_for_picochess/commit/2281abb) 2026-10-17 mame_for_picochess: levels: 5 s minimum per move in all non-Fidelity/H+G .uci files; risc2500 family

</details>

<details><summary><code>tascr30b</code> Tasc R30 with King 2.23 TM</summary>

- MAME set `tascr30b` (ChessSystem R30 (The King 2.23, TM version)), driver `chess/tasc.cpp`, clone of `tascr30`
- script runs `mess tascr30b`
- interface `tascr30.lua`
- retro.ini: elo 2380, levels 9, ponder/brain n

**Levels:** 5s move; 10s move; 30s move; 5m game; 10m game; 15m game; 30m game; 60m game; 40 moves/2h

**Commits**

- [44e89ec](https://github.com/RandyR99/chessengine/commit/44e89ec) 2026-10-30 chessengine: show_info: tascr30, mephisto. tascr30 (TASC R30): the old code read fixed LCD positions that are empty on this display and sent only empty fields. The LCD sh…
- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [c189a33](https://github.com/RandyR99/mame_for_picochess/commit/c189a33) 2026-10-27 mame_for_picochess: Revisit phase 2 step 1: 35 .uci files to conventions (Level n headings from PicoTimeControl, easiest to hardest within per-move/game/tournament groups, tourn…
- [d4eed72](https://github.com/RandyR99/mame_for_picochess/commit/d4eed72) 2026-10-20 mame_for_picochess: uci: short tournament headings ('40/2h', '60/5m') as '40 moves/2h', units h/m
- [2281abb](https://github.com/RandyR99/mame_for_picochess/commit/2281abb) 2026-10-17 mame_for_picochess: levels: 5 s minimum per move in all non-Fidelity/H+G .uci files; risc2500 family
- [f321da6](https://github.com/RandyR99/chessengine/commit/f321da6) 2026-10-14 chessengine: nmicro2: port to MAME 0.289, re-enable set_pos; drop references to removed sets
- [32f72d8](https://github.com/RandyR99/chessengine/commit/32f72d8) 2026-10-11 chessengine: tascr30: port to MAME 0.289, fix Level option never being applied

</details>

<details><summary><code>tascr30</code> Tasc R30 with King 2.5</summary>

- MAME set `tascr30` (ChessSystem R30 (The King 2.50)), driver `chess/tasc.cpp`
- script runs `mess tascr30`
- interface `tascr30.lua`
- retro.ini: elo 2370, levels 9, ponder/brain n

**Levels:** 5s move; 10s move; 30s move; 5m game; 10m game; 15m game; 30m game; 60m game; 40 moves/2h

**Commits**

- [44e89ec](https://github.com/RandyR99/chessengine/commit/44e89ec) 2026-10-30 chessengine: show_info: tascr30, mephisto. tascr30 (TASC R30): the old code read fixed LCD positions that are empty on this display and sent only empty fields. The LCD sh…
- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [c189a33](https://github.com/RandyR99/mame_for_picochess/commit/c189a33) 2026-10-27 mame_for_picochess: Revisit phase 2 step 1: 35 .uci files to conventions (Level n headings from PicoTimeControl, easiest to hardest within per-move/game/tournament groups, tourn…
- [71b0188](https://github.com/RandyR99/mame_for_picochess/commit/71b0188) 2026-10-27 mame_for_picochess: retro.ini: years matched to MAME 0.289 (arbv2 2012, feagv11 2001, fscc9 1982, sforteb 1988, tascr30 1995)
- [d4eed72](https://github.com/RandyR99/mame_for_picochess/commit/d4eed72) 2026-10-20 mame_for_picochess: uci: short tournament headings ('40/2h', '60/5m') as '40 moves/2h', units h/m
- [2281abb](https://github.com/RandyR99/mame_for_picochess/commit/2281abb) 2026-10-17 mame_for_picochess: levels: 5 s minimum per move in all non-Fidelity/H+G .uci files; risc2500 family
- [07601a1](https://github.com/RandyR99/mame_for_picochess/commit/07601a1) 2026-10-16 mame_for_picochess: retro.ini: unique small/medium names (arb, feas, tascr30, cmpchess), fill cp2000 and tkinga names
- [f321da6](https://github.com/RandyR99/chessengine/commit/f321da6) 2026-10-14 chessengine: nmicro2: port to MAME 0.289, re-enable set_pos; drop references to removed sets
- [32f72d8](https://github.com/RandyR99/chessengine/commit/32f72d8) 2026-10-11 chessengine: tascr30: port to MAME 0.289, fix Level option never being applied

</details>

<details><summary><code>tascr30a</code> Tasc R30 with King 2.20</summary>

- MAME set `tascr30a` (ChessSystem R30 (The King 2.20)), driver `chess/tasc.cpp`, clone of `tascr30`
- script runs `mess tascr30a`
- interface `tascr30.lua`
- retro.ini: elo 2365, levels 9, ponder/brain n

**Levels:** 5s move; 10s move; 30s move; 5m game; 10m game; 15m game; 30m game; 60m game; 40 moves/2h

**Commits**

- [44e89ec](https://github.com/RandyR99/chessengine/commit/44e89ec) 2026-10-30 chessengine: show_info: tascr30, mephisto. tascr30 (TASC R30): the old code read fixed LCD positions that are empty on this display and sent only empty fields. The LCD sh…
- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [c189a33](https://github.com/RandyR99/mame_for_picochess/commit/c189a33) 2026-10-27 mame_for_picochess: Revisit phase 2 step 1: 35 .uci files to conventions (Level n headings from PicoTimeControl, easiest to hardest within per-move/game/tournament groups, tourn…
- [d4eed72](https://github.com/RandyR99/mame_for_picochess/commit/d4eed72) 2026-10-20 mame_for_picochess: uci: short tournament headings ('40/2h', '60/5m') as '40 moves/2h', units h/m
- [2281abb](https://github.com/RandyR99/mame_for_picochess/commit/2281abb) 2026-10-17 mame_for_picochess: levels: 5 s minimum per move in all non-Fidelity/H+G .uci files; risc2500 family
- [f321da6](https://github.com/RandyR99/chessengine/commit/f321da6) 2026-10-14 chessengine: nmicro2: port to MAME 0.289, re-enable set_pos; drop references to removed sets
- [32f72d8](https://github.com/RandyR99/chessengine/commit/32f72d8) 2026-10-11 chessengine: tascr30: port to MAME 0.289, fix Level option never being applied
- [4d4a2eb](https://github.com/RandyR99/mame_for_picochess/commit/4d4a2eb) 2026-10-11 mame_for_picochess: retro_additions: add tascr30a (Tasc R30, The King 2.20)
- [fcfdd95](https://github.com/RandyR99/mame_for_picochess/commit/fcfdd95) 2026-10-11 mame_for_picochess: Add Chess King Master, move vetted tascr30a and master into retro.ini

</details>

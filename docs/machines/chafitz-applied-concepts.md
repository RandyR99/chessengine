# Chafitz/Applied Concepts

MAME chess machines in picochess, part of the [machine overview](../MACHINES.md) (columns and general limits explained there).

| System | Name | Year | Elo | Levels | FEN | History | Info | Ponder | Limits |
|---|---|---:|---:|---:|:-:|:-:|:-:|:-:|---:|
| `boris` | Chafitz/Applied Concepts Boris (rev. 01) | 1978 | 985 | 8 | ✓ | – | ✓ | – | 1 |
| `borisa` | Chafitz/Applied Concepts Boris (rev. 00) | 1978 | 985 | 9 | ✓ | – | ✓ | – | 1 |
| `borisdpl` | Chafitz/Applied Concepts Boris Diplomat | 1979 | 985 | 8 | ✓ | – | – | – | 1 |
| `ggm_boris25` | Chafitz/Applied Concepts GGM Boris 2.5 | 1980 | 1370 | 5 | ✓ | – | – | – | 1 |
| `ggm_morphy` | Chafitz/Applied Concepts GGM Morphy Edition | 1981 | 1450 | 8 | ✓ | – | – | ✓ | 1 |
| `ggm_sandy` | Chafitz/Applied Concepts GGM Sandy | 1981 | 1450 | 7 | ✓ | – | – | – | 1 |
| `ggm_steinitz` | Chafitz/Applied Concepts GGM Steinitz | 1982 | 1575 | 8 | ✓ | ✓ | ✓ | – |  |
| `arb_gms3` | ARB Sargon 3.0 Grand Master Series | 1981 | 1500 | 7 | ✓ | ✓ | – | – |  |
| `arb_gms4` | ARB Sargon 4.0 Grand Master Series | 1984 | 1705 | 9 | ✓ | ✓ | – | – |  |
| `prodigy` | Chafitz/Applied Concepts Destiny/Prodigy | 1982 | 1465 | 7 | ✓ | – | – | – | 1 |
| `arb_sargon25` | Chafitz/Applied Concepts Sargon 2.5 | 1980 | 1370 | 7 | ✓ | ✓ | – | – |  |
| `arb_sargon35` | Chafitz/Applied Concepts Sargon 3.5 | 1983 | 1500 | 7 | ✓ | ✓ | – | – |  |
| `arbv2` | Chafitz/Applied Concepts Sargon 4.0 | 2012 | 1940 | 8 | ✓ | ✓ | – | – |  |

<details><summary><code>boris</code> Chafitz/Applied Concepts Boris (rev. 01)</summary>

**Known limits**

- No history replay: a takeback or a resumed game can't be passed to the machine.

- MAME set `boris` (Boris (rev. 01)), driver `appliedconcepts/boris.cpp`
- script runs `mess boris`
- interface `boris.lua`
- retro.ini: elo 985, levels 8, ponder/brain n

**Levels:** 5s move; 10s move; 15s move; 30s move; 1m move; 3m move; 5m move; 10m move

**Commits**

- [ab1d2a1](https://github.com/RandyR99/chessengine/commit/ab1d2a1) 2026-11-04 chessengine: boris: live info, the best move so far from the display
- [26c26de](https://github.com/RandyR99/chessengine/commit/26c26de) 2026-11-04 chessengine: interfaces: player's underpromotion through the position setup on 45 more machines
- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [d6815c6](https://github.com/RandyR99/mame_for_picochess/commit/d6815c6) 2026-10-27 mame_for_picochess: Revisit phase 2 step 2: 50 missing working sets added (scripts, _art, .uci from the parent, retro entries; all smoke-tested): borisa, conca, concglapa, sdtor…
- [2281abb](https://github.com/RandyR99/mame_for_picochess/commit/2281abb) 2026-10-17 mame_for_picochess: levels: 5 s minimum per move in all non-Fidelity/H+G .uci files; risc2500 family
- [ff1c836](https://github.com/RandyR99/chessengine/commit/ff1c836) 2026-10-09 chessengine: boris: fix side to move after position setup, properly this time
- [207d158](https://github.com/RandyR99/chessengine/commit/207d158) 2026-10-09 chessengine: boris: port to MAME 0.289, fix side to move after position setup

</details>

<details><summary><code>borisa</code> Chafitz/Applied Concepts Boris (rev. 00)</summary>

**Known limits**

- No history replay: a takeback or a resumed game can't be passed to the machine.

- MAME set `borisa` (Boris (rev. 00)), driver `appliedconcepts/boris.cpp`, clone of `boris`
- script runs `mess borisa`
- interface `boris.lua`
- retro.ini: elo 985, levels 9, ponder/brain n

**Levels:** 5s move; 15s move; 30s move; 1m move; 2m move; 3m move; 5m move; 10m move; Analysis

**Commits**

- [ab1d2a1](https://github.com/RandyR99/chessengine/commit/ab1d2a1) 2026-11-04 chessengine: boris: live info, the best move so far from the display
- [26c26de](https://github.com/RandyR99/chessengine/commit/26c26de) 2026-11-04 chessengine: interfaces: player's underpromotion through the position setup on 45 more machines
- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [d6815c6](https://github.com/RandyR99/mame_for_picochess/commit/d6815c6) 2026-10-27 mame_for_picochess: Revisit phase 2 step 2: 50 missing working sets added (scripts, _art, .uci from the parent, retro entries; all smoke-tested): borisa, conca, concglapa, sdtor…
- [c189a33](https://github.com/RandyR99/mame_for_picochess/commit/c189a33) 2026-10-27 mame_for_picochess: Revisit phase 2 step 1: 35 .uci files to conventions (Level n headings from PicoTimeControl, easiest to hardest within per-move/game/tournament groups, tourn…
- [ff1c836](https://github.com/RandyR99/chessengine/commit/ff1c836) 2026-10-09 chessengine: boris: fix side to move after position setup, properly this time
- [207d158](https://github.com/RandyR99/chessengine/commit/207d158) 2026-10-09 chessengine: boris: port to MAME 0.289, fix side to move after position setup

</details>

<details><summary><code>borisdpl</code> Chafitz/Applied Concepts Boris Diplomat</summary>

**Known limits**

- No history replay: a takeback or a resumed game can't be passed to the machine.

- MAME set `borisdpl` (Boris Diplomat), driver `appliedconcepts/borisdpl.cpp`
- script runs `mess borisdpl`
- interface `borisdpl.lua`
- retro.ini: elo 985, levels 8, ponder/brain n

**Levels:** 5s move; 10s move; 15s move; 30s move; 1m move; 3m move; 5m move; 10m move

**Commits**

- [26c26de](https://github.com/RandyR99/chessengine/commit/26c26de) 2026-11-04 chessengine: interfaces: player's underpromotion through the position setup on 45 more machines
- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [2281abb](https://github.com/RandyR99/mame_for_picochess/commit/2281abb) 2026-10-17 mame_for_picochess: levels: 5 s minimum per move in all non-Fidelity/H+G .uci files; risc2500 family
- [4304712](https://github.com/RandyR99/chessengine/commit/4304712) 2026-10-09 chessengine: borisdpl: port to MAME 0.289, fix side to move after position setup

</details>

<details><summary><code>ggm_boris25</code> Chafitz/Applied Concepts GGM Boris 2.5</summary>

**Known limits**

- No history replay: a takeback or a resumed game can't be passed to the machine.

- MAME set `ggm` (Great Game Machine), driver `appliedconcepts/ggm.cpp`
- script runs `mess ggm boris25`
- interface `ggm_boris25.lua`
- retro.ini: elo 1370, levels 5, ponder/brain n

**Levels:** 5s move; 15s move; 40s move; 90s move; 40 moves/2h

**Commits**

- [26c26de](https://github.com/RandyR99/chessengine/commit/26c26de) 2026-11-04 chessengine: interfaces: player's underpromotion through the position setup on 45 more machines
- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [c189a33](https://github.com/RandyR99/mame_for_picochess/commit/c189a33) 2026-10-27 mame_for_picochess: Revisit phase 2 step 1: 35 .uci files to conventions (Level n headings from PicoTimeControl, easiest to hardest within per-move/game/tournament groups, tourn…
- [d4eed72](https://github.com/RandyR99/mame_for_picochess/commit/d4eed72) 2026-10-20 mame_for_picochess: uci: short tournament headings ('40/2h', '60/5m') as '40 moves/2h', units h/m
- [2281abb](https://github.com/RandyR99/mame_for_picochess/commit/2281abb) 2026-10-17 mame_for_picochess: levels: 5 s minimum per move in all non-Fidelity/H+G .uci files; risc2500 family
- [b480ed4](https://github.com/RandyR99/chessengine/commit/b480ed4) 2026-10-09 chessengine: ggm_steinitz: replace deprecated output:get_value, fix throttle restores
- [323dfbe](https://github.com/RandyR99/chessengine/commit/323dfbe) 2026-10-09 chessengine: ggm: drop the Gruenfeld opening cartridges
- [03888dd](https://github.com/RandyR99/chessengine/commit/03888dd) 2026-10-09 chessengine: ggm: drop Capablanca and unknown Steinitz cartridge entries
- [2a0eac1](https://github.com/RandyR99/chessengine/commit/2a0eac1) 2026-10-09 chessengine: ggm_boris25: replace deprecated output:get_value

</details>

<details><summary><code>ggm_morphy</code> Chafitz/Applied Concepts GGM Morphy Edition</summary>

**Known limits**

- No history replay: a takeback or a resumed game can't be passed to the machine.

- MAME set `ggm` (Great Game Machine), driver `appliedconcepts/ggm.cpp`
- script runs `mess ggm morphy`
- interface `ggm_morphy.lua` → `ggm_boris25.lua`
- retro.ini: elo 1450, levels 8, ponder/brain y

**Levels:** 5s move; 8-15s move; 10-40s move; 20-90s move; 1-4m move; 10-40m move; 30 moves/1h; 20 moves/1h

**Commits**

- [ca9e8fb](https://github.com/RandyR99/mame_for_picochess/commit/ca9e8fb) 2026-11-04 mame_for_picochess: .uci: 11 files use the standard [Level n - description] headers
- [e98fc39](https://github.com/RandyR99/mame_for_picochess/commit/e98fc39) 2026-10-29 mame_for_picochess: retro.ini: ponder/brain = y for 32 sets measured to think on the player's time (Phase 3 ponder check, RAM activity during the player's turn from a non-book p…
- [c189a33](https://github.com/RandyR99/mame_for_picochess/commit/c189a33) 2026-10-27 mame_for_picochess: Revisit phase 2 step 1: 35 .uci files to conventions (Level n headings from PicoTimeControl, easiest to hardest within per-move/game/tournament groups, tourn…
- [2281abb](https://github.com/RandyR99/mame_for_picochess/commit/2281abb) 2026-10-17 mame_for_picochess: levels: 5 s minimum per move in all non-Fidelity/H+G .uci files; risc2500 family
- [b480ed4](https://github.com/RandyR99/chessengine/commit/b480ed4) 2026-10-09 chessengine: ggm_steinitz: replace deprecated output:get_value, fix throttle restores
- [323dfbe](https://github.com/RandyR99/chessengine/commit/323dfbe) 2026-10-09 chessengine: ggm: drop the Gruenfeld opening cartridges
- [03888dd](https://github.com/RandyR99/chessengine/commit/03888dd) 2026-10-09 chessengine: ggm: drop Capablanca and unknown Steinitz cartridge entries
- [2a0eac1](https://github.com/RandyR99/chessengine/commit/2a0eac1) 2026-10-09 chessengine: ggm_boris25: replace deprecated output:get_value

</details>

<details><summary><code>ggm_sandy</code> Chafitz/Applied Concepts GGM Sandy</summary>

**Known limits**

- No history replay: a takeback or a resumed game can't be passed to the machine.

- MAME set `ggm` (Great Game Machine), driver `appliedconcepts/ggm.cpp`
- script runs `mess ggm sandy`
- interface `ggm_sandy.lua` → `ggm_morphy.lua` → `ggm_boris25.lua`
- retro.ini: elo 1450, levels 7, ponder/brain n

**Levels:** MATE; &lt;15s move; &lt;40s move; &lt;90s move; &lt;4m move; 30 moves/60m; 20 moves/60m

**Commits**

- [c189a33](https://github.com/RandyR99/mame_for_picochess/commit/c189a33) 2026-10-27 mame_for_picochess: Revisit phase 2 step 1: 35 .uci files to conventions (Level n headings from PicoTimeControl, easiest to hardest within per-move/game/tournament groups, tourn…
- [d4eed72](https://github.com/RandyR99/mame_for_picochess/commit/d4eed72) 2026-10-20 mame_for_picochess: uci: short tournament headings ('40/2h', '60/5m') as '40 moves/2h', units h/m
- [b480ed4](https://github.com/RandyR99/chessengine/commit/b480ed4) 2026-10-09 chessengine: ggm_steinitz: replace deprecated output:get_value, fix throttle restores
- [323dfbe](https://github.com/RandyR99/chessengine/commit/323dfbe) 2026-10-09 chessengine: ggm: drop the Gruenfeld opening cartridges
- [03888dd](https://github.com/RandyR99/chessengine/commit/03888dd) 2026-10-09 chessengine: ggm: drop Capablanca and unknown Steinitz cartridge entries
- [2a0eac1](https://github.com/RandyR99/chessengine/commit/2a0eac1) 2026-10-09 chessengine: ggm_boris25: replace deprecated output:get_value

</details>

<details><summary><code>ggm_steinitz</code> Chafitz/Applied Concepts GGM Steinitz</summary>

- MAME set `ggm` (Great Game Machine), driver `appliedconcepts/ggm.cpp`
- script runs `mess ggm steinitz`
- interface `ggm_steinitz.lua`
- retro.ini: elo 1575, levels 8, ponder/brain n

**Levels:** 60 moves/5m; 60 moves/15m; 60 moves/60m; 48 moves/4h; 16 moves/4h; &lt;60m move; 30 moves/60m; 40 moves/2h

**Commits**

- [26c26de](https://github.com/RandyR99/chessengine/commit/26c26de) 2026-11-04 chessengine: interfaces: player's underpromotion through the position setup on 45 more machines
- [dddd952](https://github.com/RandyR99/chessengine/commit/dddd952) 2026-11-02 chessengine: ggm_steinitz: live info from the search through write taps, no key presses
- [506d638](https://github.com/RandyR99/chessengine/commit/506d638) 2026-10-30 chessengine: show_info: no key presses during the machine's search. 16 interfaces read their info by pressing keys (INFO, page keys, CL) while the machine thinks; a press…
- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [c189a33](https://github.com/RandyR99/mame_for_picochess/commit/c189a33) 2026-10-27 mame_for_picochess: Revisit phase 2 step 1: 35 .uci files to conventions (Level n headings from PicoTimeControl, easiest to hardest within per-move/game/tournament groups, tourn…
- [d4eed72](https://github.com/RandyR99/mame_for_picochess/commit/d4eed72) 2026-10-20 mame_for_picochess: uci: short tournament headings ('40/2h', '60/5m') as '40 moves/2h', units h/m
- [b480ed4](https://github.com/RandyR99/chessengine/commit/b480ed4) 2026-10-09 chessengine: ggm_steinitz: replace deprecated output:get_value, fix throttle restores
- [323dfbe](https://github.com/RandyR99/chessengine/commit/323dfbe) 2026-10-09 chessengine: ggm: drop the Gruenfeld opening cartridges
- [03888dd](https://github.com/RandyR99/chessengine/commit/03888dd) 2026-10-09 chessengine: ggm: drop Capablanca and unknown Steinitz cartridge entries
- [2a0eac1](https://github.com/RandyR99/chessengine/commit/2a0eac1) 2026-10-09 chessengine: ggm_boris25: replace deprecated output:get_value

</details>

<details><summary><code>arb_gms3</code> ARB Sargon 3.0 Grand Master Series</summary>

- MAME set `arb` (Auto Response Board), driver `chess/ave_arb.cpp`
- script runs `mess arb gms3`
- interface `arb_gms3.lua` → `arb_sargon25.lua`
- retro.ini: elo 1500, levels 7, ponder/brain n

**Levels:** 5s move; 10s move; 30s move; 1m move; 5m move; 10m move; Analysis

**Commits**

- [ca9e8fb](https://github.com/RandyR99/mame_for_picochess/commit/ca9e8fb) 2026-11-04 mame_for_picochess: .uci: 11 files use the standard [Level n - description] headers
- [2281abb](https://github.com/RandyR99/mame_for_picochess/commit/2281abb) 2026-10-17 mame_for_picochess: levels: 5 s minimum per move in all non-Fidelity/H+G .uci files; risc2500 family
- [07601a1](https://github.com/RandyR99/mame_for_picochess/commit/07601a1) 2026-10-16 mame_for_picochess: retro.ini: unique small/medium names (arb, feas, tascr30, cmpchess), fill cp2000 and tkinga names
- [a3178e7](https://github.com/RandyR99/chessengine/commit/a3178e7) 2026-10-10 chessengine: arb: replace deprecated output calls, fix hang after reset

</details>

<details><summary><code>arb_gms4</code> ARB Sargon 4.0 Grand Master Series</summary>

- MAME set `arb` (Auto Response Board), driver `chess/ave_arb.cpp`
- script runs `mess arb gms4`
- interface `arb_gms4.lua`
- retro.ini: elo 1705, levels 9, ponder/brain n

**Levels:** 5s move; 15s move; 30s move; 1m move; 2m move; 3m move; 4m move; 6m move; Analysis

**Commits**

- [ca9e8fb](https://github.com/RandyR99/mame_for_picochess/commit/ca9e8fb) 2026-11-04 mame_for_picochess: .uci: 11 files use the standard [Level n - description] headers
- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [07601a1](https://github.com/RandyR99/mame_for_picochess/commit/07601a1) 2026-10-16 mame_for_picochess: retro.ini: unique small/medium names (arb, feas, tascr30, cmpchess), fill cp2000 and tkinga names
- [a3178e7](https://github.com/RandyR99/chessengine/commit/a3178e7) 2026-10-10 chessengine: arb: replace deprecated output calls, fix hang after reset

</details>

<details><summary><code>prodigy</code> Chafitz/Applied Concepts Destiny/Prodigy</summary>

**Known limits**

- No history replay: a takeback or a resumed game can't be passed to the machine.

- MAME set `prodigy` (Destiny Prodigy), driver `appliedconcepts/prodigy.cpp`
- script runs `mess prodigy`
- interface `prodigy.lua`
- retro.ini: elo 1465, levels 7, ponder/brain n

**Levels:** 10s move; 20s move; 45s move; 15m move; 30 moves/1h; 40 moves/1.5h; 40 moves/2h

**Commits**

- [26c26de](https://github.com/RandyR99/chessengine/commit/26c26de) 2026-11-04 chessengine: interfaces: player's underpromotion through the position setup on 45 more machines
- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [c189a33](https://github.com/RandyR99/mame_for_picochess/commit/c189a33) 2026-10-27 mame_for_picochess: Revisit phase 2 step 1: 35 .uci files to conventions (Level n headings from PicoTimeControl, easiest to hardest within per-move/game/tournament groups, tourn…
- [d4eed72](https://github.com/RandyR99/mame_for_picochess/commit/d4eed72) 2026-10-20 mame_for_picochess: uci: short tournament headings ('40/2h', '60/5m') as '40 moves/2h', units h/m
- [4e5a7a7](https://github.com/RandyR99/chessengine/commit/4e5a7a7) 2026-10-10 chessengine: prodigy: replace deprecated output:get_value

</details>

<details><summary><code>arb_sargon25</code> Chafitz/Applied Concepts Sargon 2.5</summary>

- MAME set `arb` (Auto Response Board), driver `chess/ave_arb.cpp`
- script runs `mess arb sargon25`
- interface `arb_sargon25.lua`
- retro.ini: elo 1370, levels 7, ponder/brain n

**Levels:** 5s move; 10s move; 30s move; 1m move; 5m move; 10m move; Analysis

**Commits**

- [26c26de](https://github.com/RandyR99/chessengine/commit/26c26de) 2026-11-04 chessengine: interfaces: player's underpromotion through the position setup on 45 more machines
- [ca9e8fb](https://github.com/RandyR99/mame_for_picochess/commit/ca9e8fb) 2026-11-04 mame_for_picochess: .uci: 11 files use the standard [Level n - description] headers
- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [2281abb](https://github.com/RandyR99/mame_for_picochess/commit/2281abb) 2026-10-17 mame_for_picochess: levels: 5 s minimum per move in all non-Fidelity/H+G .uci files; risc2500 family
- [07601a1](https://github.com/RandyR99/mame_for_picochess/commit/07601a1) 2026-10-16 mame_for_picochess: retro.ini: unique small/medium names (arb, feas, tascr30, cmpchess), fill cp2000 and tkinga names
- [625d02a](https://github.com/RandyR99/chessengine/commit/625d02a) 2026-10-13 chessengine: Convert CRLF line endings to LF
- [a3178e7](https://github.com/RandyR99/chessengine/commit/a3178e7) 2026-10-10 chessengine: arb: replace deprecated output calls, fix hang after reset

</details>

<details><summary><code>arb_sargon35</code> Chafitz/Applied Concepts Sargon 3.5</summary>

- MAME set `arb` (Auto Response Board), driver `chess/ave_arb.cpp`
- script runs `mess arb sargon35`
- interface `arb_sargon35.lua` → `arb_sargon25.lua`
- retro.ini: elo 1500, levels 7, ponder/brain n

**Levels:** 5s move; 10s move; 30s move; 1m move; 5m move; 10m move; Analysis

**Commits**

- [ca9e8fb](https://github.com/RandyR99/mame_for_picochess/commit/ca9e8fb) 2026-11-04 mame_for_picochess: .uci: 11 files use the standard [Level n - description] headers
- [2281abb](https://github.com/RandyR99/mame_for_picochess/commit/2281abb) 2026-10-17 mame_for_picochess: levels: 5 s minimum per move in all non-Fidelity/H+G .uci files; risc2500 family
- [07601a1](https://github.com/RandyR99/mame_for_picochess/commit/07601a1) 2026-10-16 mame_for_picochess: retro.ini: unique small/medium names (arb, feas, tascr30, cmpchess), fill cp2000 and tkinga names
- [a3178e7](https://github.com/RandyR99/chessengine/commit/a3178e7) 2026-10-10 chessengine: arb: replace deprecated output calls, fix hang after reset

</details>

<details><summary><code>arbv2</code> Chafitz/Applied Concepts Sargon 4.0</summary>

- MAME set `arbv2` (ARB V2 Sargon 4.0), driver `chess/ave_arb.cpp`, clone of `arb`
- script runs `mess arbv2`
- interface `arbv2.lua` → `arb_gms4.lua`
- retro.ini: elo 1940, levels 8, ponder/brain n

**Levels:** 6m move; 60 moves/5m; 60 moves/15m; 60 moves/30m; 60 moves/1h; 30 moves/1h; 40 moves/2h; 40 moves/2.5h

**Commits**

- [c189a33](https://github.com/RandyR99/mame_for_picochess/commit/c189a33) 2026-10-27 mame_for_picochess: Revisit phase 2 step 1: 35 .uci files to conventions (Level n headings from PicoTimeControl, easiest to hardest within per-move/game/tournament groups, tourn…
- [71b0188](https://github.com/RandyR99/mame_for_picochess/commit/71b0188) 2026-10-27 mame_for_picochess: retro.ini: years matched to MAME 0.289 (arbv2 2012, feagv11 2001, fscc9 1982, sforteb 1988, tascr30 1995)
- [d4eed72](https://github.com/RandyR99/mame_for_picochess/commit/d4eed72) 2026-10-20 mame_for_picochess: uci: short tournament headings ('40/2h', '60/5m') as '40 moves/2h', units h/m

</details>

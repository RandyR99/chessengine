# Elektor

MAME chess machines in picochess, part of the [machine overview](../MACHINES.md) (columns and general limits explained there).

| System | Name | Year | Elo | Levels | FEN | History | Info | Ponder | Limits |
|---|---|---:|---:|---:|:-:|:-:|:-:|:-:|---:|
| `atm18mcc` | Elektor ATM18 Mini Chess Computer (English) | 2009 | 1350 | 9 | – | – | – | – | 2 |
| `avrmax` | Elektor AVR-Max Chess Computer (English) | 2009 | 1290 | 9 | – | – | – | – | 2 |
| `avrmaxg` | Elektor AVR-Max-Schachzwerg (German) | 2009 | 1290 | 9 | – | – | – | – | 2 |
| `cc2schach` | Elektor CC2-Schachzwerg (German) | 2009 | 1350 | 9 | – | – | – | – | 2 |

<details><summary><code>atm18mcc</code> Elektor ATM18 Mini Chess Computer (English)</summary>

**Known limits**

- No history replay: a takeback or a resumed game can't be passed to the machine.
- No position setup: plays from the start position only.

- MAME set `atm18mcc` (ATM18 Mini Chess Computer (English)), driver `elektor/avrmax.cpp`
- script runs `mess atm18mcc`
- interface `atm18mcc.lua` → `avrmax.lua`
- retro.ini: elo 1350, levels 9, ponder/brain n

**Levels:** 7s move; 10s move; 15s move; 20s move; 30s move; 1m move; 2m move; 3m move; 6m move

**Commits**

- [c189a33](https://github.com/RandyR99/mame_for_picochess/commit/c189a33) 2026-10-27 mame_for_picochess: Revisit phase 2 step 1: 35 .uci files to conventions (Level n headings from PicoTimeControl, easiest to hardest within per-move/game/tournament groups, tourn…
- [a274ff6](https://github.com/RandyR99/chessengine/commit/a274ff6) 2026-10-12 chessengine: avrmax: port to MAME 0.289
- [b063bc0](https://github.com/RandyR99/mame_for_picochess/commit/b063bc0) 2026-10-12 mame_for_picochess: avrmax: levels as in Levels.txt; add avrmaxg and cc2schach to retro_additions

</details>

<details><summary><code>avrmax</code> Elektor AVR-Max Chess Computer (English)</summary>

**Known limits**

- No history replay: a takeback or a resumed game can't be passed to the machine.
- No position setup: plays from the start position only.

- MAME set `avrmax` (AVR-Max Chess Computer (English)), driver `elektor/avrmax.cpp`
- script runs `mess avrmax`
- interface `avrmax.lua`
- retro.ini: elo 1290, levels 9, ponder/brain n

**Levels:** 7s move; 10s move; 15s move; 20s move; 30s move; 1m move; 2m move; 3m move; 6m move

**Commits**

- [021277d](https://github.com/RandyR99/chessengine/commit/021277d) 2026-11-01 chessengine: ucinewgame: skip the soft reset via interface.no_soft_reset instead of a name list
- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [c189a33](https://github.com/RandyR99/mame_for_picochess/commit/c189a33) 2026-10-27 mame_for_picochess: Revisit phase 2 step 1: 35 .uci files to conventions (Level n headings from PicoTimeControl, easiest to hardest within per-move/game/tournament groups, tourn…
- [625d02a](https://github.com/RandyR99/chessengine/commit/625d02a) 2026-10-13 chessengine: Convert CRLF line endings to LF
- [a274ff6](https://github.com/RandyR99/chessengine/commit/a274ff6) 2026-10-12 chessengine: avrmax: port to MAME 0.289
- [b063bc0](https://github.com/RandyR99/mame_for_picochess/commit/b063bc0) 2026-10-12 mame_for_picochess: avrmax: levels as in Levels.txt; add avrmaxg and cc2schach to retro_additions

</details>

<details><summary><code>avrmaxg</code> Elektor AVR-Max-Schachzwerg (German)</summary>

**Known limits**

- No history replay: a takeback or a resumed game can't be passed to the machine.
- No position setup: plays from the start position only.

- MAME set `avrmaxg` (AVR-Max-Schachzwerg (German)), driver `elektor/avrmax.cpp`, clone of `avrmax`
- script runs `mess avrmaxg`
- interface `avrmax.lua`
- retro.ini: elo 1290, levels 9, ponder/brain n

**Levels:** 7s move; 10s move; 15s move; 20s move; 30s move; 1m move; 2m move; 3m move; 6m move

**Commits**

- [021277d](https://github.com/RandyR99/chessengine/commit/021277d) 2026-11-01 chessengine: ucinewgame: skip the soft reset via interface.no_soft_reset instead of a name list
- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [c189a33](https://github.com/RandyR99/mame_for_picochess/commit/c189a33) 2026-10-27 mame_for_picochess: Revisit phase 2 step 1: 35 .uci files to conventions (Level n headings from PicoTimeControl, easiest to hardest within per-move/game/tournament groups, tourn…
- [625d02a](https://github.com/RandyR99/chessengine/commit/625d02a) 2026-10-13 chessengine: Convert CRLF line endings to LF
- [a274ff6](https://github.com/RandyR99/chessengine/commit/a274ff6) 2026-10-12 chessengine: avrmax: port to MAME 0.289
- [48615c9](https://github.com/RandyR99/mame_for_picochess/commit/48615c9) 2026-10-12 mame_for_picochess: Move vetted avrmaxg and ivanto into retro.ini
- [b063bc0](https://github.com/RandyR99/mame_for_picochess/commit/b063bc0) 2026-10-12 mame_for_picochess: avrmax: levels as in Levels.txt; add avrmaxg and cc2schach to retro_additions

</details>

<details><summary><code>cc2schach</code> Elektor CC2-Schachzwerg (German)</summary>

**Known limits**

- No history replay: a takeback or a resumed game can't be passed to the machine.
- No position setup: plays from the start position only.

- MAME set `cc2schach` (CC2-Schachzwerg (German)), driver `elektor/avrmax.cpp`, clone of `atm18mcc`
- script runs `mess cc2schach`
- interface `atm18mcc.lua` → `avrmax.lua`
- retro.ini: elo 1350, levels 9, ponder/brain n

**Levels:** 7s move; 10s move; 15s move; 20s move; 30s move; 1m move; 2m move; 3m move; 6m move

**Commits**

- [c189a33](https://github.com/RandyR99/mame_for_picochess/commit/c189a33) 2026-10-27 mame_for_picochess: Revisit phase 2 step 1: 35 .uci files to conventions (Level n headings from PicoTimeControl, easiest to hardest within per-move/game/tournament groups, tourn…
- [a274ff6](https://github.com/RandyR99/chessengine/commit/a274ff6) 2026-10-12 chessengine: avrmax: port to MAME 0.289
- [48615c9](https://github.com/RandyR99/mame_for_picochess/commit/48615c9) 2026-10-12 mame_for_picochess: Move vetted avrmaxg and ivanto into retro.ini
- [b063bc0](https://github.com/RandyR99/mame_for_picochess/commit/b063bc0) 2026-10-12 mame_for_picochess: avrmax: levels as in Levels.txt; add avrmaxg and cc2schach to retro_additions

</details>

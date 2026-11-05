# Various

MAME chess machines in picochess, part of the [machine overview](../MACHINES.md) (columns and general limits explained there).

| System | Name | Year | Elo | Levels | FEN | History | Info | Ponder | Limits |
|---|---|---:|---:|---:|:-:|:-:|:-:|:-:|---:|
| `chmate` | Commodore Chessmate | 1978 | 815 | 7 | ✓ | – | – | – | 2 |
| `cncchess` | Conic Computer Chess Master I | 1979 | 715 | 4 | ✓ | – | – | – | 2 |
| `cncchess2` | Conic Computer Chess | 1980 | 1070 | 6 | ✓ | – | – | – | 2 |
| `cmpchess` | DataCash System CompuChess | 1977 | 715 | 5 | ✓ | – | – | – | 2 |
| `cmpchess2` | DataCash System CompuChess II | 1978 | 765 | 4 | ✓ | – | – | – | 2 |
| `conc` | Consumenta Conchess | 1982 | 1540 | 7 | ✓ | ✓ | – | – |  |
| `conca` | Consumenta Conchess (set 2) | 1982 | 1540 | 7 | ✓ | ✓ | – | – |  |
| `concgla` | Conchess Princhess Glasgow | 1984 | 1880 | 5 | ✓ | ✓ | – | – |  |
| `concams5` | Conchess Plymate Amsterdam 5.5 MHz | 1985 | 1900 | 8 | ✓ | ✓ | – | – |  |
| `concvicp` | Conchess Plymate Victoria | 1990 | 1980 | 8 | ✓ | ✓ | – | – |  |
| `concams` | Conchess Plymate Amsterdam | 1985 | 1880 | 8 | ✓ | ✓ | – | – |  |
| `concglap` | Conchess Plymate Glasgow Plus | 1984 | 1880 | 8 | ✓ | ✓ | – | – |  |
| `concglapa` | Conchess Plymate Glasgow Plus (set 2) | 1984 | 1880 | 8 | ✓ | ✓ | – | – |  |
| `debutm` | Energopribor Debut-M | 1994 | 1795 | 10 | ✓ | ✓ | – | – | 1 |
| `im01` | Elektronika IM-01 | 1986 | 1300 | 3 | ✓ | ✓ | – | – | 1 |
| `im01t` | Elektronika IM-01T | 1991 | 1300 | 7 | ✓ | ✓ | – | – | 1 |
| `im05` | Elektronika IM-05 | 1993 | 1400 | 6 | ✓ | ✓ | – | – | 1 |
| `igor` | Excalibur Igor | 1997 | 1830 | 8 | ✓ | ✓ | – | – |  |
| `ivant` | Excalibur Ivan The Terrible | 1997 | 1845 | 8 | ✓ | ✓ | – | – |  |
| `ivanto` | Excalibur Ivan The Terrible | 1996 | 1845 | 8 | ✓ | ✓ | – | – |  |
| `emirage` | Excalibur Mirage | 1996 | 1780 | 9 | ✓ | ✓ | – | – |  |
| `regence` | Chafitz/Sandy La Regence TSB 4 | 1982 | 1700 | 7 | ✓ | ✓ | – | – | 1 |
| `intel02` | BREA Intellect-02 | 1985 | 700 | 4 | ✓ | ✓ | – | – | 1 |
| `intel02a` | BREA Intellect-02 Chess (CC3) | 1985 | 895 | 3 | – | – | – | – | 1 |
| `chesskng` | I-Star Chess King (Model ET-6) | 1994 | 500 | 2 | – | – | – | – | 3 |
| `master` | Chess King Master | 1983 | 1345 | 7 | ✓ | ✓ | – | – | 1 |
| `pmicrodx` | Chess King Pocket Micro Deluxe | 1984 | 965 | 6 | – | ✓ | – | – | 1 |
| `triomphe` | Chess King Triomphe | 1985 | 1300 | 8 | – | ✓ | – | – | 1 |
| `mchess` | Mattel Computer Chess | 1980 | 1150 | 3 | ✓ | ✓ | – | – |  |
| `tchess` | Tryom Electronic Chess | 1981 | 832 | 3 | ✓ | ✓ | – | – | 2 |
| `y301xl` | Yeno 301 XL Chess Partner | 1988 | 1370 | 7 | ✓ | ✓ | – | – | 1 |
| `y416xl` | Yeno 416 XL Partner &amp; Tutor | 1989 | 1695 | 6 | ✓ | ✓ | – | ✓ |  |
| `y532xl` | Yeno 532 XL Chess Partner | 1989 | 1750 | 8 | ✓ | ✓ | ✓ | ✓ |  |
| `kchal` | Krypton Challenge | 1996 | 1775 | 10 | ✓ | ✓ | ✓ | – |  |
| `kchala` | Krypton Challenge | 1994 | 1775 | 10 | ✓ | ✓ | ✓ | – |  |
| `obsidian` | Perfect Technology Obsidian | 2003 | 2005 | 11 | ✓ | ✓ | – | – |  |

<details><summary><code>chmate</code> Commodore Chessmate</summary>

**Known limits**

- No history replay: a takeback or a resumed game can't be passed to the machine.
- The .uci times are estimates: the manual names only skill levels 1-8.

- MAME set `chmate` (Chessmate), driver `commodore/chessmate.cpp`
- script runs `mess chmate`
- interface `chmate.lua` → `ccmk2.lua`
- retro.ini: elo 815, levels 7, ponder/brain n

**Levels:** 5s move; 10s move; 15s move; 30s move; 1m move; 2m move; 3m move

**Commits**

- [da0d4a3](https://github.com/RandyR99/chessengine/commit/da0d4a3) 2026-11-01 chessengine: init.lua: Chessmate sets (ccmk2, ccmk2a, chmate) run setup unthrottled; talking machines stay throttled
- [2281abb](https://github.com/RandyR99/mame_for_picochess/commit/2281abb) 2026-10-17 mame_for_picochess: levels: 5 s minimum per move in all non-Fidelity/H+G .uci files; risc2500 family
- [f185882](https://github.com/RandyR99/chessengine/commit/f185882) 2026-10-11 chessengine: ccmk2: port to MAME 0.289, re-enable set_pos from MessChess
- [a8cdc79](https://github.com/RandyR99/mame_for_picochess/commit/a8cdc79) 2026-10-11 mame_for_picochess: chmate, ccmk2, ccmk2a: use the same level labels

</details>

<details><summary><code>cncchess</code> Conic Computer Chess Master I</summary>

**Known limits**

- No history replay: a takeback or a resumed game can't be passed to the machine.
- Doesn't know en passant: it never captures e.p., and the player's e.p. is entered by hand as two steps.

- MAME set `cncchess` (Computer Chess (Conic, model 7011)), driver `chess/compuchess.cpp`
- script runs `mess cncchess`
- interface `cncchess.lua`
- retro.ini: elo 715, levels 4, ponder/brain n

**Levels:** 5s move; 16s move; 15m move; 25m move

**Commits**

- [c189a33](https://github.com/RandyR99/mame_for_picochess/commit/c189a33) 2026-10-27 mame_for_picochess: Revisit phase 2 step 1: 35 .uci files to conventions (Level n headings from PicoTimeControl, easiest to hardest within per-move/game/tournament groups, tourn…
- [2281abb](https://github.com/RandyR99/mame_for_picochess/commit/2281abb) 2026-10-17 mame_for_picochess: levels: 5 s minimum per move in all non-Fidelity/H+G .uci files; risc2500 family
- [315874f](https://github.com/RandyR99/chessengine/commit/315874f) 2026-10-10 chessengine: compuchess: port to MAME 0.289, bring over CB-Emu MessChess fixes
- [031bbe0](https://github.com/RandyR99/mame_for_picochess/commit/031bbe0) 2026-10-10 mame_for_picochess: Move the vetted cncchess entry into retro.ini
- [36a5971](https://github.com/RandyR99/mame_for_picochess/commit/36a5971) 2026-10-10 mame_for_picochess: Move the new cncchess entry from retro.ini to retro_additions.ini
- [de581c1](https://github.com/RandyR99/mame_for_picochess/commit/de581c1) 2026-10-10 mame_for_picochess: retro.ini: add Conic Master I (cncchess), fix CompuChess entries

</details>

<details><summary><code>cncchess2</code> Conic Computer Chess</summary>

**Known limits**

- No history replay: a takeback or a resumed game can't be passed to the machine.
- Player castling and en passant are rejected right after a position setup (fine from the start position).

- MAME set `cncchess2` (Computer Chess (Conic, model 7012)), driver `chess/conic_cchess2.cpp`
- script runs `mess cncchess2`
- interface `cncchess2.lua`
- retro.ini: elo 1070, levels 6, ponder/brain n

**Levels:** 30s move; 40s move; 1m move; 9m move; 12m move; 15m move

**Commits**

- [26c26de](https://github.com/RandyR99/chessengine/commit/26c26de) 2026-11-04 chessengine: interfaces: player's underpromotion through the position setup on 45 more machines
- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [625d02a](https://github.com/RandyR99/chessengine/commit/625d02a) 2026-10-13 chessengine: Convert CRLF line endings to LF
- [67c9a92](https://github.com/RandyR99/chessengine/commit/67c9a92) 2026-10-10 chessengine: cncchess2, regence: port to MAME 0.289; add concams and concglap
- [f9be5c9](https://github.com/RandyR99/mame_for_picochess/commit/f9be5c9) 2026-10-10 mame_for_picochess: retro.ini: complete the cncchess2 and regence entries
- [758d3bb](https://github.com/RandyR99/mame_for_picochess/commit/758d3bb) 2026-10-10 mame_for_picochess: Fix cncchess2 and regence levels, add concams and concglap .uci

</details>

<details><summary><code>cmpchess</code> DataCash System CompuChess</summary>

**Known limits**

- No history replay: a takeback or a resumed game can't be passed to the machine.
- Doesn't know en passant: it never captures e.p., and the player's e.p. is entered by hand as two steps.

- MAME set `cmpchess` (CompuChess), driver `chess/compuchess.cpp`
- script runs `mess cmpchess`
- interface `cmpchess.lua` → `ccmk1.lua`
- retro.ini: elo 715, levels 5, ponder/brain n

**Levels:** 5s move; &lt;14s move; &lt;30s move; &lt;60s move; &lt;120m move

**Commits**

- [2281abb](https://github.com/RandyR99/mame_for_picochess/commit/2281abb) 2026-10-17 mame_for_picochess: levels: 5 s minimum per move in all non-Fidelity/H+G .uci files; risc2500 family
- [07601a1](https://github.com/RandyR99/mame_for_picochess/commit/07601a1) 2026-10-16 mame_for_picochess: retro.ini: unique small/medium names (arb, feas, tascr30, cmpchess), fill cp2000 and tkinga names
- [315874f](https://github.com/RandyR99/chessengine/commit/315874f) 2026-10-10 chessengine: compuchess: port to MAME 0.289, bring over CB-Emu MessChess fixes
- [56cbace](https://github.com/RandyR99/mame_for_picochess/commit/56cbace) 2026-10-10 mame_for_picochess: cmpchess.uci: add PicoTimeControl, same levels as ccmk1 (same program)
- [de581c1](https://github.com/RandyR99/mame_for_picochess/commit/de581c1) 2026-10-10 mame_for_picochess: retro.ini: add Conic Master I (cncchess), fix CompuChess entries

</details>

<details><summary><code>cmpchess2</code> DataCash System CompuChess II</summary>

**Known limits**

- No history replay: a takeback or a resumed game can't be passed to the machine.
- Doesn't know en passant: it never captures e.p., and the player's e.p. is entered by hand as two steps.

- MAME set `cmpchess2` (CompuChess: The Second Edition), driver `chess/compuchess.cpp`
- script runs `mess cmpchess2`
- interface `cmpchess2.lua` → `ccmk1.lua`
- retro.ini: elo 765, levels 4, ponder/brain n

**Levels:** 5s move; 5s to 9m; 10s to 9m; 2m to 9m

**Commits**

- [2281abb](https://github.com/RandyR99/mame_for_picochess/commit/2281abb) 2026-10-17 mame_for_picochess: levels: 5 s minimum per move in all non-Fidelity/H+G .uci files; risc2500 family
- [315874f](https://github.com/RandyR99/chessengine/commit/315874f) 2026-10-10 chessengine: compuchess: port to MAME 0.289, bring over CB-Emu MessChess fixes
- [de581c1](https://github.com/RandyR99/mame_for_picochess/commit/de581c1) 2026-10-10 mame_for_picochess: retro.ini: add Conic Master I (cncchess), fix CompuChess entries

</details>

<details><summary><code>conc</code> Consumenta Conchess</summary>

- MAME set `conc` (Conchess (standard, set 1)), driver `chess/conchess.cpp`
- script runs `mess conc`
- interface `conc.lua`
- retro.ini: elo 1540, levels 7, ponder/brain n

**Levels:** 5s move; 15s move; 1m move; 2m move; 3m move; 5m move; 30m move

**Commits**

- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [c189a33](https://github.com/RandyR99/mame_for_picochess/commit/c189a33) 2026-10-27 mame_for_picochess: Revisit phase 2 step 1: 35 .uci files to conventions (Level n headings from PicoTimeControl, easiest to hardest within per-move/game/tournament groups, tourn…
- [fa83f4f](https://github.com/RandyR99/chessengine/commit/fa83f4f) 2026-10-10 chessengine: conchess: replace deprecated output calls, fix machine en passant
- [f05b665](https://github.com/RandyR99/mame_for_picochess/commit/f05b665) 2026-10-10 mame_for_picochess: Conchess: fix concgla.uci levels, propose retro.ini entries

</details>

<details><summary><code>conca</code> Consumenta Conchess (set 2)</summary>

- MAME set `conca` (Conchess (standard, set 2)), driver `chess/conchess.cpp`, clone of `conc`
- script runs `mess conca`
- interface `conc.lua`
- retro.ini: elo 1540, levels 7, ponder/brain n

**Levels:** 5s move; 15s move; 1m move; 2m move; 3m move; 5m move; 30m move

**Commits**

- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [d6815c6](https://github.com/RandyR99/mame_for_picochess/commit/d6815c6) 2026-10-27 mame_for_picochess: Revisit phase 2 step 2: 50 missing working sets added (scripts, _art, .uci from the parent, retro entries; all smoke-tested): borisa, conca, concglapa, sdtor…
- [fa83f4f](https://github.com/RandyR99/chessengine/commit/fa83f4f) 2026-10-10 chessengine: conchess: replace deprecated output calls, fix machine en passant

</details>

<details><summary><code>concgla</code> Conchess Princhess Glasgow</summary>

- MAME set `concgla` (Conchess Princhess Glasgow), driver `chess/conchess.cpp`
- script runs `mess concgla`
- interface `concgla.lua` → `conc.lua`
- retro.ini: elo 1880, levels 5, ponder/brain n

**Levels:** 5s move; 45s move; 2m move; 3m move; 225s move

**Commits**

- [c189a33](https://github.com/RandyR99/mame_for_picochess/commit/c189a33) 2026-10-27 mame_for_picochess: Revisit phase 2 step 1: 35 .uci files to conventions (Level n headings from PicoTimeControl, easiest to hardest within per-move/game/tournament groups, tourn…
- [33c3557](https://github.com/RandyR99/mame_for_picochess/commit/33c3557) 2026-10-10 mame_for_picochess: Add Conchess Plymate Amsterdam and Glasgow Plus
- [f05b665](https://github.com/RandyR99/mame_for_picochess/commit/f05b665) 2026-10-10 mame_for_picochess: Conchess: fix concgla.uci levels, propose retro.ini entries

</details>

<details><summary><code>concams5</code> Conchess Plymate Amsterdam 5.5 MHz</summary>

- MAME set `concams5` (Conchess Plymate Amsterdam 5.5MHz), driver `chess/conchess.cpp`, clone of `concams`
- script runs `mess concams5 l16`
- interface `concams5.lua` → `conc.lua`
- retro.ini: elo 1900, levels 8, ponder/brain n

**Levels:** 5s move; 10s move; 20s move; 30s move; 1m move; 2m move; 3m move; 10m move

**Commits**

- [c189a33](https://github.com/RandyR99/mame_for_picochess/commit/c189a33) 2026-10-27 mame_for_picochess: Revisit phase 2 step 1: 35 .uci files to conventions (Level n headings from PicoTimeControl, easiest to hardest within per-move/game/tournament groups, tourn…
- [f321da6](https://github.com/RandyR99/chessengine/commit/f321da6) 2026-10-14 chessengine: nmicro2: port to MAME 0.289, re-enable set_pos; drop references to removed sets
- [67c9a92](https://github.com/RandyR99/chessengine/commit/67c9a92) 2026-10-10 chessengine: cncchess2, regence: port to MAME 0.289; add concams and concglap
- [fa83f4f](https://github.com/RandyR99/chessengine/commit/fa83f4f) 2026-10-10 chessengine: conchess: replace deprecated output calls, fix machine en passant
- [33c3557](https://github.com/RandyR99/mame_for_picochess/commit/33c3557) 2026-10-10 mame_for_picochess: Add Conchess Plymate Amsterdam and Glasgow Plus
- [758d3bb](https://github.com/RandyR99/mame_for_picochess/commit/758d3bb) 2026-10-10 mame_for_picochess: Fix cncchess2 and regence levels, add concams and concglap .uci
- [f05b665](https://github.com/RandyR99/mame_for_picochess/commit/f05b665) 2026-10-10 mame_for_picochess: Conchess: fix concgla.uci levels, propose retro.ini entries

</details>

<details><summary><code>concvicp</code> Conchess Plymate Victoria</summary>

- MAME set `concvicp` (Conchess Plymate Victoria (prototype)), driver `chess/conchess.cpp`
- script runs `mess concvicp`
- interface `concvicp.lua` → `concams5.lua` → `conc.lua`
- retro.ini: elo 1980, levels 8, ponder/brain n

**Levels:** 5s move; 10s move; 20s move; 30s move; 1m move; 2m move; 3m move; 10m move

**Commits**

- [c189a33](https://github.com/RandyR99/mame_for_picochess/commit/c189a33) 2026-10-27 mame_for_picochess: Revisit phase 2 step 1: 35 .uci files to conventions (Level n headings from PicoTimeControl, easiest to hardest within per-move/game/tournament groups, tourn…
- [fa83f4f](https://github.com/RandyR99/chessengine/commit/fa83f4f) 2026-10-10 chessengine: conchess: replace deprecated output calls, fix machine en passant
- [f05b665](https://github.com/RandyR99/mame_for_picochess/commit/f05b665) 2026-10-10 mame_for_picochess: Conchess: fix concgla.uci levels, propose retro.ini entries

</details>

<details><summary><code>concams</code> Conchess Plymate Amsterdam</summary>

- MAME set `concams` (Conchess Plymate Amsterdam), driver `chess/conchess.cpp`
- script runs `mess concams l16`
- interface `concams.lua` → `concams5.lua` → `conc.lua`
- retro.ini: elo 1880, levels 8, ponder/brain n

**Levels:** 5s move; 10s move; 20s move; 30s move; 1m move; 2m move; 3m move; 10m move

**Commits**

- [c189a33](https://github.com/RandyR99/mame_for_picochess/commit/c189a33) 2026-10-27 mame_for_picochess: Revisit phase 2 step 1: 35 .uci files to conventions (Level n headings from PicoTimeControl, easiest to hardest within per-move/game/tournament groups, tourn…
- [67c9a92](https://github.com/RandyR99/chessengine/commit/67c9a92) 2026-10-10 chessengine: cncchess2, regence: port to MAME 0.289; add concams and concglap
- [33c3557](https://github.com/RandyR99/mame_for_picochess/commit/33c3557) 2026-10-10 mame_for_picochess: Add Conchess Plymate Amsterdam and Glasgow Plus
- [758d3bb](https://github.com/RandyR99/mame_for_picochess/commit/758d3bb) 2026-10-10 mame_for_picochess: Fix cncchess2 and regence levels, add concams and concglap .uci

</details>

<details><summary><code>concglap</code> Conchess Plymate Glasgow Plus</summary>

- MAME set `concglap` (Conchess Plymate Glasgow Plus (set 1)), driver `chess/conchess.cpp`
- script runs `mess concglap`
- interface `concglap.lua` → `concams5.lua` → `conc.lua`
- retro.ini: elo 1880, levels 8, ponder/brain n

**Levels:** 5s move; 10s move; 20s move; 30s move; 1m move; 2m move; 3m move; 10m move

**Commits**

- [c189a33](https://github.com/RandyR99/mame_for_picochess/commit/c189a33) 2026-10-27 mame_for_picochess: Revisit phase 2 step 1: 35 .uci files to conventions (Level n headings from PicoTimeControl, easiest to hardest within per-move/game/tournament groups, tourn…
- [67c9a92](https://github.com/RandyR99/chessengine/commit/67c9a92) 2026-10-10 chessengine: cncchess2, regence: port to MAME 0.289; add concams and concglap
- [33c3557](https://github.com/RandyR99/mame_for_picochess/commit/33c3557) 2026-10-10 mame_for_picochess: Add Conchess Plymate Amsterdam and Glasgow Plus
- [758d3bb](https://github.com/RandyR99/mame_for_picochess/commit/758d3bb) 2026-10-10 mame_for_picochess: Fix cncchess2 and regence levels, add concams and concglap .uci

</details>

<details><summary><code>concglapa</code> Conchess Plymate Glasgow Plus (set 2)</summary>

- MAME set `concglapa` (Conchess Plymate Glasgow Plus (set 2)), driver `chess/conchess.cpp`, clone of `concglap`
- script runs `mess concglapa`
- interface `concglap.lua` → `concams5.lua` → `conc.lua`
- retro.ini: elo 1880, levels 8, ponder/brain n

**Levels:** 5s move; 10s move; 20s move; 30s move; 1m move; 2m move; 3m move; 10m move

**Commits**

- [d6815c6](https://github.com/RandyR99/mame_for_picochess/commit/d6815c6) 2026-10-27 mame_for_picochess: Revisit phase 2 step 2: 50 missing working sets added (scripts, _art, .uci from the parent, retro entries; all smoke-tested): borisa, conca, concglapa, sdtor…
- [67c9a92](https://github.com/RandyR99/chessengine/commit/67c9a92) 2026-10-10 chessengine: cncchess2, regence: port to MAME 0.289; add concams and concglap

</details>

<details><summary><code>debutm</code> Energopribor Debut-M</summary>

**Known limits**

- Promotes only to a queen; a player underpromotion goes in through a position setup (see Player underpromotion).

- MAME set `debutm` (Debut-M), driver `ussr/debut.cpp`
- script runs `mess debutm`
- interface `debutm.lua`
- retro.ini: elo 1795, levels 10, ponder/brain n

**retro.ini comment:** Mirage engine by Vladimir Rybinkin; 10 levels, each a 40-moves time control: 3-5-10-15-30-45-60-90-120-150 min (Levels.txt, chesscomputeruk.com); no manual available

**Test notes**

- debutm (ussr/debut.cpp) \| committed 2026-10-19 \| 63/66 incl. e.p. retests, 0 illegal \| ep_p; queen-only promotion (ub_b2) \| output proxies; FIX e.p.: captured pawn must leave the board before the capturing move \| 10 levels, each 40 moves in 3..150 min (chesscomputeruk confirms); new retro entry; ponder unverified (n); no manual

**Levels:** 40 moves/3m; 40 moves/5m; 40 moves/10m; 40 moves/15m; 40 moves/30m; 40 moves/45m; 40 moves/1h; 40 moves/1.5h; 40 moves/2h; 40 moves/2.5h

**Commits**

- [26c26de](https://github.com/RandyR99/chessengine/commit/26c26de) 2026-11-04 chessengine: interfaces: player's underpromotion through the position setup on 45 more machines
- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [e2aa330](https://github.com/RandyR99/mame_for_picochess/commit/e2aa330) 2026-10-20 mame_for_picochess: uci: tournament headings as '40 moves/2h' instead of '40 moves in 2h'
- [7444248](https://github.com/RandyR99/chessengine/commit/7444248) 2026-10-19 chessengine: debutm: port to MAME 0.289 (output proxies); en passant: remove the captured pawn first
- [373ea1d](https://github.com/RandyR99/mame_for_picochess/commit/373ea1d) 2026-10-19 mame_for_picochess: debutm: new engine entry, 10 levels (40 moves in 3..150 min)
- [625d02a](https://github.com/RandyR99/chessengine/commit/625d02a) 2026-10-13 chessengine: Convert CRLF line endings to LF

</details>

<details><summary><code>im01</code> Elektronika IM-01</summary>

**Known limits**

- Stops thinking in dead draws (K+minor vs K, bare kings); picochess ends these games itself.

- MAME set `im01` (Elektronika IM-01), driver `ussr/im01.cpp`
- script runs `mess im01`
- interface `im01.lua`
- retro.ini: elo 1300, levels 3, ponder/brain n

**Test notes**

- im01, im01t, im05 (ussr/im01.cpp) \| committed 2026-10-19 \| 91/97 (FEN+history now supported), 0 illegal \| ep_p; stops at dead draws (K+minor vs K) \| output proxies; RESTORED set_pos + edit_game from MessChess (lost in our copies: FEN/history/takeback impossible before); im05 keys bit-reversed vs MessChess; FIX machine promotion code leaking into the player's next move \| im01 3 levels (L4+ 15m-24h/move dropped), im01t 7, im05 6 measured (L7 &gt;1.5 h/move dropped); no manuals

**Levels:** 10s move; 1m move; 5m move

**Commits**

- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [87ca67e](https://github.com/RandyR99/chessengine/commit/87ca67e) 2026-10-19 chessengine: im01, im05: port to MAME 0.289 (output proxies); restore set_pos + edit_game from MessChess (im05 keys remapped); clear the machine's promotion code
- [b570afa](https://github.com/RandyR99/mame_for_picochess/commit/b570afa) 2026-10-19 mame_for_picochess: im01, im01t, im05: level files per conventions (impractical levels dropped, im05 measured)

</details>

<details><summary><code>im01t</code> Elektronika IM-01T</summary>

**Known limits**

- Stops thinking in dead draws (K+minor vs K, bare kings); picochess ends these games itself.

- MAME set `im01t` (Elektronika IM-01T), driver `ussr/im01.cpp`, clone of `im01`
- script runs `mess im01t`
- interface `im01t.lua` → `im01.lua`
- retro.ini: elo 1300, levels 7, ponder/brain n

**Test notes**

- im01, im01t, im05 (ussr/im01.cpp) \| committed 2026-10-19 \| 91/97 (FEN+history now supported), 0 illegal \| ep_p; stops at dead draws (K+minor vs K) \| output proxies; RESTORED set_pos + edit_game from MessChess (lost in our copies: FEN/history/takeback impossible before); im05 keys bit-reversed vs MessChess; FIX machine promotion code leaking into the player's next move \| im01 3 levels (L4+ 15m-24h/move dropped), im01t 7, im05 6 measured (L7 &gt;1.5 h/move dropped); no manuals

**Levels:** 5s move; 10s move; 30s move; 40s move; 1.5m move; 2m move; 10m move

**Commits**

- [b570afa](https://github.com/RandyR99/mame_for_picochess/commit/b570afa) 2026-10-19 mame_for_picochess: im01, im01t, im05: level files per conventions (impractical levels dropped, im05 measured)

</details>

<details><summary><code>im05</code> Elektronika IM-05</summary>

**Known limits**

- Stops thinking in dead draws (K+minor vs K, bare kings); picochess ends these games itself.

- MAME set `im05` (Elektronika IM-05), driver `ussr/im01.cpp`
- script runs `mess im05`
- interface `im05.lua`
- retro.ini: elo 1400, levels 6, ponder/brain n

**Test notes**

- im01, im01t, im05 (ussr/im01.cpp) \| committed 2026-10-19 \| 91/97 (FEN+history now supported), 0 illegal \| ep_p; stops at dead draws (K+minor vs K) \| output proxies; RESTORED set_pos + edit_game from MessChess (lost in our copies: FEN/history/takeback impossible before); im05 keys bit-reversed vs MessChess; FIX machine promotion code leaking into the player's next move \| im01 3 levels (L4+ 15m-24h/move dropped), im01t 7, im05 6 measured (L7 &gt;1.5 h/move dropped); no manuals

**Levels:** 5s move; 10s move; 30s move; 1m move; 2m move; 3m move

**Commits**

- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [87ca67e](https://github.com/RandyR99/chessengine/commit/87ca67e) 2026-10-19 chessengine: im01, im05: port to MAME 0.289 (output proxies); restore set_pos + edit_game from MessChess (im05 keys remapped); clear the machine's promotion code
- [b570afa](https://github.com/RandyR99/mame_for_picochess/commit/b570afa) 2026-10-19 mame_for_picochess: im01, im01t, im05: level files per conventions (impractical levels dropped, im05 measured)

</details>

<details><summary><code>igor</code> Excalibur Igor</summary>

- MAME set `igor` (Igor (Excalibur)), driver `excalibur/ivant.cpp`
- script runs `mess igor`
- interface `igor.lua` → `ivant.lua`
- retro.ini: elo 1830, levels 8, ponder/brain n

**Levels:** 10s move; 30s move; 1m move; 5m game; 10m game; 15m game; 60m game; 120m game

**Commits**

- [cac5a6e](https://github.com/RandyR99/chessengine/commit/cac5a6e) 2026-10-29 chessengine: ivant, igor: after a set up Ivan ignores a pawn move to the last rank as the first move until Verify, Clear (found by hand by Randy) - set_pos presses both;…
- [c189a33](https://github.com/RandyR99/mame_for_picochess/commit/c189a33) 2026-10-27 mame_for_picochess: Revisit phase 2 step 1: 35 .uci files to conventions (Level n headings from PicoTimeControl, easiest to hardest within per-move/game/tournament groups, tourn…
- [625d02a](https://github.com/RandyR99/chessengine/commit/625d02a) 2026-10-13 chessengine: Convert CRLF line endings to LF
- [958464c](https://github.com/RandyR99/chessengine/commit/958464c) 2026-10-12 chessengine: ivant: port to MAME 0.289; add ivanto interface
- [ce02607](https://github.com/RandyR99/mame_for_picochess/commit/ce02607) 2026-10-12 mame_for_picochess: ivant, igor: 5 min/game is level 70; add ivanto

</details>

<details><summary><code>ivant</code> Excalibur Ivan The Terrible</summary>

- MAME set `ivant` (Ivan The Terrible (H8/3216 version)), driver `excalibur/ivant.cpp`
- script runs `mess ivant`
- interface `ivant.lua`
- retro.ini: elo 1845, levels 8, ponder/brain n

**Levels:** 10s move; 30s move; 1m move; 5m game; 10m game; 15m game; 60m game; 120m game

**Commits**

- [cac5a6e](https://github.com/RandyR99/chessengine/commit/cac5a6e) 2026-10-29 chessengine: ivant, igor: after a set up Ivan ignores a pawn move to the last rank as the first move until Verify, Clear (found by hand by Randy) - set_pos presses both;…
- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [c189a33](https://github.com/RandyR99/mame_for_picochess/commit/c189a33) 2026-10-27 mame_for_picochess: Revisit phase 2 step 1: 35 .uci files to conventions (Level n headings from PicoTimeControl, easiest to hardest within per-move/game/tournament groups, tourn…
- [958464c](https://github.com/RandyR99/chessengine/commit/958464c) 2026-10-12 chessengine: ivant: port to MAME 0.289; add ivanto interface
- [ce02607](https://github.com/RandyR99/mame_for_picochess/commit/ce02607) 2026-10-12 mame_for_picochess: ivant, igor: 5 min/game is level 70; add ivanto

</details>

<details><summary><code>ivanto</code> Excalibur Ivan The Terrible</summary>

- MAME set `ivanto` (Ivan The Terrible (H8/3256 version)), driver `excalibur/ivanto.cpp`, clone of `ivant`
- script runs `mess ivanto`
- interface `ivanto.lua`
- retro.ini: elo 1845, levels 8, ponder/brain n

**Levels:** 10s move; 30s move; 1m move; 5m game; 10m game; 15m game; 60m game; 120m game

**Commits**

- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [c189a33](https://github.com/RandyR99/mame_for_picochess/commit/c189a33) 2026-10-27 mame_for_picochess: Revisit phase 2 step 1: 35 .uci files to conventions (Level n headings from PicoTimeControl, easiest to hardest within per-move/game/tournament groups, tourn…
- [958464c](https://github.com/RandyR99/chessengine/commit/958464c) 2026-10-12 chessengine: ivant: port to MAME 0.289; add ivanto interface
- [48615c9](https://github.com/RandyR99/mame_for_picochess/commit/48615c9) 2026-10-12 mame_for_picochess: Move vetted avrmaxg and ivanto into retro.ini
- [ce02607](https://github.com/RandyR99/mame_for_picochess/commit/ce02607) 2026-10-12 mame_for_picochess: ivant, igor: 5 min/game is level 70; add ivanto

</details>

<details><summary><code>emirage</code> Excalibur Mirage</summary>

- MAME set `emirage` (Mirage (Excalibur)), driver `excalibur/mirage.cpp`
- script runs `mess emirage`
- interface `emirage.lua`
- retro.ini: elo 1780, levels 9, ponder/brain n

**Levels:** 5s move; 10s move; 30s move; 1m move; 2m move; 3m move; 10m game; 1h game; 40 moves/2h + 20 moves/1h

**Commits**

- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [d4eed72](https://github.com/RandyR99/mame_for_picochess/commit/d4eed72) 2026-10-20 mame_for_picochess: uci: short tournament headings ('40/2h', '60/5m') as '40 moves/2h', units h/m
- [2281abb](https://github.com/RandyR99/mame_for_picochess/commit/2281abb) 2026-10-17 mame_for_picochess: levels: 5 s minimum per move in all non-Fidelity/H+G .uci files; risc2500 family
- [570af53](https://github.com/RandyR99/chessengine/commit/570af53) 2026-10-12 chessengine: emirage: port to MAME 0.289, fix captures in Multi Move
- [70bd180](https://github.com/RandyR99/mame_for_picochess/commit/70bd180) 2026-10-12 mame_for_picochess: emirage: new levels 37-66 (avg time/move), 75, 85, 92

</details>

<details><summary><code>regence</code> Chafitz/Sandy La Regence TSB 4</summary>

**Known limits**

- Player castling and en passant are rejected right after a position setup (fine from the start position).

- MAME set `regence` (La Régence), driver `chess/regence.cpp`
- script runs `mess regence`
- interface `regence.lua`
- retro.ini: elo 1700, levels 7, ponder/brain n

**Levels:** 5s move; 8s move; 15s move; 35s move; 2m move; 3.5m move; 7.5m move

**Commits**

- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [8b0248b](https://github.com/RandyR99/mame_for_picochess/commit/8b0248b) 2026-10-26 mame_for_picochess: modular_tm.cpp (TM / 68030 modules): port32t .uci = Portorose 10 levels (TURN 08 = 40 moves/2h, verified), other 7 = Berlin Pro 11 levels; retro: new lyon32t…
- [2281abb](https://github.com/RandyR99/mame_for_picochess/commit/2281abb) 2026-10-17 mame_for_picochess: levels: 5 s minimum per move in all non-Fidelity/H+G .uci files; risc2500 family
- [67c9a92](https://github.com/RandyR99/chessengine/commit/67c9a92) 2026-10-10 chessengine: cncchess2, regence: port to MAME 0.289; add concams and concglap
- [f9be5c9](https://github.com/RandyR99/mame_for_picochess/commit/f9be5c9) 2026-10-10 mame_for_picochess: retro.ini: complete the cncchess2 and regence entries
- [758d3bb](https://github.com/RandyR99/mame_for_picochess/commit/758d3bb) 2026-10-10 mame_for_picochess: Fix cncchess2 and regence levels, add concams and concglap .uci

</details>

<details><summary><code>intel02</code> BREA Intellect-02</summary>

**Known limits**

- Promotes only to a queen; a player underpromotion goes in through a position setup (see Player underpromotion).

- MAME set `intel02` (Intellect-02), driver `ussr/intellect02.cpp`
- script runs `mess intel02 chess2`
- interface `intel02_chess2.lua`
- retro.ini: elo 700, levels 4, ponder/brain n

**Test notes**

- intel02 (chess2), intel02a (chess) (ussr/intellect02.cpp) \| 9d1e200 / d9e12cc \| chess2 57/60, chess: start/black only \| chess cart: no setup mode -&gt; no FEN/history/takeback; chess2 queen-only promotion \| output proxies; chess2 set_pos restored (MessChess); chess2 NEW edit_game = silent replay + final-position set_pos \| intel02 4 levels, intel02a 3 (.uci files were swapped vs carts)

**Levels:** 5s move; 10s move; 30s move; 3m move

**Commits**

- [d644b6f](https://github.com/RandyR99/chessengine/commit/d644b6f) 2026-11-05 chessengine: intel02_chess2: the queen promotion is tested, not assumed
- [26c26de](https://github.com/RandyR99/chessengine/commit/26c26de) 2026-11-04 chessengine: interfaces: player's underpromotion through the position setup on 45 more machines
- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [9d1e200](https://github.com/RandyR99/chessengine/commit/9d1e200) 2026-10-19 chessengine: intel02: port to MAME 0.289 (output proxies); chess2: restore set_pos, new edit_game (replay + final position)
- [d9e12cc](https://github.com/RandyR99/mame_for_picochess/commit/d9e12cc) 2026-10-19 mame_for_picochess: intel02: fix swapped level files (chess2 4 levels, chess 3), spelling Intellect-02; add intel02a (chess cartridge)

</details>

<details><summary><code>intel02a</code> BREA Intellect-02 Chess (CC3)</summary>

**Known limits**

- The Chess cartridge has no setup mode: no positions, no history replay, start position only.

- MAME set `intel02` (Intellect-02), driver `ussr/intellect02.cpp`
- script runs `mess intel02 chess`
- interface `intel02_chess.lua`
- retro.ini: elo 895, levels 3, ponder/brain n

**retro.ini comment:** intel02 with the first chess cartridge (-cart chess): a modified Fidelity Chess Challenger 3 program, Elo of CC3; no setup mode, so no FEN positions, game loading or takeback (play from the start only); intel02 itself uses the 4-level chess2 cartridge

**Levels:** 5s move; 10s move; 30s move

**Commits**

- [26c26de](https://github.com/RandyR99/chessengine/commit/26c26de) 2026-11-04 chessengine: interfaces: player's underpromotion through the position setup on 45 more machines
- [9d1e200](https://github.com/RandyR99/chessengine/commit/9d1e200) 2026-10-19 chessengine: intel02: port to MAME 0.289 (output proxies); chess2: restore set_pos, new edit_game (replay + final position)
- [d9e12cc](https://github.com/RandyR99/mame_for_picochess/commit/d9e12cc) 2026-10-19 mame_for_picochess: intel02: fix swapped level files (chess2 4 levels, chess 3), spelling Intellect-02; add intel02a (chess cartridge)

</details>

<details><summary><code>chesskng</code> I-Star Chess King (Model ET-6)</summary>

**Known limits**

- No history replay: a takeback or a resumed game can't be passed to the machine.
- No position setup: plays from the start position only.
- ROM bugs (MAME: BTANB): sometimes plays illegal king moves in lost positions and hangs on a player en passant; level times are guesses.

- MAME set `chesskng` (Chess King (model ET-6)), driver `handheld/chessking.cpp`
- script runs `mess chesskng`
- interface `chesskng.lua`
- retro.ini: elo 500, levels 2, ponder/brain n

**Levels:** &lt;5s move; &lt;10s move

**Commits**

- [e98fc39](https://github.com/RandyR99/mame_for_picochess/commit/e98fc39) 2026-10-29 mame_for_picochess: retro.ini: ponder/brain = y for 32 sets measured to think on the player's time (Phase 3 ponder check, RAM activity during the player's turn from a non-book p…
- [2281abb](https://github.com/RandyR99/mame_for_picochess/commit/2281abb) 2026-10-17 mame_for_picochess: levels: 5 s minimum per move in all non-Fidelity/H+G .uci files; risc2500 family
- [1433fc2](https://github.com/RandyR99/chessengine/commit/1433fc2) 2026-10-13 chessengine: chesskng: port to MAME 0.289, fix boot, menus and Level option

</details>

<details><summary><code>master</code> Chess King Master</summary>

**Known limits**

- Player castling and en passant hang right after a position setup (fine in a normal game).

- MAME set `master` (Master (Chess King)), driver `chessking/master.cpp`
- script runs `mess master`
- interface `master.lua`
- retro.ini: elo 1345, levels 7, ponder/brain n

**Levels:** 5s move; 8s move; 35s move; 1m move; 1.75m move; 3m move; 7.5m move

**Commits**

- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [2281abb](https://github.com/RandyR99/mame_for_picochess/commit/2281abb) 2026-10-17 mame_for_picochess: levels: 5 s minimum per move in all non-Fidelity/H+G .uci files; risc2500 family
- [f5b37b3](https://github.com/RandyR99/chessengine/commit/f5b37b3) 2026-10-11 chessengine: master: rename from ckmaster (MAME renamed the set), port to MAME 0.289
- [fcfdd95](https://github.com/RandyR99/mame_for_picochess/commit/fcfdd95) 2026-10-11 mame_for_picochess: Add Chess King Master, move vetted tascr30a and master into retro.ini

</details>

<details><summary><code>pmicrodx</code> Chess King Pocket Micro Deluxe</summary>

**Known limits**

- No position setup: the program keeps attack tables next to the board that it updates move by move.

- MAME set `pmicrodx` (Pocket Micro De-Luxe), driver `chessking/pmicrodx.cpp`
- script runs `mess pmicrodx`
- interface `pmicrodx.lua`
- retro.ini: elo 965, levels 6, ponder/brain n

**Test notes**

- pmicrodx (chessking/pmicrodx.cpp) \| (committed earlier) \| set_pos OFF: 29/113 (no FEN setups); with set_pos ON 87/113 but illegal moves \| NO FEN SETUP (set_pos disabled on purpose, user decision 2026-10-29) \| no keypad setup mode, so set_pos writes the board straight into the HD44868 data RAM (0x000 + 16*(file)+rank, nibbles P1 N2 B3 R4 Q5 K6, black +8). The program also keeps 8 extra values per file next to the squares (attack/mobility-like tables) and a king-position history at 0xa0-0xbf, both updated only by its own move code; set_pos leaves them at the start-position values, so after a FEN it misjudges the position (king into check in chk_b, illegal moves in only1/kxe4, no move after a rook check). Item 9 (2026-10-30): the 8 extra values per file are an ATTACK MAP (empty: 2 = attacked by the side that just moved, 1 = by the side to move; occupied: 8 = defended + type of the least valuable enemy attacker 1P..6K; matches 99.6% of squares in real games). Writing board + map fixes normal FEN setups, but the king still walks into check in chk_b/chk_w/only1/kxe4 with either colour convention; RAM is only 256 nibbles (all dumped, no king-square variable, 0x80.. = move history). CLOSED: set_pos stays OFF (no ROM disassembly, user decision 2026-10-30). \| levels per .uci; ponder ?

**Levels:** 5s move; 10s move; 15s move; 1m move; 2m move; 3m move

**Commits**

- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [5d91e04](https://github.com/RandyR99/chessengine/commit/5d91e04) 2026-10-24 chessengine: RAM access via memory shares / address spaces instead of save-state items: supremo, nsnova, renaissa (ram_block helper), sapphire, sapphire2 (:nvram), kblitz…
- [6787212](https://github.com/RandyR99/chessengine/commit/6787212) 2026-10-11 chessengine: pmicrodx: replace deprecated output:get_value

</details>

<details><summary><code>triomphe</code> Chess King Triomphe</summary>

**Known limits**

- No position setup: plays from the start position only.

- MAME set `triomphe` (Triomphe), driver `chessking/triomphe.cpp`
- script runs `mess triomphe`
- interface `triomphe.lua`
- retro.ini: elo 1300, levels 8, ponder/brain n

**Levels:** 10s move; 20s move; 30s move; 1m move; 2m move; 3m move; 4m move; 6m move

**Commits**

- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [ece724c](https://github.com/RandyR99/chessengine/commit/ece724c) 2026-10-11 chessengine: triomphe: add interface (from MessChess, MAME 0.289), with edit_game
- [c7f271d](https://github.com/RandyR99/mame_for_picochess/commit/c7f271d) 2026-10-11 mame_for_picochess: Add Chess King Triomphe

</details>

<details><summary><code>mchess</code> Mattel Computer Chess</summary>

- MAME set `mchess` (Computer Chess (Mattel)), driver `mattel/chess.cpp`
- script runs `mess mchess`
- interface `mchess.lua`
- retro.ini: elo 1150, levels 3, ponder/brain n

**Levels:** 5s move; &lt;30s move; &lt;5m move

**Commits**

- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [2281abb](https://github.com/RandyR99/mame_for_picochess/commit/2281abb) 2026-10-17 mame_for_picochess: levels: 5 s minimum per move in all non-Fidelity/H+G .uci files; risc2500 family
- [b487521](https://github.com/RandyR99/chessengine/commit/b487521) 2026-10-13 chessengine: mchess: port to MAME 0.289, enable set_pos, add underpromotion
- [fd27913](https://github.com/RandyR99/mame_for_picochess/commit/fd27913) 2026-10-13 mame_for_picochess: retro.ini: mchess levels = 3 (entries in mchess.uci)
- [fbfc0c5](https://github.com/RandyR99/mame_for_picochess/commit/fbfc0c5) 2026-10-13 mame_for_picochess: retro.ini: mchess has 4 levels

</details>

<details><summary><code>tchess</code> Tryom Electronic Chess</summary>

**Known limits**

- After a keypad setup the machine doesn't know castling rights or an en passant chance (it shows LOSE when e.p. is its only move).
- Resigns lost positions (LOSE, no move): the plugin sends bestmove 0000.

- MAME set `tchess` (Electronic Chess (Tryom)), driver `tryom/chess.cpp`
- script runs `mess tchess`
- interface `tchess.lua`
- retro.ini: elo 832, levels 3, ponder/brain n

**Test notes**

- tchess (tryom/chess.cpp) \| committed 2026-10-19 \| 61/67, 0 illegal \| resigns lost positions (LOSE, no move: chk_b chk_w only2 ss_g3); e.p. after keyed setup invisible; castling rights not settable after setup \| output proxies; set_pos RE-ENABLED via keypad (RST, level, B blank, EP+piece+square+XMV per piece, black to move -&gt; WSD; set_pos(0) returns '') \| 3 levels: L1-6 quick eval first (L1-5 identical in tests), L7 thorough (11-13 min/move), L8 mate in 2

**Levels:** 30s move; 1m move; 10m move

**Commits**

- [6f4c493](https://github.com/RandyR99/chessengine/commit/6f4c493) 2026-10-29 chessengine: Game end: optional interface.game_over() - when it returns true on the machine's turn, init.lua sends 'bestmove 0000' once (reset by the next 'position'); pi…
- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [c7a60bc](https://github.com/RandyR99/chessengine/commit/c7a60bc) 2026-10-19 chessengine: tchess: port to MAME 0.289 (output proxies); FEN setup via keypad (blank board + Enter Position)
- [db7c8d1](https://github.com/RandyR99/mame_for_picochess/commit/db7c8d1) 2026-10-19 mame_for_picochess: tchess: 3 levels (levels 1-5 play alike), levels/ponder in retro.ini

</details>

<details><summary><code>y301xl</code> Yeno 301 XL Chess Partner</summary>

**Known limits**

- Promotes only to a queen; a player underpromotion goes in through a position setup (see Player underpromotion).

- MAME set `y301xl` (301 XL (Yeno)), driver `yeno/301xl.cpp`
- script runs `mess y301xl`
- interface `y301xl.lua`
- retro.ini: elo 1370, levels 7, ponder/brain n

**Test notes**

- y301xl (yeno/301xl.cpp) \| committed 2026-10-19 \| 55/58, 0 illegal \| ep_p; queen-only promotion \| output proxies; FIX replay: Take Back after each history move raced instant forced replies (game10 check sequence) -&gt; silent piece moves + final-position set_pos \| 7 levels (manual FR p9 = Levels.txt; '6s' dropped); no pondering

**Levels:** 5s move; 10s move; 30s move; 1m move; 1.5m move; 4m move; 10m move

**Commits**

- [26c26de](https://github.com/RandyR99/chessengine/commit/26c26de) 2026-11-04 chessengine: interfaces: player's underpromotion through the position setup on 45 more machines
- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [650d35d](https://github.com/RandyR99/chessengine/commit/650d35d) 2026-10-19 chessengine: y301xl: port to MAME 0.289 (output proxies); history replay via silent moves + final-position setup
- [bc7cd06](https://github.com/RandyR99/mame_for_picochess/commit/bc7cd06) 2026-10-19 mame_for_picochess: y301xl: 7 levels per conventions, levels/ponder in retro.ini
- [2281abb](https://github.com/RandyR99/mame_for_picochess/commit/2281abb) 2026-10-17 mame_for_picochess: levels: 5 s minimum per move in all non-Fidelity/H+G .uci files; risc2500 family

</details>

<details><summary><code>y416xl</code> Yeno 416 XL Partner &amp; Tutor</summary>

- MAME set `y416xl` (416 XL (Yeno)), driver `yeno/416xl.cpp`
- script runs `mess y416xl`
- interface `y416xl.lua`
- retro.ini: elo 1695, levels 6, ponder/brain y

**Test notes**

- y416xl (yeno/416xl.cpp) \| committed 2026-10-19 \| 56/58, 0 illegal \| ep_p \| output proxies; test_promotion used pre-0.220 machine:outputs() API (would crash) \| 6 time levels (beginner levels removed by user); permanent brain on a/b levels (manual p8: C/D = A/B without it) -&gt; ponder y

**Levels:** 5s move; 10s move; 30s move; 1m move; 5m move; 10m move

**Commits**

- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [6e59eef](https://github.com/RandyR99/chessengine/commit/6e59eef) 2026-10-19 chessengine: y416xl: port to MAME 0.289 (output proxies, incl. test_promotion)
- [204bc75](https://github.com/RandyR99/mame_for_picochess/commit/204bc75) 2026-10-19 mame_for_picochess: y416xl: 6 levels (5s-10m), beginner levels removed; permanent brain -&gt; ponder/brain = y
- [2281abb](https://github.com/RandyR99/mame_for_picochess/commit/2281abb) 2026-10-17 mame_for_picochess: levels: 5 s minimum per move in all non-Fidelity/H+G .uci files; risc2500 family

</details>

<details><summary><code>y532xl</code> Yeno 532 XL Chess Partner</summary>

- MAME set `y532xl` (532 XL (Yeno)), driver `yeno/532xl.cpp`
- script runs `mess y532xl`
- interface `y532xl.lua`
- retro.ini: elo 1750, levels 8, ponder/brain y

**Test notes**

- y532xl (yeno/532xl.cpp) \| committed 2026-10-19 \| 56/58, 0 illegal \| ep_p \| output proxies; show_info fixed 2026-10-28 (9b3e9ef): display AND LED in is_selected, no keys while an LED is lit \| 8 levels incl. Analysis (DE 10); manual 12.2 searches on the player's time -&gt; ponder y

**Levels:** 5s move; 10s move; 15s move; 30s move; 1m move; 2m move; 40 moves/2h; Analysis

**Commits**

- [558e529](https://github.com/RandyR99/chessengine/commit/558e529) 2026-10-31 chessengine: show_info: polgar (milano, academy) and y532xl read the search information from RAM, without key presses. polgar keeps the same main line list as mega4 at 0x…
- [506d638](https://github.com/RandyR99/chessengine/commit/506d638) 2026-10-30 chessengine: show_info: no key presses during the machine's search. 16 interfaces read their info by pressing keys (INFO, page keys, CL) while the machine thinks; a press…
- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [9b3e9ef](https://github.com/RandyR99/chessengine/commit/9b3e9ef) 2026-10-28 chessengine: y532xl: machine move needs the display AND the square LED (CB-Emu update; the Show Move display lights no LEDs); show_info keys only while no board LED is li…
- [e2aa330](https://github.com/RandyR99/mame_for_picochess/commit/e2aa330) 2026-10-20 mame_for_picochess: uci: tournament headings as '40 moves/2h' instead of '40 moves in 2h'
- [b0359cb](https://github.com/RandyR99/chessengine/commit/b0359cb) 2026-10-19 chessengine: y532xl: port to MAME 0.289 (output proxies)
- [187c397](https://github.com/RandyR99/mame_for_picochess/commit/187c397) 2026-10-19 mame_for_picochess: y532xl: level headings per conventions, levels/ponder in retro.ini

</details>

<details><summary><code>kchal</code> Krypton Challenge</summary>

- MAME set `kchal` (Challenge (1996 version)), driver `newcrest/legend.cpp`
- script runs `mess kchal`
- interface `kchal.lua`
- retro.ini: elo 1775, levels 10, ponder/brain n

**Levels:** 5s move; 10s move; 30s move; 1m move; 3m move; 2m game; 5m game; 10m game; 15m game; 40 moves/2h

**Commits**

- [06f1eba](https://github.com/RandyR99/chessengine/commit/06f1eba) 2026-10-30 chessengine: show_info: kchal, super9cc, berl16, renaissa. kchal (Krypton Challenge): the minus sign in the first character of the score page was ignored (queen-down posi…
- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [e2aa330](https://github.com/RandyR99/mame_for_picochess/commit/e2aa330) 2026-10-20 mame_for_picochess: uci: tournament headings as '40 moves/2h' instead of '40 moves in 2h'
- [40e2404](https://github.com/RandyR99/chessengine/commit/40e2404) 2026-10-18 chessengine: kchal: English names (leseZeichen -&gt; getdigit, German locals)
- [701a72c](https://github.com/RandyR99/chessengine/commit/701a72c) 2026-10-13 chessengine: kchal: fix standby detection that switched the machine off
- [9844e5a](https://github.com/RandyR99/chessengine/commit/9844e5a) 2026-10-13 chessengine: kchal: rework for this plugin and MAME 0.289; add slegend
- [14de866](https://github.com/RandyR99/mame_for_picochess/commit/14de866) 2026-10-13 mame_for_picochess: newcrest: new engines, .uci levels from the level picker, retro.ini fixes

</details>

<details><summary><code>kchala</code> Krypton Challenge</summary>

- MAME set `kchala` (Challenge (1994 version)), driver `newcrest/legend.cpp`, clone of `kchal`
- script runs `mess kchala`
- interface `kchal.lua`
- retro.ini: elo 1775, levels 10, ponder/brain n

**Levels:** 5s move; 10s move; 30s move; 1m move; 3m move; 2m game; 5m game; 10m game; 15m game; 40 moves/2h

**Commits**

- [06f1eba](https://github.com/RandyR99/chessengine/commit/06f1eba) 2026-10-30 chessengine: show_info: kchal, super9cc, berl16, renaissa. kchal (Krypton Challenge): the minus sign in the first character of the score page was ignored (queen-down posi…
- [af6cb5a](https://github.com/RandyR99/chessengine/commit/af6cb5a) 2026-10-28 chessengine: ignore_late_go for 100 interfaces (Phase 3 late-go check): these machines answer the player's move on their own, so a 'go' that arrives after the reply must…
- [e2aa330](https://github.com/RandyR99/mame_for_picochess/commit/e2aa330) 2026-10-20 mame_for_picochess: uci: tournament headings as '40 moves/2h' instead of '40 moves in 2h'
- [40e2404](https://github.com/RandyR99/chessengine/commit/40e2404) 2026-10-18 chessengine: kchal: English names (leseZeichen -&gt; getdigit, German locals)
- [701a72c](https://github.com/RandyR99/chessengine/commit/701a72c) 2026-10-13 chessengine: kchal: fix standby detection that switched the machine off
- [9844e5a](https://github.com/RandyR99/chessengine/commit/9844e5a) 2026-10-13 chessengine: kchal: rework for this plugin and MAME 0.289; add slegend
- [14de866](https://github.com/RandyR99/mame_for_picochess/commit/14de866) 2026-10-13 mame_for_picochess: newcrest: new engines, .uci levels from the level picker, retro.ini fixes

</details>

<details><summary><code>obsidian</code> Perfect Technology Obsidian</summary>

- MAME set `obsidian` (Obsidian), driver `novag/emerclp.cpp`
- script runs `mess obsidian`
- interface `obsidian.lua` → `emerclp.lua`
- retro.ini: elo 2005, levels 11, ponder/brain n

**Levels:** 5s move; 10s move; 30s move; 1m move; 90s move; 3m game; 5m game; 10m game; 15m game; 30m game; 40 moves/1.5h

**Commits**

- [e2aa330](https://github.com/RandyR99/mame_for_picochess/commit/e2aa330) 2026-10-20 mame_for_picochess: uci: tournament headings as '40 moves/2h' instead of '40 moves in 2h'
- [18bf94f](https://github.com/RandyR99/chessengine/commit/18bf94f) 2026-10-14 chessengine: emerclp: port to MAME 0.289; new obsidian interface
- [446c213](https://github.com/RandyR99/mame_for_picochess/commit/446c213) 2026-10-14 mame_for_picochess: emerclp/obsidian: 11 levels per conventions; obsidian new engine

</details>

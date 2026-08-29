# RCA Studio II for MiSTer

MiSTer FPGA core for the RCA Studio II, Studio III/MPT-02 family, and Toshiba Visicom COM-100.

## Install and play

1. Copy the release `.rbf` to e.g. `/media/fat/_Console/` on MiSTer.
2. Put the firmware below in `/media/fat/games/Studio-II/`.
3. Launch the core from `/_Console/` (or wherever you placed it)
3. Use **Load Cartridge** for a `.st2`, `.bin`, or `.rom` game. Use **Load Firmware** only to replace the active machine's firmware temporarily.

`Machine` selects between `Studio II`, `Studio III (PAL)`, `Studio III (NTSC)`, and `Visicom`, in that order. Changes won't take effect until you `Apply and reset`.

| Machine | Required filename | Common filename | Size | MD5 |
|---|---|---|---:|---|
| Studio II | `boot0.rom` | `studio2.rom` | 2 KB | `B37205BF19B197682F00619D05DA194B` |
| Studio III PAL | `boot1.rom` | `studio3_pal.bin` | 4 KB | `A6B94E449BC9EC58A30E1F75D590C558` |
| Studio III NTSC | `boot2.rom` | `studio3_ntsc.bin` | 4 KB | `849A484AA4B2784ECE5C35C39D9D51A8` |
| Visicom | `boot3.rom` | `visicom.rom` | 2 KB | `AEEC6FE3934481E20EB7DB6D5FF56A54` |

The Studio II firmware contains five games: `A1` Doodle, `A2` Patterns, `A3` Bowling, `A4` Freeway, and `A5` Addition. Play instructions for these and more are in [docs/how-to-play.md](docs/how-to-play.md).

## Keypad and CLEAR

The consoles use left keypad A and right keypad B. Mapped on MiSTer keyboard like this:

```text
   Keypad A (left)        Keypad B (right)
    1  2  3                7  8  9
    Q  W  E                U  I  O
    A  S  D                J  K  L
       X                      ,
```

| Key | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 0 |
|---|---|---|---|---|---|---|---|---|---|---|
| Keypad A | `1` | `2` | `3` | `Q` | `W` | `E` | `A` | `S` | `D` | `X` |
| Keypad B | `7` | `8` | `9` | `U` | `I` | `O` | `J` | `K` | `L` | `,` |

`CLEAR` is F3, **Clear** in the OSD, or gamepad Select. Every `A0`–`A9` and `B0`–`B9` action can also be assigned directly through MiSTer's **Define Buttons**.

## Controller profiles

**Mapping: Auto** uses the exact cartridge file's CRC, falling back to 8-way when it has no match, and changes profile after a resident game is selected. **Manual** lets you choose the profile. Keyboard, direct keypad bindings, CLEAR, and the on-screen keypad remain active in both modes. The table below describes the current implementation, including its gaps.

`D-pad 2/8/4/6` means up/down/left/right; an 8-way mapping uses `1/3/7/9` for diagonals.

| Profile | Exact gamepad mapping | Auto routing / limitation |
|---|---|---|
| None | No D-pad, Fire, or Extra mapping | Start still sends the detected selection key |
| Cross | D-pad `2/8/4/6`, Fire `5`, Extra `0` | Gamepad 0 -> A, gamepad 1 -> B |
| Space War | Fire -> `A2`; left/right -> `B4/B6` | One gamepad drives both keypads |
| Freeway | Up/down -> `A2/A8`; left/right -> `B4/B6` | Resident Freeway expects `A4/A6`, so mapped steering is currently wrong |
| Bowling | Up/down -> `A2/A8`; Fire -> `A5` | A only; alternating player B is not mapped |
| Baseball | Gamepad 0 Fire -> `A5`; gamepad 1 up/down/Fire -> `B2/B8/B5` | Fixed batter-A/pitcher-B mapping; role-swapped A movement is missing |
| Homebrew | D-pad -> A 8-way and B cross; Fire -> `B0` | One gamepad drives both; Start varies by recognized title |
| Gunfighter | D-pad `B2/B8/B4/B6`, Fire `B5`, Extra `B0` | One gamepad on B; **Players: 2** splits the same layout across A/B |
| 8-way | D-pad `1`–`9`, Fire `5`, Extra `0` | One gamepad sends the same mapping to A and B |
| Doodle | D-pad B 8-way, Fire `B5`, Extra `B0` | Always gamepad 0 on B; Start selects `A1` |
| 2P Homebrew | D-pad `2/8/4/6`, Fire `0` | Gamepad 0 -> A, gamepad 1 -> B |
| Clear-only | No profile inputs, including Start | Select/CLEAR and direct bindings still work |
| Paddle | Up/down `B2/B8`, left/right `B4/B6`, Fire `B5` | B only; two-player paddle control is not implemented |

**Players: Auto** uses the routing above. **1** makes gamepad 0 drive every implemented side; **2** normally routes gamepad 0 to A and gamepad 1 to B. Doodle remains gamepad 0/B-only; Paddle remains B-only (gamepad 1 in mode 2); Bowling remains A-only.

Start normally sends the one selection key stored for the detected cartridge; it is not a macro for mode, difficulty, or game-code setup. Gunfighter, 8-way, and Doodle always send `A1`; Clear-only sends none. Consequently, the generic 8-way fallback does not send the `A0` required by Visicom cartridges—bind/use `A0` directly. Auto detection is file-specific and fallback mappings are only conveniences, not verified controls for every title.

## On-screen keypad

**Stick Keypad** assigns the numstick overlay to A or B. The right stick selects 1–9, the left stick selects 0, and holding a direction for about half a second registers it. Nudge and release the right stick for 5.

## Project information

Current implementation notes and known verification gaps are in [docs/development.md](docs/development.md); planned work is in [roadmap.md](roadmap.md).

Original core by Jason Coombes, with MiSTer integration and early Pixie work by Flandango and later contributions by Alan Steremberg and Elle Ball. See the [full credits](CREDITS.md) for detailed acknowledgements. GPL-2.0-or-later; see file headers and [LICENSE](LICENSE).

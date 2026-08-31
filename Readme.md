# RCA Studio II for MiSTer

MiSTer FPGA core for the RCA Studio II, Studio III/MPT-02 family, and Toshiba Visicom COM-100.

## Install and play

Copy the release `.rbf` to e.g. `/media/fat/_Console/` on MiSTer.

Put the four native firmware files below in `/media/fat/games/Studio-II/`.

Put the user-supplied `chip8.bin` in the same directory as your CHIP-8 games
for automatic loading, or load it manually.

Launch the core from `/_Console/` (or wherever you placed it).

Use **Load Cartridge** for a `.st2`, `.bin`, or `.rom` game, or **Load
CHIP-8** for a classic `.ch8` program. Use **Load Firmware** only to replace
the active machine's native firmware temporarily; use **Load CHIP-8
Interpreter** only for the separate `chip8.bin` cache.

`Machine` selects between `Studio II`, `Studio III (PAL)`, `Studio III (NTSC)`, and `Visicom`, in that order. Changes won't take effect until you `Apply and reset`.

| Machine | Autoload filename | Common filename | Size | MD5 |
|---|---|---|---:|---|
| Studio II | `boot0.rom` | `studio2.rom` | 2 KB | `B37205BF19B197682F00619D05DA194B` |
| Studio III PAL | `boot1.rom` | `studio3_pal.bin` | 4 KB | `A6B94E449BC9EC58A30E1F75D590C558` |
| Studio III NTSC | `boot2.rom` | `studio3_ntsc.bin` | 4 KB | `849A484AA4B2784ECE5C35C39D9D51A8` |
| Visicom | `boot3.rom` | `visicom.rom` | 2 KB | `AEEC6FE3934481E20EB7DB6D5FF56A54` |
| CHIP-8 interpreter | `chip8.bin` | `chip8.bin` | 768 bytes | `9F037435B6721BE9EE91DC93293E52CE` |

[Marcel van Tongeren's Studio-family interpreter](https://www.emma02.hobby-site.com/studio_chip8.html)
is supported but is not bundled. Supply its 768-byte image as `chip8.bin` and
either load it manually or place it in the same directory as your CHIP-8 games.

The Studio II firmware contains five games: `A1` Doodle, `A2` Patterns, `A3` Bowling, `A4` Freeway, and `A5` Addition. Play instructions for these and more are in [docs/how-to-play.md](docs/how-to-play.md).

## Keypad and CLEAR

The keyboard is mapped like this:

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

For CHIP-8, virtual keys `0`–`9` use keypad A `0`–`9`, while `A`–`F` use
keypad B `1`–`6` (keyboard `7`, `8`, `9`, `U`, `I`, `O`). The automatic
gamepad profile maps D-pad up/left/down/right to CHIP-8 `5/7/8/9`, Start to
`1`, Fire to `F`, and Extra to `0`. Programs choose their own layouts, so
keyboard input, direct keypad bindings, manual profiles, and Numstick remain
available when a program uses something else.

The interpreter targets classic Studio-family CHIP-8 with program space
`$0200`–`$0AFF` and about `$A0` bytes of writable game RAM at virtual
`$0B00`–`$0B9F`, backed by physical `$0800`–`$089F`. Programs needing self-modifying program memory, jumps/calls
into `$0800`–`$0BFF`, more RAM, CHIP-8X, Super-Chip, or XO-CHIP may fail.
Visicom is unsupported.

**Sound: Off** silences the output without stopping or resetting the selected machine's
tone generator. Turning sound back on resumes the live beeper or tone state.

**Beeper tuning** affects the Studio II only. Medium is the default and follows
the December 1976 RCA demonstration unit at approximately 625 Hz fresh and
502.4--502.5 Hz sustained. Low and High retain the same pitch curve, timing,
release, and retrigger behavior while scaling the complete curve downward or
upward. The option is disabled for the Studio III and Visicom.

## Controller profiles

**Mapping: Auto** selects a profile from the exact cartridge file's CRC, falls back to 8-way when there is no match, and changes profile after a resident game is selected. **Manual** lets you select a profile directly. Keyboard input, direct `A0`–`B9` bindings, CLEAR, and the on-screen keypad remain available in either mode.

Gamepad 0 gets the controls for the title's primary one-player game or mode. That may be keypad A, keypad B (as in Squash), or a combination of both used by one player.

Automatic profile coverage is intentionally incomplete. Use **Mapping: Manual**
when a title has no verified profile or needs different controls.

## Numstick (On-screen keypad)

**Numstick** assigns the numstick overlay to A or B. The right stick selects 1–9, the left stick selects 0, and holding a direction for about half a second registers it. Nudge and release the right stick for 5.

## Project information

Original core by Jason Coombes, with MiSTer integration and early Pixie work by Flandango and later contributions by Alan Steremberg and Elle Ball. See the [full credits](CREDITS.md) for detailed acknowledgements. GPL-2.0-or-later; see file headers and [LICENSE](LICENSE).

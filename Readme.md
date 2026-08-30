# RCA Studio II for MiSTer

MiSTer FPGA core for the RCA Studio II, Studio III/MPT-02 family, and Toshiba Visicom COM-100.

## Status

All outstanding high priority fixes are done: NE555 beeper fine-tuning and pitch-modeling is implemented, Visicom instability is resolved, and the Studio III NTSC horizontal line issue related to using the wrong BIOS is resolved (check the BIOS hashes below; they have been corrected since the initial core release). The beeper emulation is now modeled directly on reference recordings for pitch range and curve, retrigger behavior, and timbre. While still imperfect, in my opinion this core represents the best currently available sound emulation for this hardware.

## Install and play

1. Copy the release `.rbf` to e.g. `/media/fat/_Console/` on MiSTer.
2. Put the four native firmware files below and the user-supplied `chip8.bin`
   in `/media/fat/games/Studio-II/`.
3. Launch the core from `/_Console/` (or wherever you placed it).
4. Use **Load Cartridge** for a `.st2`, `.bin`, or `.rom` game, or **Load
   CHIP-8** for a classic `.ch8` program. Use **Load Firmware** only to replace
   the active machine's native firmware temporarily.

`Machine` selects between `Studio II`, `Studio III (PAL)`, `Studio III (NTSC)`, and `Visicom`, in that order. Changes won't take effect until you `Apply and reset`.

| Machine | Required filename | Common filename | Size | MD5 |
|---|---|---|---:|---|
| Studio II | `boot0.rom` | `studio2.rom` | 2 KB | `B37205BF19B197682F00619D05DA194B` |
| Studio III PAL | `boot1.rom` | `studio3_pal.bin` | 4 KB | `A6B94E449BC9EC58A30E1F75D590C558` |
| Studio III NTSC | `boot2.rom` | `studio3_ntsc.bin` | 4 KB | `849A484AA4B2784ECE5C35C39D9D51A8` |
| Visicom | `boot3.rom` | `visicom.rom` | 2 KB | `AEEC6FE3934481E20EB7DB6D5FF56A54` |
| CHIP-8 interpreter | `chip8.bin` | `chip8.bin` | 768 bytes | `9F037435B6721BE9EE91DC93293E52CE` |

[Marcel van Tongeren's Studio-family interpreter](https://www.emma02.hobby-site.com/studio_chip8.html)
is required but is not bundled: its available terms include a non-commercial
restriction and are not GPL-compatible. Name the user-supplied 768-byte image
`chip8.bin` and keep it in the same directory as the `.ch8` programs. When a
program is selected, MiSTer automatically loads that companion first and then
selects the interpreter on Studio II or either Studio III. With the layout
above, keep `.ch8` files directly in `/media/fat/games/Studio-II/`; a program in
a subdirectory needs another `chip8.bin` beside it. Loading a normal cartridge
or native firmware returns to that machine's previous firmware. CHIP-8 loading
is disabled on Visicom.

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
keypad B `1`–`6` (keyboard `7`, `8`, `9`, `U`, `I`, `O`). Games choose their
own layouts, but the common movement cluster is useful enough for one automatic
profile: D-pad up/left/down/right maps to CHIP-8 `5/7/8/9`, Start maps to `1`,
Fire to `F`, and Extra to `0`. Keyboard, direct keypad bindings, manual profiles,
and Numstick remain available when a program uses something else.

The interpreter targets classic Studio-family CHIP-8 with program space
`$0200`–`$0AFF` and about `$A0` bytes of writable game RAM at virtual
`$0B00`–`$0B9F`, backed by physical `$0800`–`$089F`. Programs needing self-modifying program memory, jumps/calls
into `$0800`–`$0BFF`, more RAM, CHIP-8X, Super-Chip, or XO-CHIP may fail.
Visicom is unsupported.

**Sound: Off** silences the output without stopping or resetting the selected machine's
tone generator. Turning sound back on resumes the live beeper or tone state.

## Controller profiles

**Mapping: Auto** selects a profile from the exact cartridge file's CRC, falls back to 8-way when there is no match, and changes profile after a resident game is selected. **Manual** lets you select a profile directly. Keyboard input, direct `A0`–`B9` bindings, CLEAR, and the on-screen keypad remain available in either mode.

Gamepad 0 gets the controls for the title's primary one-player game or mode. That may be keypad A, keypad B (as in Squash), or a combination of both used by one player.

The profile system is not yet complete. There are some issues. Use the Manual option, etc. if needed.

## Numstick (On-screen keypad)

**Numstick** assigns the numstick overlay to A or B. The right stick selects 1–9, the left stick selects 0, and holding a direction for about half a second registers it. Nudge and release the right stick for 5.

I plan on changing this to allow control of one keypad's 1-9 square with each stick, with A0 and B0 being automapped to L / R potentially for full coverage. Not entirely sure yet. At
the very least it will be useful for testing, so it will probably be useful to others as well.

## Project information

Original core by Jason Coombes, with MiSTer integration and early Pixie work by Flandango and later contributions by Alan Steremberg and Elle Ball. See the [full credits](CREDITS.md) for detailed acknowledgements. GPL-2.0-or-later; see file headers and [LICENSE](LICENSE).

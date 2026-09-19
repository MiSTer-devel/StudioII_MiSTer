# RCA Studio II for MiSTer

MiSTer FPGA core for the RCA Studio II, RCA Studio III/Conic MPT-02 family, and Toshiba Visicom COM-100.

Supported hardware includes:
* RCA Studio II
* RCA Studio III (unreleased)
* Academy Apollo 80
* Conic M-1200
* Hanimex MPT-02
* Mustang 9016
* Sheen M-1200
* Soundic Victory (MPT-02)
* Toshiba Visicom COM-100
* Trevi M-1200

## Install

Copy the release .rbf to e.g. /media/fat/_Console/ on MiSTer.

Put the 4 BIOS files below in /media/fat/games/Studio-II/. [OpenStudio2](https://github.com/meauxdal/OpenStudio2) is bundled for CHIP-8 support. BIOS images are not included.

| Machine | MiSTer filename | Common filename | Size | MD5 |
|---|---|---|---:|---|
| Studio II | boot0.rom | [BIOS] RCA Studio II (USA).bin | 2 KB | B37205BF19B197682F00619D05DA194B |
| Studio III PAL | boot1.rom | studio3_pal.bin | 4 KB | A6B94E449BC9EC58A30E1F75D590C558 |
| Studio III NTSC | boot2.rom | studio3_ntsc.bin | 4 KB | 849A484AA4B2784ECE5C35C39D9D51A8 |
| Visicom | boot3.rom | visicom.rom | 2 KB | AEEC6FE3934481E20EB7DB6D5FF56A54 |

The above is not comprehensive; other firmwares are also compatible and can also be autoloaded by name as well as manually. Each machine remembers its own firmware during the session.

## Keypad and CLEAR

Keypad A and B are called "Keyboards" in RCA documentation. Keypad is used instead to avoid confusion. 

The keypads are mapped to the MiSTer keyboard like this:

```text
   Keypad A (left)        Keypad B (right)
    1  2  3                7  8  9
    Q  W  E                U  I  O
    A  S  D                J  K  L
       X                      ,
```

| Key | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 0 |
|---|---|---|---|---|---|---|---|---|---|---|
| Keypad A | 1 | 2 | 3 | Q | W | E | A | S | D | X |
| Keypad B | 7 | 8 | 9 | U | I | O | J | K | L | , |

## CHIP-8

The bundled OpenStudio2 CHIP-8 interpreter uses separate 4 KB CHIP-8 RAM. Marcel van Tongeren's [Studio II CHIP-8 interpreter](https://github.com/etxmato/emma_02/blob/master/data/StudioII/chip8.bin) can also be loaded (768 bytes; MD5 9F037435B6721BE9EE91DC93293E52CE).

CHIP-8 uses the COSMAC VIP keypad:

```text
    MiSTer keyboard       CHIP-8
       1 2 3 4            1 2 3 C
       Q W E R            4 5 6 D
       A S D F            7 8 9 E
       Z X C V            A 0 B F
```

This keyboard layout is active only while a CHIP-8 program is loaded. Direct
keypad bindings and Numstick continue to use keypad A for `0`–`9` and keypad B
`1`–`6` for `A`–`F`.

The **CHIP-8** gamepad profile maps D-pad Up/Left/Down/Right to 5/7/8/9, Start to 1, Fire to F, and Extra to 0. There is probably a better mapping. Please create an issue if you have a suggestion.

Marcel van Tongeren's chip8.bin interpreter has additional memory limitations. See Marcel van Tongeren's [informational page](https://emma02.hobby-site.com/studio_chip8.html) for more details.

CHIP-8 cannot be used on Visicom due to the lack of a CHIP-8 interpreter.

## Options

**NE555 pitch** adjusts the Studio II and Visicom beeper tuning.

**CDP1863 pitch** only applies to Studio III NTSC. The PAL option applies the CDP1864 divide-by-four stage for PAL-equivalent pitch on NTSC. Sound and the applicable pitch control follow the video controls in the **Audio & Video** submenu.

The **Palettes** submenu provides built-in presets for Studio II, both Studio III variants, and Visicom. Studio II and Visicom custom palettes use 16-byte MiSTer Game Boy `.gbp` files. Studio III custom palettes use a headerless `.pal` file containing eight sequential RGB888 entries (24 bytes); trailing bytes are ignored. Loading a palette changes colour immediately without resetting the machine. The custom-file row is shown only while that machine's **Custom** preset is selected. Example `.gbp` and `.pal` palettes are in [palettes](palettes/).

The Studio III **Prototype** preset approximates photographs of the lost Studio III demo. It is a display-referred interpretation, not a measurement of the prototype's electrical output. **Warm** and **Cool** are aesthetic alternatives for convenient comparison.

**Clear** initializes (resets) the game or firmware you have running. It's a physical button on the hardware.

**Load Software** accepts conventional cartridge images and paged `.st2` packages. **Load CHIP-8** remains a separate top-level action.

**Unload Software** ejects without resetting; video remains active and the previous firmware or resident-game mapping becomes visible again.

**Unload Software and Reset** ejects the active cartridge or CHIP-8 program and resets the machine.

**Machine** and **Apply and Reset** remain on the main menu so the full Studio II family is immediately visible. The **System** submenu contains only the less frequent Machine ROM and CHIP-8 Core replacement actions. Clear, Reset, loading ordinary software, and both unload actions also remain on the main menu.

## Controller profiles

The top-level Mapping, Joystick, Players, and Numstick controls stay immediately accessible. **Mapping: Auto** selects a controller profile from the cartridge CRC, falling back to 8-way for unknown games. Resident games can also select their profiles automatically. **Manual** exposes direct Joystick profile selection. Game-specific controls are listed in [docs/how-to-play.md](docs/how-to-play.md).

## Numstick (on-screen keypad)

**Numstick** assigns the overlay to keypad A or B. The right stick selects 1–9 and the left stick selects 0. Hold a direction for about half a second to register it; nudge and release the right stick for 5.

## Studio IV

Studio IV is not supported.

## Project information

Original core by Jason Coombes; MiSTer integration and Pixie work by Flandango; later contributions by Alan Steremberg and Elle Ball. See [CREDITS.md](CREDITS.md) for detailed acknowledgements.

GPL-2.0-or-later; see file headers and [LICENSE](LICENSE). OpenStudio2 is licensed under [MIT](/rom/openstudio2-LICENSE.txt).

# RCA Studio II for MiSTer

MiSTer FPGA core for the RCA Studio II, Studio III/MPT-02 family, and Toshiba Visicom COM-100.

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

Put the 4 BIOS files below in /media/fat/games/Studio-II/. [OpenStudio2](https://github.com/meauxdal/OpenStudio2) is bundled for CHIP-8 support. BIOS images can be found in the Emma 02 GitHub repository, e.g. [Studio II](https://github.com/etxmato/emma_02/blob/master/data/StudioII/studio2.rom).

| Machine | MiSTer filename | Common filename | Size | MD5 |
|---|---|---|---:|---|
| Studio II | boot0.rom | studio2.rom | 2 KB | B37205BF19B197682F00619D05DA194B |
| Studio III PAL | boot1.rom | studio3_pal.bin | 4 KB | A6B94E449BC9EC58A30E1F75D590C558 |
| Studio III NTSC | boot2.rom | studio3_ntsc.bin | 4 KB | 849A484AA4B2784ECE5C35C39D9D51A8 |
| Visicom | boot3.rom | visicom.rom | 2 KB | AEEC6FE3934481E20EB7DB6D5FF56A54 |

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
    1  2  3  C
    4  5  6  D
    7  8  9  E
    A  0  B  F
```

- 0–9 map to keypad A 0-9
- A–F map to keypad B 1–6

The **CHIP-8** gamepad profile maps D-pad Up/Left/Down/Right to 5/7/8/9, Start to 1, Fire to F, and Extra to 0. There is probably a better mapping. Please create an issue if you have a suggestion.

Marcel van Tongeren's chip8.bin interpreter has additional memory limitations. See Marcel van Tongeren's [informational page](https://emma02.hobby-site.com/studio_chip8.html) for more details.

CHIP-8 works on Studio II and III, but not on Visicom.

OpenStudio2's current `Fx0A` key wait is level-sensitive. A single physical press
can therefore satisfy several consecutive waits before release; Clock Program's
six-digit time entry is a confirmed affected case. A CHIP-8-only press/release
latch matching Marcel's behavior is planned.

Some original-era programs that call native VIP routines remain incompatible
with OpenStudio2. See the [compatibility ledger](docs/os2-early-chip8.md) for
reported results, known blockers, and the status of Marcel interpreter checks.
The 1,536-byte `Snoopy Cosmac picture.ch8` is one such hybrid image, but it does
not need native-call support: use the portable 296-byte
`Snoopy picture [Marco Varesio, 2015].ch8` conversion instead.

## Options

**NE555 pitch** adjusts the Studio II and Visicom beeper tuning.

**CDP1863 pitch** only applies to Studio III NTSC. The PAL option applies the CDP1864 divide-by-four stage for PAL-equivalent pitch on NTSC.

**Load Palette** allows setting a 2-color (Studio II, CHIP-8) or 4-color (Visicom) color palette. MiSTer Game Boy .gbp palettes are supported. Example palettes are in [palettes](palettes/).

**Clear** initializes (resets) the game or firmware you have running. It's a physical button on the hardware.

**Unload Cartridge** ejects without resetting; video remains active and the previous firmware or resident-game mapping becomes visible again.

**Unload Cartridge and Reset** ejects the active cartridge and resets the machine. 

## Controller profiles

**Mapping: Auto** selects a controller profile from the cartridge CRC, falling back to 8-way for unknown games. Resident games can also select their profiles automatically. **Manual** allows direct profile selection. Game-specific controls are listed in [docs/how-to-play.md](docs/how-to-play.md).

## Numstick (on-screen keypad)

**Numstick** assigns the overlay to keypad A or B. The right stick selects 1–9 and the left stick selects 0. Hold a direction for about half a second to register it; nudge and release the right stick for 5.

## Studio IV

Studio IV is not supported.

## Project information

Original core by Jason Coombes; MiSTer integration and Pixie work by Flandango; later contributions by Alan Steremberg and Elle Ball. See [CREDITS.md](CREDITS.md) for detailed acknowledgements.

GPL-2.0-or-later; see file headers and [LICENSE](LICENSE). OpenStudio2 is licensed under [MIT](/rom/openstudio2-LICENSE.txt).

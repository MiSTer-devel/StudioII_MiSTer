# RCA Studio II for MiSTer

MiSTer FPGA core for the **RCA Studio II** (1977), with support for the Studio III family and Toshiba Visicom COM-100.

![status](https://img.shields.io/badge/status-playable-brightgreen)

## Status

- Studio II (monochrome, NTSC) support
- Studio III (color, PAL & NTSC) support (Conic MPT-02 clones)
- Visicom (color, NTSC) support
- Compatibility across all known software; including titles like azya52's [`race`](https://github.com/azya52/rcastudioii) homebrew and Realm Of Illusion's [`noshaders`](https://www.pouet.net/prod.php?which=77744) demo by frog

### Known issues / open verification

- Visicom software can behave unexpectedly (visual glitches, hanging). The conditions for this are still under investigation. It is currently recommended to reload the core before loading Visicom games and to use .st2 files.
- Beeper frequency needs additional fine tuning. 
- Direct video has not yet been tested at time of writing.
- Not every game and mode has an automap profile, and not all known software is present in the hash table.

**Note**: If upgrading from the `RCA-StudioII` to the `Studio-II` core, delete or rename all related `RCA-StudioII` or `Studio-II` config files from `/media/fat/config`. If you get scaler issues, this should fix it. Note also that for Studio II's BIOS, `boot.rom` is now `boot0.rom`.

## Features

- RCA Studio II, Studio III PAL, Studio III NTSC and Visicom machine modes.
- Headered `.st2` cartridge support (in addition to flat `bin` / `.rom`)
- Automatic per-game joystick profiles by game hash. Many games can be played with effectively no setup.
- Additional automapping for each game mode in the Studio II firmware.
- Auto / 1 / 2-player controller routing.
- Direct controller bindings for every key on both 10-key keypads.
- Jaguar-style analog-stick on-screen keypad (`Stick Keypad`).
- Integer scaling modes.
- HDMI video sync is preserved on `Clear` and game switches within the same region.

## Installing

Copy a release from `releases/` to e.g. `/media/fat/_Console/` on MiSTer.

Place BIOS files in `/media/fat/games/Studio-II/`:

| Machine         | Boot slot / filename | Recommended BIOS image | Size | MD5                                |
| --------------- | -------------------- | ---------------------- | ---: | ---------------------------------- |
| Studio II       | `boot0.rom`          | Studio II              | 2 KB | `B37205BF19B197682F00619D05DA194B` |
| Studio III PAL  | `boot1.rom`          | Victory (PAL)          | 4 KB | `5E261010D361A378EAB13F543A96D3C5` |
| Studio III NTSC | `boot2.rom`          | Studio III (NTSC)      | 2 KB | `F2EBBF8FA4A2F8509C041B6F07E55C5A` |
| Visicom         | `boot3.rom`          | Visicom                | 2 KB | `AEEC6FE3934481E20EB7DB6D5FF56A54` |

You can load a different firmware or return to the firmware (to play the resident games, for example) from a cartridge using the `Load Firmware` option, which accepts a `.bin` or `.rom` image. The BIOS is loaded into the currently selected machine's slot.

## Controls

The Studio II has two 10-key keypads (called Keyboard A and B in official documentation; we use Keypad here instead to avoid confusion with the usual modern usage of keybooard). Keypad A is the left keypad (`EF3`) and keypad B is the right keypad (`EF4`).

```text
   Keypad A (left)        Keypad B (right)
    1  2  3                7  8  9
    Q  W  E                U  I  O
    A  S  D                J  K  L
       X                      ,
```

| Key | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 0 |
|---|---|---|---|---|---|---|---|---|---|---|
| **Keypad A** | `1` | `2` | `3` | `Q` | `W` | `E` | `A` | `S` | `D` | `X` |
| **Keypad B** | `7` | `8` | `9` | `U` | `I` | `O` | `J` | `K` | `L` | `,` |

**CLEAR** is **F3**, `Clear` in the OSD, or gamepad Select. The core keeps video timing alive through CLEAR so games that use it as part of normal startup do not force an HDMI resync.

### Joystick profiles

In `Mapping: Auto`, the core computes a CRC16 of the cartridge and chooses a profile. The OSD Joystick row is updated to show the detected profile; `Manual` profile selection is also available. Keyboard, on-screen keypad and direct A0-A9/B0-B9 bindings remain active in either mode.

| Profile | Up | Down | Left | Right | Fire | Extra | Start | Typical use |
|---|---|---|---|---|---|---|---|---|
| `CROSS` | `2` | `8` | `4` | `6` | `5` | `0` | `A1` | MPT-02 cross-layout games |
| `SPACEWAR` | — | — | `B4` | `B6` | `A2` | — | `A1` | Space War |
| `FREEWAY` | `A2` | `A8` | `B4` | `B6` | — | — | profile-specific | Freeway-style asymmetric controls |
| `BOWLING` | `A2` | `A8` | — | — | `A5` | — | profile-specific | Bowling |
| `BASEBALL` | `B2` | `B8` | — | — | `A5` / `B5` | — | `A0` | Baseball |
| `HOMEBREW` | `2` | `8` | `4` | `6` | `B0` | — | game-specific | Robson 1P homebrew; diagonals use `1/3/7/9` |
| `HB2P` | `2` | `8` | `4` | `6` | `0` | — | `A1` | Hockey / Combat |
| `GUNFIGHTER` | `B2` | `B8` | `B4` | `B6` | `B5` | `B0` | `A1` | Gunfighter / Moonship Battle |
| `8WAY` | `2` | `8` | `4` | `6` | `5` | `0` | `A1` | General 8-way fallback |
| `DOODLE` | `B2` | `B8` | `B4` | `B6` | `B5` | `B0` | `A1/A2` | BIOS Doodle / Patterns |
| `PADDLE` | `B2` | `B8` | `B4` | `B6` | `B5` | — | `A1` | Tennis / Squash single-player mapping |
| `CLEAR_ONLY` | — | — | — | — | — | — | — | Addition / explicit no-controller cases |
| `NONE` | — | — | — | — | — | — | `A1` | No automatic keypad mapping |

`Players: Auto` uses each profile's natural layout. `1` keeps gameplay on gamepad 0; `2` splits two-sided profiles between the two gamepads.

### On-screen keypad

`Stick Keypad` can place the numstick overlay on keypad A or B.

- Right stick: keys 1-9.
- Left stick: 0.
- Nudge and release the right stick: 5.
- Hold for approximately 0.5 seconds to register a key.

## Credits

- **Jason Coombes** ([@JasonA-dev](https://github.com/JasonA-dev)) — Original core design and implementation. His 2022–2025 work remains a load-bearing part of the project.
- **Flandango** ([@Flandango](https://github.com/Flandango)) — MiSTer integration and early Pixie work.
- **Alan Steremberg** ([@alanswx](https://github.com/alanswx)) — Later 2026 CPU, video, timing and machine-support work.
- **Elle Ball** ([@meauxdal](https://github.com/meauxdal)) — MiSTer core improvements (OSD layout tuning, integer scaling fixes, automatic controller mappings, HDMI sync loss mitigation), extensive library research and testing, documentation.

Accuracy and compatibility work also relies heavily on:

- **Paul Robson** — Studio II emulator and homebrew software.
- **MAME contributors** — Studio II, CDP1861, Studio III and Visicom reference implementations.
- **Marcel van Tongeren** — Emma 02.
- **Andrew Modla** — `rca-studio2`.
- **Eric Smith** — COSMAC VHDL reference implementation.
- **dmadole** — AVI1861 hardware replacement.
- **kanpapa** — `cosmac_mbc`.
- **RCA documentation and community hardware researchers** — Primary documentation, measurements and hardware observations.

Special thanks:

- **Kevin Bunch** — Reference Studio II capture and critical hardware insight.
- **Hagley Museum and Library** — Historical materials and preservation.

## Licence

GPL-2.0-or-later; see file headers. `rtl/cosmac.v` and `rtl/reference/cosmac.vhdl` are GPL-3.0 reference code and are not compiled into the core.

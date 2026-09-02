# Controller implementation

This document covers the current controller architecture. Game-specific controls
and selection sequences belong in `how-to-play.md`; user-facing operation belongs
in `Readme.md`.

## Input paths

`Studio-II.sv` receives MiSTer joystick, keyboard, direct keypad, and Numstick
inputs. `rtl/rcastudioii.sv` combines them into the two physical ten-key keypad
masks consumed through EF3 and EF4. CLEAR remains independent of both keypads.

The OSD exposes `Mapping`, `Joystick`, `Players`, and `Numstick`. Automatic mode
selects a profile from the cartridge CRC or resident-game key, writes it back to
OSD bits `[5:2]`, and disables manual editing of that row. Manual mode uses the
selected profile directly. CHIP-8 selects its common `5/7/8/9` movement profile;
Start maps to `1`, Fire to `F`, and Extra to `0`.

## Identification

Cartridge profiles use CRC16-CCITT over the exact downloaded bytes, with
polynomial `0x1021` and initial value `0xFFFF`. Headered and raw images therefore
have different CRCs. Resident games are identified from their firmware selection
key.

The generic `8-way` fallback is the neutral controller profile. D-pad cardinals
produce keypad A `2/4/6/8`, diagonals produce `1/3/7/9`, Fire produces `A5`,
and Extra produces `A0`. Start supplies the identified title's start key
(`A1` for the ordinary Studio fallback and `A0` for the Visicom cartridge
fallback), while Select remains the independent CLEAR control. The directional,
centre-`5`, and `0` positions match the explicitly marked Visicom joystick.
Do not extend that observation to MPT-02-family joysticks without independent
documentation or hardware evidence.

Before adding a mapping, verify the exact image, container, machine, start
sequence, keypad roles, and mapped actions. `tools/cart-crc.sh` hashes explicitly
supplied images; `crc16-ccitt-hashes-by-game_20260829.txt` is the dated grouped
inventory. Hash newer in-repo builds directly before adding them.

The `Climb/Outbreak` profile maps D-pad up/left/right to `A2/A4/A6`, Fire to
the `B1` replay key, and Extra plus left/right to Outbreak's simultaneous
`A4+B4` / `A6+B6` fast movement. `Space Explorer` maps the eight directions on
keypad B, Fire to `A0`, and Extra to the `B5` target lock; Start is idle because
the program begins directly.

The `Race` profile keeps the eight directional keys on keypad A and maps Fire
to an independent `A2`. The core can therefore present `A2` acceleration and a
direction key simultaneously; whether the original keypad accepts every such
chord remains a hardware-testing question.

The `Freeway` profile maps Start to `B0` for normal mode, Fire to `A2` for
acceleration, Extra to `A0` for hard mode, and D-pad Down to the `A8` brake.
Its left/right steering remains on `B4/B6`.

The `Tennis` profile defaults to one-player Squash: Start selects `A1` and the
first controller drives keypad B. With Players set to two, Start selects `A2`
Tennis and the controllers drive keypads A and B respectively. D-pad up/down
maps to `2/8`, left/Fire/right selects racket size `4/5/6`, and Extra maps to
that player's `0` pause key.

## Current boundary

The controller architecture is accepted: verified cartridge profiles,
Auto/Manual mapping, Auto/1/2-player selection, Numstick assignment, and the
manual keypad paths form one coherent input model. The compiled profile system
remains its source of truth; no external replacement or parallel profile path is
planned.

Profile coverage is deliberately open to evidence-backed additions. The five
standard Studio II firmware games currently select their profiles from the first
selection key after reset; the other supported firmware menus do not yet have
equivalent per-machine coverage. Numstick also consumes the analog sticks
without suppressing ordinary left-stick profile movement, so selecting `0` can
produce an unwanted direction. These focused refinements are tracked in the
roadmap without reopening the controller architecture.

Keep any evidence-backed additions in the shared CRC-to-profile table rather
than adding title-specific RTL or profiles that branch internally among several
games. Preserve manual keypad access and leave unknown controls unmapped.

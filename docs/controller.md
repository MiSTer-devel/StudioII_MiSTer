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

Before adding a mapping, verify the exact image, container, machine, start
sequence, keypad roles, and mapped actions. `tools/cart-crc.sh` hashes explicitly
supplied images; `crc16-ccitt-hashes-by-game_20260829.txt` is the current grouped
inventory.

## Current boundary

The compiled profile system is functional but incomplete and is scheduled for
replacement by one external, versioned mapping database. Do not extend it with a
parallel path or title-specific RTL. Until that replacement lands, keep fixes
small, preserve manual keypad access, and leave unknown controls unmapped.

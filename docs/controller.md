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
have different CRCs. Resident games are identified from the first recognized
firmware selection key after reset. Studio II and both Studio III timings map
Doodle/Patterns to the shared Doodle profile and Bowling to Bowling; Studio II
Freeway uses its dedicated profile, while Studio III Blackjack uses the neutral
8-way fallback with numeric entry through the keypads. Visicom maps Doodle and
Patterns to Visicom Art, Bowling to Bowling, Freeway to Freeway, and Addition
to the neutral fallback.

Grand Pack's verified paged image (CRC `1594`) reuses the Studio III selection
decoder on PAL and NTSC: A1/A2 select Doodle, A3 Bowling, and A4/A5 the neutral
8-way fallback. CLEAR re-arms selection; gameplay keys cannot change it. Its
selection does not overwrite the remembered resident-firmware mapping, which
unload restores. Start selects A1. Use the `.st2` image: the raw `EF21` image
needs discontiguous placement that the generic raw loader does not provide.

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

Pinball's raw/headered CRCs `D3E2`/`92BA` select `8-way`. Auto mirrors the
controller onto both pads, so the one-player game on keypad B is playable;
Players 2 separates the pads. Up-left supplies `1` to launch and Extra supplies
`0` to shove. Left/right remain `4/6` flippers.

The `Climber/Outbreak` profile keeps all eight keypad A directions, Fire to
the `B1` replay key, and Extra plus left/right to Outbreak's simultaneous
`A4+B4` / `A6+B6` fast movement. `Space Explorer` maps the eight directions on
keypad B, Fire to `A0`, and Extra to the `B5` target lock; Start is idle because
the program begins directly.

The current `Race` profile uses B4/B6 steering, Up/Fire B2 acceleration and
Down/Extra B5 braking. The user confirms B8 braking from Race's controls;
this mismatch remains open in the audit below. Start currently emits B2.

The `Visicom Art` profile keeps all eight drawing directions and both colour
controls on keypad B. Movement draws; Fire maps to `B5` to cycle forward and
Extra maps to `B0` to cycle backward through red, yellow, blue, and the flashing
move/erase state. Start retains the resident selection key: `A1` for Doodle and
`A3` for Patterns, where releasing `A3` begins or resumes repetition. Patterns
uses `A0` to stop repetition, available through Numstick A or a direct binding.

The `Bowling` profile maps Up/Fire/Down to `2/5/8`. Auto mirrors controller 1
onto both keypads so it follows the firmware's A/B player alternation. Players
set to 2 separates controller 1 onto A and controller 2 onto B.

The `Freeway` profile selects the firmware's machine-specific layout. On Studio
II, Start is normal (`B0`), Extra is hard (`A0`), Fire accelerates (`A2`), Down
brakes (`A8`), and Left/Right steer on `B4/B6`. On Visicom, Start selects
License A/easy (`B0`), Extra selects License B/hard (`B5`), Fire duplicates
D-pad Up acceleration (`B2`), and Down/Left/Right map to `B8/B4/B6`. The two
difficulty choices remain mutually exclusive.

Gunfighter/Moonship Battle and Tennis/Squash share stock eight-way directions,
Fire `5` and Extra `0`. Auto keeps controller 1 on B for solo play; explicit
Players 1 mirrors it onto A/B, and Players 2 splits controllers 1/2 onto A/B.
Start always selects `A1`; select `A2` Tennis/two-player Gunfighter or `A3`
Moonship through keypad A. Players changes routing only. In Auto, use Numstick A
or direct keys for A-side setup; Players 1 exposes all ten digits on both pads.
Gameplay verification of this correction remains pending.

## Initial mapping audit

These are candidates from documented controls and RTL inspection, not completed
play tests. Keep working mappings until replacements pass setup and play.

| Game / existing CRCs | Candidate bucket | Finding / remaining check |
|---|---|---|
| Gunfighter / Moonship (`043E`, `3CDC`) | Stock 8-way; routing separate | Restored 1P mirroring and diagonals. Verify solo Gunfighter, both sides in 1P, independent 2P and Moonship movement. |
| Tennis / Squash (`88FB`, `FB76`) | Stock 8-way; routing separate | Restored 1P mirroring and setup digits. Verify A1/A2 selection, both pads' 4/5/6 racquet choices, A7/A8/A9 speed, both paddles and 0 pause. |
| Race | Stock 8-way on B, or custom acceleration button | User's source excerpt establishes B4/B6 steering; user confirms B2 acceleration and B8 brake. RTL emits B5 for brake. Check exact source/image correspondence and setup before changing profile. |
| Pinball | Stock 8-way on B | Preserve working solo B controls when generic Auto routing changes; check alternating players. |
| Bowling / Baseball | Stock 8-way candidate | Justify direction restrictions; check alternating keypad roles, including fielding after sides swap. |
| Robson games | Assess individually | Check setup digits, B0 fire versus A0 restart, and Pacman's B8 down before sharing layouts. |

For both corrected cartridges, switch Players during play and confirm selection
is unchanged. Exact image bytes and machine must accompany gameplay results;
the existing CRC assignments have not been expanded or revalidated here.

## Current boundary

The compiled profile system remains the implementation source of truth, with
Auto/Manual mapping, Numstick assignment, and manual keypad access. Player
routing and profile restrictions need the focused cleanup tracked in the
roadmap; the current behavior should not be treated as the acceptance target.
No external replacement or parallel profile path is planned.

Profile coverage is deliberately open to evidence-backed additions. All default
firmware menus select an existing shared profile or the neutral fallback from
the first recognized selection key after reset. Numstick also consumes the
analog sticks without suppressing ordinary left-stick profile movement, so
selecting `0` can produce an unwanted direction. This focused refinement remains
tracked in the roadmap without reopening the controller architecture.

Keep any evidence-backed additions in the shared CRC-to-profile table rather
than adding title-specific RTL or profiles that branch internally among several
games. Preserve manual keypad access and leave unknown controls unmapped.

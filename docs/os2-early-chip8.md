# Early CHIP-8 images under OpenStudio2

Static inspection, 2026-09-10. Interpreter reference: neighboring OpenStudio2 checkout at `52ff1dbb1e0f5ebaddf86e31500fe9c7ea68595f`, matching `rom/openstudio2.md`. Inspection focused on `openstudio2.asm`, especially `op_0`, `unsupported`, and memory layout. No build, runtime test, regression, or hardware capture was performed.

## Images

Paths are relative to `software/RCA-Studio-II-Fullset/3 CHIP-8/Cull candidates/1 Games/`. CRC16 is CCITT (`1021`, init `FFFF`), matching the core convention.

| File | Bytes | Logical range | CRC32 | CRC16 |
|---|---:|---|---|---|
| `Chesmac (Raimo Suonio)(1979).ch8` | 2638 | `200-C4D` | `5CFAC198` | `9DDF` |
| `Tick-Tack-Toe (fix)(Joseph Weisbecker)(1977).ch8` | 470 | `200-3D5` | `11A03104` | `BDD6` |
| `Tic-Tac-Toe ([AUD_2464_09_B41_ID23_01].ch8` | 512 | `200-3FF` | `B5FB032B` | `8F18` |
| `Bingo [TCNJ S.572.2, 3](197x).ch8` | 1536 | `200-7FF` | `984371D5` | `86B9` |

SHA-256, in the same order:

```text
f734741b1cadd3a49248e89fe4054d9e8c6c4e88f457021d1cf9655a200f5ed3
40474f473154e467ac9ece7e01656764cdbb16fe6884c6ecc4092ef5a7a7dec9
22d6c108415ff9ed86c7c7fcdcf29563e923f954e06ac938a171d593964072d6
702676f43590720f95e5fc3c334a00a58478b0fca5c082f25c772f54abcaa65a
```

The 470-byte tic-tac-toe image matches the first 470 bytes of the 512-byte image. The latter adds 42 bytes at `3D6-3FF`, including initialized board storage. Both use the same entry routine. All four fit within OS2's 3584-byte program capacity.

## First blockers

Addresses below are logical CHIP-8 addresses and follow actual control flow.

| Image | Startup path | First unsupported instruction |
|---|---|---|
| Chesmac | `200:1248` -> `248:287C` -> `87C:0880` | Native call `0880` |
| Both tic-tac-toe images | `200:02E4` | Native call `02E4` |
| Bingo | `200:604F`, `202:A454`, `204:2386` -> `386:0402` | Native call `0402` |

OS2's `op_0` handles only low bytes `E0` and `EE`; other `0NNN` forms enter the permanent `unsupported` loop. These images therefore encounter unsupported native CDP1802 calls before game input or CHIP-8 drawing.

The calls depend on the original interpreter environment rather than a later CHIP-8 dialect:

- Tic-tac-toe `2E4-2F1` clears physical `03F0-03FF`, used afterward as board state.
- Chesmac `0880-0896` copies data from physical `08E1-0980` to `0CF8-0D97`. Many additional native calls follow, so bypassing the first is insufficient.
- Bingo `0402-040D` uses CDP1802 register conventions and inline data. Additional native helpers occur at `040E`, `0414`, `041A`, and elsewhere.

## Compatibility boundary

OS2 maps CHIP-8 program RAM to physical `1000-1FFF`, V0-VF to `08A0-08AF`, and display memory to `0900-09FF`. It does not reproduce the original interpreter's native memory/register environment.

This makes the native routines fundamentally incompatible without adaptation. For example, tic-tac-toe expects board data at physical `03F0`, while under OS2 logical `03F0` maps to `13F0`. Chesmac likewise uses fixed native addresses that conflict with OS2 code, work RAM, display memory, and program mapping. Simply jumping to native code would neither relocate those addresses nor recreate the required register state.

This inspection establishes the first blocker only. Compatibility beyond a hypothetical native-code port remains untested. OS2 also differs in CHIP-8 behavior including VY-based shifts, I advancement after register transfers, VF preservation on logic operations, wrapping draws without frame wait, and held-key handling for `Fx0A`. Timer cadence, randomness, display assumptions, later memory dependencies, and controls are also unverified.

No standard CHIP-8 opcode defect is demonstrated here, and quirk or timing changes cannot resolve these startup traps.

Useful next evidence would be a fresh-start runtime capture for each exact image recording machine, interpreter revision, input sequence, final CHIP-8 PC/opcode, and native trap PC.

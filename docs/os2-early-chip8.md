# Early CHIP-8 images under OpenStudio2

Static inspection, 2026-09-10. Interpreter authority: neighboring OpenStudio2
checkout at `52ff1dbb1e0f5ebaddf86e31500fe9c7ea68595f`, clean when inspected,
especially `openstudio2.asm` (`op_0`, `unsupported`, and the memory constants).
This is the revision recorded in `rom/openstudio2.md`. No build, interpreter
execution, regression, or hardware capture was performed. Specific reported
failure symptoms and machine/input sequences remain unrecorded.

## Exact images

All paths below are relative to
`software/RCA-Studio-II-Fullset/3 CHIP-8/Cull candidates/1 Games/`.
Hashes cover complete file bytes. CRC16 is CCITT with polynomial `1021` and
initial value `FFFF`, matching the core's identification convention. These
identities do not establish provenance, controls, or controller profiles.

| File | Bytes | Loaded logical range | CRC32 | CRC16 |
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

The 470-byte tic-tac-toe image is byte-identical to the first 470 bytes of
the 512-byte image. The latter has 42 extra bytes at logical `3D6-3FF`,
including nonzero initial board storage. The filename's "fix" does not
indicate a different entry routine: both start with the same native clear.
All four fit within OS2's 3584-byte program capacity; none is oversized.

## First blockers

Addresses in this table are logical CHIP-8 addresses. Paths follow the actual
entry instructions, not a linear decode of sprite data or native code.

| Image | Unconditional startup path | First unsupported instruction |
|---|---|---|
| Chesmac | `200:1248` -> `248:287C` -> `87C:0880` | Native call `0880` |
| Both tic-tac-toe images | `200:02E4` | Native call `02E4` |
| Bingo | `200:604F`, `202:A454`, `204:2386` -> `386:0402` | Native call `0402` |

OS2's `op_0` recognizes low bytes `E0` and `EE` for clear/return and otherwise
branches to the permanent `unsupported` loop. All three calls therefore trap
before reaching game input or a CHIP-8 draw instruction, assuming the accepted
interpreter and payload load correctly. This predicts a startup stall; it is
not an observed screenshot or a diagnosis of every possible hardware symptom.

These are embedded CDP1802 subroutines, not evidence of a later CHIP-8 dialect:

- Tic-tac-toe, `2E4-2F1`: `F8 03 BF F8 F0 AF F8 00 5F 1F 8F 3A EA D4`.
  This sets RF to physical `03F0`, writes zero through RF, increments it,
  loops until its low byte wraps, and returns through `SEP R4`. It clears
  `03F0-03FF`, where the CHIP-8 code subsequently accesses board state using
  `A3F0`, `FD1E`, and register transfers.
- Chesmac, `880-896`: sets RC to `0980`, RD to `0D97`, selects X=RD,
  skips the first decrement, then copies bytes downward with `LDN RC` and
  `STXD`, stopping when RC's low byte is `E1`; returns through `SEP R4`.
  The source range is physical `08E1-0980`, destination `0CF8-0D97`.
  There are numerous further native calls, including `04CA`, `04E6`,
  `0502`, `051E`, and routines at `0Bxx`. Bypassing the first call cannot
  make this image compatible.
- Bingo, `402-40D`: `45 5A E5 8A F4 AA 15 9A 7C 00 BA D4`.
  It reads an inline byte through R5, writes through RA, uses the next byte
  as an address increment, advances R5 again, and returns through R4.
  The startup call is followed by `0001` at `388`, serving as inline
  data, not a separately executed CHIP-8 instruction under that convention.
  Other helpers at `40E` and `414` move data through a register address
  selected by an inline byte; `41A` decrements RA. Later `03FF` uses RB's
  high byte to change RA. These rely on native register conventions.

## Compatibility boundary and remaining questions

OS2 maps logical CHIP-8 RAM to physical `1000-1FFF`, keeps V0-VF at
`08A0-08AF`, and displays from `0900-09FF`. It does not expose an original
interpreter image or its native execution environment at logical addresses.
For example, tic-tac-toe's board is physically at `13F0` under OS2, not
`03F0`. Chesmac's fixed native addresses also conflict with OS2's code,
work RAM, display, and program mapping. Merely jumping to a native routine
at `1NNN` would not relocate its address constants or establish its expected
register state. Treat this as a native-code/environment dependency, not a
missing generic arithmetic opcode or insufficient CHIP-8 RAM.

This inspection establishes the first blocker in each file. It does not
establish complete compatibility after a hypothetical port. OS2's shifts
use VY, register transfers advance I, logic operations preserve VF, draws
wrap without a frame wait, and `Fx0A` accepts held keys. Those implemented
policies must be evaluated separately if execution progresses beyond the
native calls; comments describing VIP compatibility are not hardware proof.
Timer cadence, random behavior, display geometry, later memory assumptions,
and game controls remain unverified. No standard opcode defect is demonstrated
by these startup paths, and changing quirks or timing cannot resolve these
particular entry traps.

Next useful runtime evidence is a bounded fresh-start capture for each exact
image, recording machine, interpreter identity, input sequence, and the last
CHIP-8 PC/opcode plus native trap PC. Builds and regressions require explicit
authorization under `AGENTS.md`; Quartus remains user-run. Existing embedding
verification in `docs/development.md` is still pending. Supporting these native
environments or making separately identified CHIP-8 ports would be additional
scope; no interpreter, RTL, image, or controller profile was changed here.

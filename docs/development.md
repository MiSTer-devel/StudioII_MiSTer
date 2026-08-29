# Development reference

Mutable architecture, implementation state, verification scope, and build notes live here. `CLAUDE.md` contains only permanent repository rules. Current RTL defines what is implemented; primary documentation and measured hardware define the target.

Read the focused references when relevant:

- `docs/how-to-play.md` — game selection and keypad research.
- `docs/beeper-status.md` — Studio II audio evidence and current acceptance criteria.
- `docs/analog-video.md` — direct-video behavior and hardware test procedure.
- `roadmap.md` — planned work.

## Implemented machines

| Machine | Video | Sound | Notes |
|---|---|---|---|
| Studio II | CDP1861, NTSC mono | discrete beeper | primary target |
| Studio III PAL | CDP1864 | CDP1864 tone | 312-line PAL timing |
| Studio III NTSC | CDP1861 + CDP1862 | CDP1863 | 1861 timing with separate colour |
| Visicom COM-100 | CDP1861 + second DMA bitplane | none | separate memory map and fixed palette |

The CPU, DMA video, raw and paged cartridges, four resident firmware slots, machine memory maps, controller profiles, on-screen keypad, integer scaling, and sync-preserving same-standard resets are implemented. The loader intentionally models only 4 KB of cartridge address space; high-page diagnostics such as ST3CTA Tester 3 remain unsupported.

## Module and clock map

`Studio-II.sv` is the MiSTer `emu` top. `rtl/rcastudioii.sv` contains the CPU, memory maps, cartridge loader, keypad/controller mapping, Studio II beeper, and machine selection.

Live video modules:

- `rtl/pixie/cdp1861.v` — Studio II, Studio III NTSC, and Visicom timing/DMA.
- `rtl/pixie/cdp1862.v` — Studio III NTSC colour.
- `rtl/pixie/cdp1863.v` — Studio III NTSC tone and shared divider model.
- `rtl/pixie/cdp1864.v` — Studio III PAL video, colour, and tone timing.
- `rtl/pixie/pixie_video.v` — 1861 wrapper.

`clk_sys` is about 7.040229 MHz. `ce_pix` divides it by four to the approximately 1.760 MHz machine timebase; CPU machine cycles occur every eight `ce_pix` pulses. MiSTer video is resampled into `clk_vid` at about 42.24 MHz and presented to `video_mixer` at about 7.04 MHz, repeating each native pixel four times.

The Verilator harness normally holds `ce_pix` high. Use `--ce4` for reset release, CLEAR, DMA/CPU phase, or other clock-structure work, and `--press-phase N` to sweep phase-sensitive input. The harness instantiates `rtl/rcastudioii.sv`, not the MiSTer top, so it cannot prove HPS boot ordering, Apply classification, or F1/F2 sync preservation.

## Video behavior

The normal output path is:

```text
rcastudioii sync + blanking + RGB
    -> clk_sys/clk_vid resampling
    -> video_mixer (LINE_LENGTH=352)
    -> video_freak
    -> MiSTer framework
```

`video_mixer` derives raster DE from HBlank/VBlank. The core's `video_de`/`bitmap_de` is only for simulation and bitmap capture.

The CDP1861 path has 112 native pixel times and 262 lines per frame. Raster active starts at pixel 24 and is 88 pixels wide. Bitmap DMA occupies pixels 40–103, leaving the authored window 16 pixels from the raster's left edge and eight from the right. Do not move the bitmap window to centre it; adjust porches/blanking and revalidate timing instead.

The CDP1864 path has 112 native pixel times, 312 lines, and a 192-line display. Switching between PAL and NTSC is a real standard change and may make the display resync.

Integer scaling depends on two top-level integration details:

1. `video_mixer.LINE_LENGTH` is 352 (88 active source pixels x4).
2. VS is delayed by one `CE_PIXEL` only on the `video_freak` input so its final active-line count is not overwritten by a same-edge reset.

The OSD exposes scale modes 0–3 with `.SCALE({1'b0, status[12:11]})`; mode 4 is intentionally absent.

## Reset and machine selection

CPU/machine reset and raster reset are separate. `reset` restarts machine state; `video_reset` restarts raster counters and the CPU phase divider only for a hard reset.

| Event | Class | Raster behavior |
|---|---|---|
| Core load, MiSTer reset, unknown download | hard | restarts |
| Cartridge load (F1) | sync-preserving | remains live |
| Manual firmware load (F2) | sync-preserving | remains live |
| Same-standard Apply and reset | sync-preserving | remains live |
| PAL/NTSC Apply and reset | hard | restarts |
| CLEAR | sync-preserving | remains live |

Download type remains latched through the post-download reset stretch because `ioctl_index` is valid only during transfer. Apply/reset records whether the requested machine crosses standards before changing `machine_active`. Hard reset sources always dominate overlaps. CLEAR is normal console operation; its special case leaves the Studio III tone generator running.

The Machine OSD field is staged until **Apply and reset**, except for the short boot-follow path used to restore saved settings. Firmware slots are:

| Machine | File |
|---|---|
| Studio II | `boot0.rom` |
| Studio III PAL | `boot1.rom` |
| Studio III NTSC | `boot2.rom` |
| Visicom | `boot3.rom` |

Studio II firmware is normally 2 KB; each resident BRAM is 4 KB so Studio III firmware fits. F2 writes the active machine's slot. Boot autoload uses index 0 with `ioctl_index[7:6]` selecting the slot.

## Memory and cartridge model

Studio II / Studio III NTSC base behavior:

- `$0000-$07FF`: firmware/resident games.
- `$0800-$09FF`: 512-byte RAM.
- `$0A00-$0BFF`: cartridge window.
- `$0C00-$0DFF`: RAM mirror unless paged cartridge ROM owns it.
- `$0E00-$0FFF`: cartridge window.
- Undecoded reads return `$FF`.

Studio III may use 4 KB firmware and has 64 mirrored 3-bit colour cells in `$0B00-$0BFF`. A DMA offset selects `{offset[7:5], offset[2:0]}`, so one cell covers eight pixels by four logical bitmap rows.

Visicom uses `$0000-$0FFF` for ROM/cartridge, `$1000-$11FF` for 512-byte RAM and plane 0, `$1300-$13FF` for plane 1, and leaves `$1200-$12FF` empty. Its two plane bits select one of four fixed colours.

Raw `.bin`/`.rom` images load from `$0400`. `.st2` is detected from `RCA2` magic and uses its header page table. Page ownership permits cartridge pages `$0C/$0D` to replace the normal RAM mirror. Studio II rejects system pages `$00-$03` and RAM pages `$08-$09`; Studio III also reserves colour page `$0B`; Visicom accepts `$04-$0F` because its RAM is above the cartridge bank. Pages `$10+` are dropped.

Controller automapping hashes exact downloaded bytes using CRC16-CCITT, polynomial `0x1021`, initial value `0xFFFF`. Headered and raw forms have different CRCs even when their payloads match.

## Controller profile implementation

`Mapping` selects Auto or Manual. Auto drives gameplay directly from `auto_profile` and writes that value back to OSD bits `[5:2]`; Manual uses the selected Joystick value. The OSD row is disabled while Auto owns it.

Profiles are implemented in `rtl/rcastudioii.sv`. Their exact user-visible behavior, including player routing and limitations, is documented in `Readme.md`. Game-control evidence belongs in `docs/how-to-play.md`; do not infer controls from a similar title.

For CRC additions, verify the exact Fullset filename, machine, start sequence, keypad/player roles, and every in-game action. Include each known container/header revision. `tools/cart-crc.sh` hashes explicitly supplied images; `docs/crc16-ccitt-hashes-by-game_20260824.txt` is the grouped inventory.

## Hardware-derived constraints

- The Studio II has 512 bytes of paired nibble RAM; bitmap memory runs from `$0900` at top left through `$09FF` at bottom right, eight bytes per logical row, bit 7 leftmost.
- The physical data bus has pull-ups, supporting open-bus reads of `$FF`.
- Physical keypad selection is `N1 AND TPB`; software uses `OUT 2`, which is what the core decodes.
- The CDP1861 requests eight DMA-OUT cycles for each displayed scanline and the CPU supplies bytes through R0. Software repeats 32 logical bitmap rows into 128 active bitmap lines.
- The Studio II is NTSC-only and uses an adjusted RC oscillator; its approximately 1.760 MHz clock is a practical model, not an exact crystal constant.
- CDP1861/CDP1864 EF timing leads nominal line boundaries deliberately. Interrupt and DMA requests are accepted at instruction boundaries, DMA remains asserted until serviced, and parity adaptation may move service by one machine cycle.
- `CON` is captured with each luminance DMA byte. Studio III NTSC is a 1861+1862+1863 machine, not a retimed 1864; its 1863 tone is four times the 1864-integrated tone for the same latch.
- In the CPU Cx row, `C4` is NOP and `C5-C7`/`CC-CF` are long skips.

## Current verification gaps

- Some Visicom starts can glitch or hang. Investigate input/reset state and phase before changing correct steady-state rendering; use hardware or a trustworthy trace.
- A bottom horizontal line appears with some Studio II/Studio III firmware combinations. Establish whether software authored it before changing geometry.
- Studio II beeper rel3 still requires final MiSTer listening acceptance; see `docs/beeper-status.md`.
- Analog/direct video has not been verified on real hardware; see `docs/analog-video.md`.
- Profile coverage and exact-file identification remain incomplete.

## Verification and local layout

No single test establishes overall accuracy:

| Evidence | Establishes | Does not establish |
|---|---|---|
| Directed RTL tests | asserted decode/port/mirror behavior | untested timing or FPGA inference |
| `tools/refemu` | repeatable CPU/bitmap comparisons | cycle-accurate EF/DMA timing or independent truth |
| Other emulators | useful second implementation | independence from shared models |
| Primary docs and hardware | physical constraints and measured behavior | corpus-wide regression |
| Quartus reports | inference, fit, timing closure | runtime correctness |
| MiSTer testing | complete built integration | exhaustive internal state |

Canonical paths are `rom/` for firmware, `software/` for the corpus, `tools/refemu/` for the reference emulator, `verilator/obj_dir_headless/Vtop` for the headless model, and `out/` for generated captures. `refs/` is optional research material and must not be a normal build dependency. Scripts derive the repository root from their own location; never embed a maintainer's private path.

Quartus commands are `tools/quartus-build.sh`, `tools/quartus-build.sh map`, and `tools/quartus-build.sh clean`. The script uses the amd64 Quartus 17 container with `--parallel=1`, which is required under Apple Silicon emulation. After RAM changes, inspect `output_files/Studio-II.map.rpt` for inferred `altsyncram` instances.

Focused regressions include `tools/memdecode-test.sh`, `tools/tone-test.sh`, `tools/visicom-test.sh`, `tools/score-21.sh`, `tools/score-conic.sh`, and `tools/verify-beeper.sh`. Comparison totals are regression signals, not permanent accuracy percentages. Exclude semantically incomparable cases explicitly, retain representative images from every machine, and review them visually.

## References and provenance

When timing is ambiguous, combine RCA/Weisbecker primary material, MAME, Emma 02, Paul Robson's emulator and software, Andrew Modla's `rca-studio2`, Eric Smith's COSMAC VHDL, dmadole's AVI1861, and real hardware evidence.

The original core is by Jason Coombes, with MiSTer integration and early Pixie work by Flandango. Alan Steremberg carried later CPU/DMA/video and machine-support work. Elle Ball contributed controller profiles, OSD and scaling work, sync-preservation changes, research, and hardware testing.

Accuracy work also relies on Paul Robson, MAME contributors, Marcel van Tongeren, Andrew Modla, Eric Smith, dmadole, kanpapa, RCA documentation, and community hardware research. Special thanks to Kevin Bunch for reference captures and hardware insight, and to the Hagley Museum and Library for preservation work.

The project is GPL-2.0-or-later. GPL-3 reference files under `rtl/reference` and `rtl/cosmac.v` are not compiled into the core.

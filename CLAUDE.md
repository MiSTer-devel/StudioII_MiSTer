# CLAUDE.md — RCA Studio II for MiSTer

Canonical engineering reference for this repository. Prefer current RTL and measured behaviour over old comments or assumptions. Historical handoffs and deleted legacy documents are evidence only; durable engineering knowledge belongs here. Do not edit anything under `sys/`; it is MiSTer framework code.

## Documentation authority

Keep engineering state, invariants, limitations, verification scope and workflow in this file. Keep planned future work short and current in `roadmap.md`; do not turn this reference back into a dated investigation diary.

| Document | Authority |
|---|---|
| `CLAUDE.md` | Current engineering architecture, invariants, traps, limitations and verification state |
| `Readme.md` | User-facing setup, controls and release notes |
| `roadmap.md` | Planned future features and accuracy work |
| `docs/how-to-play.md` | Canonical per-title selection and keypad research for players and profile design |
| `docs/crc16-ccitt-hashes-by-game_20260824.txt` | Canonical game-grouped CRC inventory and Fullset filenames |

If these disagree about implementation, current RTL and measured hardware win. If control sources disagree, `docs/how-to-play.md` uses original manuals and author readmes ahead of emulator help. CRCs always describe exact file bytes; a corrected ST2 header necessarily creates a new hash.

## Current state

By the time you read this, the core shoud be released to MiSTer-devel. Current status summary:

| Machine | Video | Sound | Notes |
|---|---|---|---|
| Studio II | CDP1861, NTSC mono | discrete beeper | primary target |
| Studio III PAL | CDP1864 | CDP1864 tone | 312-line PAL timing |
| Studio III NTSC | CDP1861 + CDP1862 | CDP1863 | 1861 timing, colour added beside it |
| Visicom COM-100 | CDP1861 + second DMA bitplane | none | separate memory map and fixed four-colour palette |

The CDP1802 implements the instruction set required by the software corpus, interrupts, DMA and machine-cycle timing. Video is DMA-driven; there is no framebuffer scraper. `.bin`/`.rom` and paged `.st2` cartridges work. Studio II RAM mirroring, Studio III colour RAM, Visicom RAM/plane layout, four resident BIOS slots, joystick automapping, numstick input, aspect ratio and integer scaling are implemented.

All functionality that can currently be exercised has passed hardware testing. All four machine modes work, all known playable titles are compatible, integer scaling works, and HDMI sync is preserved through CLEAR, cartridge/firmware reloads, and machine changes that remain within the same video standard. High-page diagnostic ST2 images remain outside the loader's 4 KB cartridge model. Remaining RC1 items are verification gaps, hardware-accuracy questions and incomplete automap coverage rather than known general compatibility failures; see **RC1 known issues / open verification** below.

## Non-negotiable repository rules

- **Never modify `sys/`, including `video_freak.sv`, `video_mixer.sv`, `hps_io.sv`, etc.** Fix integration in the top level/core RTL.
- Quartus 17.0.x only.
- After changing RAM ports, verify the memory still infers as block RAM in `output_files/Studio-II.map.rpt`.
- When changing video/timing, state the hardware/emulator reference used.
- `bitmap_de` is a simulation/capture signal only. Normal MiSTer output uses raster blanking through `video_mixer`; do not route `bitmap_de` into the framework unless a deliberate border-crop feature is being added.

## Top-level architecture

`Studio-II.sv` is the MiSTer `emu` top. `rtl/rcastudioii.sv` contains the CPU, machine memory maps, keypad/controller mapping and machine video selection.

Important live video modules:

- `rtl/pixie/cdp1861.v` — Studio II, Studio III NTSC and Visicom timing/DMA.
- `rtl/pixie/cdp1862.v` — Studio III NTSC colour.
- `rtl/pixie/cdp1863.v` — Studio III NTSC tone and shared divider model for 1864 tone.
- `rtl/pixie/cdp1864.v` — Studio III PAL video/colour timing.
- `rtl/pixie/pixie_video.v` — 1861 wrapper.

Studio II, Studio III NTSC and Visicom all use the same 1861 timing path. Visicom differs in display-enable decode, memory map and colour data, not in raster timing.

## Clock and video path

Internal machine timing:

- `clk_sys` ≈ 7.040229 MHz.
- `ce_pix` divides this by 4, giving the ≈1.760 MHz 1861/CPU pixel-time base used by the core.
- CPU machine cycles are every eight `ce_pix` pulses.

The Verilator harness ties `ce_pix` high by default to avoid spending four host clocks per pixel; frame-relative behaviour is normally unchanged because core state is CE-gated. This fast mode does **not** reproduce every phase relationship present in the FPGA. Run the headless harness with `--ce4` when reset release, CLEAR, DMA/CPU phase or another clock-structure effect is under investigation. `--press-phase N` offsets scripted input within a frame so phase-sensitive polling can be swept.

MiSTer output runs from the PLL's `clk_vid` ≈ 42.24 MHz. The source stream is resampled into that domain and presented to `video_mixer` at ≈7.04 MHz (`ce_pix_vid`), repeating each native source pixel 4×. For the 1861 raster this turns the 88-pixel active line into 352 output samples.

Current top-level path:

```text
rcastudioii H/V sync + blanking + RGB
        ↓ resample clk_sys → clk_vid
video_mixer (LINE_LENGTH = 352)
        ↓ VGA_R/G/B, VGA_HS/VS, vga_de, CE_PIXEL
video_freak
        ↓ VGA_DE, VIDEO_ARX/VIDEO_ARY
MiSTer framework
```

`video_mixer` derives the framework-facing raster DE from HBlank/VBlank. The core's `video_de` output is therefore intentionally not connected at the top level.

### Integer scaling fix (2026-08-23)

Scale modes are working on hardware.

Two integration defects were fixed without touching `sys/`:

1. `video_mixer.LINE_LENGTH` is 352, matching 88 active source pixels × 4 resampling.
2. The VS supplied only to `video_freak` is delayed by one `CE_PIXEL`.

The second point matters because the RCA raster begins VBlank on the same source edge that VSync rises. Unmodified `video_freak` counts a DE falling edge and a VS rising edge in the same always block; without separating them, the later `vcpt <= vcpt + 1` overwrites its `vcpt <= 0` reset. Delaying the VS seen by `video_freak` by one output pixel lets it first count the final active line, then latch/reset the vertical measurement cleanly on the following CE.

Do not "fix" this inside `sys/video_freak.sv`.

OSD scale field is intentionally two bits feeding modes 0–3:

```systemverilog
.SCALE({1'b0, status[12:11]})
```

Mode 4 is intentionally not exposed.

## Video geometry

### CDP1861 / NTSC path

- 112 native pixel times per line.
- 262 lines/frame.
- H active begins at native pixel 24, therefore 88 active raster pixels/line.
- Bitmap data is 64 pixels wide at native pixels 40–103 inside that raster (`ACTIVE_START = 40`, `ACTIVE_END = 104`); it is not the framework DE.
- Vertical blanking wraps around the frame; VSync is near the end of the frame.

The bitmap window is pinned by the DMA burst and BIOS ISR phase. It deliberately sits 16 pixels from the raster's left edge and eight from the right. Do not centre the picture by moving `ACTIVE_START`; adjust porches/blanking around it, and revalidate against hardware timing.

The current 1861 DMA timing includes the phase work needed by real software:

- INT/EF timing leads according to AVI1861-derived behaviour.
- CPU honours DMA at instruction boundaries.
- DMA request stays asserted until the required cycles are serviced.
- Fetch/execute parity adaptation can move the request by one machine cycle.
- The line-buffer read window tolerates the observed interrupt-entry phase variation.

### CDP1864 / PAL path

- 112 native pixel times per line.
- 312 lines/frame.
- 192-line display area.
- PAL ↔ NTSC machine changes are genuine timing-standard changes and may break display sync; this is accepted.

## Reset policy and sync preservation

The reset policy is implemented and hardware-tested. CPU/machine reset and video-timing reset are deliberately separate: `reset` restarts machine state, while `video_reset` restarts raster counters and the CPU phase divider only for a hard reset.

| Event | Reset class | Video behaviour |
|---|---|---|
| Initial core/FPGA load | Hard | raster timing restarts |
| `Reset and close OSD` / MiSTer reset | Hard | raster timing restarts |
| Automatic boot firmware load (index 0) or an unknown download | Hard | raster timing restarts |
| Cartridge load (F1 / index 1) | Sync-preserving | raster remains live |
| Manual `Load Firmware` (F2 / index 2) | Sync-preserving | raster remains live |
| `Apply and reset` within the same standard | Sync-preserving | raster remains live |
| PAL ↔ NTSC `Apply and reset` | Hard | timing standard changes; display resync is expected |
| CLEAR (F3, OSD or gamepad Select) | Sync-preserving | raster remains live |

Studio II, Studio III NTSC and Visicom are all NTSC and can therefore switch among one another without dropping HDMI sync. Studio III PAL is the only PAL mode, so entering or leaving it is a hard reset.

During a sync-preserving reset:

- the CPU and machine state reset;
- the display is forced off;
- cartridge/firmware downloads hold reset for the transfer plus the post-download stretch;
- 1861/1864 raster counters keep running;
- `cpu_div` keeps counting so the CPU machine-cycle grid stays phase-coherent with the live raster.

Download type is latched through the post-download hold because `ioctl_index` is meaningful only during the transfer. Apply/reset captures whether the requested machine crosses PAL/NTSC before `machine_active` changes. `apply_reset_cnt` and both Apply edge-history registers are explicitly initialized because they participate in reset classification at startup. Hard reset sources always dominate if reset causes overlap.

CLEAR is normal Studio software operation, not merely a developer reset. Its established special case also leaves the Studio III tone generator running; other sync-preserving resets reset the tone state while retaining raster timing.

Hardware testing passes for the exercised CLEAR, cartridge load, manual firmware load and same-standard machine-switch paths. PAL ↔ NTSC transitions intentionally use the hard-reset path.

## Machine selection and BIOSes

The OSD Machine field is staged. `machine_active` changes on **Apply and reset** (with a short boot-follow exception so Main can restore saved configuration during startup). An apply within the current video standard uses the sync-preserving reset path; crossing between PAL and NTSC uses the hard-reset path.

Four BIOS BRAMs are resident:

| Machine | boot file |
|---|---|
| Studio II | `boot0.rom` |
| Studio III PAL | `boot1.rom` |
| Studio III NTSC | `boot2.rom` |
| Visicom | `boot3.rom` |

Studio II BIOSes are normally 2 KB. Studio III/Visicom images may be 4 KB; the BRAMs are 4 KB. Manual `Load Firmware` is index 2 and writes to the currently active machine's BIOS slot. Boot autoload uses index 0 with `ioctl_index[7:6]` selecting the slot.

Do not regress this back to a single 2 KB BIOS buffer.

## Memory maps

### Studio II / Studio III NTSC base behaviour

- `$0000-$07FF` ROM/system+resident games.
- `$0800-$09FF` 512-byte RAM.
- `$0A00-$0BFF` cartridge window.
- `$0C00-$0DFF` RAM mirror unless cartridge ROM is paged there.
- `$0E00-$0FFF` cartridge window.
- undecoded/open bus reads high (`$FF`).

RAM answers where A9=0 and nothing stronger is decoded, which produces the documented mirrors above `$0FFF` as well.

### Studio III

- 4 KB BIOS images can cover the high ROM area.
- colour RAM is in the `$0B00-$0BFF` window (64×3-bit storage mirrored through the page).
- PAL uses CDP1864; NTSC uses 1861+1862+1863.

### Visicom

- `$0000-$0FFF` ROM/cartridge space.
- `$1000-$11FF` 512-byte main RAM; display plane 0 is in its upper half.
- `$1300-$13FF` second 256-byte display plane.
- `$1200-$12FF` empty.
- mirrors repeat according to the reduced decode.

Visicom video reads plane 0 and the byte `$200` above it during the same DMA cycle. The two bits select one of four fixed colours. The top level applies the final RGB palette.

## Hardware invariants and timing traps

These are hardware-derived constraints, not a history of the implementation. Preserve them when changing CPU, memory, video or I/O behaviour.

### Studio II hardware

- The RCA block diagram shows four 512-byte ROM devices and four 256x4 RAM devices. The RAMs pair into 512 bytes; display memory runs from `$0900` at the top left through `$09FF` at the bottom right, eight bytes per logical row with bit 7 at the left.
- The physical data bus has 22 kOhm pull-ups. An undriven read therefore tends high, which supports the implemented open-bus value of `$FF`.
- The physical keypad-selector strobe is `N1 AND TPB`, so any output port whose N1 bit is set can clock the selector. The core deliberately decodes `OUT 2`, the port software uses. Corpus testing found no behavioural difference, but the wider physical decode remains a fidelity detail if unusual software depends on it.
- The CDP1861 has no framebuffer. It requests eight DMA-OUT machine cycles for each displayed scanline and the 1802 supplies bytes through `R(0)`. Studio II software repeats its 32 logical bitmap rows to produce 128 active bitmap lines.
- Studio II is NTSC-only. PAL timing belongs to the CDP1864 machines; a PAL Studio II mode would be an invented machine and would also change software timing.
- The console clock is a slug-tuned RC oscillator adjusted against the line frequency, not a crystal. Treat the implemented approximately 1.760 MHz timebase as a practical hardware model rather than an exact crystal-derived constant.

### Studio III hardware

- The CDP1864 is PAL-native: 312 non-interlaced lines, a maximum 64x192 bitmap, eight dot colours, four background colours and an integrated programmable tone divider.
- On the CDP1864 path, `INP 1` enables interrupt/DMA requests, `INP 4` disables them, `OUT 1` steps the background colour and `OUT 4` loads the tone latch. The corresponding opcodes are `69`, `6C`, `61` and `64`.
- The 1861 and 1864 models expose two four-line EF windows. Their lead relative to nominal line boundaries is intentional because software synchronizes its display loop to those edges.
- `CON` follows gated writes to colour memory. Colour inputs are latched in parallel with each luminance DMA byte, not looked up later as a framebuffer overlay.
- MPT-02 colour storage is 64 3-bit cells mirrored across `$0B00-$0BFF`. A DMA offset selects `{offset[7:5], offset[2:0]}`, so one cell covers eight pixels across by four logical bitmap rows down.
- Studio III NTSC is not a retimed CDP1864. It combines the CDP1861, CDP1862 and standalone CDP1863. For the same tone latch, the 1863 path is four times the 1864-integrated frequency; the shared divider's `div4` selection implements that difference.

### CPU, DMA and build traps

- Interrupts and DMA are accepted only at instruction boundaries. A DMA request remains asserted until all required cycles are acknowledged.
- The AVI1861-derived INT/EF lead and fetch/execute-parity adaptation are deliberate. Removing them can recreate whole-frame strobes in timing-sensitive software. The line-buffer read window likewise tolerates a one-machine-cycle variation in interrupt entry.
- The Cx opcode row contains both long branches and long skips. `C4` is NOP; `C5-C7` and `CC-CF` are the long-skip family.
- Verilator output can be stale after RTL edits. Clean `obj_dir` and `obj_dir_headless` when a rebuild appears not to reflect a change.
- Quartus may regenerate `Studio-II.qsf`; do not add live modules there or blindly stage it after a build. Keep `files.qip` and every Verilator source list synchronized when adding, removing or renaming a live RTL module.
- Verilator cannot detect failed FPGA RAM inference. A two-write-port RAM or unsupported mixed-port read-during-write mode can silently become thousands of ALMs while simulation, fit and timing still pass. Inspect the map report's inferred `altsyncram` instances after any RAM-port change.

## Cartridge loading

Raw `.bin`/`.rom` images load flat starting at `$0400`.

`.st2` is detected by `RCA2` magic and uses the 256-byte header page table at offsets 64–127. Blocks are written to their declared 256-byte pages. Cartridge page ownership is recorded so pages such as `$0C/$0D` can replace the normal RAM mirror when an image actually supplies ROM there.

Known Visicom cartridges use pages `$08-$0F`; the Studio II/III RAM/colour exclusions must not be applied to that machine.

The loader and cartridge BRAM model only the first 4 KB: ST2 pages must have a zero high nibble. Studio II rejects system pages `$00-$03` and RAM pages `$08-$09`; Studio III also reserves colour page `$0B`; Visicom accepts `$04-$0F` because its RAM is above that bank. Pages `$10` and above are dropped. In particular, the ST3CTA Tester 3 diagnostic uses pages `$24-$2F` and therefore does not load; supporting it requires an explicit banking/memory-model design, not just relaxing `st2_pg_ok`.

CRC16-CCITT automapping is computed over the exact downloaded file bytes (poly `0x1021`, init `0xFFFF`). `.st2` and `.bin` containers therefore have different CRCs even when their payloads describe the same game; both hashes must be listed when known.

## Joystick / OSD profile system

`Mapping` and `Joystick` are separate OSD fields:

- Auto: core uses `auto_profile` and writes the detected profile back into OSD bits `[5:2]`.
- Manual: user selection in `[5:2]` drives the mapping.

The Joystick row is disabled while Auto is active. The mapping itself does **not** depend on successful OSD writeback; `auto_profile` drives gameplay directly.

`status_set`/`status_in` readback structure has been checked and is correct: the top level replaces only `[5:2]` with `auto_profile`, and `hps_io` snapshots the whole word on the rising edge of `status_set`.

Profiles currently include None, Cross, Space War, Freeway, Bowling, Baseball, Homebrew, Gunfighter, 8-way, Doodle, 2P Homebrew, Clear-only and Paddle.

### Profile coverage

Known profile entries are functional, but the table is not complete: not every game/mode has an automap profile and not all known software is represented in the CRC table. Add hashes only when the exact image and controls are identified. Because CRCs cover exact downloaded bytes, list both `.bin` and `.st2` hashes where both containers are known.

`MAP_CLEAR_ONLY` can be selected by its known CRC entries or by the built-in Addition game. `playerA`/`playerB` key state is event-driven, so stale held-key state across reset remains relevant when diagnosing an unexpected built-in selection.

Do not rewrite the profile table speculatively. Prefer exact game identification and verified controls.

`docs/how-to-play.md` is the control-research authority. It uses console keypad notation (`A0-A9`, `B0-B9`), records multi-step selectors such as Hockey's mode plus difficulty, preserves asymmetric controls such as Pacman's `B8` down input, and lists titles whose controls are still unknown. Do not infer a profile from a similar game name when that file lists a gap.

For CRC work:

- `tools/Generate-CRC16Inventory.ps1` recursively hashes `.rom`, `.bin` and `.st2` using CRC16-CCITT (`0x1021`, initial `0xFFFF`).
- The raw fullset table preserves every scanned file; the by-game table deduplicates collection copies while retaining distinct file/header revisions.
- Firmware must be hashed because resident ROMs contain selectable games and participate in identity/profile research.
- Before adding a case entry, verify the canonical Fullset name, exact CRC, machine, start sequence, player/keypad roles and in-game actions. Include every known container/header revision for the same payload.

## Known issues / open verification

### Visicom intermittent instability

All dumped Visicom games are playable. Some software can behave unexpectedly, possibly if certain keys are pressed at startup, or if the hardware gets into a bad state somehow. Issues include obvious visual glitches and/or game hangs.

More investigation needed regarding this behaviour. Do not change timing blindly: a real Visicom or trustworthy hardware trace remains the best reference. Investigate reset/input state, phase/reacquisition and cartridge-start conditions before changing the two-plane renderer, which produces correct gameplay during normal operation.

### Bottom horizontal line on some BIOS/software

A visible line has been observed at the bottom of the picture with the Studio II alternate BIOS and Studio III 4 KB BIOS dumps. It is not present with every BIOS/image.

Treat this as an open hardware-accuracy question. Because it varies with software/BIOS, it may be authored behaviour or a consequence of how that BIOS drives display memory/timing rather than a universal raster bug. Compare against reference emulators and, ideally, real hardware before changing blanking or active geometry.

### Beeper tuning

The Studio II beeper targets about 628.4 Hz (near E♭5, via a fractional divider). A very long Pac-Man hardware tone settles at 505.28 Hz before release, establishing the sustained floor at about 505.2 Hz in the integer-divider model. This is about 377.5 cents below the measured upper pitch: close to a major third, with the floor in the B4 neighborhood. Nine repeated long Math Fun notes on another recording establish roughly 200 ms from attack through the rounded descent toward the floor. The branch models this as a 20 ms principal-pitch crest followed by a monotonically slowing decay whose early hardware fit is preserved and whose final few hertz use finer, progressively slower divider bands. The contour is still about 506.1 Hz at 200 ms and reaches the 505.2 Hz floor at about 210 ms, avoiding a digitally abrupt landing. This is a fitted behavioral contour, not a claim that the capacitor sees a simple 4.4 kΩ charging resistance; the 555 control-pin transfer and surrounding circuit affect the observed pitch. The difference in absolute pitch is normal console/source variance. The 514--525 Hz troughs in Gunfighter, Concentration/Match and Outbreak are near-floor release turnarounds. Outbreak, Pac-Man and Math Fun prove that their upward S-tail is intrinsic analog release behavior: it occurs without a following programmed note. Speedway / Tag adds a different constraint: Joyce Weisbecker repeats extremely short pulses as fast as about 20 Hz and keeps them around the principal pitch, whereas Math Fun's retail-style pips repeat near 6 Hz and droop slightly. A "pip" must not be implemented as a fixed sound shape; continuous analog state plus the game's Q timing must produce it. The current RTL keeps the oscillator audible after Q falls through a divider-only RC-like amplitude release, turns pitch upward during that release, and continues pitch recovery after the envelope reaches silence. The envelope's prominent portion has an effective time constant near 21 ms, falls to roughly -16 dB by 40 ms and below -30 dB near 75--80 ms, then ends its faint tail at about 96 ms. A close Q-high retrigger preserves the instantaneous audible divider and amplitude while restarting a hidden fresh-note contour at the upper pitch. Concentration/Match hardware shows that the live pitch keeps recovering after Q rises, reaching about 560 Hz (roughly 200 cents below the principal pitch and a semitone above its turnaround) before the fresh contour catches it and pulls it downward. The Q-high continuation is therefore limited to a measured partial-recovery equilibrium near 560 Hz; Q-low recovery still proceeds to 628.4 Hz. This avoids both the old frozen 534 Hz second pulse and the cumulative lowering that results from applying a complete new descent directly to an already-lowered state. The provisional 600-clock pitch-recovery step models about 515-to-554 Hz in 40 ms and about 117 ms from the floor to the upper endpoint. The 8-bit envelope takes about 2 ms from zero to full. These release constants require refinement against a capture with Q-edge timing; do not retune the accepted early driven descent to compensate for release or analysis-window effects.

### Analog/direct video

Implemented and expected to work, but not yet verified on real analog hardware.

## Sound

Studio II uses a signed 16-bit sample path for the discrete beeper model, including the approximate NE555 driven pitch droop, audible upward release, amplitude envelope and stateful retrigger behavior described above.

Studio III NTSC uses the CDP1863 tone generator. Studio III PAL uses the CDP1864-compatible divider path. Visicom has no Studio III tone hardware.

## Verification model and limits

No single comparison is a complete accuracy result. Use evidence appropriate to the failure class:

| Evidence | What it establishes | What it does not establish |
|---|---|---|
| Current RTL directed tests | Decode, mirrors, port behaviour and other explicitly asserted properties | Untested timing, analog behaviour or FPGA resource inference |
| `tools/refemu` frame/state comparison | Repeatable CPU-state and bitmap comparisons across the software corpus | Cycle-accurate scanline/EF timing, memory mirrors, top-level MiSTer integration or independent hardware truth |
| MAME / Emma 02 comparison | A useful second implementation and broad machine/software behaviour | Independence when the RTL was derived from the same device model |
| RCA documents, AVI1861 and real captures | Hardware constraints, cycle relationships and measured behaviour | Complete regression coverage across all software |
| Quartus map/timing reports | FPGA inference, fit and timing closure | Runtime correctness or software compatibility |
| Hardware testing | The complete built core, MiSTer framework, display chain and real controls | Exhaustive internal state or every cartridge/input sequence |

`tools/refemu` can match a Studio II frame's total instruction budget while distributing cycles incorrectly inside the display window; it does not faithfully model every scanline and EF1 edge. Static frame agreement is therefore a regression metric, not a general RTL-accuracy percentage. If the RTL and C reference both follow the same MAME device model, agreement mainly validates the translation and glue. Add RCA documentation, AVI1861, Emma 02 or real-hardware evidence for disputed timing.

Frame capture also cannot exercise memory mirrors or prove block-RAM inference. Directed tests and Quartus map inspection cover those separate classes. `bitmap_de` exists so bitmap-only captures remain comparable while the real output includes border and full-raster blanking; it is not the framework-facing DE.

## Build and regression

Quartus 17.0.x:

```sh
tools/quartus-build.sh
tools/quartus-build.sh map
tools/quartus-build.sh clean
```

The build script runs the amd64 Quartus container with `--parallel=1`. This is required when it runs under emulation on Apple Silicon: `quartus_sh --flow compile` plus `NUM_PARALLEL_PROCESSORS ALL` can leave crashed helpers and a parent blocked on named pipes. Use the script rather than substituting a raw flow command. A healthy emulated build uses roughly a full CPU core rather than lingering near idle.

After memory changes, check `Inferred altsyncram megafunction` in `output_files/Studio-II.map.rpt`. A RAM silently falling into logic can cost thousands of ALMs while still simulating, fitting and closing timing correctly.

Useful regressions include:

- `tools/memdecode-test.sh`
- `tools/tone-test.sh`
- `tools/visicom-test.sh`
- `tools/score-21.sh`
- `tools/score-conic.sh`

`tools/contact-sheet.py` renders corpus captures side by side and helps distinguish a different game state from a broken frame when a comparison score moves. Do not turn old score totals into permanent requirements: reference-emulator changes and test recipes legitimately move them.

The current Verilator harness instantiates `rtl/rcastudioii.sv` directly rather than the MiSTer top level. It therefore does not exercise HPS boot ordering, saved-machine boot-follow, `ioctl_index` reset classification, Apply classification or overlapping top-level reset sources. In `verilator/sim.v`, `video_reset` is tied to `ioctl_download`, so every simulated download restarts raster timing; the harness can verify the core reset interface and CLEAR behaviour, but it cannot prove F1/F2 or Apply sync preservation. Keep every core-port change synchronized with all simulation instantiations.

## References

Use more than one source when timing is ambiguous.

- RCA/Weisbecker primary documentation in the local reference material.
- MAME `studio2`, `cdp1861`, CDP1864/Visicom implementations.
- Marcel van Tongeren's Emma 02, especially for Studio III and Visicom behaviour.
- Paul Robson's Studio II emulator/homebrew and the vendored comparison harness.
- Andrew Modla's `rca-studio2`.
- Eric Smith's COSMAC VHDL.
- dmadole's AVI1861 hardware replacement, especially for 1861 cycle/phase behaviour.

## Credits / provenance

The original core is by Jason Coombes, with MiSTer integration and early Pixie work by Flandango. Alan Steremberg carried the later 2026 CPU/DMA/video and machine-support work. Elle Ball contributed joystick profiles, OSD tuning and enhancements, and extensive software and hardware testing. See `Readme.md` for the user-facing credits.

GPL-2.0-or-later. Eric Smith's GPL-3 reference files under `rtl/reference` / `rtl/cosmac.v` are reference material and are not part of the compiled core.

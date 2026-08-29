# Roadmap

Studio II audio phase one comes first. Prefer small, measurable changes that
preserve a unified core model, and keep per-title policy out of RTL when a stable
user-serviceable data format can represent it.

## 1. Complete Studio II audio phase one

The oscillator duty cycle and output-only mute are implemented. Verify the
candidate on MiSTer to close this phase. The exact implementation boundary,
tests, listening cases, and accepted pitch model are maintained in
`docs/beeper-status.md`. The hard early attack knee belongs to a later audio
phase.

## 2. External controller profiles

Move per-title mappings out of synthesized RTL and into a stable,
user-serviceable database. The core should accept new games and corrected
mappings without requiring a maintainer or a new build.

Use one compact declarative format and one loading/interpreting path. Migrate the
existing mappings rather than retaining permanent compiled and external systems.
Preserve both keypads, start/select sequences, player roles, non-gameplay actions
such as CLEAR, manual selection and useful exact-file identification. Invalid or
missing data must fail safely to ordinary unmapped/manual controls.

The format is the long-lived interface. Keep it versioned, documented and unable
to introduce executable behavior or title-specific RTL.

Add missing game and mode mappings only when exact images and controls are known.
Add this knowledge through the external database rather than growing RTL again.

## 3. Studio III, Visicom and verification quality

- Investigate intermittent Visicom startup glitches and hangs against real
  hardware evidence before changing timing or rendering.
- Determine whether the bottom horizontal line seen with some Studio II and
  Studio III BIOS/software combinations is authored behavior or a core defect.
- Verify analog/direct-video output on real hardware. Do not change its timing or
  geometry as part of HDMI presentation work.
- Replace raw aggregate frame-match percentages with an expectation manifest.
  Count only cases that are semantically expected to match the reference;
  classify other cases as excluded or human-review with a recorded reason.
- Export a small representative image set for Studio II, Studio III PAL, Studio
  III NTSC and Visicom on each full regression run. Keep these images available
  for human review rather than deleting every capture with temporary files.
- Include a Studio III NTSC case that visibly covers the lower-right edge of the
  64x32 logical bitmap so the reported horizontal-line issue is directly checked.

## 4. Future Studio II audio work

- Model and tune the hard early attack knee against hardware recordings without
  disturbing the accepted pitch, duty-cycle or release behavior.
- Generate focused audio test ROMs with known Q timing so hardware capture and
  RTL state can be aligned without relying on gameplay sequences.

## 5. HDMI presentation options

- Add an HDMI-only border crop that cannot affect analog/direct video.
- Add a 5x cropped mode for 1080p and verify centering, aspect behavior and its
  interaction with existing integer scaling on hardware.

Keep these in the existing video path; do not create a second geometry model.

## Deferred architectural expansion

High-page diagnostic ST2 images remain outside the 4 KB cartridge model. Do not
expand the loader or memory model without a concrete compatibility need and an
explicit banking design.

# Roadmap

This is the short list of planned work beyond the current RC1 stabilization effort. It is intentionally limited to concrete user-facing improvements and accuracy work.

## 1. External controller profiles

Move controller-profile data out of RTL into an external database.

- Define a compact, documented mapping format.
- Allow a mapping file with the same base name as a ROM to load automatically with that ROM.
- Allow any mapping file to be selected and loaded manually.
- Preserve mappings for both keypads, start/select sequences, player roles and non-gameplay actions such as CLEAR.
- Keep exact-file CRC detection available where it remains useful, without requiring every mapping to be compiled into the core.

## 2. Beeper accuracy

Continue comparing the Studio II discrete-beeper model against real-hardware recordings. Concentration / Match's characteristic double-Q pulse now constrains Q-high retrigger recovery to a partial-charge crest near 560 Hz rather than the former frozen 534 Hz. Capture the revised core passage and obtain an instrumented Q-edge trace to verify both Q-high spans, the intervening gap, the roughly 200-cent interval below the principal pitch and repeat behavior. Continue refining pitch behavior, recovery between closely spaced sounds and amplitude shaping only where measurements support a change.

## 3. Mute switch

Add the console's real-hardware mute switch as a user control.

## 4. Border toggle

Add an HDMI-only option that removes or crops the raster border so the game bitmap can fill more of the display.

This option must be gated entirely out of the analog/direct-video path. Analog timing and geometry must remain unchanged regardless of the border setting.

## 5. 5x crop for 1080p

Add a 5x cropped scaling mode suitable for 1080p output. Verify the crop, centering, aspect behavior and interaction with the existing integer-scaling modes on hardware.

## 6. Visicom accuracy testing

Complete additional Visicom COM-100 accuracy testing against real hardware. Required hardware observations are currently pending; avoid speculative timing or rendering changes until those results are available.

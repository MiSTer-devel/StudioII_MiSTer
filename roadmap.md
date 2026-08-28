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

The current model is broadly convincing, but closely clustered Gunfighter sounds remain a critical failed stress test: Q-high/Q-low transitions on double and triple hits can sound synthetic or uneven. Capture the exact Gunfighter edge cadence and live beeper state, reproduce it in the behavioral model, and replace the fixed retrigger behavior with a natural continuous-state rule. Preserve the accepted pitch endpoints, release envelope, Concentration / Match double pulse, Speedway rapid pulses and non-additive repeated-hit behavior. See `docs/beeper-status.md` for the canonical current assessment.

## 3. Mute switch

Add the console's real-hardware mute switch as a user control.

## 4. Border toggle

Add an HDMI-only option that removes or crops the raster border so the game bitmap can fill more of the display.

This option must be gated entirely out of the analog/direct-video path. Analog timing and geometry must remain unchanged regardless of the border setting.

## 5. 5x crop for 1080p

Add a 5x cropped scaling mode suitable for 1080p output. Verify the crop, centering, aspect behavior and interaction with the existing integer-scaling modes on hardware.

## 6. Visicom accuracy testing

Complete additional Visicom COM-100 accuracy testing against real hardware. Required hardware observations are currently pending; avoid speculative timing or rendering changes until those results are available.

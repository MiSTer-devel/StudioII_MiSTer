# Studio II beeper: current status

The beeper is broadly convincing, and the parts that already sound right should
be preserved. Rel3 contains an experimental Gunfighter retrigger model derived
from the labeled `kb-gf` hardware clips. Its numerical checks pass, but listening
on MiSTer is still the release criterion.

## Accepted baseline

- The reference tuning is about 628.4 Hz at the upper pitch and 505.2 Hz at the
  sustained floor. Console-to-console variation is expected and is not a reason
  to move these defaults.
- A long Q-high interval descends smoothly toward the floor in about 210 ms.
- Q low does not mute the circuit. Pitch turns upward while an RC-like amplitude
  envelope fades to silence in about 96 ms, and the pitch state continues to
  recover afterward.
- Pitch and amplitude remain continuous across close Q transitions. Repeated
  sounds remain bounded rather than stacking a fresh full descent on every hit.
- Speedway's rapid roughly 20 Hz pulses remain near the upper pitch. Long notes,
  isolated releases, and Concentration / Match's characteristic double pulse are
  useful protected regression cases and are currently close to hardware.
- The Studio II signed sample path is isolated from the Studio III programmable
  tone path.

## Gunfighter evidence

The ROM and simulator establish the programmed cadence:

- shot: Q high for one 60 Hz frame, approximately 16.67 ms;
- cactus: Q high for seven frames, approximately 116.67 ms;
- labeled cactus-to-shot samples: Q low for 2, 3, 4, 5, 6 or 9 frames.

Measured about 11 ms into the next shot, those six gaps produce approximately
596.8, 605.4, 613.4, 616.0, 618.7 and 626.6 Hz. The old fixed-ceiling model was
27--38 Hz low in the close 2--4 frame cases, then reached the top too abruptly.
The two files labeled `single` follow the long/cactus-family contour rather than
the clean one-frame-shot family.

The acoustic onset alignment is repeatable to the game's frame grid, but it is
not a direct electrical Q/control-voltage capture. Treat the family and contour
as stronger evidence than any isolated ridge value.

## Rel3 candidate

The audible release and the recovered next-start state are now represented
separately. Q low keeps the accepted slower audible upward tail, preserving the
Pac-Man/Outbreak release checks. A hidden divider follows a rounded,
distance-dependent recovery. On Q rising, live pitch remains unchanged at the
edge, glides to the hidden state over about 6 ms, and waits there until the fresh
driven contour catches it. There is no fixed second-pulse pitch.

The behavioral result is 591.5, 604.1, 611.6, 617.2, 620.7 and 626.0 Hz for the
six Gunfighter gaps, or 2.55 Hz RMS error against the hardware estimates. The
same checks retain Concentration / Match's approximately 559.5 Hz second crest,
Speedway's principal-pitch rapid pulses, the long-note endpoints, release
amplitude/pitch and bounded repeated hits.

## Audio phase-one candidate

The duty-cycle and mute implementation is now deliberately orthogonal to the
accepted pitch, retrigger and envelope state. No curve constant changed.

### 1. Duty cycle

The oscillator phase scheduling around `snd_cnt`, `snd_out` and
`snd_toggle_at` in `rtl/rcastudioii.sv` now:

- replaces the equal high/low phases with the approximately 11:6 high/low ratio
  measured in KB's recordings.
- derives both phase lengths from one latched full period, with a sum equal to
  the former two half-periods so the fundamental contour does not move.
- keeps the fractional 628.4 Hz plateau by sharing one selected base length over
  each high/low pair and advancing the error accumulator once per full cycle.
- keeps one oscillator running through Q-low release without changing
  `snd_half`, `snd_drive_half`, `snd_control_half`, note age, or the amplitude
  envelope.

`tools/beeper-curve-test.py` checks phase lengths at the top and bottom dividers:
high+low equals the old full period, the ratio rounds to 11:6, and the average
fundamentals remain approximately 628.4 Hz and 505.2 Hz. Every existing
pitch/release/retrigger check passes unchanged.

The unequal signed waveform has a non-zero arithmetic mean. Keep the existing
`+/-snd_magnitude` levels for this small timbre change and judge the real MiSTer
audio path by listening; do not add an unmeasured filter or a second envelope to
compensate for it.

### 2. Mute

Free status bit 16 in `Studio-II.sv` exposes the switch:

```systemverilog
"O[16],Audio,On,Mute;"
```

`AUDIO_L` and `AUDIO_R` are gated to signed zero at the top level when muted.
Mute does not enter `rcastudioii`, gate Q, reset either tone generator, or change
audio state. Unmuting therefore reveals the oscillator at the phase, pitch and
envelope it reached while muted. This also keeps the control consistent across
Studio II and Studio III without adding a machine-specific path. Existing OSD
profile writeback preserves bit 16 because it replaces only status bits `[5:2]`.

### Remaining acceptance

1. Run `tools/verify-beeper.sh`; all existing checks plus the new duty checks pass.
2. Build with the supported Quartus 17 flow and confirm normal map/timing results.
3. On MiSTer, compare the same Gunfighter, Concentration / Match and Speedway
   passages used to accept rel3. Duty cycle may change timbre, not pitch contour.
4. Mute during a long descending note and unmute during its release/recovery; the
   resumed sound must prove that state continued underneath the mute.

Do not special-case a game or fold the later hard early-attack knee into this
change. The build and MiSTer listening checks above close audio phase one.

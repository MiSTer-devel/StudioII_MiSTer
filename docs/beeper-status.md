# Studio II beeper

This file records the accepted behavioral model, its evidence, and remaining
measurement uncertainty. Release chronology belongs in release notes and Git.

## Behavioral baseline

- The retail-reference contour has a fresh-note pitch near 628.4 Hz and a
  sustained floor near 505.2 Hz. Console tolerance is expected.
- Medium, the default, scales that complete contour by approximately `0.9945`
  to the December 1976 RCA demonstration unit: about 625 Hz fresh and
  502.4--502.5 Hz sustained. Low and High scale Medium by `31/32` and `32/31`,
  producing approximately 605.5/486.8 Hz and 645.1/518.6 Hz endpoints.
- Q high holds the upper pitch for about 20 ms, then follows a rounded descent
  that settles in roughly 210--220 ms.
- Q low does not mute or reset the oscillator. Pitch recovers upward continuously
  while an RC-like amplitude envelope fades over roughly 96 ms.
- Pitch and amplitude remain continuous across close Q transitions. Retriggers
  recover according to the low-gap duration and do not stack independent notes.
- Rapid pulses such as Speedway remain near the upper pitch. Concentration /
  Match and Gunfighter exercise close-retrigger behavior.
- The output waveform uses an approximately 11:6 high/low duty ratio while
  preserving the full-cycle period.

The December 1976 demonstration recordings independently show the same pitch
span and driven-curve family at about `0.9945` of the accepted absolute tuning.
That proportional agreement and Paul Robson's approximately 625 Hz circuit
description make the demonstration unit the Medium/default reference.

## Circuit description

Paul Robson's archived Studio II technical note describes a Q-gated NE555
astable switched by the 1802's SEQ and REQ instructions. It gives `Ra = 400
kOhm` and `Rb = 480 kOhm`, with the control pin connected to ground through a
`10 uF` electrolytic capacitor. That independently supports the observed
continuous downward pitch warp and gives high/low phase lengths proportional
to `(Ra + Rb):Rb = 880:480 = 11:6`, matching the accepted duty ratio.
Read in audible units, its stated working frequency of about 625 agrees with
the measured 628.4 Hz fresh-note pitch to within about 0.5 percent.

The surviving note prints `C = 1.8 pF`, `625 kHz`, and an approximate decay to
half frequency in 0.4 seconds. The capacitance/frequency units are inconsistent
with an audible beeper and should be treated as a likely notation or
transcription error, not silently corrected. The broad description corroborates
the circuit topology and direction of the pitch change; measured gameplay audio
remains the authority for the accepted 628.4--505.2 Hz contour and timing.

Robson also describes a possible capacitor-charging circuit that extends the
first power-up beep beyond its programmed 80 ms. Treat that startup event as a
separate initial-condition problem rather than using it to tune ordinary
in-game Q pulses.

The surviving source was preserved from
`https://archive.kontek.net/studio2.classicgaming.gamespy.com/techinfo.htm`.

## Implementation

`rtl/rcastudioii.sv` maintains one oscillator state through drive, release, and
retrigger. Audible release and recovered next-start state are represented
separately: the live pitch follows the release tail, while a hidden divider
tracks recovery. On Q rising, live pitch glides to the recovered state without a
discontinuous edge, then rejoins the driven contour.

The selected tuning scales the complete oscillator period while the drive,
release, retrigger, and amplitude timings remain unchanged. The scale is latched
with the period so its high and low phases cannot use different settings. Those
phases are then derived in an 11:6 ratio whose sum preserves the tuned full
period. The fractional-period accumulator advances once per full cycle.

The OSD reserves a three-bit tuning field. Code 0 is Medium, 1 is Low, and 2 is
High; codes 3--7 currently fall back to Medium so later non-reference settings
can be added without narrowing the interface. The setting affects only the
Studio II beeper. The signed sample path remains independent of the Studio III
programmable-tone path.

`Studio-II.sv` implements `Sound: On/Off` by gating `AUDIO_L` and `AUDIO_R` to
signed zero. It does not gate Q, reset either generator, or alter oscillator,
pitch, phase, or envelope state.

## Evidence and verification

The model is constrained by labeled retail-console recordings, the RCA
demonstration archive, ROM/simulator Q cadence, and MiSTer listening. Acoustic
analysis uses cycle periods, spectral ridges, and harmonics; recordings do not
provide direct electrical Q or control-voltage timing.

`tools/beeper-curve-test.py` checks all three tuning endpoints, reserved-code
fallback, descent, release, retrigger families, phase-length sums, duty ratio,
and protected game cases.
`tools/verify-beeper.sh` runs the focused audio checks. Synthesis reports must
still be inspected separately for timing and inference, and MiSTer listening is
required for release acceptance.

## Remaining uncertainty

- Archival release ridges suggest a faster upward recovery than the accepted
  curve, but short-window endpoint bias can also produce impossible overshoot.
- The hardest early-attack knee is not fully constrained.
- Direct electrical or line-level captures with a recorded Q trace would remove
  acoustic onset ambiguity.

Any refinement must improve aggregate hardware agreement without moving the
accepted normalized contour, special-casing a title, or regressing the protected
rapid, long-note, release, and close-retrigger cases.

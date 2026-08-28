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

## Next work

1. Build rel3 and listen to the labeled Gunfighter single/double/triple passages.
2. Recheck Concentration / Match and Speedway immediately afterward; numerical
   preservation is necessary but does not prove that the 6 ms glide sounds right.
3. Capture the rel3 output through the same chain and align it to the `kb-gf`
   clips. Use `--trace-q` for the matching simulated live/control state.
4. Accept, retune or reject the hidden-control trajectory from those matched
   results. Do not move the established endpoints or release envelope to hide a
   retrigger problem.
5. After accepting the pitch model, replace the oscillator's 50% duty cycle with
   the approximately 11:6 high/low timing indicated by KB's recordings. Treat
   this as a timbre change and preserve the accepted fundamental pitch contour.
6. Add the console mute switch as an output-only control that leaves beeper state
   running underneath it.

Do not special-case a game, reset pitch on every Q rise, or retune accepted
endpoints to mask the transition problem. Duty-cycle correction and mute complete
audio phase one after the rel3 pitch model is accepted. The hard early attack knee
remains later refinement.

The primary implementation and executable constraints are in
`rtl/rcastudioii.sv` and `tools/beeper-curve-test.py`. The dated handoffs and
per-game analyses remain supporting evidence; this file is the canonical current
status.

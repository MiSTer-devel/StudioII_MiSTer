# Studio II beeper: current status

The beeper is broadly convincing, and the parts that already sound right should
be preserved. It is not finished. Closely clustered Gunfighter sounds are the
critical stress test: the transitions between Q high and Q low still sound
synthetic or uneven, especially on double and triple hits. The current model is
therefore failing an important aural test even though its individual pitch curves
and focused behavioral checks are close.

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

## Critical unresolved behavior

The current retrigger rule uses a live pitch state plus a hidden fresh-note
contour. On Q high, the live pitch can continue recovering toward a fixed region
near 560 Hz until the restarted contour catches it. This gives convincing results
for the measured Concentration / Match sequence and prevents cumulative pitch
drop, but it can sound canned when Q changes rapidly at different intervals.
Gunfighter exposes that weakness more clearly than the existing unit tests.

The likely problem is transition dynamics, not the upper or lower tuning. Exact
Gunfighter Q-high durations, Q-low gaps, and state at each edge are still the
most important missing evidence. A matched edge trace is more useful now than
additional tuning from an unaligned acoustic pitch ridge.

## Next work

1. Capture a reproducible Gunfighter sequence with every Q edge and the live
   beeper state, including single, double, and triple hits.
2. Add those exact timings to the behavioral model. Treat listening against
   matched hardware as a release criterion, not merely a subjective note after
   the numerical checks pass.
3. Prototype a more natural continuous-state transition rule before changing
   RTL. The preferred direction lets Q alter the motion of shared pitch/inertia
   state instead of steering each retrigger toward a fixed second-pulse crest.
4. Recheck Gunfighter first, then protect Concentration / Match, Speedway, long
   Pac-Man/Math Fun notes, release shape, and non-additive repeated hits.

Do not special-case a game, reset pitch on every Q rise, or retune accepted
endpoints to mask the transition problem. The separate 50% versus approximately
11:6 NE555 duty-cycle/timbre issue and the hard early attack knee remain worthwhile
follow-up work, but neither should be mixed into the Gunfighter retrigger fix.

The primary implementation and executable constraints are in
`rtl/rcastudioii.sv` and `tools/beeper-curve-test.py`. The dated handoffs and
per-game analyses remain supporting evidence; this file is the canonical current
status.

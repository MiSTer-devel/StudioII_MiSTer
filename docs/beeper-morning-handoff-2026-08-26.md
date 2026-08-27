# Studio II beeper morning handoff

Date: 2026-08-26  
Branch: `beeper-release-retrigger`

The bedtime build is the accepted baseline. It has the correct approximately
628.4 Hz principal pitch, 505.23 Hz floor, non-additive retriggers, audible
upward release and RC-like amplitude decay. Its softened final descent is about
506.1 Hz at 200 ms and reaches the floor near 210 ms. Do not retune it
speculatively.

Next task: precisely compare Concentration / Match's double-Q pulse against a
matching hardware capture. Measure both Q-high spans, the Q-low gap, turnaround
and second-pulse pitches, the second-pulse interval in cents, pitch/amplitude
through the retrigger and hardware repeat variation. Current core capture:
`C:\Users\Elle\Downloads\concentration-double-q-pulse-bedtime-mister.ogg`.

Detailed context: `docs/beeper-release-retrigger-handoff-2026-08-25.md` and
`CLAUDE.md`. Do not run Quartus synthesis or touch `Studio-II.qsf`, `sys/`, or
the unrelated game-file moves.

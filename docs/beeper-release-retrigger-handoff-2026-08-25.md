# Studio II beeper release/retrigger handoff

Date: 2026-08-25  
Branch: `beeper-release-retrigger`  
Base commit: `b80674a Adjust beeper curve`  
Repository: `C:\Workspace\Git\StudioII_MiSTer`

## Current judgment

The user judges release03 **extremely close**. Its recordings validate the
principal pitch, sustained floor, non-additive retriggers, upward recovery and
RC-like amplitude envelope. The one remaining requested change was a softer,
slightly longer landing on the pitch floor. The final approach now uses finer,
progressively slower divider bands and reaches the same floor around 210 ms.
Preserve this model until new recording evidence identifies a specific mismatch.

The next session should analyze a recording of this softened-floor build, not
begin with another speculative RTL adjustment. In particular, do not retune the
accepted early driven descent to make an analysis-window bend look sharper.

## Implemented model

Studio II now has a signed 16-bit beeper sample path. Studio III retains its
fixed-level CDP1863/CDP1864 square-wave path.

### Driven pitch

- Principal pitch: approximately 628.4 Hz.
- Fractional upper half-period: 1400/1401 pixel clocks, 574/1024 long.
- Sustained floor: approximately 505.23 Hz (`SND_HALF_BOTTOM = 1741`, meaning
  1742 clocks per half-cycle).
- Principal-pitch knee: approximately 20 ms (`35205` clocks).
- Driven descent after the knee: approximately 190 ms.
- RC-like divider intervals: `240, 280, 330, 410, 520, 740, 1600, 2400, 3400, 4800, 6800, 8191`.
- The early driven curve is unchanged; finer terminal bands leave it near 506.1 Hz at 200 ms and feather it into the 505.23 Hz floor at approximately 210 ms overall.

This is the accepted beeper03 descent. Avoid changing it without new evidence.

### Audible release and recovery

When Q falls, the oscillator remains audible while pitch turns upward. Pitch
recovery uses one divider step per 600 pixel clocks:

- about 515-to-554 Hz in 40 ms;
- about 117 ms from the sustained floor to the upper endpoint.

After the amplitude envelope reaches silence, pitch recovery continues. The
release-pitch constant remains provisional because no direct Q-edge-aligned
hardware capture is available.

### RC-like amplitude envelope

The final change replaced the overly prominent linear release with a cheap
divider-only approximation of exponential decay. One-level intervals by current
8-bit amplitude are:

| Amplitude | Interval (pixel clocks) |
|---:|---:|
| 192--255 | 170 |
| 128--191 | 240 |
| 64--127 | 400 |
| 32--63 | 800 |
| 16--31 | 1600 |
| 8--15 | 3200 |
| 1--7 | 5700 |

Expected envelope landmarks:

- approximately 2 ms from zero to full on attack;
- level 40/255, approximately -16.1 dB, after 40 ms of release;
- level 6/255, approximately -32.6 dB, after 78 ms;
- silence at approximately 96 ms.

The quick prominent decay plus faint residual tail was chosen because the prior
linear envelope stayed audible almost all the way back to 624--628 Hz on short
Pac-Man and cartridge-load sounds. Release03 recordings confirm the new envelope
at approximately -16 dB after 40 ms, -33 dB after 78 ms and silence near 96 ms.

### Non-additive close retriggers

The first audible-release version applied a fresh driven descent directly to the
already-lowered instantaneous divider. Repeated cactus hits therefore accumulated
downward, producing erroneous second and later troughs around 510--514 Hz.

The correction uses two pitch states:

- `snd_half`: instantaneous audible/release divider;
- `snd_drive_half`: hidden fresh-note reference contour.

On Q-high, audible pitch and amplitude remain continuous. The hidden contour
restarts at the upper pitch, receives the normal 20 ms knee and accepted descent,
and must catch the audible divider before it may pull it lower. Consequently a
retrigger neither forces an upward glide nor stacks another full descent onto an
already-lowered note.

The focused repeated-cactus test produces trough dividers
`[1699, 1699, 1699, 1699, 1699, 1699]`, proving there is no cumulative lowering.

## Latest analyzed recordings

The current release03 files are in `C:\Users\Elle\Downloads\`:

- `gf-release03-1-mister-x.ogg`
- `gf-release03-2-mister-x.ogg`
- `pm-release03-1-mister-x.ogg`
- `pm-release03-2-mister-x.ogg`
- `freeway-release03-mister-x.ogg` -- actually Speedway / Tag, despite the name

Measurements from release03:

- Gunfighter clean pips have a 628.36 Hz median.
- Gunfighter cactus/overlap troughs range from about 521.6 to 526.4 Hz without
  cumulative downward stacking.
- Pac-Man sustained floors repeat at approximately 505.08--505.12 Hz.
- Pac-Man short release tails remain measurable only to about 588--590 Hz, and
  sustained release tails to about 544--546 Hz, rather than exposing the full
  recovery toward 628 Hz.
- The recorded envelope measures approximately -16 dB at 40 ms, -33 dB at
  78 ms and effectively silent near 96 ms.
- Speedway / Tag's rapid pulses remain around the 628 Hz principal pitch.

These release03 captures predate only the subsequent 200-to-210 ms soft-floor
extension. They validate the parts of the model that extension leaves unchanged.

The older linear-release files are:

- `gf.ogg`
- `cartridgeload.ogg`
- `pacman.ogg`

They identified the overly prominent **linear** release and predate the final
RC-like envelope change.

Measurements from the older analysis:

- Gunfighter clean pips centered near 628.3 Hz.
- An isolated cactus descended to about 522--524 Hz and recovered upward.
- After the non-additive correction, most rapid-cactus troughs remained around
  524--530 Hz instead of progressively falling into the 510--514 Hz region.
- Cartridge load traced approximately 628 -> 567 -> 628 Hz; the complete upward
  return was too prominent with the linear envelope.
- Pac-Man sustained tones settled at approximately 505.1--505.2 Hz after about
  200 ms.
- Pac-Man short tones reached approximately 550 Hz, then remained measurable
  almost back to 624 Hz because the linear tail stayed too loud.

Reusable analysis command:

```powershell
& "C:\Users\Elle\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe" `
  tools\analyze-beeper-recordings.py <recording.ogg> --csv <frames.csv>
```

The analyzer uses overlapping 36 ms pitch windows. Sharp bends, release onset and
the last faint frames are window-biased; judge pitch and amplitude together.

## Next focused experiment: Concentration / Match double-Q pulse

The user flags Concentration / Match's double-Q pulse as the next high-value
measurement. Its second pitch has a distinctive near-semitonal or microtonal
relationship to the initial pitch and may expose analog pitch inertia more
precisely than ordinary single notes.

Use `concentration-double-q-pulse-bedtime-mister.ogg` as the current core-side
capture, but obtain or identify a matching real-hardware passage before changing
RTL. Measure:

- both Q-high durations and the intervening Q-low gap, preferably from a
  simulator trace or instrumented core rather than inferred from audio alone;
- the first stable pitch, turnaround pitch and second-pulse pitch;
- the second-pulse interval relative to the initial pitch in frequency ratio and
  cents (`1200 * log2(f2 / f1)`);
- pitch and amplitude together through the gap and retrigger;
- repeat-to-repeat variation on hardware versus the deterministic core.

Do not model this as a game-specific note or tune the contour from a single
36 ms-window measurement. The useful result is a repeatable constraint on the
shared stateful beeper model, especially recovery/inertia during a close Q pulse.

## Verification completed

`tools/beeper-curve-test.py` currently passes checks for:

- monotonically slowing driven intervals;
- 19.5 ms pips at 628.40 Hz;
- 48, 100 and 120 ms driven-pitch landmarks;
- soft 506.1 Hz floor approach at 200 ms and 505.23 Hz sustained floor at 211 ms;
- full driven amplitude;
- release entry without pitch/amplitude discontinuity;
- 541.61 Hz and -16.1 dB after 40 ms of release;
- residual level -32.6 dB after 78 ms;
- silent recovery after the release tail;
- amplitude- and pitch-continuous retrigger;
- hidden-contour non-additive bound;
- 20 Hz short pulses remaining at the principal pitch;
- repeated cactus notes with no cumulative lowering.

Python compilation and `git diff --check` pass for the beeper-related files. No
Quartus synthesis should be run by the assistant; the user explicitly requested
that project synthesis remain on their side.

## Worktree and preservation warning

The beeper implementation is uncommitted. Relevant modified files are:

- `rtl/rcastudioii.sv`
- `Studio-II.sv`
- `verilator/sim.v`
- `verilator/sim_headless.cpp`
- `tools/beeper-curve-test.py`
- `CLAUDE.md`

`Studio-II.qsf` changes itself during Quartus use and should not be included with
the beeper work merely because it appears dirty.

There are also unrelated game-file moves in the shared worktree: tracked files
under `releases/games/` appear deleted and a top-level `games/` directory is
untracked. These are user-owned changes. Do not restore, delete, move, stage or
otherwise alter them as part of beeper work.

## Suggested next-session prompt

```text
Continue Studio II beeper analysis on branch `beeper-release-retrigger` in
C:\Workspace\Git\StudioII_MiSTer. Read
docs/beeper-release-retrigger-handoff-2026-08-25.md and CLAUDE.md.

The user judges the current build near dead-on. The next focused experiment is
Concentration / Match's double-Q pulse and its distinctive near-semitonal or
microtonal second-pulse relationship. Compare a matching hardware capture with
concentration-double-q-pulse-bedtime-mister.ogg; measure the Q-high/Q-low timing,
turnaround, second-pulse frequency ratio and interval in cents, pitch/amplitude
trajectory and repeat variation. Preserve the accepted beeper03 descent,
600-clock upward release recovery, non-additive hidden-contour retrigger and
RC-like amplitude envelope unless a repeatable measurement supports a targeted
shared-model change. Do not run Quartus synthesis and do not touch project-file
churn or unrelated game moves.
```

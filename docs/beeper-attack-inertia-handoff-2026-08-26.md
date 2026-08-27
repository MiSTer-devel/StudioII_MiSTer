# RCA Studio II beeper: attack inertia and waveform handoff

Date: 2026-08-26  
Repository: `C:\Workspace\Git\StudioII_MiSTer`  
Branch: `rel2`  
HEAD at handoff: `9cd7048`  

## Purpose

This handoff is for a fresh, higher-reasoning review of the Studio II beeper RTL.
The current branch has reached a strong behavioral result for sustained pitch,
release, and close retriggers. Concentration / Match's distinctive double pulse
now sounds convincing and measures in the correct microtonal neighborhood.
Speedway remains clean and pure. Gunfighter is the remaining subjective outlier,
and a new set of real-hardware Addition recordings now gives a much cleaner way
to diagnose the attack transient that probably causes it.

There is also a separate, newly measured timbre problem: the RTL emits an almost
perfect 50% square wave, while the NE555 hardware has strong even harmonics and
an asymmetric duty cycle. Do not try to repair this timbre difference by changing
pitch constants.

No attack-inertia or duty-cycle RTL change has been made as part of this handoff.

## Current user judgment

Treat the following as important listening evidence, not as claims inferred only
from numerical analysis:

- Concentration / Match's double pulse sounds "right on" and should be protected.
- Speedway sounds pure and shows no regression.
- Pac-Man's overall pitch curve and targets are very good, although its timbre and
  initial transient remain wrong.
- Gunfighter is close but is the audible outlier; it does not yet sound perfect.
- The hardware, not the current core, has the more nasal tone.
- The likely remaining pitch-model concept is inertia/interpolation, with careful
  modeling of the initial transient rather than another fixed delay.

## Workspace state and preservation warning

The worktree is intentionally dirty. At handoff, tracked beeper work exists in:

- `rtl/rcastudioii.sv`
- `tools/beeper-curve-test.py`
- `CLAUDE.md`
- `roadmap.md`

The user has also reorganized software/reference material. At handoff:

- the old tracked `games/*.st2` files show as deleted;
- `pd_software/`, `ref/`, and `rom/` are untracked;
- `rom/studio2.rom` is present and is 2,048 bytes;
- `software/` contains the larger supplied `.st2` corpus.

These are user changes. Do not restore, move, delete, stage, or otherwise clean
them as part of beeper work.

The latest Quartus build reports and `output_files/Studio-II.sof` remain, dated
2026-08-26 09:18, but `output_files/Studio-II.rbf` is no longer present at the
time of this handoff. Earlier in the session it existed and was successfully
tested on hardware by the user; do not claim the RBF is currently available.

## Available local toolchain

Ubuntu WSL 2 is installed. This session installed:

- Verilator 5.032
- `make`
- `g++`
- `zlib1g-dev`
- Python 3 and NumPy
- FFmpeg

The headless Verilator model builds and runs through WSL. Typical commands from
PowerShell are:

```powershell
wsl -d Ubuntu -- bash -lc 'cd /mnt/c/Workspace/Git/StudioII_MiSTer/verilator && make lint && make headless'
wsl -d Ubuntu -- bash -lc 'cd /mnt/c/Workspace/Git/StudioII_MiSTer && python3 tools/beeper-curve-test.py && bash tools/tone-test.sh'
```

When RTL behavior appears stale, remove or rebuild `verilator/obj_dir_headless`
before drawing conclusions. Follow the repository warning in `CLAUDE.md` about
keeping simulation source lists synchronized.

## Validation already completed

Using the current dirty RTL:

- Verilator 5.032 lint completed with existing non-fatal warnings.
- The headless simulator compiled successfully.
- `tools/beeper-curve-test.py` passed every check.
- `tools/tone-test.sh` passed every CDP1864 tone check and Studio II isolation
  check.
- `tools/memdecode-test.sh` passed all eight checks after `studio2.rom` was
  restored.
- Built-in Doodle rendered content in the simulator.
- `software/StudioII-Cartridges/baseball.st2` loaded and rendered gameplay.
- `software/StudioII-Cartridges/mathfun.st2` loaded, rendered, and exercised Q
  transitions and audio.

The full RTL-versus-reference 48-frame score was not run because the older
`software/carts/*.bin` layout and prebuilt reference-emulator executable were not
available in their expected paths.

## Current RTL model

The Studio II beeper lives in `rtl/rcastudioii.sv`, beginning near line 1213.
Important current constants are:

```systemverilog
localparam [15:0] SND_HALF_TOP      = 16'd1400;
localparam [15:0] SND_HALF_BOTTOM   = 16'd1741;
localparam [15:0] SND_HOLD_TICKS    = 16'd35205; // approximately 20 ms
localparam [15:0] SND_RETRIGGER_TOP = 16'd1571;  // approximately 560 Hz
localparam [15:0] SND_RECOVER_STEP  = 16'd600;   // approximately 117 ms floor-to-top
localparam [15:0] SND_ATTACK_STEP   = 16'd14;    // approximately 2 ms amplitude attack
```

The current pitch architecture uses:

- `snd_half`: the audible/live oscillator half-period;
- `snd_drive_half`: a hidden fresh-note descent trajectory;
- a 20 ms `SND_HOLD` at the principal pitch before driven descent;
- piecewise `snd_decay_interval()` bands for the approximately 190 ms descent
  following that hold;
- upward pitch recovery while Q is low;
- an RC-like amplitude release lasting approximately 96 ms;
- live amplitude and pitch continuity across close retriggers;
- a hidden fresh-note contour restarted at Q rise;
- continued live pitch recovery during Q-high retrigger, capped near 560 Hz,
  until the fresh descent catches the live divider.

The last item is the current uncommitted change. It fixed the previous behavior
where Concentration's second pulse remained frozen near 534 Hz. The matching
Python behavioral test was updated in `tools/beeper-curve-test.py`.

The oscillator itself is currently symmetric: `snd_out` toggles after each equal
`snd_toggle_at` interval. This guarantees approximately 50% duty cycle.

## Established pitch and envelope constraints

Do not discard these constraints merely to improve one Gunfighter passage:

- Principal pitch target: approximately 628.4 Hz on the original reference
  console, near E-flat 5.
- Sustained floor: approximately 505.23 Hz, established by a very long Pac-Man
  hardware note.
- Endpoint span: approximately 377.5 cents.
- Math Fun establishes approximately 200 ms from attack through the soft approach
  to the floor; the model reaches the floor near 210 ms including the current
  20 ms hold.
- Release amplitude is approximately -16 dB at 40 ms, below -30 dB near 75--80
  ms, and ends its faint tail near 96 ms.
- Release pitch turns upward while amplitude fades and continues recovering after
  the sound becomes inaudible.
- Close retriggers must preserve instantaneous amplitude and pitch state.
- Repeated retriggers must not cumulatively push the divider below the normal
  fresh-note trajectory.
- Concentration's Q-high retrigger crest is approximately 560 Hz, around 200 cents
  below the principal pitch and roughly 135 cents above the first trough.
- Rapid approximately 20 Hz Speedway pulses must remain near the principal pitch.

Absolute tuning varies between consoles. The new FLiP hardware set often centers
around 632--634 Hz rather than 628.4 Hz. Compare normalized contours or cents
before considering any endpoint change.

## MiSTer `rel2-01` recordings

All are 44.1 kHz stereo Vorbis files in `C:\Users\Elle\Downloads`:

| File | Meaning | Duration |
| --- | --- | ---: |
| `rel2-01-cm01-mister.ogg` | Concentration / Match | 2.00 s |
| `rel2-01-cm02-mister.ogg` | Concentration / Match | 1.37 s |
| `rel2-01-cm03-mister.ogg` | Concentration / Match | 7.42 s |
| `rel2-01-ad01-mister.ogg` | Addition | 10.90 s |
| `rel2-01-gf01-mister.ogg` | Gunfighter | 36.98 s |
| `rel2-01-sp01-mister.ogg` | Speedway | 21.80 s |

Shorthand supplied by the user:

- `gf` = Gunfighter
- `ad` = Addition
- `cm` = Concentration / Match
- `sp` = Speedway

## Analysis method and caveats

The reusable analyzer is `tools/analyze-beeper-recordings.py`. It:

- decodes with FFmpeg to 44.1 kHz mono float PCM;
- filters the 480--760 Hz fundamental band for event detection;
- uses overlapping 36 ms Hann windows with a 4 ms hop;
- follows the strongest 500--700 Hz fundamental ridge;
- reports event-level and frame-level pitch data.

This is the same method used for the earlier Gunfighter and Concentration hardware
reports. It is reliable for repeatable central pitch trajectories. Event onset,
tail duration, and faint final frames are threshold-dependent, especially in the
new noisier hardware recordings. Treat isolated values above about 640 Hz, values
from very short detected fragments, and late low-amplitude tail estimates with
caution. Repeatable families across several files are much stronger evidence.

## Concentration / Match result: protect this behavior

The current MiSTer double-pulse topology is:

```text
approximately 628 Hz
  -> approximately 521 Hz first trough
  -> approximately 560 Hz partial-recovery/retrigger crest
  -> approximately 521 Hz second trough
  -> recovery
```

`cm02` and the final multi-part event in `cm03` are nearly identical. `cm01` is a
slightly longer variant but follows the same topology. Representative MiSTer
values at 12 ms intervals are:

| Relative time | Frequency |
| ---: | ---: |
| 24 ms | 627 Hz |
| 48 ms | 576 Hz |
| 72 ms | 544 Hz |
| 96 ms | 528 Hz |
| 120 ms | 521 Hz |
| 144 ms | 538 Hz |
| 168 ms | 558 Hz |
| 180 ms | 560 Hz |
| 204 ms | 546 Hz |
| 228 ms | 529 Hz |
| 252 ms | 521 Hz |
| 276 ms | 534 Hz |

The older hardware report placed the important windows at approximately:

- first/second trough family: 517--525 Hz;
- partial recovery crest: 559--561 Hz;
- long-sequence state retention: later components begin below a clean 628 Hz
  reset.

The current frequency relationships are therefore excellent. Acoustic durations
in the new MiSTer recordings are around 326--343 ms for the multi-part events,
versus approximately 308--322 ms in the older hardware captures. Short MiSTer
events measure about 193 ms versus approximately 173--180 ms in the older set.
Those differences deserve awareness but are partly detector/capture-chain
dependent. Do not sacrifice the pitch topology without stronger Q-aligned timing
evidence.

## Speedway result: no regression

The main rapid-pulse passages remain essentially flat at the upper pitch:

- central values are approximately 628.1--628.6 Hz;
- the longest detected joined passage lasts about 12.9 seconds without sustained
  pitch movement;
- rapid pulses remain individually articulated through the amplitude envelope.

One final isolated event in `rel2-01-sp01-mister.ogg` bends approximately
628 -> 568 -> 613 Hz. It appears to be a distinct longer game event, not
corruption of the rapid Speedway pulse train.

The prior hardware Speedway recording centered around 621.45 Hz, which is a
normal source/console tuning difference. Its approximately 20 Hz pulse rate and
absence of meaningful droop remain the behavioral constraint.

## Gunfighter result: remaining outlier

`rel2-01-gf01-mister.ogg` contains 80 detected events. Most clean pips are
extremely stable near 628.3 Hz. The common shaped/cactus event is also highly
deterministic:

| Relative time | Current MiSTer |
| ---: | ---: |
| 24 ms | approximately 625 Hz |
| 36 ms | approximately 603 Hz |
| 48 ms | approximately 576 Hz |
| 72 ms | approximately 544 Hz |
| 96 ms | approximately 528 Hz |
| 120 ms | approximately 521 Hz |
| 144 ms | approximately 536 Hz |
| 168 ms | approximately 560 Hz |

The earlier hardware Gunfighter report gave a representative trajectory of:

| Relative time | Hardware report |
| ---: | ---: |
| 24 ms | approximately 614 Hz |
| 36 ms | approximately 609 Hz |
| 48 ms | approximately 557--562 Hz |
| 72 ms | approximately 538--540 Hz |
| 96 ms | approximately 524--525 Hz |
| 120--140 ms | approximately 546--553 Hz |
| 156--192 ms when overlapped | approximately 603--611 Hz |

Do not over-align these tables without the same exact gameplay action and Q-edge
trace. Nonetheless, the current model clearly has a sharp knee: it moves too
little initially, then descends rapidly, reaches a slightly deeper trough, and
produces a broad upward tail. This agrees with the user's judgment that Gunfighter
is close but not fully natural.

Some longer current events reach the 505 Hz floor. Those may represent genuinely
long/overlapped game actions not present in the old short hardware cluster; do
not classify them as failures without a matched action capture.

## New real-hardware reference set

All files are 44.1 kHz stereo Vorbis in `C:\Users\Elle\Downloads`:

- `addition-hw-01.ogg` through `addition-hw-04.ogg`
- `freeway-hw-01.ogg` through `freeway-hw-03.ogg`
- `bowling-hw-01.ogg` and `bowling-hw-02.ogg`
- `doodle-hw-01.ogg` and `doodle-hw-02.ogg`

These were supplied after the `rel2-01` MiSTer recordings. They include repeated
short sounds, held tones, and close retrigger patterns. Doodle in particular has
many complex events and is best used with known B0 hold/gap timings rather than
as an unlabeled event corpus.

### Addition is the strongest attack-transient reference

The hardware confirms that Addition really has two sound families:

- short/flat upper-pitch pips;
- shallow V-shaped pitch gestures.

The V-shaped event repeats with exceptional consistency across all four files.
Using the same 36 ms estimator, representative hardware and current MiSTer curves
are:

| Relative time | Hardware | MiSTer `rel2-01` |
| ---: | ---: | ---: |
| 16 ms | approximately 634 Hz | approximately 628 Hz |
| 24 ms | approximately 632 Hz | approximately 626 Hz |
| 32 ms | approximately 626 Hz | approximately 615 Hz |
| 40 ms | approximately 616 Hz | approximately 600 Hz |
| 48 ms | approximately 611 Hz | approximately 599 Hz |
| 56 ms | approximately 616 Hz | approximately 607 Hz |
| 64 ms | approximately 628 Hz | approximately 617 Hz |
| 72 ms | approximately 628 Hz | approximately 625 Hz |

Normalize for console pitch before comparing. Relative to each source's initial
pitch:

- hardware median trough: about -64 cents;
- current MiSTer median trough: about -82 cents.

The present model therefore exaggerates the gesture by roughly 18 cents and
11--12 Hz in absolute terms. More importantly, it produces a hard acceleration:
little movement before the hold expires, followed by a descent that overtakes the
hardware curve too sharply. Hardware starts moving gently and makes a broader,
shallower bend.

The alternating flat/bent vocabulary is not itself a core bug. The likely bug is
the discontinuous transition between a perfectly flat 20 ms hold and an aggressive
piecewise descent. Addition is a cleaner fitting target for this than Gunfighter
because its event family is extremely repeatable.

### Freeway and Doodle preserve the established endpoints

The long hardware events support the existing pitch range and continuous state:

- Freeway long holds reach approximately 509.8--510.5 Hz on a source whose upper
  pitch is around 632--634 Hz.
- Doodle long holds repeatedly reach approximately 505--509 Hz on sources whose
  upper pitch is around 628--630 Hz.
- Both games expose upward recovery and many intermediate retrigger pitches through
  the low 500s, 540s, 560s, and 600s.

This is evidence for keeping a persistent analog/control state. It is not evidence
for resetting every note or assigning fixed semantic sound shapes.

### Bowling supplies another short-pulse family

Bowling's repeated hardware sounds cluster near a 632 Hz principal pitch and are
about 80 ms acoustically at the detector threshold. Their strongest central pitch
is stable, while fading edges often measure in the 611--620 Hz range. Because the
late frames are low amplitude, use them as supporting rather than primary evidence.
The regular repetition is useful for checking that a new attack model does not
accumulate pitch error across pips.

## New timbre finding: asymmetric NE555 duty cycle

The hardware recordings have strong even harmonics. Representative measurements,
relative to each clip's fundamental, are:

| Source window | H2 | H3 | H4 | H5 |
| --- | ---: | ---: | ---: | ---: |
| Addition hardware flat tone | -3.0 dB | -19.2 dB | +1.8 dB | +4.0 dB |
| Bowling hardware pulse | -6.6 dB | -26.8 dB | -3.8 dB | +1.1 dB |
| Addition MiSTer flat tone | -66.7 dB | -8.7 dB | -61.9 dB | -14.0 dB |
| Speedway MiSTer stream | -44.6 dB | -8.7 dB | -57.2 dB | -13.9 dB |

The absolute hardware harmonic balance also includes the console output stage,
speaker/capture response, and gating, so do not fit these dB values literally.
The categorical difference is robust: hardware has large even harmonics; MiSTer
nearly nulls them.

The quoted Studio II oscillator component values are `Ra = 400 kOhm` and
`Rb = 480 kOhm`. A conventional NE555 astable has duty fraction:

```text
(Ra + Rb) / (Ra + 2*Rb) = 880 / 1360 = 11 / 17 = approximately 64.7%
```

The high and low phase durations are proportional to:

```text
(Ra + Rb) : Rb = 880 : 480 = 11 : 6
```

The current equal-duration toggle is therefore physically inconsistent and
explains much of the missing nasal character. A first-pass waveform correction
should use separate high and low counts in an approximately 11:6 ratio while
preserving the total period and existing fractional 628.4 Hz tuning.

Do this as a separate conceptual change from pitch inertia. Validate pitch first
and re-measure it after duty-cycle work because asymmetric edge placement can
slightly affect short-window estimators even when the full period is unchanged.

## Primary diagnosis

The remaining pitch abstraction leak is probably `SND_HOLD_TICKS`, not the top or
floor constant. The present model is effectively:

```text
flat for 20 ms -> abruptly enter a relatively fast period ramp -> slow near floor
```

The hardware Addition curve looks more like:

```text
begin moving gently -> accelerate smoothly into a shallow bend -> reverse smoothly
```

This is consistent with the user's pitch-inertia intuition. A hard delay followed
by a first-order or table-driven motion will continue to create a knee. Consider a
state model with a gradual change in slope, for example:

- two cascaded fixed-point smoothing states;
- a position plus damped velocity state;
- another cheap second-order/critically damped approximation;
- or a carefully fitted table that explicitly preserves continuous slope.

The behavioral goal matters more than claiming a literal circuit topology. The
NE555 control-pin transfer and surrounding network are not necessarily a single
ideal RC in observed pitch space.

Any candidate should retain one continuous live control/pitch state across Q
transitions. It should not introduce game detection, note categories, or additive
per-retrigger descent.

## Suggested implementation strategy

1. **Freeze the current baseline.** Record the current curve-test output and, if
   useful, generate current Verilator Q traces for representative Addition,
   Gunfighter, Concentration, and Speedway sequences.
2. **Prototype outside RTL first.** Extend the Python behavioral model with an
   alternative inertial attack state. Fit normalized Addition targets, especially
   the gentle 16--32 ms movement and approximately -64-cent trough.
3. **Preserve endpoints.** Keep the principal and sustained-floor targets fixed.
4. **Preserve state.** Reversal and retrigger should operate on the same live
   states; no instantaneous pitch reset.
5. **Protect Concentration.** Require a second crest around 558--562 Hz, first and
   second troughs in the approximately 517--525 Hz family, and no cumulative
   lowering.
6. **Protect Speedway.** Rapid approximately 20 Hz pulses must remain effectively
   flat at the principal pitch.
7. **Recheck Gunfighter.** Look for removal of the hard knee and a shallower,
   smoother cactus trajectory. Prefer matched gameplay/Q timing before final
   tuning.
8. **Then address duty cycle.** Implement asymmetric high/low phases while keeping
   total period unchanged; compare harmonic spectra and subjective nasality.
9. **Treat startup separately.** Do not tune ordinary in-game behavior from the
   power-on sound until startup initial conditions and any pulse-extension circuit
   are understood.

## Tests to add or strengthen

The current Python tests are good endpoint/property tests but should gain explicit
attack-shape constraints. Suggested additions:

- Addition normalized pitch windows at approximately 16, 24, 32, 40, 48, 56,
  and 64 ms;
- a bound on maximum early slope so the 20 ms knee cannot return;
- an invariant that short Speedway pulses do not droop meaningfully;
- Concentration double-pulse crest/trough windows after the new attack model;
- repeated Bowling-like pips do not accumulate downward state;
- long Doodle/Freeway holds still reach the floor;
- Q-low release retains upward pitch motion and the accepted amplitude envelope;
- waveform full-period average preserves the intended fundamental after asymmetric
  duty-cycle changes;
- waveform duty ratio is near 11:6 and even harmonics are no longer numerically
  nulled.

For Verilator, continue running at minimum:

```bash
cd verilator
make lint
rm -rf obj_dir_headless
make headless
cd ..
python3 tools/beeper-curve-test.py
bash tools/tone-test.sh
bash tools/memdecode-test.sh
```

Use `--ce4` when investigating Q-edge or clock-phase sensitivity; the default fast
harness ties `ce_pix` high and does not reproduce every FPGA phase relationship.

After any final RTL change, run a Quartus map/build and verify memory inference and
timing. Verilator cannot prove FPGA RAM inference or the analog output spectrum.

## What not to do

- Do not retune 628.4 Hz or 505.23 Hz solely from the new console's 632--634 Hz
  absolute pitch.
- Do not revert the current Q-high retrigger recovery before reproducing the
  Concentration double-pulse measurements.
- Do not fix Gunfighter by special-casing Gunfighter or by assigning semantic pip,
  cactus, or double-pulse shapes.
- Do not use a longer fixed hold as the only attack fix; Addition shows that the
  shape, not just the delay, is wrong.
- Do not alter pitch to imitate nasal timbre; address oscillator duty and output
  spectrum separately.
- Do not treat low-amplitude tail ridge estimates as equally reliable as repeated
  central frames.
- Do not conflate power-on startup behavior with ordinary in-game notes.
- Do not clean or normalize the user's dirty worktree or software reorganization.

## Open questions for the next review

1. Can a two-state fixed-point inertial model match Addition without increasing
   FPGA cost unreasonably or complicating reset behavior?
2. Can the existing hidden `snd_drive_half` trajectory be evolved into that model,
   or is it cleaner to replace the hold/drive/live intersection with a unified
   control state?
3. Does a matched Gunfighter Q trace confirm that its perceived mismatch is the
   same attack knee exposed by Addition?
4. How much of the Concentration event-duration difference is detector/capture
   threshold versus actual release timing?
5. Can the 11:6 oscillator phase ratio be implemented without disturbing the
   fractional principal-frequency accumulator?
6. After duty correction, is an additional inexpensive output filter or waveshaper
   needed, or does the asymmetry alone supply enough of the hardware nasality?
7. What initial control/amplitude state and additional circuit behavior are needed
   for the distinct startup sound?

## Recommended opening prompt for the next chat

> Review `docs/beeper-attack-inertia-handoff-2026-08-26.md` completely, then inspect
> the current dirty diff in `rtl/rcastudioii.sv` and
> `tools/beeper-curve-test.py`. Develop and critically evaluate an RTL plan for a
> smooth stateful attack/pitch-inertia model using the new Addition hardware curve
> as the primary fitting target. Preserve the accepted Concentration double pulse,
> Speedway rapid pulses, 628.4/505.23 Hz endpoints, release envelope, and
> non-additive retriggers. Separately review an approximately 11:6 asymmetric NE555
> duty-cycle change for timbre. Do not modify or clean unrelated user files. Before
> implementing, explain the proposed state equations, fixed-point widths, resource
> cost, transition/reset behavior, and validation criteria.


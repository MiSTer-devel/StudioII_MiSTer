# Studio II beeper retrigger handoff

Date: 2026-08-27  
Repository: `C:\Workspace\Git\StudioII_MiSTer`  
Baseline branch: `main`  
Baseline HEAD: `4e40966` (`Fix regression paths for local software library`)  
Released core commit: `0ac7eeb` (`Publish 20260827 unstable beeper test build`)

## Purpose and current judgment

Start the next round of beeper work on a new branch from this clean `main`
baseline. The 2026-08-27 build is intentionally a conservative unstable/test
release, not a declaration that the beeper is finished.

The user is not satisfied with the current retrigger effect. The most audible
problem is Gunfighter's double and triple hits: the individual pitch curve is
close, but closely spaced hits can sound synthetic or uneven. The behavior has
been reasonably consistent across the hardware units tested so far, so this is
probably a model problem rather than ordinary board-to-board tuning variation.
More hardware recordings are expected.

Do not continue this work directly on `main`. Create a dedicated branch in the
next session (for example `codex/beeper-retrigger`) and keep the released build
as the comparison baseline.

## What the current release establishes

The baseline should be preserved unless new evidence directly contradicts it:

- fresh-note pitch is approximately 628.4 Hz on the original reference unit;
- a long note settles near 505.2 Hz on that unit;
- the driven descent reaches its floor in about 210 ms, including a 20 ms crest;
- Q-low produces an audible, upward-pitch release with an RC-like amplitude fade;
- pitch/control state continues recovering after the release becomes inaudible;
- a close Q-high retrigger preserves instantaneous pitch and amplitude;
- rapid approximately 20 Hz Speedway pulses stay near the upper pitch;
- repeated notes are bounded and do not stack an additional full descent;
- Concentration / Match's tested 120 ms on, 12 ms off sequence crests around
  560 Hz on its second pulse.

The focused behavioral test is `tools/beeper-curve-test.py`. It encodes all of
these constraints and passes on the released baseline.

## Current retrigger mechanism

The implementation is in `rtl/rcastudioii.sv`, in the Studio II sound block near
line 1213. Important constants are:

```systemverilog
localparam [15:0] SND_HALF_TOP       = 16'd1400;
localparam [15:0] SND_HALF_BOTTOM    = 16'd1741;
localparam [15:0] SND_HOLD_TICKS     = 16'd35205; // approximately 20 ms
localparam [15:0] SND_RETRIGGER_TOP  = 16'd1571;  // approximately 560 Hz
localparam [15:0] SND_RECOVER_STEP   = 16'd600;   // approximately 117 ms floor-to-top
localparam [15:0] SND_ATTACK_STEP    = 16'd14;    // approximately 2 ms amplitude attack
```

Two pitch states are involved:

- `snd_half` is the live oscillator/control state and remains continuous across
  Q transitions.
- `snd_drive_half` is a hidden fresh-note trajectory. It restarts from the upper
  pitch at every Q rise, holds for 20 ms, and then descends until it catches the
  live state.

During a close retrigger, `snd_half` continues upward recovery while Q is high,
but only until it reaches the fixed `SND_RETRIGGER_TOP` limit or the hidden
fresh-note contour catches it. That intersection creates the second-pulse crest.
This was introduced to make Concentration / Match convincing without allowing
successive retriggers to push the pitch progressively lower.

The fixed approximately 560 Hz ceiling and the restart/catch interaction are
the first things to question. They fit one representative two-pulse sequence,
but may be too canned for Gunfighter sequences with different Q-high/Q-low
durations. Also inspect `snd_recover_cnt <= snd_curve_cnt` on Q rise: reusing the
partially accumulated release counter preserves phase, but its interaction with
several short gaps has not been validated against exact hardware Q edges.

## New multi-unit evidence

The full analysis is in `docs/multi-unit-beeper-analysis-2026-08-27.md`. Absolute
oscillator tuning and time constants vary materially between consoles:

| Unit | Fresh upper pitch | Sustained floor | Interpretation |
| --- | ---: | ---: | --- |
| HW1 / current reference | about 628.4 Hz | about 505.2 Hz | Current RTL endpoints |
| HW2 | about 669--671 Hz | about 539 Hz | Nearly uniform +112-cent shift; curve shape agrees |
| HW3 | not cleanly isolated | about 518.5 Hz | Contains the best new two-pulse memory capture |
| HW4 | about 662--665 Hz | about 524.5--525.3 Hz | Wider/slower-looking sweep and clear releases |

This argues against changing the default endpoints to match one newly measured
unit. Normalize traces by each unit's upper/floor span before comparing retrigger
shape.

`audio_refs/noshaders-hw3-01.ogg` is the most useful new retrigger example. Its
first driven region reaches about 518 Hz, recovers upward, exposes a second crest
around 595--598 Hz, and descends to the same plateau again. It confirms continuous
analog memory, but it does not justify changing `SND_RETRIGGER_TOP` directly:
HW3's clean fully charged upper pitch and the exact Q edge timing are unknown.

HW2 and HW4 independently confirm upward pitch release. HW2 is particularly
useful because both endpoints are nearly a uniform scale shift from HW1, which
supports the present general descent shape despite component variation.

## Highest-value next work

1. Create the dedicated retrigger branch from `main` at or after `4e40966`.
2. Run `tools/beeper-curve-test.py`, `tools/tone-test.sh`, and
   `tools/memdecode-test.sh` before changing RTL and save the output as the
   branch baseline.
3. Add a simulation-only trace for every Q edge during a reproducible Gunfighter
   sequence. Log time plus `Q`, `snd_half`, `snd_drive_half`, `snd_state`,
   `snd_curve_cnt`, `snd_recover_cnt`, and `snd_amp`. The critical missing
   evidence is exact pulse/gap duration, not another acoustic ridge alone.
4. Reduce the trace to explicit single-, double-, and triple-hit timing cases in
   the Python model. Current tests cover one representative double hit and a
   repeated 120/40 ms stress case, but not the actual Gunfighter cadence.
5. Prototype retrigger transition rules in Python before editing RTL. Prefer one
   continuous control state whose motion responds naturally to Q changes over a
   fixed second-pulse target. Possible directions include preserving recovery
   velocity, a small second-order/inertial state, or making the hidden contour
   interaction depend only on live state and elapsed edge timing.
6. Compare every candidate against Concentration / Match and Speedway as well as
   Gunfighter. A Gunfighter improvement that breaks the accepted Concentration
   double pulse or bends rapid Speedway pips is not acceptable.
7. When new hardware recordings arrive, prioritize controlled isolated, double,
   and triple Gunfighter hits after a long recovery interval. A simultaneous or
   instrumented Q-edge trace would be much more valuable than additional
   unlabeled gameplay audio.

## Guardrails

- Do not tune behavior by game identity or cartridge CRC.
- Do not reset the analog pitch state on every Q rise.
- Do not change the accepted upper/floor endpoints merely to match HW2 or HW4.
- Do not combine retrigger work with the separate waveform/timbre problem. The
  current oscillator is a symmetric square wave, while the NE555 hardware likely
  has an approximately 11:6 high/low ratio. That deserves its own branch/change.
- Do not use the 26/48 video comparison score as an audio-quality metric. It is a
  regression baseline only.
- Keep synthesis cost modest and maintain Studio III/CDP1864 tone isolation.

## Validation and release baseline

The released test build is:

- `releases/Studio-II_20260827.rbf`
- size: 2,667,572 bytes
- SHA-256: `6C3FBD42B71F201CB69C6372532326C64511043DA76ABE2F2EC65C8C9C8AF9C3`

Before release, the following passed:

- clean headless Verilator build;
- `tools/beeper-curve-test.py`;
- `tools/memdecode-test.sh`;
- `tools/tone-test.sh`;
- Quartus compilation with zero errors and positive setup/hold slack.

The corrected Studio II visual regression sweep uses the local `software/`
library and returns the established 26/48 frame score (8/10 built-ins and 18/38
cartridge frames). Conic and Visicom cartridge images are also under `software/`,
but their separate system firmware images are not present in this checkout.

## Relevant files

- `rtl/rcastudioii.sv` — live beeper implementation
- `tools/beeper-curve-test.py` — executable behavioral model and constraints
- `tools/analyze-beeper-recordings.py` — reusable acoustic analyzer
- `docs/multi-unit-beeper-analysis-2026-08-27.md` — HW2/HW3/HW4 findings
- `docs/beeper-attack-inertia-handoff-2026-08-26.md` — detailed previous analysis
- `docs/gunfighter-beeper-analysis.md` — original Gunfighter hardware study
- `docs/concentration-match-beeper-analysis.md` — accepted double-pulse evidence
- `audio_refs/` — local hardware recordings and earlier analysis images
- `software/StudioII-Cartridges/gunfighter.st2` — local Gunfighter cartridge

## Suggested next-chat prompt

Create a new branch from the clean `main` baseline and continue the Studio II
beeper retrigger investigation using
`docs/beeper-retrigger-handoff-2026-08-27.md`. Focus on the unnatural Gunfighter
double/triple-hit behavior. First preserve and trace the released implementation;
then model the actual Q-edge cadence and prototype a continuous-state retrigger
rule without changing the accepted pitch endpoints, release envelope, or rapid
Speedway behavior. Keep Concentration / Match as a protected regression case.

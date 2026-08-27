# Studio II beeper investigation handoff

Date: 2026-08-25  
Branch: `beeper`  
Repository: `C:\Workspace\Git\StudioII_MiSTer`

## Objective

Replace the Studio II's simplistic gated square-wave sound with a model that
reproduces the real NE555 circuit's continuous analog pitch state, downward sweep,
intrinsic upward release scoop, amplitude decay, and memory across rapid Q pulses.

This applies only to the Studio II discrete beeper.  Studio III / MPT-02 machines
continue to use the CDP1863/CDP1864 programmable-tone path.

## Current worktree

Tracked files modified:

- `rtl/rcastudioii.sv`
- `CLAUDE.md`

Untracked analysis files:

- `tools/analyze-beeper-recordings.py`
- `docs/gunfighter-beeper-analysis.md`
- `docs/concentration-match-beeper-analysis.md`
- `docs/outbreak-beeper-analysis.md`
- `docs/pacman-beeper-analysis.md`
- `docs/speedway-tag-beeper-analysis.md`
- `docs/mathfun-beeper-analysis.md`
- this handoff

Generated frame CSVs exist under `docs/` but are ignored by the repository's
current ignore rules.  They can be regenerated with the analyzer.

No commit has been made.  `git diff --check` and Python syntax checks pass.  A
full RTL compile/lint has not been run because a local HDL compiler was not
available in this session.

## Current RTL constants and behavior

The implementation begins near `rtl/rcastudioii.sv:1213`.

| Parameter | Current value | Result |
| --- | ---: | ---: |
| Beeper clock | approximately 1.760229 MHz | `ce_pix` rate |
| Upper half-period | 1400/1401 clocks, 574/1024 long | approximately 628.402 Hz |
| Lower half-period | 1742 clocks | approximately 505.232 Hz |
| Initial dwell | 44,011 clocks | approximately 25 ms |
| Eight decay bands combined | 308,132 clock ticks | approximately 175.05 ms |
| Attack-to-floor total | dwell + decay | approximately 200.05 ms |
| Silent full recovery | current step count | approximately 38.9 ms |
| Audible retrigger recovery | current step count | approximately 19.4 ms |

The exact decay intervals are `1504, 940, 658, 517, 517, 658, 940, 1504`
across eight nearly equal divider ranges.

Current behavior when Q falls is still incorrect: `snd_out` is forced low
immediately, pitch recovers silently, and no amplitude-decaying release is heard.
On a close Q-high retrigger, `SND_RECOVER` forces an audible climb toward the upper
pitch before holding/decaying again.

## Recording evidence

### Endpoint and timing summary

| Source | Principal / upper region | Lowest reliable region | Important timing |
| --- | ---: | ---: | --- |
| Gunfighter | 628.4 Hz clean-pip median | 524--527 Hz partial trough | cactus family reaches trough near 95--105 ms, then levels/scoops |
| Concentration / Match | approximately 628--629 Hz | 515--525 Hz during repeated parts | short 173--180 ms; multi 308--322 ms; one long sequence approximately 739 ms |
| Outbreak | pips average approximately 627 Hz | 514--516 Hz release trough | long notes 227--238 ms; trough near 130 ms, then intrinsic upscoop |
| Pac-Man | attack region approximately 618--619 Hz in this source | sustained 505.278 Hz plateau | settles by roughly 200 ms; holds over 0.5 s; releases to 534--538 Hz |
| Speedway / Tag | 621.45 Hz median | no meaningful droop | fastest attacks every 49.9 ms, approximately 20 Hz |
| Math Fun | 614.14 Hz retail-pip region | long-note floor median 497.82 Hz | nine long notes settle near floor in approximately 200 ms, then hold |

Absolute tuning varies between console/recording sources.  Pac-Man and Math Fun
put the sustained floor at approximately 505.3 and 497.8 Hz respectively.  The
current 505.232 Hz divider target follows the Pac-Man capture; Math Fun documents
normal lower-tuned variance.  Do not combine an upper endpoint from one source and
a floor from another to infer component tolerance without normalizing for source
tuning.

### Confirmed analog behavior

1. **The principal pitch is in the E-flat-5 neighborhood.**  Clean hardware pips
   cluster near 628.4 Hz on the first console; the Speedway source centers at
   621.45 Hz.
2. **The sustained floor is in the B4 neighborhood.**  Pac-Man holds 505.28 Hz;
   Math Fun repeatedly holds about 497.82 Hz.  Earlier 514--525 Hz values were
   near-floor release turnarounds, not the final asymptote.
3. **The complete descent is about 200 ms, not 400 ms.**  Math Fun supplies nine
   repeated long examples.  The current model uses 25 ms dwell + 175 ms decay.
4. **The upward S-tail is intrinsic to release.**  Outbreak has no programmed
   after-note, yet every long note turns upward while fading.  Pac-Man and Math
   Fun repeat the same behavior after long stable plateaus.
5. **Pitch and amplitude remain audible after Q falls.**  Therefore Q is a logic
   drive into the analog circuit, not an instantaneous audio mute.
6. **State survives across Q gaps.**  Concentration/Match multi-part sounds and
   Gunfighter overlaps resume from partially recovered electrical states.
7. **A "pip" is not a separate sound model.**  Joyce Weisbecker keeps Speedway /
   Tag pulses inside the initial-pitch window and repeats them as fast as about
   20 Hz.  Math Fun's retail-style pips repeat near 6 Hz and last long enough to
   droop slightly.  Continuous circuit state plus the game's Q timing must produce
   both results.

### Important source caveats

- `mathfun1.ogg`, `mathfun2.ogg`, and `mathfun3.ogg` have different container
  hashes but decode to identical PCM (`MD5 27e570400503e8c1831c538170293349`).
  Treat them as one 183.04-second source, not three independent captures.
- Math Fun contains persistent interference near 316 Hz and 2.983 kHz.  The 316
  Hz line continues through silence and is not the beeper floor.
- The Speedway / Tag file is concatenated from six active sections separated by
  brief silences.  One boundary is only about 42 ms.
- Acoustic pulse width is longer than programmed Q-high time because the hardware
  release persists.  Do not infer exact Q duration from the microphone envelope.
- Compressed/source recordings support pitch and timing well, but not a final
  absolute amplitude calibration.

## Analysis tooling and data

`tools/analyze-beeper-recordings.py`:

- decodes Ogg through FFmpeg;
- detects events in a configurable frequency band;
- tracks the fundamental in overlapping 36 ms frames;
- accepts `--detect-min`, `--detect-max`, `--pitch-min`, and `--pitch-max`;
- writes frame-level CSV with `--csv`.

Use the normal approximately 500--700 Hz pitch range for most clips.  Math Fun was
analyzed with detection at 450--700 Hz and pitch tracking at 480--700 Hz to exclude
its 316 Hz interference while retaining its lower-tuned floor.

Original recordings remain in `C:\Users\Elle\Downloads\`:

- `test1.ogg`--`test7.ogg` — Gunfighter
- `cm1.ogg`--`cm7.ogg` — Concentration / Match
- `outbreak1.ogg`--`outbreak7.ogg` — Outbreak
- `pacman1.ogg`--`pacman3.ogg` — Pac-Man
- `RCA Studio II speedway tag [aU8HEn9Oas8].ogg` — Speedway / Tag
- `mathfun1.ogg`--`mathfun3.ogg` — Math Fun, identical decoded audio

## Remaining engineering work

### Highest priority: audible release architecture

The existing one-bit `audio` interface and top-level fixed `+6000/-6000` mapping
cannot express a decaying amplitude envelope cleanly.  The next implementation
should evaluate a signed/multibit Studio II sample path while preserving the
Studio III tone path.

A useful conceptual state model is:

1. `DRIVEN_HOLD` — Q high, initial principal-pitch window;
2. `DRIVEN_DECAY` — Q remains high, pitch descends toward the floor;
3. `AUDIBLE_RELEASE` — Q low, amplitude fades while pitch turns upward;
4. `SILENT_RECOVERY` — release is inaudible but control voltage continues toward
   the upper state.

A Q-high transition during release or silent recovery must resume from the
instantaneous analog pitch/amplitude state.  It must not teleport to the upper
pitch or be forced to finish a canned recovery glide.

### Validation needed

1. Obtain or generate Q-edge traces for the same games and align them with the
   recordings.  This separates programmed gate timing from the analog tail.
2. Fit the decay curve shape, not only its endpoint and total duration.  The
   current eight-band symmetric S-curve is cheap but has not been numerically fit
   to Pac-Man/Math Fun frame trajectories.
3. Measure release amplitude and pitch jointly from Outbreak, Pac-Man, and Math
   Fun.  Prioritize relative envelope shape over absolute recording gain.
4. Test at least these patterns:
   - Speedway approximately 20 Hz pulses stay near the principal pitch;
   - Math Fun approximately 6 Hz pips droop slightly;
   - Outbreak long note reaches its trough and scoops upward with no next note;
   - Pac-Man/Math Fun sustained notes hold the floor, then release upward;
   - Concentration multi-parts retain state across short gaps.
5. Run Verilator lint/headless tests and a Quartus map/build after the interface
   change.  No full RTL validation has been run for the current worktree.

## Suggested next-chat prompt

```text
Continue the Studio II beeper work on the checked-out `beeper` branch in
C:\Workspace\Git\StudioII_MiSTer. Read
docs/beeper-handoff-2026-08-25.md and the linked per-game analysis documents.

The recording analysis is complete enough to establish approximately 628.4 Hz
upper pitch, approximately 505.2 Hz modeled floor with console/source variance,
about 200 ms attack-to-floor timing, continuous state across Q transitions, and
an intrinsic upward-pitch amplitude-decaying release after Q falls. The present
RTL still mutes immediately on Q-low and cannot reproduce that release.

First inspect all existing worktree changes without discarding them. Then design
and implement the smallest clean signed/multibit audio-path change that adds an
audible release and preserves analog state across retriggers. Add focused
simulation coverage for sustained notes, isolated release, rapid Speedway pulses,
and close multi-part retriggers. Validate proportionately and document any model
constants that remain provisional.
```

# Outbreak beeper cluster analysis

Source: `outbreak1.ogg` through `outbreak7.ogg`, Lee Romanow's Outbreak,
recorded from Studio II hardware and provided 2026-08-25.

## Sound-family identification

Outbreak uses only two semantic sounds:

- a pip, repeated in `outbreak1`, `outbreak3`, `outbreak6`, and `outbreak7`;
- a long note, captured once each in `outbreak2`, `outbreak4`, and `outbreak5`.

The detector finds about 101--119 ms of acoustic activity for ordinary pips.  The
three long-note captures last about 227--238 ms including their fading tails.

## Pip

The pips begin around 628--632 Hz and spend most of their audible duration around
625--629 Hz.  Across 31 cleanly tracked pip events, the median of each event's
ridge has a cluster median of 627.1 Hz.  This is consistent with a brief droop
from the approximately 628.4 Hz freshly charged pitch rather than a separate
fixed-frequency sound.

## Long note

The three long notes reproduce the same contour closely:

| Time from analyzed attack | Fundamental |
| ---: | ---: |
| 0--8 ms | about 628--631 Hz |
| 16--32 ms | about 609--620 Hz |
| 40--48 ms | about 557--570 Hz |
| 64 ms | about 545--548 Hz |
| 80 ms | about 530--533 Hz |
| 96 ms | about 526 Hz |
| 112 ms | about 518--520 Hz |
| 128--136 ms | minimum about 514--516 Hz |
| 144 ms | about 519--525 Hz |
| 152--176 ms | rises to about 529--554 Hz, then fades |

The three independent minima are approximately 516.1, 514.4, and 515.4 Hz.  They
are extremely consistent measurements of where this programmed note releases and
turns upward, but they are not measurements of the sustained oscillator floor.

## Intrinsic release tail

Outbreak provides the clean disambiguation missing from Gunfighter and
Concentration/Match.  There is no second programmed note after the long sound,
yet every long-note capture turns upward after its approximately 515 Hz trough
and remains audible while rising toward roughly 534--554 Hz.  The S-shaped tail
is therefore an intrinsic analog release response.  It is not conditional on a
following Q-high retrigger.

This also explains why similar upward tails recur so consistently in the other
games.  A following pip may interrupt, extend, or expose the response, but it is
not what creates the response.

## Model implications

The present RTL cannot reproduce this behavior:

1. When Q falls, it immediately forces `snd_out` low, so the modeled circuit has
   no audible release at all.
2. Pitch recovers silently while Q is low and is heard only if another Q-high
   arrives.  Outbreak proves that recovery itself remains audible on release.
3. The note releases around 130 ms near, but not quite at, the sustained floor;
   a later Pac-Man capture settles at approximately 505.3 Hz.

A faithful revision needs distinct driven, release, and silent-recovery phases.
On Q falling, the oscillator should continue through an amplitude-decaying
release while its control pitch turns upward.  Once the release becomes inaudible,
the same control state can continue charging silently.  A Q-high during release
should resume from the instantaneous analog state rather than reset or complete a
mandatory climb to the upper pitch.

Implementing the amplitude decay cleanly will require more than changing divider
constants because the current core exposes the Studio II beeper as a one-bit
square wave.  The Outbreak recordings establish the required release behavior and
timing, but no RTL release implementation is made in this analysis pass.  A later
very long Pac-Man capture supersedes the provisional extrapolation and measures
the sustained floor directly at approximately 505.3 Hz.

Frame-level measurements are in `docs/outbreak-frequency-frames.csv`.

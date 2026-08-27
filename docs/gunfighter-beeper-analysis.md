# Gunfighter beeper cluster analysis

Source: `test1.ogg` through `test7.ogg`, recorded from Studio II hardware and
provided 2026-08-25.  The clips contain Gunfighter pips, cactus hits, a little
mechanical joystick noise, and several likely overlaps/retriggers.

## Method

The recordings are 44.1 kHz stereo Vorbis.  Analysis mixes them to mono, isolates
the 480--760 Hz fundamental band for event detection, and follows the strongest
fundamental ridge in overlapping 36 ms Hann-windowed frames.  The frame length is
short enough to follow the bends while averaging over enough oscillator cycles to
reject the joystick clicks.  Harmonics near 1.25 kHz and 2.51 kHz independently
confirm that the approximately 628 Hz ridge is the fundamental, not a harmonic.

The reusable analysis is in `tools/analyze-beeper-recordings.py`; its frame-level
output for this cluster is `docs/gunfighter-frequency-frames.csv`.

## Results

| Sound family | Observations | Measured behavior |
| --- | ---: | --- |
| Clean/near-clean pips | 9 | Stable cluster median 628.4 Hz; most are within about 1 Hz, with two close-following examples near 625 Hz |
| Cactus-family attacks | repeated in tests 1, 2, 4, and 7 | Start at the same approximately 628 Hz upper pitch and reach about 524--527 Hz around 95--105 ms after the detected attack |
| Leveled cactus tails | repeated | After the low point, the ridge returns to roughly 546--553 Hz instead of continuing monotonically downward |
| Likely cactus-plus-pip overlaps | tests 2, 4, and 7 | The shared cactus contour is followed near 150 ms by a roughly 603--611 Hz region rather than an instantaneous reset to 628 Hz |

Representative cactus-family trajectory (times are approximate relative to the
analyzed attack and are consistent across several clips):

| Time | Fundamental |
| ---: | ---: |
| 0 ms | 628--629 Hz |
| 24 ms | about 614 Hz |
| 36 ms | about 609 Hz |
| 48 ms | about 557--562 Hz |
| 72 ms | about 538--540 Hz |
| 96 ms | about 524--525 Hz |
| 120 ms | about 548--551 Hz |
| 140 ms | about 546--553 Hz |
| 156--192 ms, when extended/overlapped | about 603--611 Hz |

## Interpretation

The clearest finding is that the principal pitch is near E-flat 5, not E-flat 4.
The measured points are best treated as board-specific oscillator pitches rather
than snapping them to equal temperament: approximately 628.4 Hz at the top and
524.8 Hz at the cactus sound's release turnaround.  The latter is not the
circuit's sustained floor.

The repeated tail shape supports the observation that logical Q duration alone is
not enough to describe the audible pitch.  In particular, a monotonic software
"note sweep" would miss both the approximately 550 Hz leveling region and the
approximately 607 Hz partial recovery exposed around a closely following pip.
Later Outbreak captures show that the upward S-tail is intrinsic release behavior,
not something created by the following pip.  The pip can interrupt or expose that
analog response, but the control-voltage and release state already exist.

The short cluster does **not** establish the sustained floor.  A later very long
Pac-Man capture does: it settles at approximately 505.3 Hz.  Later repeated Math
Fun notes confirm approximately 200 ms from attack to the stable floor.  The
current branch uses the measured endpoint and that complete-sweep timing.

## Core constants informed by this cluster

At the core's approximately 1.760229 MHz beeper clock:

- upper half-period: 1400/1401 clocks, with 574/1024 long cycles, approximately
  628.4 Hz;
- sustained-floor half-period: 1742 clocks, approximately 505.2 Hz.

Both endpoints are now measured: Gunfighter supplies the upper pitch and Pac-Man
supplies the long-sustained floor.  They span about 377.5 cents, close to a major
third.  The decay and recovery intervals are scaled to preserve their prior
wall-clock timing.

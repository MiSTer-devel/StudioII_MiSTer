# Pac-Man beeper analysis

Source: `pacman1.ogg` through `pacman3.ogg`, recorded from Studio II hardware and
provided 2026-08-25.

## Sustained floor

`pacman1.ogg` contains the first very long sustained note in the recording set.
After descending, its fundamental remains essentially stationary for more than
half a second:

- plateau median: 505.278 Hz;
- plateau mean: 505.360 Hz;
- standard deviation: 0.306 Hz;
- observed plateau range: 505.010--506.120 Hz.

With the core clock, an integer half-period of 1742 clocks produces 505.232 Hz.
This is adopted as the measured sustained floor.

The floor is musically in the B4 neighborhood.  Relative to equal-tempered B4 at
493.883 Hz it measures about 39.5 cents sharp in the recording, not flat in
absolute concert tuning.  More importantly for the circuit model, it lies about
377.5 cents below the measured 628.4 Hz upper pitch, close to a major-third span.

## Long-note contour

Approximate timing from the first reliable analysis frame:

| Time | Fundamental |
| ---: | ---: |
| 0--8 ms | about 618--619 Hz |
| 24 ms | about 589 Hz |
| 40 ms | about 558 Hz |
| 64 ms | about 536 Hz |
| 96 ms | about 521 Hz |
| 120 ms | about 514 Hz |
| 160 ms | about 508 Hz |
| 200 ms onward | approximately 505.3 Hz plateau |
| 886 ms | approximately 520 Hz on release |
| 894--910 ms | approximately 534--538 Hz while fading |

The capture directly supersedes the earlier 314.3 Hz floor extrapolation.  The
514--525 Hz troughs in the other games were already near the true floor; they
released before settling on the stable 505.3 Hz plateau.

## Short notes and intrinsic release

`pacman2.ogg` and `pacman3.ogg` descend from about 619 Hz to roughly 554--560 Hz,
then scoop upward to approximately 562--566 Hz as they fade.  The very long note
does the same thing after its plateau, rising from about 505 Hz to 534--538 Hz.
There is no required following note in either case.  Pac-Man therefore provides a
second independent confirmation, after Outbreak, that the upward scoop is an
intrinsic analog release response.

## Model decision

The RTL sustained floor is changed to 505.232 Hz.  A later Math Fun recording
provides nine repeated long notes and confirms approximately 200 ms from attack to
the stable floor, so the modeled curve is subsequently shortened to a 25 ms dwell
plus about 175 ms of decay.

The audible release remains unimplemented: the present one-bit output is still
silenced immediately when Q falls.  Pac-Man strengthens the requirement for a
future amplitude-decaying release state whose pitch recovers upward from the
instantaneous control voltage.

Frame-level measurements are in `docs/pacman-frequency-frames.csv`.

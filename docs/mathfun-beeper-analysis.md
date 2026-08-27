# Math Fun beeper analysis

Source: `mathfun1.ogg` through `mathfun3.ogg`, provided 2026-08-25.

## Source note

The three Ogg files have different container hashes but decode to the exact same
PCM audio (`MD5 27e570400503e8c1831c538170293349`).  They are therefore one
183.04-second recording supplied three times, not three independent captures.
The analysis is run once against `mathfun1.ogg`.

The source contains persistent narrowband interference near 316 Hz and 2.983 kHz.
The 316 Hz line is present through silence and is not the beeper floor.  Event
tracking therefore uses a 450--700 Hz detection band and a 480--700 Hz pitch band.

## Long notes

Nine clean long-note events are readily repeatable in the recording.  Their
acoustic durations are about 0.78--0.85 seconds.  Each descends to a stable floor,
holds it for most of the programmed duration, and then scoops upward on release.

Across those events:

- median floor: 497.82 Hz;
- individual event medians: approximately 497.63--498.80 Hz;
- typical release scoop: roughly 497 Hz to 516--530 Hz before fading.

This source is tuned lower than the Pac-Man capture, whose plateau is 505.28 Hz.
The difference is consistent with console oscillator and source-transfer variance;
both place the floor in the B4 neighborhood and show the same release topology.

A representative Math Fun descent is:

| Time from analyzed attack | Fundamental |
| ---: | ---: |
| 0 ms | about 614 Hz |
| 32 ms | about 562 Hz |
| 64 ms | about 531 Hz |
| 96 ms | about 518 Hz |
| 128 ms | about 507 Hz |
| 160 ms | about 503 Hz |
| 192--224 ms | reaches about 498--500 Hz |
| 224--730 ms | stable approximately 497--499 Hz plateau |
| 734--754 ms | release rises through roughly 501--519 Hz |

The nine repetitions establish approximately 200 ms from attack to the stable
floor much more reliably than the old approximately 0.4-second documentation.

## Retail-style pips

The ordinary short sounds cluster around 614.1 Hz in this source and last roughly
80--120 ms acoustically.  In the repeated run near 60 seconds, attacks are spaced
about 166 ms apart, or approximately 6.0 pips per second.  They commonly reach
roughly 600--605 Hz before release, so they are long enough to expose a small
droop.

This contrasts sharply with Speedway / Tag's fastest approximately 20 Hz pulses,
which stay at the principal pitch.  It reinforces that "pip" describes a game-level
usage pattern, not a separate oscillator mode.

## Model decision

The endpoint remains 505.232 Hz, matching the Pac-Man console while allowing for
Math Fun's lower-tuned source.  The eight decay-band intervals are shortened so
their combined duration is about 175 ms; with the existing 25 ms initial dwell,
the modeled oscillator reaches its floor in about 200 ms.

The intrinsic amplitude-decaying release remains unimplemented.  Math Fun adds
nine more examples showing that the post-floor upscoop occurs before silence and
does not require a following note.

Frame-level measurements are in `docs/mathfun-frequency-frames.csv`.

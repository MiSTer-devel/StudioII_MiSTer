# Concentration / Match beeper cluster analysis

Source: `cm1.ogg` through `cm7.ogg`, recorded from Studio II hardware and
provided 2026-08-25.

## Sound-family identification

| Recording | Contents |
| --- | --- |
| `cm1.ogg`--`cm3.ogg` | one short sound each |
| `cm4.ogg` | one multi-part sound |
| `cm5.ogg` | the sole long sequence |
| `cm6.ogg` | one multi-part sound |
| `cm7.ogg` | multi-part, short, multi-part |

The short sounds last about 173--180 ms acoustically.  The repeated multi-part
sounds last about 308--322 ms.  The long sequence occupies about 739 ms from its
first detected attack to its final tail and contains a roughly 23 ms separation
near 0.31 seconds.

## Frequency measurements

The same 36 ms sliding-ridge analysis used for the Gunfighter cluster was applied
here.  Frame-level output is in `docs/concentration-match-frequency-frames.csv`.

All three sound families begin in the same upper-pitch neighborhood established
by Gunfighter.  Edge frames read as high as 631--633 Hz because they mix the
attack transient with the tone; the settled upper ridge is about 628--629 Hz.

The short sound has a highly repeatable contour:

| Time from analyzed attack | Fundamental |
| ---: | ---: |
| 0--12 ms | about 628--632 Hz |
| 24 ms | about 612--622 Hz |
| 36--60 ms | about 548--559 Hz |
| 72 ms | about 539 Hz |
| 84 ms | about 532 Hz |
| 96 ms | about 525 Hz |
| 108 ms | about 527--529 Hz |
| 120--132 ms | about 545--547 Hz |

The multi-part sound initially follows that contour, then exposes another partial
recovery and descent instead of returning to the upper pitch:

| Time from analyzed attack | Fundamental |
| ---: | ---: |
| 96--120 ms | about 521--525 Hz |
| 144--168 ms | about 559--561 Hz |
| 180 ms | about 548 Hz |
| 204 ms | about 531 Hz |
| 216--228 ms | about 520--523 Hz |
| 240--252 ms | about 517--518 Hz |

The multi-part contour agrees across `cm4`, `cm6`, and both instances in `cm7`.
The single long sequence repeats the same partial-recovery/descending structure
several times.  Its later components reach approximately 515--518 Hz, lower than
the 524--527 Hz low point reached by the shorter Gunfighter cactus captures.

## Electrical interpretation

These recordings strongly validate the approximately 628.4 Hz upper setting now
used by the core.  Their 515--525 Hz troughs are near-floor release turnarounds,
not quite the isolated asymptote.  A later very long Pac-Man note establishes the
sustained floor at approximately 505.3 Hz; repeated Math Fun notes later confirm
about 200 ms from attack to the stable floor.

The semantic sounds are not independent equal-pitch notes.  Low-amplitude
separations appear inside the multi-part waveforms, and each audible portion
continues from the capacitor's analog state.  It rises only to roughly 560 Hz
before descending again.  Outbreak later confirms that this upward tail exists
intrinsically on release rather than being created by a subsequent note.  The
long sequence retains still more memory:
after its approximately 23 ms central separation, the next measured region starts
around 607 Hz rather than resetting cleanly to 628 Hz.

This is direct evidence for carrying pitch-control and release state across Q-low
gaps.  It also cautions against forcing every Q-high transition to finish an
audible climb all the way to the upper pitch.  The present core does that during
its `SND_RECOVER` state, so multi-part Concentration sounds are a useful future
test case once the isolated charge/discharge sweeps are available.

## Model decision

This cluster does not quite measure the true lower asymptote.  Tuning the floor to
the sole long sequence would fit this game's release timing rather than the analog
circuit.  The branch instead uses the later Pac-Man sustained plateau at about
505.3 Hz and uses Math Fun's repeated approximately 200 ms complete sweeps for
the curve timing.

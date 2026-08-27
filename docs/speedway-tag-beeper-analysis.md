# Speedway / Tag beeper analysis

Source: `RCA Studio II speedway tag [aU8HEn9Oas8].ogg`, a concatenated recording
of Joyce Weisbecker's Speedway / Tag, provided 2026-08-25.

## Concatenation structure

The file is about 7.00 seconds long and contains six active sections separated by
silences.  Approximate active spans are:

1. 0.003--1.105 s
2. 1.183--2.001 s
3. 2.043--2.658 s
4. 2.754--4.287 s
5. 4.356--4.811 s
6. 4.965--6.947 s

The short 42 ms separation between sections 2 and 3 is still a real concatenation
boundary rather than part of the game's pulse rhythm.

## Principal pitch

Across 1,210 reliable analysis frames, the fundamental remains tightly grouped:

- median: 621.45 Hz;
- mean: 622.00 Hz;
- 10th--90th percentile: 620.08--625.01 Hz.

That is essentially E-flat 5 for this recording source.  It is a little below the
approximately 628.4 Hz measured on the other hardware captures, plausibly from
console tuning, recording, or source-transfer variance.  It does not show the
sustained downward movement seen in longer programmed notes.

## Pulse timing

The smallest repeated acoustic pulse shapes have a high-energy width around
36--38 ms.  Their actual programmed Q-high interval may be shorter because the
microphone/recording retains the analog release after Q falls.

The fastest regular passages repeat attacks every approximately 49.9 ms, or about
20.0 pulses per second.  This leaves only roughly 12--13 ms of low acoustic energy
between adjacent pulse shapes.  Other sections use attack spacings around 53--59
ms and 84 ms, plus patterned omissions and groupings.

This is substantially faster articulation than the other recording clusters.  It
also explains why pitch frames spanning several pulses can appear continuous even
though the amplitude waveform is strongly pulsed.

## Interpretation

"Pip" is not a portable electrical envelope or a fixed pitch gesture.  In these
games it describes the audible result of very short Q programming.  Weisbecker
keeps each driven interval inside the circuit's initial-pitch window and creates
rhythm by rapidly repeating those intervals.  The principal frequency therefore
does not have time to develop into the droop heard in Gunfighter, Concentration,
Outbreak, or Pac-Man.

This argues against giving a pip its own hard-coded sound shape.  The core should
model the analog state continuously and let each game's Q timing determine whether
the result is a stable principal-pitch pulse, a partial droop, a sustained floor,
or a release scoop.

## Model decision

No divider or curve constants are changed from this recording.  The source
validates the principal E-flat-5 neighborhood and provides a future timing test:
rapid approximately 20 Hz pulses must remain near the upper pitch while preserving
their individual analog releases.  The current immediate Q-low mute still cannot
reproduce those releases accurately.

Frame-level measurements are in `docs/speedway-tag-frequency-frames.csv`.

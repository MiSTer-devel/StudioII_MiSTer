# MPT-02 audio reference

## Evidence

FliP supplied nine recordings and `tunebox.bin` in `refs/mpt-02-audio/`.
The accompanying `mpt-02-audio.txt` identifies a PAL MPT-02 with a CDP1864.
Audio was captured directly from the chip, before RF mixing; this machine
has no internal speaker. Treat this as one console's chip output reference.
It does not establish the standalone CDP1863's behavior or the RF audio path.
FliP's recording 7 has an audible overlay; treat its measurements with caution.

Source: https://forums.atariage.com/topic/209519-rca-studio-ii-gold-mine-an-interview-with-the-studio-2-production-manager/?do=findComment&comment=5913450

Tunebox selects tunes with keys 1-9; key 0 stops playback. Tune 1 is the
Bingo cartridge's "Bingo was his name-o" tune. The remaining tunes include
Fur Elise and Happy Birthday; their individual key assignments are not listed.
The ROM includes native 1802 code using OUT 4 at file offset `0x103`.
Confirm its launch and interpreter requirements before automating playback.

ROM size: 1024 bytes. SHA-256:
`30190213c205467578d4f86936c3735a22a0abc17484d5380603111da425eeff`

All recordings are stereo AAC at 48000 Hz. Container durations:

| File number | Seconds |
| --- | ---: |
| 1 | 6.929 |
| 2 | 15.836 |
| 3 | 6.747 |
| 4 | 13.819 |
| 5 | 22.223 |
| 6 | 86.666 |
| 7 | 34.913 |
| 8 | 12.409 |
| 9 | 18.472 |

## Current RTL baseline

- `rtl/pixie/cdp1863.v` supplies both Studio III tone paths. PAL selects
  a half-period of `4 * (latch + 1)` CPU machine cycles.
- OUT 4 loads the latch. Q low clears the counter and holds the output low.
  A falling Q also restores latch `0x35`; the source marks this as uncertain.
- `rtl/studio2_beeper_inline.svh` routes both Studio III tone paths through
  `mpt02_audio`, with +/-6000 input levels.
- `tools/tone-test.sh` checks divider frequency, pitch selection, Q-low edge
  silence, and Studio II isolation. These are model checks, not capture matches.
- The headless simulator counts audio edges and can trace Q transitions;
  it does not currently export a sampled waveform for this comparison.

## Comparison work

1. Confirm tune/file mapping and reproduce Tunebox on the PAL core. Record
   OUT 4 values, Q transitions, and their cycle timestamps alongside audio.
2. Measure stable note fundamentals against `f_cpu / (64 * (latch + 1))`.
   Fit a common clock scale separately from divider errors.
3. Compare note starts, repeated notes, rests, pitch writes while Q is low,
   and stop behavior. Check which latch/reset cases the ROM actually exercises;
   request targeted hardware tests for cases these tunes cannot distinguish.
4. Compare duty cycle, harmonics, and onset/decay after timing is established.
   Account for AAC and the capture chain before attributing shaping to hardware.
5. Change only behavior supported by measurements. Add directed regressions
   for confirmed digital behavior and preserve Studio II and NTSC coverage.

## Filtering comparison

The captures are substantially softer than the current square-wave output.
Median harmonic levels for 134 windows near 379.3 Hz, relative to the
fundamental:

| Harmonic | Capture (dB) | Current square wave (dB) |
| --- | ---: | ---: |
| 3 | -16.20 | -9.54 |
| 5 | -24.35 | -13.98 |
| 7 | -30.54 | -16.90 |
| 9 | -35.52 | -19.08 |

The default MiSTer IIR coefficients in `sys/sys_top.v` change these ratios by
less than 0.02 dB. Its DC blocker also has negligible effect here. This is an
analytic steady-state comparison with repository defaults, not a MiSTer capture;
user-selected filters and the analog output hardware are not included.

Across 586 accepted windows from all nine recordings, a square wave followed
by one RC low-pass pole at approximately 435 Hz fits the odd-harmonic ratios
with a median absolute error of 0.41 dB. This is an effective combined response,
not proof of a specific chip component.
The recording input and AAC encoding remain part of the measured path.

Method: decode at 48000 Hz, use the active channel, apply an 8192-sample Hann
window, and integrate five FFT bins per harmonic. Retain windows with over
94% of spectral power in the fundamental band. A synthetic square-wave check
recovers its expected harmonic ratios within 0.001 dB. Recording 1-2 audio
is on the left channel; 3-9 is on the right.

Local results and reproduction script are beside the captures:
`filter-analysis.json` and `check-filter.cjs`. Run from the repository root:
`node refs/mpt-02-audio/check-filter.cjs` (requires FFmpeg).

## Implemented estimate

`rtl/audio/mpt02_audio.sv` applies this response to Studio III audio using
`alpha = 101/8192` at the CPU machine-cycle enable (about 220029 Hz).
The resulting pole is approximately 434.4 Hz. The filter uses shifts and adds
with 16 fractional bits, retaining the existing +/-6000 input levels.
Its state continues through Q transitions, CLEAR, pitch writes, and mute;
video reset restores the silent input level. Studio II and Visicom retain
their existing paths.

The NTSC CDP1863 path uses the same filter provisionally for listening tests.
TODO: validate the NTSC response against hardware recordings.

This is the best estimate from the supplied recordings. Pitch-generator
semantics remain unchanged. Pitch, transient, and envelope comparisons remain
pending; further hardware evidence can refine the response.

Run `make -C verilator mpt02-audio-test` to check step/release behavior,
clock-enable hold, reset, output bounds, and harmonics against the captures.

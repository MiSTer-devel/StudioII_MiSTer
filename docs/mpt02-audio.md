# MPT-02 audio reference

## Evidence

FliP supplied nine recordings and `tunebox.bin` in `refs/mpt-02-audio/`.
The accompanying `mpt-02-audio.txt` identifies a PAL MPT-02 with a CDP1864.
Audio was captured directly from the chip, before RF mixing; this machine
has no internal speaker. Treat this as one console's chip output reference.
It does not establish the standalone CDP1863's behavior or the RF audio path.
FliP's recording 7 has an audible overlay; treat its measurements with caution.

`refs/mpt-02-audio/Victory sounds/` adds ten numbered audio test samples,
a startup capture, and five gameplay videos. These are also PAL captures
using the same direct chip-output method, as confirmed by the user.
The eight tune files in that folder are byte-identical to originals 1-5
and 7-9. The filename for 7 identifies Mary Lamb with Jingle Bells overlaid.

The fullset's `2 Other/Q-Sound Test (2026.08.30) (FliP).txt` describes
selectable Q-on pulse length and Q-off delay, both roughly in milliseconds.
Keys 1/2 select on/off, 3 clears the value, 4/5/6 add 1/10/100,
7/8/9 subtract 1/10/100, and 0 starts or stops playback.
The numbered capture labels are nominal settings; measured timing is below.

Source: https://forums.atariage.com/topic/209519-rca-studio-ii-gold-mine-an-interview-with-the-studio-2-production-manager/?do=findComment&comment=5913450

Tunebox selects tunes with keys 1-9; key 0 stops playback. Tune 1 is the
Bingo cartridge's "Bingo was his name-o" tune. The supplied filenames identify
2 as Frere Jacques, 3 as Fur Elise, 4 as Ode to Joy, 5 as Twinkle Twinkle,
7 as Mary Lamb, and 8 as Jingle Bells. Tunes 6 and 9 remain unidentified.
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

`rtl/audio/mpt02_audio.sv` applies a one-pole low-pass to Studio III audio at the CPU machine-cycle enable (about 220029 Hz). The OSD option Audio & Video > Studio III Filter (`status[30:29]`) selects the response:

| Setting | alpha | Pole | Source |
| --- | ---: | ---: | --- |
| MPT-02 (default) | 101/8192 | 434.4 Hz | FliP's direct CDP1864 captures |
| Apollo 80 | 581/8192 | 2576 Hz | TLD1985's Academy Apollo 80 footage |
| Off | - | - | raw square wave |

The filter uses shifts and adds with 16 fractional bits, retaining the existing +/-6000 input levels. Its state continues through Q transitions, CLEAR, pitch writes, and mute; video reset restores the silent input level. Off follows the tone directly. Studio II and Visicom retain their existing paths. The headless simulator takes `--studio3-filter mpt02|apollo80|off`.

The NTSC CDP1863 path uses the same filter provisionally for listening tests.
TODO: validate the NTSC response against hardware recordings.

This is the best estimate from the supplied recordings. Pitch-generator
semantics remain unchanged. Pitch-write and latch-reset behavior still need
targeted hardware evidence.

Run `make -C verilator mpt02-audio-test` to check step/release behavior, clock-enable hold, reset, output bounds, and harmonics against both captures and the unfiltered square wave.

## Q Sound Test captures

The ST2 maps pages 04-07 and 0C-0F. Playback at `0C00` gates Q without
writing OUT 4. The delay at `043A` takes `220*n + 4*floor(n/256) + 10`
machine cycles, including its return. Each unit loops 35 times over
DEC/GLO/BNZ. For these settings, SEQ-to-REQ takes `220*n + 50` cycles
without interrupts or DMA. Off time also includes keypad polling.

The Victory BIOS interrupt handler at `001C` waits through active video
before returning. This stretches the delays and introduces frame-dependent
variation. The labels are not wall-clock milliseconds.

| On/off setting | Capture median period (ms) |
| --- | ---: |
| 10/10 | 60 |
| 10/20 | 82 |
| 10/30 | 117 |
| 20/30 | 140 |
| 30/30 | 163 |
| 50/30 | 221 |
| 100/30 | 360 |
| 100/50 | 418 |
| 100/80 | 498 |
| 100/100 | 556 |

With the fullset Victory PAL BIOS, RTL Q traces give period ranges of
104.24-116.82 ms for 10/30 and 540.71-553.29 ms for 100/100, at the core's
1.760229 MHz timebase. The captured default tone is about 506.44 Hz,
implying about 1.75026 MHz under the current divider model. Rescaling by
that inferred clock gives 104.83-117.49 ms and 543.79-556.44 ms.
This is consistent with the capture timing; it is not an independent
measurement of the console clock.

On the active right channel, a gated 506.44 Hz square wave with a 435 Hz
pole fits repeated onsets with median normalized RMS residuals of 3.5-5.7%
per recording, versus 42.5-43.4% without the pole. Release fits leave
4.5-11.4%. These comparisons use eight repeated bursts per file and 16 ms
windows, fitting gain, edge position, offset, and linear drift. Release
phase comes from the onset fit. AAC, capture response, and phase uncertainty
remain in the residual; no additional envelope model is justified here.
The comparisons support retaining the current PAL filter and default-tone gating.

Reproduction: build `make -C verilator headless mpt02-audio-test`, then run
`bash tools/trace-q-sound.sh` to record both Q traces. Analyze with:

```sh
node tools/analyze-q-sound.cjs refs/mpt-02-audio/q-sound-core-100-100.log refs/mpt-02-audio/q-sound-core-10-30.log > refs/mpt-02-audio/q-sound-analysis.json
```

The analysis uses a separate 300-800 Hz band and 5 ms RMS window
to locate bursts, then fits the original decoded waveform. Thresholded
burst widths include filter delay; the table uses onset-to-onset periods.

## Academy Apollo 80 footage (TLD1985)

`refs/mpt-02-audio/TLD1985/` holds two YouTube downloads from TLD1985: `Academy Apollo 80 test footage [kG9BFg_rviA].mkv` (1135 s) and `Biorythm Test Footage [7RonvuuTPAw].mkv` (137 s). Both are 640x480 at 25 fps with Opus audio at 48000 Hz; the two audio channels are identical. The capture point is unknown. Silent passages carry a 50 Hz buzz and its harmonics, which suggests an RF or TV audio path rather than a direct chip tap. This is a second console from the same family, not a second MPT-02.

Pitch: 23 distinct steady tones between 258 and 2278 Hz all fit `f_clk / (64 * (latch + 1))` within 0.02%, using latch values from 0x0B to 0x69. The default tone measures 506.32 Hz, which implies a 1.74984 MHz clock with latch 0x35. FliP's MPT-02 default tone implies 1.75026 MHz. This independently confirms the divider model and default latch on a second PAL console.

Timbre: the Apollo audio is much brighter than the MPT-02 captures. Median odd-harmonic levels for the default tone are H3 -10.7 dB, H5 -17.0 dB, H7 -21.2 dB, and H9 -24.5 dB. A square wave through one pole near 2.6 kHz fits all tones with a median absolute error of 0.61 dB. The 435 Hz pole errs by 8.0 dB, and an unfiltered square wave by 4.3 dB. A 2.6 kHz pole is close to the 3.18 kHz corner of PAL 50 us FM de-emphasis, so the TV or capture path may explain most of it. Even harmonics sit at -17 to -22 dB below 500 Hz and fall with frequency; their source is unclear.

Implication: these two sources disagree about the PAL low-pass. The MPT-02 tap may include an on-board RC network, or the Apollo path may lack one. Both responses are available as OSD settings (see Implemented estimate); MPT-02 stays the default until the capture points are known. Ask FliP where on the MPT-02 the audio was tapped, and ask TLD1985 how the Apollo audio was captured.

The video shows several Studio III games and the Biorhythm cartridge, which may help with PAL colour and layout comparisons. Local results and scripts: `refs/mpt-02-audio/tld1985-analysis.txt` and `tld-tones.py`, `tld-refine.py`, `tld-fit.py`.

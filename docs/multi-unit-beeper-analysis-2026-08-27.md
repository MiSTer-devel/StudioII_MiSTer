# Multi-unit Studio II beeper comparison

Source: the `hw2`, `hw3`, and `hw4` recordings under `audio_refs/`, provided
2026-08-27. Measurements use the same sliding fundamental-ridge method as the
earlier game-specific analyses, supplemented by whole-clip tracking for sustained
recordings that contain little or no silence.

## Board-to-board tuning

The recordings demonstrate material component-level variation between consoles.
Absolute pitch should therefore be treated as board-specific rather than snapped
to an equal-tempered note.

| Console | Fresh upper pitch | Sustained floor | Notes |
| --- | ---: | ---: | --- |
| Original HW1 reference | about 628.4 Hz | about 505.2 Hz | Current RTL reference |
| HW2 | about 669--671 Hz | about 539 Hz | Nearly a uniform +112-cent shift from HW1 |
| HW3 | not isolated cleanly | about 518.5 Hz | Two-pulse memory/retrigger capture |
| HW4 | about 662--665 Hz | about 524.5--525.3 Hz | Slightly wider and slower-looking sweep |

HW2 is particularly informative: its upper pitch and floor are both about 6.7%
higher than the current model. After normalizing that scale difference, its
long Freeway horn closely follows the accepted driven contour and approximately
200 ms floor approach. This supports retaining the current behavioral shape
without retuning the default to one newly measured board.

HW4's clean `doodle-hw4-10.ogg` sustained note settles near 524.54 Hz for about
one second. `doodle-hw4-09.ogg` and `freewayhorn-hw4-02.ogg` independently place
the same board's floor in the 524--526 Hz range. Its final approach appears to
take roughly 240--300 ms, showing that the control-capacitor time constant varies
as well as absolute oscillator pitch.

## Release and retrigger behavior

Audible upward release remains consistent across the tested hardware. It appears
in the HW2 and HW4 Freeway horns, multiple HW4 Doodle sounds, the HW4 vertical
Space War sound, and the HW3 capture. Depending on note length and recording
level, the ridge remains visible while rising from the sustained floor into the
550--600 Hz region.

`noshaders-hw3-01.ogg` contains the most useful new memory sequence. A first
driven region reaches an approximately 518 Hz plateau, recovers upward, exposes
a second crest around 595--598 Hz, and descends to the same plateau again. This
supports continuous analog state across Q transitions, but does not establish a
universal retrigger crest because the exact Q-high and Q-low edge timing is not
available.

The present fixed partial-recovery limit and hidden fresh-note contour remain a
provisional fit. Gunfighter double and triple hits are the highest-value next
capture target: isolated, double, and triple sequences should be recorded after
a long recovery interval and, ideally, aligned with an instrumented Q-edge trace.

## Release decision

No divider or retrigger constants are changed from this batch. The current core
is a useful unstable/test baseline: single-note pitch, driven descent, sustained
floor, audible release, and state continuity are substantially better supported
than before, while close multi-hit retriggers remain explicitly open to further
measurement. Avoid speculative retuning until additional consoles and repeatable
Gunfighter sequences are available.

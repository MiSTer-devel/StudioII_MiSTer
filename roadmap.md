# Roadmap

Only unfinished work belongs here. Accepted behavior belongs in the focused
technical documents; completed milestones belong in release notes and Git.

## Reference analysis

- Inventory original FLiP material with stable IDs, supplied descriptions,
  machine/capture metadata, sizes, and cryptographic hashes.
- Keep original `refs/` material local and immutable. Commit reusable analysis
  code and only the small derived measurements needed to support a decision.
- Build one repeatable video pipeline for colour clusters, geometry, sync, and
  temporal stability, with capture-path assumptions kept separate from source
  signal inferences.
- Extend the audio analyzer to process all useful events consistently, including
  confidence and contamination flags and one tuning scale per console.

## Fidelity work

### Studio II audio

- Apply one release estimator to the untrimmed archival and retail recordings
  before deciding whether the accepted upward recovery is too slow.
- Better constrain the early-attack knee without moving the accepted endpoints
  or regressing protected short-note, long-note, release, and retrigger cases.
- Produce focused test ROMs with known Q-high/Q-low intervals.
- Seek direct electrical or line-level captures with a recorded Q trace.

### Visicom video

- Derive a supported four-colour palette from stable regions across the supplied
  hardware captures, accounting for matrix, transfer, black level, gain, gamma,
  chroma phase, and compression uncertainty.
- Verify plane-index order, border/background relationship, active geometry, and
  placement independently of palette fitting.
- Accept one palette only after automated index-to-RGB checks and hardware review;
  do not add selectable emulator palettes or title-specific colours.

## Regression suite

- Document the headless harness contract: loading, reset settling, frame and input
  timing, capture outputs, machine selection, and reference-emulator limits.
- Replace uniform corpus scoring with a small declarative scenario manifest and
  one runner. Each case must identify its exact inputs, behavior under test,
  evidence, assertion class, and reviewed expected state.
- Use exact, property, human-review, or reference-comparison assertions according
  to what the evidence supports.
- Retain reviewable screenshots, diffs, timelines, hashes, and failure reasons.
- Prove each release-blocking test can fail through an appropriate negative
  control.
- Reuse useful driver code from the legacy scripts, but do not preserve their
  aggregate scores or unverified assumptions.

## External controller mappings

- Audit current mappings against `docs/how-to-play.md` and primary sources.
- Define one compact, versioned, non-executable external format covering exact
  image identity, both keypads, player roles, start sequences, CLEAR, and manual
  fallback.
- Replace the compiled per-title table with one loading/interpreting path; do not
  retain parallel compiled and external systems.
- Add mappings only for verified images and controls. Invalid or missing data
  must fall back safely to ordinary unmapped/manual input.

## Hardware and presentation

- Verify analog/direct-video timing and geometry on real hardware.
- Observe CHIP-8 sound-timer behavior separately on Studio II, Studio III PAL,
  and Studio III NTSC before changing audio routing.
- Capture matching reviewed scenarios over HDMI and direct video.
- Add an HDMI-only border crop and a cropped 5x mode for 1080p without changing
  the direct-video or machine geometry models.

## Deferred

High-page diagnostic ST2 images remain outside the 4 KB cartridge model. Do not
expand the loader without a concrete compatibility requirement and explicit
banking design.

# Bundled OpenStudio2 interpreter

Source: OpenStudio2 revision `8ae7a08ea0984d8280a0d64933a61f04582ab927`
plus the uncommitted `5xyN` decoder fix, assembled 2026-09-11. It ignores
the low nibble as the original VIP does, supporting Dot-Dash's `57AD`.
Assembly source SHA-256:
`6cfb7f9581801e8742ef94dfe86c5d1ca20f11387625bcc1ca6c9d75b3159ae4`.
The source repository is currently private; builds use only
this bundled copy and never require the neighboring checkout.

`openstudio2.hex` is the unmodified source image: 4096 plain hexadecimal
bytes, one per line. The 2 KB interpreter occupies offsets `000-7FF`;
the unused half at `800-FFF` is explicitly filled with `FF`.
Only `rom4` uses this initialization file; separate CHIP-8 RAM is unchanged.

MIT License, Copyright (c) 2026 Elle Ball.
See [openstudio2-LICENSE.txt](openstudio2-LICENSE.txt).

SHA-256 checksums:

- Exact HEX file: `c8f885aa351b1bedcf1610ca139eefd322798cc1d7a1d41d4e546152c5db9b8f`
- All 4096 decoded bytes: `569eac5b7642e13d79a7a850acb27588ddf1e68971356d95377e5943bb8ad053`
- First 2048 decoded bytes (binary override): `8c39788f2f6a696f07167b76995fdb833292296b80af3aec1c6c5e897bbf7dd2`

Validation: the new comparison regression fails before the fix; the full
firmware execution suite and generated-image check pass afterward. The
bundled bytes match the rebuilt image, including `FF` padding. MiSTer gameplay
and FPGA embedding of this revision remain unverified.

Update this provenance and repeat embedding and gameplay verification when
replacing the image.

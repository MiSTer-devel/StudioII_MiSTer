# Bundled OpenStudio2 interpreter

Source: OpenStudio2 revision `52ff1dbb1e0f5ebaddf86e31500fe9c7ea68595f`
(merged main). The source repository is currently private; builds use only
this bundled copy and never require the neighboring checkout.

`openstudio2.hex` is the unmodified source image: 4096 plain hexadecimal
bytes, one per line. The 2 KB interpreter occupies offsets `000-7FF`;
the unused half at `800-FFF` is explicitly filled with `FF`.
Only `rom4` uses this initialization file; separate CHIP-8 RAM is unchanged.

MIT License, Copyright (c) 2026 Elle Ball.
See [openstudio2-LICENSE.txt](openstudio2-LICENSE.txt).

SHA-256 checksums:

- Exact HEX file: `d5bc94651924b1b6a8e5158161efa248b7660d450270d611504b6bfb5c9c1ba9`
- All 4096 decoded bytes: `9277e67fd60bd3d54c16e05a226be544034a9d7b06472024f2c56d9ac7e911f4`
- First 2048 decoded bytes (binary override): `1cb64b075dbe406f3d3881cc08252936cc4f19ecef4980eda8587d0f9a7af639`

Update this provenance and repeat embedding and gameplay verification when
replacing the image.

Visicom Palette Utility
=======================

vispalette creates 16-byte .vcp palette files for the Toshiba Visicom COM-100
mode of the Studio II MiSTer core.

The utility prompts for RGB values (0-255) for each of the Visicom's four color
indices. Values are entered in hardware-index order 0-3, but the output file is
written in GBP order.

Usage:

    vispalette output.vcp

Build on Linux / WSL:

    gcc -O2 -Wall -Wextra -o vispalette vispalette.c

Build a standalone Windows executable from WSL:

    sudo apt install gcc-mingw-w64-x86-64
    x86_64-w64-mingw32-gcc -O2 -Wall -Wextra -static -o vispalette.exe vispalette.c

VCP and GBP use the same 16-byte format and ordering: four RGB888 colors in
lightest-to-darkest file order, followed by four reserved zero bytes.

For Visicom, file entries map to hardware indices in reverse order:

    R3 G3 B3 R2 G2 B2 R1 G1 B1 R0 G0 B0 00 00 00 00

Index 0 is the Visicom border/background color, so the final (darkest) palette
entry maps to the dark border/background. The other three Visicom colors are
foreground hues and do not imply a strict luminance order.

Ordinary .gbp files may be loaded directly.

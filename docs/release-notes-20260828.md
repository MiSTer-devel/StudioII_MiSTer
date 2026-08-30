# 2026-08-28 milestone release

This build marks a major step for the RCA Studio II MiSTer core: the complete
Studio II, Studio III/MPT-02, and Visicom family is now in a release-ready state.
Visicom is fixed, Studio III NTSC firmware and video operation are fixed, and the
Studio II beeper has reached a level of fidelity that we believe is unmatched by
any other current emulation of the console.

## Studio II beeper: audio phase one complete

The beeper is no longer a generic square wave. It is a hardware-derived model
built from labeled console recordings and protected by focused regression cases.
The release baseline includes:

- measured upper and lower pitch targets near 628.4 Hz and 505.2 Hz;
- the long-note descent and the audible Q-low release/recovery envelope;
- bounded, gap-dependent retrigger behavior that reproduces Gunfighter's closely
  spaced shot/cactus sequences without disrupting other games;
- protected Concentration / Match, Speedway, long-note, and repeated-hit cases;
- the approximately 11:6 high/low duty cycle measured in the recordings; and
- output-only **Sound: On/Off** control that leaves the running generator state
  untouched.

The implementation keeps the Studio II discrete-beeper path separate from the
Studio III programmable-tone path. The selected DSE build passed listening
acceptance on MiSTer; [the beeper status](beeper-status.md) records the
measurements, model, and accepted baseline in detail.

## Visicom compatibility

Visicom now boots and runs cleanly in the accepted build. Cartridge handling is
machine-aware rather than inheriting Studio II assumptions:

- headered `.st2` images can populate the Visicom's cartridge pages;
- raw `.bin` and `.rom` dumps load at `$0800`, preserving firmware and loading
  the complete cartridge;
- gamepad Start uses the Visicom cartridge entry key `A0`, including the generic
  8-way fallback; and
- the separate memory map, second DMA bitplane, and four-colour output remain one
  coherent Visicom machine model.

## Studio III NTSC

Studio III NTSC firmware and display operation are accepted in this DSE build.
The documented 4 KB `boot2.rom` slot works with the dedicated CDP1861 + CDP1862
+ CDP1863 path, and the previously reported BIOS/display failure no longer
reproduces on MiSTer.

## Family-wide improvements carried by this release

- Studio II, Studio III PAL, Studio III NTSC, and Visicom machine modes with four
  resident firmware slots.
- Headered `.st2` and flat `.bin`/`.rom` cartridge support with machine-specific
  memory ownership.
- Hardware-specific monochrome, Studio III colour, and Visicom two-plane colour
  paths.
- Automatic per-file controller profiles, manual overrides, two-player routing,
  direct bindings for all 20 keypad keys, and an analog-stick keypad overlay.
- Integer scaling options and HDMI sync preservation across CLEAR, cartridge
  loads, firmware loads, and same-standard machine resets.
- Automatic per-program or manually cached loading of the user-supplied
  `chip8.bin` interpreter for classic Studio-family CHIP-8 programs.
- Independent Studio II beeper and Studio III programmable-tone implementations
  with a shared output-only sound control.

## Build and acceptance

The release candidate was built with the supported Quartus 17.0.2 toolchain
using seed 3. The full flow completed successfully, with worst-case setup slack
of +0.462 ns and worst-case hold slack of +0.249 ns. The map report retains the
five firmware/cartridge ROMs and both machine RAMs as block memory.

Remaining work—analog/direct-video testing, broader controller-profile coverage,
and possible research into the beeper's hardest early-attack knee—is documented
in the [roadmap](../roadmap.md). None is considered a blocker for this milestone
release.

See the [credits](../CREDITS.md) for the contributors, hardware references,
emulator research, and preservation work that made this milestone possible.

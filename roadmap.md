# Roadmap

Developement is effectively done. Ideas for potential improvements are listed.

## Keyboard and keypad ideas

- physical numpad support.
- Emma 02-style two-player layout: player one uses the keyboard
  number row and player two uses the physical numpad
- Retain current keyboard layout on keypad A while physical 
  numpad drives keypad B
- Add conventional CHIP-8 QWERTY layout:

  | Original CHIP-8 keypad | Standard QWERTY mapping |
  |---|---|
  | 1 2 3 C | 1 2 3 4 |
  | 4 5 6 D | Q W E R |
  | 7 8 9 E | A S D F |
  | A 0 B F | Z X C V |

- Add an optional literal CHIP-8 keyboard layout in which every COSMAC VIP
  keypad symbol uses its matching MiSTer keyboard key (A to A, B to B,
  and so on).

## Hardware and presentation

- Acquire reference audio for Studio III to verify accuracy
- Verify direct video
- Make Studio III homebrew that exercises tone generator

### Numstick refinements

- Prevent the left analog stick from also generating ordinary profile movement
  while Numstick is using it to select 0. Prefer automatic suppression while
  Numstick is active, unless an explicit left-stick option proves necessary.

  This seems difficult to do, but might be possible. Low priority.

## Deferred

High-page diagnostic ST2 images remain outside the 4 KB cartridge model. Do not
expand the loader without a concrete compatibility requirement and explicit
banking design.

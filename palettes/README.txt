Visicom Color Palettes

.vcp files provide alternate four-color palettes for Toshiba Visicom
COM-100 video.

.vcp format is 16 bytes. First 12 bytes are four RGB888 colors:

  0  Green
  1  Blue
  2  Yellow
  3  Red

The final four bytes are reserved and must be zero.

This matches the format of the .gbp (Game Boy Palette) file used in the 
MiSTer Game Boy core. .gbp palettes can be used if renamed to .vcp, but no
testing has been done regarding this.

mame.vcp
  Green   #004000
  Blue    #AFDFE4
  Yellow  #B9C42F
  Red     #EF454A
Palette used by MAME.

emma02.vcp
  Green   #004000
  Blue    #70D0FF
  Yellow  #D0FF70
  Red     #FF7070
Palette used by Emma 02.

boxart-print.vcp
  Green   #4B7841
  Blue    #99C8C8
  Yellow  #E7CA51
  Red     #D5A696
Sampled from screenshot in Visicom box art (photo by Nicole Express).

nicole-express.vcp
  Green   #002600
  Blue    #2688F2
  Yellow  #AFB72B
  Red     #D52E18
Sampled and adjusted from Nicole Express captures.

flip.vcp
  Green   #1F3618
  Blue    #627FB6
  Yellow  #B5A443
  Red     #C74C32
Sampled and adjusted from FLiP captures.

balanced.vcp
  Green   #11320C
  Blue    #5A93D5
  Yellow  #B9B43D
  Red     #D14C38
Drawn from all combined sources.

boxart-adjusted.vcp
  Green   #21391A
  Blue    #678CC6
  Yellow  #C4AD39
  Red     #BC674A
Sampled from Visicom box art (photo by Nicole Express), averaged against 
other sources.

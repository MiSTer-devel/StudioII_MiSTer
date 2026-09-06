Visicom Color Palettes

.vcp files provide alternate four-color palettes for Toshiba Visicom
COM-100 video.

VCP and MiSTer Game Boy GBP files use the same 16-byte format and ordering:
four RGB888 colors in lightest-to-darkest file order, followed by four
reserved zero bytes.

For Visicom, the four file entries map to hardware indices in reverse order:

  file 0 -> index 3
  file 1 -> index 2
  file 2 -> index 1
  file 3 -> index 0  (border/background)

The useful semantic anchor is the final/darkest GBP entry mapping to Visicom's
dark border/background. The other three Visicom colors are foreground hues and
do not have a guaranteed luminance order.

Ordinary .gbp files may be loaded directly.

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

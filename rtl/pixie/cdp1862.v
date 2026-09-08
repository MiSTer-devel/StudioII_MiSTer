//============================================================================
//
//  CDP1862 "COS/MOS Color Generator Controller".
//
//  Written 2026 by Alan Steremberg. The NTSC Studio III pairs this with a
//  CDP1861; Emma 02's StudioIII/standard-ntsc.xml declares both devices.
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//============================================================================
//
//  The 1861 latches colour with each DMA byte and shifts it with luminance. This
//  module selects dot or background colour and supplies the BCKGND luminance
//  qualifier described by the CDP1862 interface and MAME's cdp1862 device.
//
//  Colours are {R,G,B} on this bus. Note the colour RAM itself is in the 1864's
//  pin order (bit 0 red, bit 1 blue, bit 2 green); rtl/rcastudioii.sv permutes
//  it once, before either part sees it.
//
//============================================================================

`default_nettype none

module cdp1862
(
    input             enable,       // this machine has an 1862 fitted
    input             luminance,    // the 1861's monochrome video bit
    input             in_raster,    // inside the visible raster
    input       [2:0] dot_colour,   // colour latched with this byte
    input             bg_active,    // this pixel takes the background
    input       [2:0] bg_colour,

    output      [2:0] video,        // {R,G,B}
    output            bckgnd        // show it at background luminance
);

//  Without an 1862 the machine is a plain monochrome Studio II: white dots on
//  black, and no background luminance to qualify.
assign video  = !enable   ? {3{luminance}}
              : !in_raster ? 3'b000
              : luminance  ? dot_colour
              :              (bg_active ? bg_colour : 3'b000);

assign bckgnd = enable && bg_active && !luminance;

endmodule

`default_nettype wire

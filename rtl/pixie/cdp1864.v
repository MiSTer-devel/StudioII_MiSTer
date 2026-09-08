//============================================================================
//
//  CDP1864 "PAL Compatible Color TV Interface".
//
//  Written 2026 by Alan Steremberg. Structure, and all of the DMA/INT/EFx
//  timing detail, is derived from this repo's rtl/pixie/cdp1861.v. Both parts
//  have no frame buffer and share the same CPU/DMA contract. Geometry and colour
//  follow the RCA datasheet, MAME's cdp1864 device by Curt Coder (BSD-3-Clause),
//  and Emma 02's machine XML.
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//============================================================================
//
//  This remains separate from cdp1861 so PAL geometry cannot alter Studio II
//  timing. Port shared DMA, interrupt, EF, and horizontal timing fixes between
//  the modules by hand.
//
//  Differences from the 1861:
//
//      1861 (NTSC, mono)            1864 (PAL, colour)
//      262 lines/frame              312 lines/frame
//      display 80..207 (128)        display 76..267 (192)
//      rows shown 4x                rows shown 6x  (32 x 6 = 192)
//      1 bit of video               3 bits, {R,G,B}
//      -                           1-of-4 background colour, stepped by OUT 1
//      -                           tone generator (not here; see below)
//
//  Both run 14 machine cycles per line, so the whole horizontal structure --
//  DMA phase, the tolerant read window, HSync placement -- carries over
//  untouched. 1.75MHz / 50Hz / 312 lines = 14.02 cycles a line, against the
//  Studio II's 1.76MHz / 60Hz / 262 = 14.0.
//
//  The tone generator lives in rtl/pixie/cdp1863.v. Its div4 input selects the
//  CDP1864's integrated divider or the standalone CDP1863 path.
//
//============================================================================

`default_nettype none

module cdp1864
(
    input             clk,          // pixel-rate domain
    input             ce_pix,       // one pulse per pixel time
    input             cpu_ce,       // one pulse per CPU machine cycle (8 pixel times)
    input             reset,

    // ---- CPU side -------------------------------------------------------
    input       [1:0] SC,           // 1802 state code: 2'b10 == DMA cycle
    input       [7:0] data_in,      // luminance byte the CPU put on the bus this DMA cycle
    input       [2:0] colour_in,    // {R,G,B} from colour RAM for that same byte
    input             con,          // Color On: colour RAM has been written (see below)
    input             disp_on,      // INP 1
    input             disp_off,     // INP 4 on this machine, not OUT 1
    input             bg_step,      // OUT 1: step the background colour

    output            DMAO,         // DMA-OUT request, active high
    output reg        INT,          // interrupt request, active high
    output reg        EFx,          // display status -> EF1, active high

    // ---- video side -----------------------------------------------------
    output            csync,
    // DE for the 64x192 bitmap alone; video_de is the whole raster. The harness
    // captures this so its frames stay 64x192 and the recorded scores keep their
    // meaning.
    output            bitmap_de,
    output            bitmap_hblank,
    output            bitmap_vblank,
    output      [2:0] video,        // {R,G,B}
    // BCKGND. Datasheet: "This output indicates that the color selected by the
    // RGB outputs is due to background color select rather than a one bit in a
    // display luminance byte. BCKGND may be used to lower the luminance of the
    // background color so that the same color may be used for display of data."
    // So it is not a fourth colour -- it is a brightness qualifier on the three.
    // Blanked (held high on the real pin) during blanking; here it simply reads
    // low outside the raster, since there is no colour to qualify.
    output            bckgnd,
    output reg        VSync,
    output reg        HSync,
    output reg        VBlank,
    output reg        HBlank,
    output            video_de
);

// ---------------------------------------------------------------------------
// Geometry
// ---------------------------------------------------------------------------
localparam PIXELS_PER_LINE   = 112;                   // 14 machine cycles, as the 1861
localparam LINES_PER_FRAME   = 312;                   // PAL. INLACE low = 312 non-interlaced.

// Sources agree on a 192-line display but not its position. Use Emma 02's
// hardware-tested 76..267 window; RCA Fig. 4 contradicts its own 192H label and
// MAME's start value is marked uncertain. Recheck against hardware before moving
// this window because its offset positions the picture in the full raster.
localparam DISPLAY_START     = 76;
localparam DISPLAY_END       = 268;                   // one past the last (192 lines)
localparam INT_START         = DISPLAY_START - 2;     // 74
localparam EFX_TOP_START     = DISPLAY_START - 4;     // 72
localparam EFX_BOT_START     = DISPLAY_END   - 4;     // 264

// Same line length, CPU, and ISR structure as the 1861; keep its interrupt/EF
// leads and parity adaptation synchronized.
localparam INT_LEAD          = 8;
localparam EFX_LEAD          = 8;
localparam DMA_ADAPT         = 1;

localparam DMA_START         = 16;
localparam ACTIVE_START      = DMA_START + 24;        // 40
localparam ACTIVE_END        = ACTIVE_START + 64;     // 104
localparam DE_START          = ACTIVE_START;
localparam DE_END            = DE_START + 64;

// Sync and blanking follow the PAL line in the datasheet's Fig. 6 (p. 8), not
// the narrower bitmap window.
//
//     front porch   0..8    4.54us   (Fig 6: 3.14)
//     HSync         8..16   4.54us   (Fig 6: 4.57)
//     back porch   16..24   4.54us   (Fig 6: 3.43, incl. breezeway and burst)
//     active       24..112 49.99us   (Fig 6: 50.86)
//
// The bitmap stays at 40..104: the DMA phase pins it, and the BIOS ISR counts
// cycles against that burst.
localparam HSYNC_START       = 8;
localparam HSYNC_END         = 16;
localparam H_ACTIVE_START    = 24;
// Vertical, also Fig 6: vertical sync 4H, vertical blanking 24H. Using 20 here to
// match Fig 4's "20H" vertical blanking bracket, which is the more specific of
// the two. VSync is lines 0..3, so there is no START to name.
localparam VSYNC_END         = 4;
localparam VBLANK_END        = 20;

// ---------------------------------------------------------------------------
// Counters
// ---------------------------------------------------------------------------
reg [7:0] hcount;
reg [8:0] vcount;

always @(posedge clk) begin
    if (reset) begin
        hcount <= 8'd0;
        vcount <= 9'd0;
    end
    else if (ce_pix) begin
        if (hcount == PIXELS_PER_LINE - 1) begin
            hcount <= 8'd0;
            vcount <= (vcount == LINES_PER_FRAME - 1) ? 9'd0 : vcount + 9'd1;
        end
        else hcount <= hcount + 8'd1;
    end
end

// ---------------------------------------------------------------------------
// Display enable. INP 1 on, INP 4 off -- the 1864 moves display-off off OUT 1,
// which it needs for the background colour step. Datasheet: N0 with TPB enables
// interrupt and DMA ("a 61 or 69 instruction"), N2 with MRD and TPB disables
// them ("a 6C instruction").
// ---------------------------------------------------------------------------
reg display_enabled;
always @(posedge clk) begin
    if (reset)         display_enabled <= 1'b0;
    else if (disp_off) display_enabled <= 1'b0;
    else if (disp_on)  display_enabled <= 1'b1;
end

// ---------------------------------------------------------------------------
// Background colour: 1-of-4, stepped by OUT 1. Order and values follow Emma 02's
// palette list for this machine -- back_blue, back_black, back_green, back_red.
// RGB alone cannot encode the BCKGND luminance difference; bckgnd carries that
// qualifier to the top level.
// ---------------------------------------------------------------------------
reg [1:0] bg_index;
always @(posedge clk) begin
    if (reset)        bg_index <= 2'd0;
    else if (bg_step) bg_index <= bg_index + 2'd1;
end

reg [2:0] bg_colour;
always @(*) begin
    case (bg_index)
        2'd0:    bg_colour = 3'b001;   // blue
        2'd1:    bg_colour = 3'b000;   // black
        2'd2:    bg_colour = 3'b010;   // green
        default: bg_colour = 3'b100;   // red
    endcase
end

wire line_displayed = (vcount >= DISPLAY_START) && (vcount < DISPLAY_END);

// ---------------------------------------------------------------------------
// DMA request and byte capture. Identical to the 1861 except that the colour
// bits are latched alongside each luminance byte -- the datasheet has RDATA,
// GDATA and BDATA "latched concurrent with the latching of the luminance
// information from the data bus during the display interval".
// ---------------------------------------------------------------------------
reg dma_early;
always @(posedge clk) begin
    if (reset) dma_early <= 1'b0;
    else if (ce_pix && hcount == 4)
        dma_early <= (DMA_ADAPT != 0) && (vcount > DISPLAY_START) && (vcount < DISPLAY_END) && (SC == 2'b00);
end

assign DMAO = display_enabled && line_displayed &&
              (hcount >= (dma_early ? DMA_START - 8 : DMA_START)) && (dma_cnt < 4'd7);

reg  [7:0] linebuf [0:7];
reg  [2:0] colbuf  [0:7];
// CON, "Color On" -- the datasheet has the pin "connected to the gated MWR signal
// of the color memory", so the part is monochrome until software writes colour
// RAM. Latched per byte with everything else so a mid-frame enable cannot tear.
reg  [7:0] conbuf;
reg  [3:0] dma_cnt;

always @(posedge clk) begin
    if (reset) begin
        dma_cnt <= 4'd0;
    end
    else begin
        if (ce_pix && (hcount == PIXELS_PER_LINE - 1)) begin
            dma_cnt <= 4'd0;
        end
        if (cpu_ce && (SC == 2'b10) && (dma_cnt < 4'd8)) begin
            linebuf[dma_cnt[2:0]] <= data_in;
            colbuf [dma_cnt[2:0]] <= colour_in;
            conbuf [dma_cnt[2:0]] <= con;
            dma_cnt <= dma_cnt + 4'd1;
        end
    end
end

// ---------------------------------------------------------------------------
// Pixel shifter. The luminance byte shifts as on the 1861; the colour for the
// byte being shifted is held alongside it, so a lit pixel takes the dot colour
// and an unlit one the background.
// ---------------------------------------------------------------------------
reg [7:0] shift_reg;
reg [2:0] shift_col;
reg       shift_con;
wire in_active = line_displayed && (hcount >= ACTIVE_START) && (hcount < ACTIVE_END);

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'd0;
        shift_col <= 3'd0;
        shift_con <= 1'b0;
    end
    else if (ce_pix) begin
        if (in_active) begin
            if (hcount[2:0] == 3'd0) begin
                shift_reg <= linebuf[hcount[5:3] - 3'd5];   // ACTIVE_START/8 == 5
                shift_col <= colbuf [hcount[5:3] - 3'd5];
                shift_con <= conbuf [hcount[5:3] - 3'd5];
            end
            else shift_reg <= {shift_reg[6:0], 1'b0};
        end
        else shift_reg <= 8'd0;
    end
end

reg in_active_d;
always @(posedge clk) begin
    if (reset)       in_active_d <= 1'b0;
    else if (ce_pix) in_active_d <= in_active;
end

// Outside the bitmap but still inside the raster the part paints the background
// colour -- Fig 4 shows BACKGROUND filling the area around the DISPLAY AREA, and
// it is what makes the picture full-screen on a TV. Outside the raster it is
// blanking, which must be black.
wire [2:0] border = (display_enabled && colour_on_seen) ? bg_colour : 3'b000;
assign video = in_raster
                 ? ((display_enabled && in_active_d)
                      ? (shift_con ? (shift_reg[7] ? shift_col : bg_colour)
                                   : (shift_reg[7] ? 3'b111    : 3'b000))
                      : border)
                 : 3'b000;

// High wherever the RGB above came from the background rather than from a set
// bit in a luminance byte: the border, and unlit pixels inside the bitmap once
// colour is on. Not asserted before CON, where the part is monochrome and the
// "background" is plain black.
assign bckgnd = in_raster && display_enabled && colour_on_seen &&
                !(in_active_d && shift_con && shift_reg[7]);

// CON latched once, for the border: the per-byte conbuf only covers the bitmap.
reg colour_on_seen;
always @(posedge clk) begin
    if (reset)    colour_on_seen <= 1'b0;
    else if (con) colour_on_seen <= 1'b1;
end

// Inside the visible raster (the delayed forms track the shifter's one-pixel lag).
reg in_raster;
always @(posedge clk) begin
    if (reset)       in_raster <= 1'b0;
    else if (ce_pix) in_raster <= (hcount >= H_ACTIVE_START) && (vcount >= VBLANK_END);
end

// ---------------------------------------------------------------------------
// Sync, blanking and the CPU-visible status flags. The EF shape is the same as
// the 1861's, which the datasheet confirms for this part too: "Two pulses per
// field are generated on this line, each of which is four horizontal lines wide.
// The first pulse begins four horizontal lines before the display, and the
// second pulse begins four horizontal lines prior to the end of the display."
// ---------------------------------------------------------------------------
always @(posedge clk) begin
    if (reset) begin
        HSync <= 1'b0; VSync <= 1'b0;
        HBlank <= 1'b1; VBlank <= 1'b1;
        INT <= 1'b0;   EFx <= 1'b0;
    end
    else if (ce_pix) begin
        HSync  <= (hcount >= HSYNC_START) && (hcount < HSYNC_END);
        // VSYNC_START is zero; an explicit unsigned lower-bound comparison is
        // always true. The 1861 still needs both bounds for its 254..257 pulse.
        VSync  <= (vcount < VSYNC_END);
        // Blanking describes the raster now. Everything inside it but outside the
        // bitmap is active picture painted in the background colour, which is what
        // Fig 4 draws as BACKGROUND surrounding the DISPLAY AREA.
        HBlank <= (hcount < H_ACTIVE_START);
        VBlank <= (vcount < VBLANK_END);

        INT <= display_enabled &&
               (((vcount == INT_START - 1)     && (hcount >= 112 - INT_LEAD)) ||
                ((vcount >= INT_START) && (vcount < DISPLAY_START) &&
                 !((vcount == DISPLAY_START - 1) && (hcount >= 112 - INT_LEAD))));

        EFx <= display_enabled &&
               ((((vcount == EFX_TOP_START - 1) && (hcount >= 112 - EFX_LEAD)) ||
                 ((vcount >= EFX_TOP_START) && (vcount < DISPLAY_START) &&
                  !((vcount == DISPLAY_START - 1) && (hcount >= 112 - EFX_LEAD)))) ||
                (((vcount == EFX_BOT_START - 1) && (hcount >= 112 - EFX_LEAD)) ||
                 ((vcount >= EFX_BOT_START) && (vcount < DISPLAY_END) &&
                  !((vcount == DISPLAY_END - 1) && (hcount >= 112 - EFX_LEAD)))));
    end
end

assign csync    = ~(HSync ^ VSync);
assign video_de = ~(VBlank | HBlank);

// Capture-only bitmap window; video_de covers the full active raster.
reg bitmap_de_r, bitmap_hblank_r, bitmap_vblank_r;
always @(posedge clk) begin
    if (reset) begin
        bitmap_de_r     <= 1'b0;
        bitmap_hblank_r <= 1'b1;
        bitmap_vblank_r <= 1'b1;
    end
    else if (ce_pix) begin
        bitmap_de_r     <= line_displayed &&
                           (hcount >= DE_START) && (hcount < DE_END);
        bitmap_hblank_r <= (hcount < DE_START) || (hcount >= DE_END);
        bitmap_vblank_r <= !line_displayed;
    end
end
assign bitmap_de     = bitmap_de_r;
assign bitmap_hblank = bitmap_hblank_r;
assign bitmap_vblank = bitmap_vblank_r;

endmodule

`default_nettype wire

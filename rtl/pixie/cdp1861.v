//============================================================================
//
//  CDP1861 "Pixie" video display controller.
//
//  Written 2026 by Alan Steremberg, replacing pixie_video_studioii.v by
//  Jason Coombes (JasonA-dev) with additions by Flandango, whose module
//  interface and Studio II integration this keeps.
//
//  Scanline windows and the DMA cadence follow MAME's cdp1861 device by
//  Curt Coder (BSD-3-Clause); behaviour checked against Paul Robson's Studio II
//  emulator.
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//============================================================================
//
//  The real part has no frame buffer. It asserts DMA-OUT and the 1802 performs
//  8 DMA-OUT machine cycles per displayed scanline, reading bytes through R(0)
//  and handing them over; the 1861 shifts them straight out as pixels. Because
//  the address comes from R(0), scrolling and any display base fall out for free.
//
//  Timing matched against mame/src/devices/video/cdp1861.{h,cpp}:
//      112 pixels/line (14 machine cycles), 262 lines/frame
//      display   scanlines 80..207   (128 lines)
//      INT       scanlines 78..79    (2 lines before display)
//      EF1       scanlines 76..79 and 204..207 (4 line-times, top and bottom)
//  The Studio II only has 256 bytes of display RAM, so its ISR re-points R(0)
//  back by 8 for each of the 4 scanlines in a group -- that is software's job,
//  not ours. We request DMA on every one of the 128 displayed lines, as the
//  real part does.
//
//============================================================================

`default_nettype none

module cdp1861
(
    input             clk,          // pixel-rate domain
    input             ce_pix,       // one pulse per pixel time
    input             cpu_ce,       // one pulse per CPU machine cycle (8 pixel times)
    input             reset,

    // ---- CPU side -------------------------------------------------------
    input       [1:0] SC,           // 1802 state code: 2'b10 == DMA cycle
    input       [7:0] data_in,      // byte the CPU put on the bus this DMA cycle
    // Toshiba Visicom COM-100. Its DMA delivers two bytes per cycle rather than
    // one: Emma 02's Cdp1802::visicomDmaOut reads M(R(0)) and M(R(0)+$200) and
    // takes the top bit of each, so the picture is two bit planes 512 bytes
    // apart and every pixel is one of four colours instead of on/off. The
    // second plane arrives here as data_in2 and leaves as vis_index; the
    // palette itself is not this part's business (see Studio-II.sv).
    input             vis_mode,     // this machine is a Visicom
    input       [7:0] data_in2,     // the byte at M(R(0)+$200), same DMA cycle
    // CDP1862 colour, for the NTSC Studio III. That machine puts a separate
    // colour generator beside this part, fed from the same colour RAM and the
    // same DMA cycles -- so the latching lives here, where the DMA is, and the
    // colouring is done by cdp1862.v downstream. All of this is inert on a
    // Studio II, which has no 1862 and drives con low.
    input       [2:0] colour_in,    // {R,G,B} from colour RAM for that byte
    input             con,          // Color On: colour RAM has been written
    input             bg_step,      // OUT 1: step the background colour
    input             disp_on,      // INP 1
    input             disp_off,     // OUT 1

    output            DMAO,         // DMA-OUT request, active high
    output reg        INT,          // interrupt request, active high
    output reg        EFx,          // display status -> EF1, active high

    // ---- video side -----------------------------------------------------
    output            csync,
    output            video,
    output      [2:0] colour_out,   // dot colour for the pixel on `video`
    output      [1:0] vis_index,    // Visicom: this pixel's colour, 0-3
    output            bg_active,    // this pixel takes the background colour
    output      [2:0] bg_colour_out,// ...which is this
    // DE for the 64x128 bitmap alone, as distinct from video_de, which is now the
    // whole raster. The Verilator harness captures this so its frames stay 64x128
    // and every recorded score keeps its meaning; the framework gets video_de.
    output            bitmap_de,
    output            bitmap_hblank,
    output            bitmap_vblank,
    output reg        VSync,
    output reg        HSync,
    output reg        VBlank,
    output reg        HBlank,
    output            video_de
);

// ---------------------------------------------------------------------------
// Geometry
// ---------------------------------------------------------------------------
localparam PIXELS_PER_LINE   = 112;
localparam LINES_PER_FRAME   = 262;

localparam DISPLAY_START     = 80;                    // first displayed scanline
localparam DISPLAY_END       = 208;                   // one past the last (128 lines)
localparam INT_START         = DISPLAY_START - 2;     // 78
localparam EFX_TOP_START     = DISPLAY_START - 4;     // 76
localparam EFX_BOT_START     = DISPLAY_END   - 4;     // 204
// INT and EFx lead their nominal line boundaries by one machine cycle
// (8 pixels), following the AVI1861 hardware replacement: its 74HC4040 line
// counter is clocked by the active-low HCLOCK asserted in line states 14+0,
// so it increments at the START of state 14 -- one machine cycle before the
// line boundary -- and INTREQ / DISP_STATUS decode straight off it. That
// cycle is margin the BIOS ISR needs (see the INT assignment below), and the
// EF1 edges are what its spin loops synchronise against. DMA_ADAPT enables
// the fetch/execute-parity resync on the DMA request (see the DMAO logic).
// Swept empirically against Robson's Hockey and Combat, whose main loops
// exercise every interrupt-entry phase: this combination is the clear optimum
// (each lead in {0,16} or adapt off strobes hundreds of frames of a 700-frame
// hockey rally instead of the residual handful). A lead of 0 would disable
// that term entirely (hcount >= 112 is never true).
localparam INT_LEAD          = 8;
localparam EFX_LEAD          = 8;
localparam DMA_ADAPT         = 1;

// 8 DMA cycles = 64 pixel times at the head of the line, then 6 machine cycles
// of CPU time. Byte k is fetched by pixel 8k+7 and shown from pixel 16+8k, so
// every byte is always in hand before it is needed.
// MAME's cdp1861 runs a free-running DMA timer: DMA_START = 2*8 clocks after reset, then
// DMA_ACTIVE = 8*8 asserted / DMA_WAIT = 6*8 idle, i.e. a 112-clock period locked to the line.
// That puts the request at hcount 16..79 -- not 0..63. Each byte arrives at the end of its
// machine cycle, so it is shifted out over the following 8 pixels: active display is 24..87.
localparam DMA_START         = 16;
localparam DMA_END           = DMA_START + 64;        // 80  (8 machine cycles)
// Interrupt entry can place the first DMA byte at hcount 31 or 39. Reading at
// 40+8k accepts either phase. Hardware may show the late phase as an 8-pixel
// horizontal nudge; the fixed window keeps digital output stable.
localparam ACTIVE_START      = DMA_START + 24;        // 40  (three machine cycles behind the request)
localparam ACTIVE_END        = ACTIVE_START + 64;     // 104
// The shifter is aligned to the 8-pixel byte boundaries above; the visible window is tuned
// separately so byte 0's first pixel lands on the first visible column.
localparam DE_START          = ACTIVE_START;
localparam DE_END            = DE_START + 64;

// Sync and blanking use a complete NTSC line rather than the bitmap window.
// The 1861 has no equivalent timing figure; these proportions follow the
// CDP1864 datasheet's Fig. 6 because both parts use a 112-pixel line:
//
//     front porch   0..8    4.54us   (Fig 6: 3.14)
//     HSync         8..16   4.54us   (Fig 6: 4.57)
//     back porch   16..24   4.54us   (Fig 6: 3.43, incl. breezeway and burst)
//     active       24..112 49.99us   (Fig 6: 50.86)
//
// The bitmap stays at 40..104 because the DMA phase pins it -- the BIOS ISR
// counts cycles against that burst -- so it sits 16 pixels from the left of the
// active area and 8 from the right, rather than dead centre.
localparam HSYNC_START       = 8;
localparam HSYNC_END         = 16;
localparam H_ACTIVE_START    = 24;
// The capture harness advances frames on VSync's rising edge. Keep it at 254;
// vertical blanking wraps the frame boundary from line 254 through line 11.
localparam VSYNC_START       = 254;
localparam VSYNC_END         = 258;
localparam VBLANK_END        = 12;

// ---------------------------------------------------------------------------
// Counters -- both advance exactly once per pixel time.
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
// Display enable: INP 1 turns it on, OUT 1 off. With the display off the part
// drives neither DMA, nor the interrupt, nor EF1.
// ---------------------------------------------------------------------------
reg display_enabled;
always @(posedge clk) begin
    if (reset)         display_enabled <= 1'b0;
    else if (disp_off) display_enabled <= 1'b0;
    else if (disp_on)  display_enabled <= 1'b1;
end

wire line_displayed = (vcount >= DISPLAY_START) && (vcount < DISPLAY_END);

// ---------------------------------------------------------------------------
// DMA request and byte capture
// ---------------------------------------------------------------------------
// Hold DMAO until eight cycles are serviced because the CPU accepts DMA only
// between instructions. Drop it at the seventh acknowledge: the CPU has
// already sampled the request and commits the eighth cycle.
//
// The AVI1861 slips line timing by one machine cycle when fetch/execute parity
// is odd. A fixed HDMI raster cannot move the line, so DMA_ADAPT asserts the
// request one cycle early instead. Exempt line 80 while the ISR preamble is
// still loading R(0); its two possible phases fit the tolerant read window.
reg dma_early;
always @(posedge clk) begin
    if (reset) dma_early <= 1'b0;
    else if (ce_pix && hcount == 4)
        dma_early <= (DMA_ADAPT != 0) && (vcount > DISPLAY_START) && (vcount < DISPLAY_END) && (SC == 2'b00);
end

assign DMAO = display_enabled && line_displayed &&
              (hcount >= (dma_early ? DMA_START - 8 : DMA_START)) && (dma_cnt < 4'd7);

reg  [7:0] linebuf [0:7];   // filled by DMA during this line, shown 8 pixels behind
reg  [7:0] linebuf2[0:7];   // Visicom's second bit plane, from M(R(0)+$200)
reg  [2:0] colbuf  [0:7];   // the CDP1862's colour for each of those bytes
reg  [7:0] conbuf;
reg  [3:0] dma_cnt;

always @(posedge clk) begin
    if (reset) begin
        dma_cnt   <= 4'd0;
    end
    else begin
        if (ce_pix && (hcount == PIXELS_PER_LINE - 1)) begin
            dma_cnt <= 4'd0;                          // new line, refill from byte 0
        end
        // Latch on the CPU's DMA state code alone -- the acknowledging cycle
        // completes one machine cycle after the request drops, so gating on
        // DMAO here would lose the last byte of the line.
        if (cpu_ce && (SC == 2'b10) && (dma_cnt < 4'd8)) begin
            linebuf[dma_cnt[2:0]] <= data_in;
            linebuf2[dma_cnt[2:0]] <= data_in2;
            colbuf [dma_cnt[2:0]] <= colour_in;
            conbuf [dma_cnt[2:0]] <= con;
            dma_cnt   <= dma_cnt + 4'd1;
        end
    end
end

// ---------------------------------------------------------------------------
// Pixel shifter
// ---------------------------------------------------------------------------
reg [7:0] shift_reg;
reg [7:0] shift_reg2;       // Visicom plane 1, shifted in lockstep with plane 0
reg [2:0] shift_col;
reg       shift_con;
wire in_active = line_displayed && (hcount >= ACTIVE_START) && (hcount < ACTIVE_END);

always @(posedge clk) begin
    if (reset) begin
        shift_reg  <= 8'd0;
        shift_reg2 <= 8'd0;
    end
    else if (ce_pix) begin
        if (in_active) begin
            // Reload on each 8-pixel boundary inside the active window.
            if (hcount[2:0] == 3'd0) begin
                shift_reg  <= linebuf [hcount[5:3] - 3'd5];   // ACTIVE_START/8 == 5
                shift_reg2 <= linebuf2[hcount[5:3] - 3'd5];
                shift_col <= colbuf [hcount[5:3] - 3'd5];
                shift_con <= conbuf [hcount[5:3] - 3'd5];
            end
            else begin
                shift_reg  <= {shift_reg [6:0], 1'b0};
                shift_reg2 <= {shift_reg2[6:0], 1'b0};
            end
        end
        else begin
            shift_reg  <= 8'd0;
            shift_reg2 <= 8'd0;
        end
    end
end

// shift_reg is loaded one pixel before its first bit is visible, so the active-window gate has to
// be delayed to match it. Gating on the undelayed in_active blanked the last pixel of byte 7 --
// the rightmost column of the screen, which showed up as a missing right-hand border.
reg in_active_d;
always @(posedge clk) begin
    if (reset)       in_active_d <= 1'b0;
    else if (ce_pix) in_active_d <= in_active;
end

// On the Visicom a pixel is lit if either plane is set: colour 0 is the
// background (a dark green, not black), so "not colour 0" is the luminance.
assign video = display_enabled & in_active_d &
               (vis_mode ? (shift_reg[7] | shift_reg2[7]) : shift_reg[7]);

// Plane 1 is the high bit, matching Emma 02: colour |= 1 from the first read,
// |= 2 from the one $200 above it. Outside the bitmap this reads 0, which is
// the background colour -- the Visicom's border is the same dark green, and
// Emma sets backGroundInit_ = 0 for it rather than the 1 every other pixie
// machine gets.
assign vis_index = (display_enabled & in_active_d) ? {shift_reg2[7], shift_reg[7]}
                                                   : 2'd0;

// ---------------------------------------------------------------------------
// CDP1862 hand-off. This part stays monochrome -- `video` is its luminance bit,
// exactly as before -- and everything below is what the colour generator beside
// it would consume. A Studio II leaves con low and cdp1862.v passes white.
// ---------------------------------------------------------------------------
reg [1:0] bg_index;
always @(posedge clk) begin
    if (reset)        bg_index <= 2'd0;
    else if (bg_step) bg_index <= bg_index + 2'd1;
end

reg [2:0] bg_colour;
always @(*) begin
    case (bg_index)                    // Emma 02's order for this palette:
        2'd0:    bg_colour = 3'b001;   // blue
        2'd1:    bg_colour = 3'b000;   // black
        2'd2:    bg_colour = 3'b010;   // green
        default: bg_colour = 3'b100;   // red
    endcase
end

reg colour_on_seen;
always @(posedge clk) begin
    if (reset)    colour_on_seen <= 1'b0;
    else if (con) colour_on_seen <= 1'b1;
end

reg in_raster;
always @(posedge clk) begin
    if (reset)       in_raster <= 1'b0;
    else if (ce_pix) in_raster <= (hcount >= H_ACTIVE_START) &&
                                  !((vcount >= VSYNC_START) || (vcount < VBLANK_END));
end

assign colour_out    = shift_con ? shift_col : 3'b111;
assign bg_colour_out = bg_colour;
// Background wherever the picture is not a lit dot, once colour is on.
assign bg_active     = in_raster && display_enabled && colour_on_seen &&
                       !(in_active_d && shift_con && shift_reg[7]);

// ---------------------------------------------------------------------------
// Sync, blanking and the CPU-visible status flags
// ---------------------------------------------------------------------------
always @(posedge clk) begin
    if (reset) begin
        HSync <= 1'b0; VSync <= 1'b0;
        HBlank <= 1'b1; VBlank <= 1'b1;
        INT <= 1'b0;   EFx <= 1'b0;
    end
    else if (ce_pix) begin
        HSync  <= (hcount >= HSYNC_START) && (hcount < HSYNC_END);
        VSync  <= (vcount >= VSYNC_START) && (vcount < VSYNC_END);
        // Blanking now describes the raster, not the bitmap: everything outside
        // it is active picture, drawn black on this monochrome part.
        HBlank <= (hcount < H_ACTIVE_START);
        VBlank <= (vcount >= VSYNC_START) || (vcount < VBLANK_END);

        // AVI1861 hardware advances its line counter at the start of state 14,
        // one machine cycle before the line boundary. INT must lead likewise so
        // the BIOS can finish its preamble before line 80 DMA uses R(0).
        INT <= display_enabled &&
               (((vcount == INT_START - 1)     && (hcount >= 112 - INT_LEAD)) ||
                ((vcount >= INT_START) && (vcount < DISPLAY_START) &&
                 !((vcount == DISPLAY_START - 1) && (hcount >= 112 - INT_LEAD))));
        // EFx leads for the same AVI1861 line-counter reason. The BIOS waits on
        // this edge to align its display loop with the first DMA burst.
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

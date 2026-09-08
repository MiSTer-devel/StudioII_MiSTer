//============================================================================
//
//  CDP1863 programmable frequency generator -- and the identical generator
//  built into the CDP1864.
//
//  Written 2026 by Alan Steremberg. Shared by the standalone CDP1863 in Studio
//  III NTSC and the equivalent generator integrated into the CDP1864.
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//============================================================================
//
//  Sources:
//
//  * CDP1864 datasheet p1: "a programmable frequency generator designed to
//    produce 256 tones that range from 107 Hz to 13672 Hz".
//  * Datasheet p7 control-line truth table: op code 64 -> LOAD TONE GENERATOR
//    LATCH; "AUD - AUDIO OUT: This is the output of the programmable frequency
//    generator."
//  * Datasheet p6: TPB "is used ... as the input to the tone generator", so the
//    divider runs at the machine-cycle rate -- cpu_ce here.
//  * Datasheet p5: AOE "allows the selected frequency to be generated at the
//    AUDIO-OUT terminal. A low-level input holds AUDIO OUT low. AOE may be
//    connected to Q output of the CDP1802."
//  * Weisbecker's Studio III notes: "64 INSTRUCTION SETS SOUND FREQUENCY
//    (INVERSE)" and "Q GATES SOUND OUTPUT".
//
//  The datasheet pins only the endpoints of the range, so the division chain is
//  MAME's. The two parts differ by exactly one stage:
//
//      CDP1864 (integrated)  f = clock / 8 / 4 / (latch+1) / 2
//      CDP1863 (standalone)  f = clock / 8     / (latch+1) / 2
//
//  clock/8 is the machine-cycle rate either way, so in cpu_ce ticks the output
//  toggles every 4*(latch+1) on the 1864 and every (latch+1) on the 1863 -- the
//  same latch giving four times the frequency on the standalone part. That is
//  MAME's cdp1863.cpp driven from its clock2 input, which is where TPB goes.
//
//============================================================================

`default_nettype none

module cdp1863
(
    input             clk,
    input             cpu_ce,       // one pulse per machine cycle: TPB
    input             reset,

    input             div4,         // 1 = the CDP1864's extra divide-by-4 stage
    input             tone_we,      // OUT 4: load the divider latch
    input       [7:0] tone_d,
    input             aoe,          // Audio Output Enable -- wired to the 1802's Q

    output            aud
);

localparam [7:0] TONE_DEFAULT = 8'h35;

reg  [7:0] tone_latch;
reg  [9:0] tone_cnt;                                  // up to 4*256 cpu_ce ticks
reg        tone_out;
reg        aoe_d;

//  Half period in cpu_ce ticks, less one because the counter starts at zero.
wire [9:0] half = div4 ? ({tone_latch, 2'b00} + 10'd3)     // 4*(latch+1) - 1
                       : ({2'b00, tone_latch});            //   (latch+1) - 1

always @(posedge clk) begin
    if (reset) begin
        tone_latch <= TONE_DEFAULT;
        tone_cnt   <= 10'd0;
        tone_out   <= 1'b0;
        aoe_d      <= 1'b0;
    end
    else begin
        aoe_d <= aoe;

        // MAME resets the latch on AOE's falling edge; neither the datasheet nor
        // Weisbecker's notes document this behavior. Do not reset by level:
        // software may load the pitch before enabling tone. OUT 4 wins if both
        // occur together.
        if (aoe_d && !aoe) tone_latch <= TONE_DEFAULT;
        if (tone_we)       tone_latch <= tone_d;       // OUT 4 always wins

        if (!aoe) begin                                // AOE low holds AUDIO OUT
            tone_cnt <= 10'd0;                         // low (datasheet p5)
            tone_out <= 1'b0;
        end
        else if (cpu_ce) begin                         // TPB drives the divider
            if (tone_cnt >= half) begin
                tone_cnt <= 10'd0;
                tone_out <= ~tone_out;
            end
            else tone_cnt <= tone_cnt + 10'd1;
        end
    end
end

assign aud = aoe & tone_out;

endmodule

`default_nettype wire

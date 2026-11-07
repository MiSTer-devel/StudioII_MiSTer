module mpt02_audio
(
	input clk,
	input reset,
	input cpu_ce,
	input [1:0] filter, // 0 MPT-02 (435 Hz), 1 Apollo 80 (2.6 kHz), 2/3 off
	input tone,
	output signed [15:0] audio
);

// One-pole low-pass at the machine-cycle enable (220029 Hz), alpha = n/8192.
// MPT-02: alpha 101/8192, 434.4 Hz pole, fitted to FliP's direct CDP1864 captures.
// Apollo 80: alpha 581/8192, 2576 Hz pole, fitted to TLD1985's Academy Apollo 80 footage.
// Off: the raw +/-6000 square wave.
reg signed [31:0] level;
wire signed [31:0] target = tone ? 32'sd393216000 : -32'sd393216000;
wire signed [31:0] delta = target - level;
wire signed [31:0] step_mpt02  = (delta >>> 7) + (delta >>> 8)
                               + (delta >>> 11) + (delta >>> 13);
wire signed [31:0] step_apollo = (delta >>> 4) + (delta >>> 7)
                               + (delta >>> 11) + (delta >>> 13);

always @(posedge clk) begin
	if (reset) level <= -32'sd393216000;
	else if (filter[1]) level <= target;
	else if (cpu_ce) level <= level + (filter[0] ? step_apollo : step_mpt02);
end

assign audio = level[31:16];

endmodule

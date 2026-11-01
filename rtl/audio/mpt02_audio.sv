module mpt02_audio
(
	input clk,
	input reset,
	input cpu_ce,
	input tone,
	output signed [15:0] audio
);

// Approximate 435 Hz low-pass fitted to FLiP's direct CDP1864 captures.
// At 220029 machine cycles/s, alpha = 101/8192 gives a 434.4 Hz pole.
reg signed [31:0] level;
wire signed [31:0] target = tone ? 32'sd393216000 : -32'sd393216000;
wire signed [31:0] delta = target - level;

always @(posedge clk) begin
	if (reset) level <= -32'sd393216000;
	else if (cpu_ce) begin
		level <= level + (delta >>> 7) + (delta >>> 8)
		               + (delta >>> 11) + (delta >>> 13);
	end
end

assign audio = level[31:16];

endmodule

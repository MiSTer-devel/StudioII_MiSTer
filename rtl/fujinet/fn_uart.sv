// 8N1 UART for the FujiNet link, run from a fast clock (CLK_50M), with byte
// handshakes into the core's clock.

module fn_uart
(
	input            clk_u,
	input     [31:0] speed,          // hps_io uart_speed
	input            rxd,
	output reg       txd = 1'b1,

	input            clk,
	output reg       rx_strobe,
	output reg [7:0] rx_byte,
	input            tx_valid,
	input      [7:0] tx_byte,
	output           tx_ready
);

reg [11:0] div;
always @(posedge clk_u) begin
	case (speed)
		32'd3125000: div <= 12'd16;
		32'd1562500: div <= 12'd32;
		32'd921600:  div <= 12'd54;
		32'd460800:  div <= 12'd109;
		32'd230400:  div <= 12'd217;
		32'd115200:  div <= 12'd434;
		default:     div <= 12'd32;
	endcase
end

// receive
reg  [2:0] rxs = 3'b111;
always @(posedge clk_u) rxs <= {rxs[1:0], rxd};
wire       rx = rxs[2];

reg [11:0] rcnt;
reg  [3:0] rbit;
reg  [7:0] rsh;
reg        rbusy;
reg  [7:0] rdat;
reg        rtog;

always @(posedge clk_u) begin
	if (!rbusy) begin
		if (!rx) begin
			rbusy <= 1'b1;
			rcnt  <= {1'b0, div[11:1]};
			rbit  <= 4'd0;
		end
	end else if (rcnt != 12'd0) begin
		rcnt <= rcnt - 12'd1;
	end else begin
		rcnt <= div - 12'd1;
		rbit <= rbit + 4'd1;
		if (rbit == 4'd0) begin
			if (rx) rbusy <= 1'b0;            // a glitch, not a start bit
		end else if (rbit == 4'd9) begin
			rbusy <= 1'b0;
			if (rx) begin
				rdat <= rsh;
				rtog <= ~rtog;
			end
		end else begin
			rsh <= {rx, rsh[7:1]};
		end
	end
end

reg [2:0] rtog_s;
always @(posedge clk) begin
	rtog_s    <= {rtog_s[1:0], rtog};
	rx_strobe <= rtog_s[2] ^ rtog_s[1];
	if (rtog_s[2] ^ rtog_s[1]) rx_byte <= rdat;
end

// transmit: the core raises a request toggle, the UART answers with its own
reg       treq, tack_u;
reg [7:0] tdat;
reg [2:0] tack_s;
wire      tack = tack_s[2];
reg       tpend;

assign tx_ready = !tpend && (treq == tack);

always @(posedge clk) begin
	tack_s <= {tack_s[1:0], tack_u};
	tpend  <= 1'b0;
	if (tx_valid && tx_ready) begin
		tdat  <= tx_byte;
		treq  <= ~treq;
		tpend <= 1'b1;
	end
end

reg [2:0] treq_s;
reg [11:0] tcnt;
reg  [3:0] tbit;
reg  [9:0] tsh;
reg        tbusy;
always @(posedge clk_u) begin
	treq_s <= {treq_s[1:0], treq};
	if (!tbusy) begin
		if (treq_s[2] != tack_u) begin
			tsh   <= {1'b1, tdat, 1'b0};
			tbusy <= 1'b1;
			tbit  <= 4'd0;
			tcnt  <= 12'd0;
		end
	end else if (tcnt != 12'd0) begin
		tcnt <= tcnt - 12'd1;
	end else begin
		if (tbit == 4'd10) begin
			tbusy  <= 1'b0;
			tack_u <= treq_s[2];
		end else begin
			txd  <= tsh[0];
			tsh  <= {1'b1, tsh[9:1]};
			tbit <= tbit + 4'd1;
			tcnt <= div - 12'd1;
		end
	end
end

endmodule

// FujiNet cartridge for the RCA Studio II: the per-read half (core1) of
// fujinet-firmware pico/studio2 (s2_cart.h s2_bus_read). The HPS shim
// (s2cartd) runs the rest (core0) and keeps the tables and memories here.
//
// Link (SLIP frames, END=C0 ESC=DB):
//   HPS -> FPGA  'W' a23-16 a15-8 a7-0 data...  sequential writes from a
//   FPGA -> HPS  tag d0 d1 d2                   one event
//
// Link address map:
//   00000-1FFFF  image buffers {view, page, byte}
//   20000-207FF  arena ($E400-$EBFF)
//   20800-20FFF  raster buffers 0 and 1
//   21000-213FF  page table {view, page, byte}; 16-bit LE, taken on the high byte
//   21400-217FF  bank table {view, bank, win, byte}
//   22000-2200F  control
//
// Table entry: [15:14] type (0 none, 1 rom, 2 hot, 3 raster), [13] writable,
//              [10:8] kind (0 buffer, 1 zero, 2 $FF, 3 arena), [7:0] page index

module fujinet_cart
(
	input             clk,
	input             reset,
	input             enable,
	input             cpu_ce,
	input             ram_rd,
	input      [15:0] ram_a,

	output            active,
	output            hold,
	output            drive,
	output reg  [7:0] q,

	input             rx_strobe,
	input       [7:0] rx_byte,
	output            tx_valid,
	output      [7:0] tx_byte,
	input             tx_ready
);

localparam [7:0] VERSION = 8'd1;

localparam [1:0] PG_NONE = 2'd0, PG_ROM = 2'd1, PG_HOT = 2'd2, PG_RASTER = 2'd3;
localparam [2:0] K_BUF = 3'd0, K_ZERO = 3'd1, K_FF = 3'd2, K_ARENA = 3'd3;

localparam [7:0] PG_REGSEL  = 8'hE9;
localparam [7:0] PG_REGDATA = 8'hEA;
localparam [7:0] HOT_BANK   = 8'h80;
localparam [7:0] HOT_STUB   = 8'hF0;
localparam [15:0] STUB_T    = 16'hE9F2;
localparam [7:0] REG_PTRLO  = 8'h18, REG_PTRHI = 8'h19, REG_POKE = 8'h1A;
localparam [7:0] RS_NONE    = 8'hFF;

// raster timing in machine cycles (S2_LINEGAP_US 12, S2_VBLANK_US 1000, S2_SILENCE_US 50)
localparam [7:0] LINEGAP = 8'd2;
localparam [7:0] VBLANK  = 8'd220;
localparam [7:0] SILENCE = 8'd11;

////////////////////////////////////////////////////////////////////////////////
// control

reg        c_hold, c_ready;
reg        live, armed;
reg        pend_valid, pend_idx;
reg  [1:0] mbx;
reg  [4:0] nbanks [0:1];
reg [24:0] wait_cnt;
reg        waited;

assign active = enable & c_ready;
assign hold   = enable & (c_hold | (!c_ready & !waited));

always @(posedge clk) begin
	if (!enable) begin
		wait_cnt <= 25'd0;
		waited   <= 1'b0;
	end else if (!waited) begin
		wait_cnt <= wait_cnt + 25'd1;
		if (&wait_cnt[24:23]) waited <= 1'b1;     // ~3.6 s at 7 MHz, then run without the cart
	end
end

////////////////////////////////////////////////////////////////////////////////
// memories

reg  [7:0] buf_mem [0:131071];
reg  [7:0] sm_mem  [0:4095];           // arena, then raster 0 and 1
reg [15:0] pg_tbl  [0:511];
reg [15:0] bk_tbl  [0:511];

reg  [7:0] bank;
wire [7:0] hi = ram_a[15:8];
wire       in_win = (hi >= 8'hC4) && (hi <= 8'hCF);
wire [3:0] win = hi[3:0] - 4'd4;

reg [15:0] pe, be;
always @(posedge clk) begin
	pe <= pg_tbl[{live, hi}];
	be <= bk_tbl[{live, bank[3:0], win}];
end

wire       use_bank = in_win && (nbanks[live] != 5'd0);
wire [1:0] ty       = active ? pe[15:14] : PG_NONE;
wire [2:0] kind     = use_bank ? ((bank >= 8'd16) ? K_FF : be[10:8]) : pe[10:8];
wire [7:0] idx      = use_bank ? be[7:0] : pe[7:0];

reg  [7:0] r_line;
reg  [3:0] r_col;
reg        front;
wire       r_in = (r_line < 8'd128) && (r_col < 4'd8);

wire [16:0] buf_ra = {live, idx, ram_a[7:0]};
wire [11:0] sm_ra  = (ty == PG_RASTER) ? {1'b1, front, r_line[6:0], r_col[2:0]} : {1'b0, idx[2:0], ram_a[7:0]};

reg  [7:0] buf_q, sm_q;
always @(posedge clk) begin
	buf_q <= buf_mem[buf_ra];
	sm_q  <= sm_mem[sm_ra];
end

reg [1:0] ty_q;
reg [2:0] kind_q;
reg       r_in_q;
always @(posedge clk) begin
	ty_q   <= ty;
	kind_q <= kind;
	r_in_q <= r_in;
	q <= (ty_q == PG_RASTER) ? (r_in_q ? sm_q : 8'h00)
	   : (kind_q == K_BUF)   ? buf_q
	   : (kind_q == K_ZERO)  ? 8'h00
	   : (kind_q == K_ARENA) ? sm_q : 8'hFF;
end

assign drive = (ty != PG_NONE);

////////////////////////////////////////////////////////////////////////////////
// events

reg [31:0] ev_mem [0:4095];
reg        tx_pop;
reg [11:0] ev_wp, ev_rp;
wire [11:0] ev_wp1 = ev_wp + 12'd1;
wire        ev_full  = (ev_wp1 == ev_rp);
wire        ev_empty = (ev_wp == ev_rp);
reg         ev_we;
reg  [31:0] ev_in;
reg  [15:0] ev_lost;

////////////////////////////////////////////////////////////////////////////////
// bus: one decision per read, two clocks into the machine cycle

reg ce1, ce2;
always @(posedge clk) begin
	ce1 <= cpu_ce;
	ce2 <= ce1;
end
wire strobe = ce2 & ram_rd & active;

reg  [7:0]  regsel;
reg  [15:0] ptr;
reg  [15:0] prev;
reg         seen, r_seen;
reg  [7:0]  r_cnt, quiet;
reg         was_reset;

reg         pk_go, pk_go2;
reg  [15:0] pk_a;
reg  [7:0]  pk_v;
reg  [15:0] pk_pe, pk_be;

wire [7:0]  lo = ram_a[7:0];
wire        mbox = mbx[live];

reg         lk_ping, lk_busreset;

always @(posedge clk) begin
	ev_we <= 1'b0;
	pk_go <= 1'b0;

	if (cpu_ce) begin
		if (r_cnt != 8'hFF) r_cnt <= r_cnt + 8'd1;
		if (quiet != 8'hFF) quiet <= quiet + 8'd1;
	end
	if (reset) was_reset <= 1'b1;

	if (lk_busreset) begin
		regsel <= RS_NONE;
		ptr    <= 16'd0;
		seen   <= 1'b0;
		r_seen <= 1'b0;
		r_line <= 8'd0;
		r_col  <= 4'd0;
		bank   <= 8'd0;
	end else if (strobe) begin
		quiet <= 8'd0;
		was_reset <= 1'b0;

		case (ty)
		PG_HOT: begin
			if (mbox && hi == PG_REGSEL && lo >= HOT_BANK && lo < HOT_STUB) begin
				if (nbanks[live] != 5'd0) begin
					bank  <= lo - HOT_BANK;
					ev_in <= {"B", lo - HOT_BANK, 16'd0};
					ev_we <= 1'b1;
				end
			end else if (mbox && hi == PG_REGSEL && (lo == REG_PTRLO || lo == REG_PTRHI || lo == REG_POKE)) begin
				regsel <= lo;
			end else if (mbox && hi == PG_REGDATA && regsel != RS_NONE) begin
				case (regsel)
				REG_PTRLO: begin ptr[7:0]  <= lo; regsel <= RS_NONE; end
				REG_PTRHI: begin ptr[15:8] <= lo; regsel <= RS_NONE; end
				default: begin
					pk_go <= 1'b1;
					pk_a  <= ptr;
					pk_v  <= lo;
					ptr   <= ptr + 16'd1;
					ev_in <= {"P", ptr, lo};
					ev_we <= 1'b1;
				end
				endcase
			end else begin
				if (mbox && hi == PG_REGSEL && lo < HOT_BANK) regsel <= RS_NONE;
				ev_in <= {"H", ram_a, 8'd0};
				ev_we <= 1'b1;
			end
		end
		PG_RASTER: begin
			r_seen <= 1'b1;
			r_cnt  <= 8'd0;
			if (!r_seen || r_cnt > VBLANK) begin
				r_line <= 8'd0;
				r_col  <= 4'd0;
				if (pend_valid) begin
					ev_in <= {"F", 7'd0, pend_idx, 16'd0};
					ev_we <= 1'b1;
				end
			end else if (r_cnt > LINEGAP) begin
				if (r_line != 8'hFF) r_line <= r_line + 8'd1;
				r_col <= 4'd0;
			end else if (r_col != 4'hF) begin
				r_col <= r_col + 4'd1;
			end
		end
		default: ;
		endcase

		if (ram_a == 16'h0000 && seen && (prev == STUB_T || quiet > SILENCE || was_reset)) begin
			bank <= 8'd0;
			ev_in <= armed ? {"S", 7'd0, ~live, 16'd0} : {"B", 24'd0};
			ev_we <= 1'b1;
		end
		prev <= ram_a;
		seen <= 1'b1;
	end
	pk_go2 <= pk_go;
end

// The raster pages read at once from the new position: the strobe's update
// lands before the data read two clocks later, as s2_raster_next returns it.
// Flip and swap act on the same strobe.
wire flip_now = strobe && ty == PG_RASTER && (!r_seen || r_cnt > VBLANK) && pend_valid;
wire swap_now = strobe && ram_a == 16'h0000 && seen && (prev == STUB_T || quiet > SILENCE || was_reset) && armed;

// poke: look the pointer's page up on the second table ports
always @(posedge clk) begin
	pk_pe <= pg_tbl[{live, pk_a[15:8]}];
	pk_be <= bk_tbl[{live, bank[3:0], pk_a[11:8] - 4'd4}];
end
wire        pk_win  = (pk_a[15:8] >= 8'hC4) && (pk_a[15:8] <= 8'hCF) && (nbanks[live] != 5'd0);
wire [15:0] pk_e    = pk_win ? ((bank >= 8'd16) ? 16'h0000 : pk_be) : pk_pe;
wire        pk_we   = pk_go2 && pk_e[13] && (pk_e[10:8] == K_BUF);

////////////////////////////////////////////////////////////////////////////////
// link receive

localparam [7:0] SL_END = 8'hC0, SL_ESC = 8'hDB, SL_EEND = 8'hDC, SL_EESC = 8'hDD;

reg        rx_esc;
reg  [2:0] rx_n;            // header bytes seen, 4 = data
reg        rx_bad;
reg [23:0] la;
reg  [7:0] lo_latch;
reg        lk_we;
reg  [7:0] lk_d;
reg [23:0] lk_a;

wire [7:0] rx_d = rx_esc ? ((rx_byte == SL_EEND) ? SL_END : (rx_byte == SL_EESC) ? SL_ESC : rx_byte) : rx_byte;

always @(posedge clk) begin
	lk_we <= 1'b0;
	if (rx_strobe) begin
		if (rx_byte == SL_END) begin
			rx_n   <= 3'd0;
			rx_bad <= 1'b0;
			rx_esc <= 1'b0;
		end else if (rx_byte == SL_ESC) begin
			rx_esc <= 1'b1;
		end else begin
			rx_esc <= 1'b0;
			case (rx_n)
			3'd0: begin rx_bad <= (rx_d != "W"); rx_n <= 3'd1; end
			3'd1: begin la[23:16] <= rx_d; rx_n <= 3'd2; end
			3'd2: begin la[15:8]  <= rx_d; rx_n <= 3'd3; end
			3'd3: begin la[7:0]   <= rx_d; rx_n <= 3'd4; end
			default: if (!rx_bad) begin
				lk_we <= 1'b1;
				lk_a  <= la;
				lk_d  <= rx_d;
				la    <= la + 24'd1;
			end
			endcase
		end
	end
end

// link writes; a poke takes the buffer's write port first
reg        lk_buf_pend;
reg [16:0] lk_buf_a;
reg  [7:0] lk_buf_d;

always @(posedge clk) begin
	lk_ping     <= 1'b0;
	lk_busreset <= 1'b0;

	if (pk_we)
		buf_mem[{live, pk_e[7:0], pk_a[7:0]}] <= pk_v;
	else if (lk_buf_pend) begin
		buf_mem[lk_buf_a] <= lk_buf_d;
		lk_buf_pend <= 1'b0;
	end

	if (flip_now) begin
		front      <= pend_idx;
		pend_valid <= 1'b0;
	end
	if (swap_now) begin
		live  <= ~live;
		armed <= 1'b0;
	end

	if (!enable) c_ready <= 1'b0;

	if (lk_we) begin
		if (lk_a[23:17] == 7'd0) begin
			lk_buf_pend <= 1'b1;
			lk_buf_a    <= lk_a[16:0];
			lk_buf_d    <= lk_d;
		end else if (lk_a[23:12] == 12'h020) begin
			sm_mem[lk_a[11:0]] <= lk_d;
		end else if (lk_a[23:10] == 14'h084) begin
			if (!lk_a[0]) lo_latch <= lk_d;
			else pg_tbl[lk_a[9:1]] <= {lk_d, lo_latch};
		end else if (lk_a[23:10] == 14'h085) begin
			if (!lk_a[0]) lo_latch <= lk_d;
			else bk_tbl[lk_a[9:1]] <= {lk_d, lo_latch};
		end else if (lk_a[23:4] == 20'h02200) begin
			case (lk_a[3:0])
			4'h0: begin c_hold <= lk_d[0]; c_ready <= lk_d[1]; end
			4'h1: live <= lk_d[0];
			4'h2: armed <= lk_d[0];
			4'h3: begin pend_valid <= lk_d[7]; pend_idx <= lk_d[0]; end
			4'h4: mbx[0] <= lk_d[0];
			4'h5: mbx[1] <= lk_d[0];
			4'h6: nbanks[0] <= lk_d[4:0];
			4'h7: nbanks[1] <= lk_d[4:0];
			4'h8: lk_ping <= 1'b1;
			4'h9: begin lk_busreset <= 1'b1; front <= lk_d[0]; pend_valid <= 1'b0; end
			default: ;
			endcase
		end
	end
end

////////////////////////////////////////////////////////////////////////////////
// event FIFO and SLIP transmit

reg ping_pend;
always @(posedge clk) begin
	if (lk_ping) ping_pend <= 1'b1;
	if (lk_busreset) begin
		ev_rp   <= ev_wp;
		ev_lost <= 16'd0;
	end
	if (ev_we) begin
		if (ev_full) ev_lost <= ev_lost + 16'd1;
		else begin
			ev_mem[ev_wp] <= ev_in;
			ev_wp <= ev_wp1;
		end
	end else if (ping_pend && !ev_full) begin
		ev_mem[ev_wp] <= {"O", VERSION, {5'd0, hold, active, enable}, ev_lost[7:0]};
		ev_wp <= ev_wp1;
		ping_pend <= 1'b0;
	end
	if (tx_pop && !lk_busreset) ev_rp <= ev_rp + 12'd1;
end

reg [31:0] ev_out;
reg        ev_avail;
always @(posedge clk) begin
	ev_out   <= ev_mem[ev_rp];
	ev_avail <= !ev_empty && !tx_pop;     // ev_out is a clock behind a write or a pop
end

reg  [2:0] tx_n;            // 0-3 the event's bytes, 4 END
reg        tx_busy, tx_esc2, tx_ld;
reg  [7:0] tx_cur;
reg [31:0] tx_ev;

wire [7:0] tx_raw = (tx_n == 3'd0) ? tx_ev[31:24] : (tx_n == 3'd1) ? tx_ev[23:16] :
                    (tx_n == 3'd2) ? tx_ev[15:8]  : tx_ev[7:0];
wire       tx_spec = (tx_raw == SL_END) || (tx_raw == SL_ESC);

assign tx_valid = tx_busy;
assign tx_byte  = tx_cur;

always @(posedge clk) begin
	tx_pop <= 1'b0;
	tx_ld  <= 1'b0;
	if (!tx_busy && !tx_ld) begin
		if (ev_avail && !ev_empty && !tx_pop) begin
			tx_ev <= ev_out;
			tx_n  <= 3'd0;
			tx_ld <= 1'b1;
			tx_pop <= 1'b1;
		end
	end else if (tx_ld) begin
		tx_cur  <= tx_spec ? SL_ESC : tx_raw;
		tx_esc2 <= tx_spec;
		tx_busy <= 1'b1;
	end else if (tx_ready) begin
		if (tx_esc2) begin
			tx_cur  <= (tx_raw == SL_END) ? SL_EEND : SL_EESC;
			tx_esc2 <= 1'b0;
		end else if (tx_n == 3'd4) begin
			tx_busy <= 1'b0;
		end else if (tx_n == 3'd3) begin
			tx_n   <= 3'd4;
			tx_cur <= SL_END;
		end else begin
			tx_n <= tx_n + 3'd1;
			tx_ld <= 1'b1;
			tx_busy <= 1'b0;
		end
	end
end

endmodule

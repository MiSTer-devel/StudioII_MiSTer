`timescale 1ns/1ps

module emu_reset_test;
reg clk = 0;
reg reset = 0;
always #10 clk = !clk;

emu dut (.CLK_50M(clk), .RESET(reset));

integer info_count = 0;
reg [7:0] last_info = 0;
always @(posedge clk) begin
    if (dut.hps_io.info_req) begin
        info_count <= info_count + 1;
        last_info <= dut.hps_io.info;
    end
end

task automatic finish_info_delay;
    repeat (3) @(negedge clk);
    dut.info_dly = 22'd2;
    repeat (5) @(negedge clk);
endtask

task automatic settle;
    repeat (300) @(negedge clk);
endtask

task automatic download(input [15:0] index, input [7:0] data);
    dut.hps_io.ioctl_index = index;
    dut.hps_io.ioctl_addr = 0;
    dut.hps_io.ioctl_download = 1;
    repeat (2) @(negedge clk);
    dut.hps_io.ioctl_wr = 1;
    dut.hps_io.ioctl_dout = data;
    @(negedge clk);
    dut.hps_io.ioctl_wr = 0;
    dut.hps_io.ioctl_download = 0;
    settle();
endtask

task automatic apply_machine(input [1:0] machine);
    dut.hps_io.status[14:13] = machine;
    dut.hps_io.status[15] = 1;
    repeat (2) @(negedge clk);
    dut.hps_io.status[15] = 0;
    settle();
endtask

initial begin
    settle();
    if (!dut.reset) $fatal(1, "Missing BIOS must hold reset");

    // Only one byte: BIOS-free startup must work for short CHIP-8 programs.
    download(16'd3, 8'h12);
    if (dut.rom_loaded || !dut.chip8_active || dut.reset || dut.video_reset)
        $fatal(1, "CHIP-8 must release reset without a BIOS");

    reset = 1;
    @(negedge clk);
    if (!dut.reset || !dut.video_reset) $fatal(1, "Hard reset must dominate CHIP-8");
    reset = 0;
    settle();
    if (dut.reset) $fatal(1, "CHIP-8 must survive hard reset");

    dut.hps_io.status[1] = 1;
    @(negedge clk);
    if (!dut.reset || dut.video_reset) $fatal(1, "CLEAR must preserve raster timing");
    dut.hps_io.status[1] = 0;
    settle();

    apply_machine(2'd3);
    if (dut.chip8_active || !dut.reset)
        $fatal(1, "Visicom must not bypass the BIOS requirement");
    apply_machine(2'd0);
    if (!dut.chip8_active || dut.reset) $fatal(1, "Returning to Studio II must resume CHIP-8");

    dut.hps_io.status[28] = 1;
    @(negedge clk);
    dut.hps_io.status[28] = 0;
    settle();
    if (dut.chip8_active || !dut.reset) $fatal(1, "Unload must restore the BIOS requirement");

    // Interpreter replacement alone must not enter CHIP-8 mode.
    download(16'd4, 8'h00);
    if (dut.chip8_active || !dut.reset) $fatal(1, "Interpreter load must not release reset");
    download(16'd3, 8'h12);
    if (dut.chip8_active || !dut.reset) $fatal(1, "Invalid interpreter must not enable CHIP-8");

    if (info_count != 0) $fatal(1, "Profile info must wait for boot settings");
    dut.boot_follow_cnt = 23'h400000;
    force dut.auto_profile = 4'd8;
    finish_info_delay();
    if (info_count != 1 || last_info != 9)
        $fatal(1, "Initial automatic profile must be announced");
    settle();
    if (info_count != 1) $fatal(1, "Stable profile must not repeat info");

    dut.hps_io.status[6] = 1;
    for (integer p = 0; p < 16; p = p + 1) begin
        dut.hps_io.status[5:2] = 4'(p);
        finish_info_delay();
        if (info_count != p + 2 || last_info != p + 1)
            $fatal(1, "Manual profile info index mismatch");
    end

    force dut.auto_profile = 4'd2;
    finish_info_delay();
    if (info_count != 17) $fatal(1, "Manual mode must ignore automatic changes");
    dut.hps_io.status[6] = 0;
    finish_info_delay();
    if (info_count != 18 || last_info != 3)
        $fatal(1, "Returning to automatic mapping must announce active profile");

    dut.hps_io.status[40] = 1;
    force dut.auto_profile = 4'd4;
    finish_info_delay();
    if (info_count != 18) $fatal(1, "Info Messages Off must suppress popups");
    dut.hps_io.status[40] = 0;
    finish_info_delay();
    if (info_count != 18) $fatal(1, "Enabling info must not replay old messages");

    dut.hps_io.ioctl_index = 16'd1;
    dut.hps_io.ioctl_download = 1;
    finish_info_delay();
    if (info_count != 18) $fatal(1, "Profile info must wait for download completion");
    dut.hps_io.ioctl_download = 0;
    finish_info_delay();
    if (info_count != 19 || last_info != 5)
        $fatal(1, "Completed software load must announce profile");
    release dut.auto_profile;

    $display("PASS BIOS-free CHIP-8 reset and profile info");
    $finish;
end
endmodule

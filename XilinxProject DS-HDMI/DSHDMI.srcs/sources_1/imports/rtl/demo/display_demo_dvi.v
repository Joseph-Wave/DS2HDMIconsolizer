`timescale 1ns / 1ps
`default_nettype none

`include "consts.v"

module display_demo_dvi (
    
    // MODULE
	input wire clk,
	input wire [4:0] pin_control,	// ['GSP' 'GCK' 'DCLK' 'SPL' 'LS']
	input wire [17:0] pin_RGB,		// { pin_R[17:12], pin_G[11:6], pin_B[5:0] }
	
	// HDMI
	output wire hdmi_tx_clk_n,      // HDMI clock differential negative
    output wire hdmi_tx_clk_p,      // HDMI clock differential positive
    output wire [2:0] hdmi_tx_n,    // Three HDMI channels differential negative
    output wire [2:0] hdmi_tx_p,     // Three HDMI channels differential positive
    
    // LEDs
    output wire [1:0] led,
    
    // Buttons
    input wire [1:0] btn
);

//////////////////////////////////////////////////////////////////////////////
//                              DISPLAY TIMING                              //
//////////////////////////////////////////////////////////////////////////////

    wire clk_logic, clk_1x, clk_5x, clk_lock;
    
    display_clocks  #(
		.MULT_MASTER(`CLOCK_MULT_MASTER),
		.DIV_MASTER(`CLOCK_DIV_MASTER),
		.DIV_5X(`CLOCK_DIV_5X),
		.DIV_1X(`CLOCK_DIV_1X),
		.IN_PERIOD(`CLOCK_IN_PERIOD)
	) display_clocks_inst (
       .i_clk(clk),
       .i_rst(0),
       .o_clk_1x(clk_1x),
       .o_clk_5x(clk_5x),
       .o_locked(clk_lock),
       .o_clk_main(clk_logic) // clk_logic is the same as clk_1x but in other buffer
    );
    
//////////////////////////////////////////////////////////////////////////////
//                          CLOCK VISUAL CHECKER                            //
//////////////////////////////////////////////////////////////////////////////

	reg [36:0] clk_divisor = 0;
	reg pin_status_0 = 1;
	always @(posedge clk) begin
		if (clk_divisor < 12000000*2) clk_divisor <= clk_divisor + 1;
		else begin 
			$display("%d", 1); $display(" sec");
			pin_status_0 <= !pin_status_0;
			clk_divisor <= 0;
		end 
	end
	
	assign led[0] = pin_status_0;
	
	reg pin_menu = 0;
	always @(posedge clk_logic) begin
		if (btn[0] == 1) pin_menu = 1;
		if (btn[1] == 1) pin_menu = 0;
	end
	
	assign led[1] = pin_menu;
	
//////////////////////////////////////////////////////////////////////////////
//                              DISPLAY SIGNALS                             //
//////////////////////////////////////////////////////////////////////////////

    wire signed [15:0] sx;
    wire signed [15:0] sy;
    wire h_sync, v_sync, line, frame;
    
    display_timings  #(
       .H_RES(`H_RES),
       .V_RES(`V_RES),
       .H_FP(`TIME_H_FP),
       .H_SYNC(`TIME_H_SYNC),
       .H_BP(`TIME_H_BP),
       .V_FP(`TIME_V_FP),
       .V_SYNC(`TIME_V_SYNC),
       .V_BP(`TIME_V_BP),
       .H_POL(`TIME_H_POL),
       .V_POL(`TIME_V_POL)
	) display_timings_inst (
        .i_clk(clk_1x),
        .i_rst(!clk_lock),
        .o_hs(h_sync),
        .o_vs(v_sync),
        .o_de(line),
        .o_frame(frame),
        .o_sx(sx),
        .o_sy(sy)
    );

//////////////////////////////////////////////////////////////////////////////
//                             FRAME FINDER                                 //
//////////////////////////////////////////////////////////////////////////////

	wire hdmi_start; // Unused
	wire pulse_px;
	wire pulse_line;
	wire signed [`BYT+1:0] addr_px_in;
	wire signed [`BYT+1:0] addr_line_in;
	
	frame_finder frame_finder_inst (
		.i_clk(clk_logic),
		.video_in({pin_control[4], pin_control[3], pin_control[2], pin_control[1], pin_control[0]}),
		.sync_go(hdmi_start),
		
		.pulse_line(pulse_line),
		.addr_line(addr_line_in),
		
		.pulse_px(pulse_px),
		.addr_px(addr_px_in)
	);

//////////////////////////////////////////////////////////////////////////////
//                             DISPLAY SCALE                                //
//////////////////////////////////////////////////////////////////////////////

	wire signed [`BYT+1:0] ds_x;
	wire signed [`BYT+1:0] ds_y;

	ds_timing ds_timing_inst (
		.i_clk(clk_logic),
		.sx(sx),
		.sy(sy),
		.ds_x(ds_x),
		.ds_y(ds_y)
	);

//////////////////////////////////////////////////////////////////////////////
//                            SRAM FRAME BUFFER                             //
//////////////////////////////////////////////////////////////////////////////

	wire [5:0] pin_B = pin_RGB[5:0];
	wire [5:0] pin_G = pin_RGB[11:6];
	wire [5:0] pin_R = pin_RGB[17:12];

	wire [`ADR:0] addrIn = (addr_line_in >= 0 && addr_px_in >= 0) ? addr_line_in[7:0] * `DS_H_RES + addr_px_in[7:0] : `BRAM_H * `BRAM_V;
	wire [`DAT:0] dataIn = {pin_R[5:0], pin_G[5:0], pin_B[5:0]}; // you can save up the ALPHA bit

	wire [`ADR:0] addrOut = (ds_x >= 0 && ds_y >= 0) ? ds_y[7:0] * `DS_H_RES + ds_x[7:0] : (`BRAM_H * `BRAM_V) << 2;
	wire [`DAT:0] dataOut;

	bram bram_inst (
		.clkA(clk_logic),
		.enA(pulse_px),
		.addrIn(addrIn),
		.dataIn(dataIn),
		.clkB(clk_logic),
		.enB(1),
		.addrOut(addrOut),
		.dataOut(dataOut)
	);

//////////////////////////////////////////////////////////////////////////////
//                                 Test Card                                //
//////////////////////////////////////////////////////////////////////////////
	
	wire [23:0] dataPrint;
	
	coloring coloring_inst (
		.i_clk(clk_logic),
		.i_menu(pin_menu),
		.sx(sx),
		.sy(sy),
		.ds_x(ds_x),
		.ds_y(ds_y),
		.dataIn(dataOut),
		.dataOut(dataPrint)
	);
	
	wire [`BYT:0] blue   = dataPrint[7:0];
	wire [`BYT:0] green = dataPrint[15:8];
	wire [`BYT:0] red  = dataPrint[23:16]; 

//////////////////////////////////////////////////////////////////////////////
//                 HDMI: TMDS Encoding and Serialization                    //
//////////////////////////////////////////////////////////////////////////////
// Remember to comment this in quick simulations

    wire tmds_ch0_serial, tmds_ch1_serial, tmds_ch2_serial, tmds_chc_serial;
    dvi_generator dvi_out (
        .i_clk_1x(clk_1x),
        .i_clk_5x(clk_5x),
        .i_rst(!clk_lock),
        .i_de(line),
        .i_data_ch0(blue),
        .i_data_ch1(green),
        .i_data_ch2(red),
        .i_ctrl_ch0({v_sync, h_sync}),
        .i_ctrl_ch1(2'b00),
        .i_ctrl_ch2(2'b00),
        .o_tmds_ch0_serial(tmds_ch0_serial),
        .o_tmds_ch1_serial(tmds_ch1_serial),
        .o_tmds_ch2_serial(tmds_ch2_serial),
        .o_tmds_chc_serial(tmds_chc_serial) // encode pixel clock via same path
    );

//////////////////////////////////////////////////////////////////////////////
//                        HDMI: TMDS Buffered Output                        //
//////////////////////////////////////////////////////////////////////////////

    OBUFDS #(.IOSTANDARD("TMDS_33")) 
        tmds_buf_ch0 (.I(tmds_ch0_serial), .O(hdmi_tx_p[0]), .OB(hdmi_tx_n[0]));
    OBUFDS #(.IOSTANDARD("TMDS_33")) 
        tmds_buf_ch1 (.I(tmds_ch1_serial), .O(hdmi_tx_p[1]), .OB(hdmi_tx_n[1]));
    OBUFDS #(.IOSTANDARD("TMDS_33")) 
        tmds_buf_ch2 (.I(tmds_ch2_serial), .O(hdmi_tx_p[2]), .OB(hdmi_tx_n[2]));
    OBUFDS #(.IOSTANDARD("TMDS_33")) 
        tmds_buf_chc (.I(tmds_chc_serial), .O(hdmi_tx_clk_p), .OB(hdmi_tx_clk_n));

endmodule
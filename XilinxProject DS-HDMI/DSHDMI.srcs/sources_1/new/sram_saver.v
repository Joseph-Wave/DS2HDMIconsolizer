`timescale 1ns / 1ps
`include "consts.v"

module sram_saver (
	input wire clk,
	
	input wire [`DAT:0] px_data,
	
	input wire bram_pxSample,
	input wire bram_lineSample,
	input wire [`BYT:0] bram_pxAddr,
	input wire [`BYT:0] bram_lineAddr,
	
	output wire RamWEn_W,
	output wire RamCEn_W,
	output wire RamOEn_W,
	output wire [`ADR:0] MemAdr_W,
	output wire [`DAT:0] MemDB_W,
	
	output wire saving_on
);

	reg start_W = 0;
	reg [`ADR:0] send_addr;
	reg [`DAT:0] send_data;
	wire busy_W;
	
	reg _saving_on = 0;
	
	assign saving_on = _saving_on; 
	
	localparam [1:0] 
		stp_wIdle		= 2'b00,
		stp_wWrite		= 2'b01,
		stp_wWait		= 2'b10;
	
	reg [1:0] stp_inMem = stp_wIdle;
	
	always @(posedge clk) begin
	
		case(stp_inMem)

			stp_wIdle: begin
				if (bram_pxSample) begin
					_saving_on <= 1;     			
					send_addr <= bram_lineAddr * `DS_H_RES + bram_pxAddr;
					send_data <= px_data;			
					stp_inMem <= stp_wWrite;
				end
				
				if (_saving_on && !bram_lineSample) _saving_on <= 0;
			end
			
			stp_wWrite: begin
				start_W <= !busy_W;
				if (busy_W) stp_inMem <= stp_wWait;
			end
			
			stp_wWait: begin
				start_W <= 0;
				if (!busy_W) stp_inMem <= stp_wIdle;
			end
	
		endcase
	end

	// Controller
/*	
	wire RamWEn_W;
	wire RamCEn_W;
	wire RamOEn_W;
	wire [`ADR:0] MemAdr_W;
	wire [`DAT:0] MemDB_W;
*/
	sramCtrl_w sramInstW (
		.clk(clk),
		.start_W(start_W),
		.addr_W(send_addr),
		.data_W(send_data),
		.port_busy(busy_W),
		.sram_WE(RamWEn_W),
		.sram_CE(RamCEn_W),
		.sram_OE(RamOEn_W),
		.sram_A(MemAdr_W),
		.sram_IO(MemDB_W)
	);
    
endmodule

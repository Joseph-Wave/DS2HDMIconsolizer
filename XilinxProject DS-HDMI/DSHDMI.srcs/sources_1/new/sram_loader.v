`timescale 1ns / 1ps
`include "consts.v"

module sram_loader(
	input wire clk,

	input wire pix_clk,
	
	input wire [`BDT+1:0] ds_x,
	input wire [`BDT+1:0] ds_y,
	
	output wire [`DAT:0] ramDataOut
);  

	reg ramClkA = 0;
	reg [`BYT:0] ramAddrIn = 0; reg [`BYT:0] ramAddrIn_old = 0;
	reg [`RDL:0] ramDataIn = 0;

	reg start_R = 0;
	reg [`RAL:0] load_addr;
	wire [`RDL:0] load_data;
	wire busy_R;

	localparam [1:0] 
		stp_rIdle		= 2'b00,
		stp_rRead		= 2'b01,
		stp_rWait		= 2'b10,
		stp_rEnd		= 2'b11;
	
	reg [1:0] stp_outMem = stp_rIdle;
	reg to_bram = 0;
	
	reg [`BYT:0] _ds_y = 0;
	
	always @(posedge clk) begin
	
		case(stp_outMem)
			
			stp_rIdle: begin
				if (!saving_on) begin
					_ds_y <= ds_y;
					load_addr <= ds_y * `ds_resH;
					ramAddrIn <= 0;
					stp_outMem <= stp_rRead;
				end
			end
	
			stp_rRead: begin
				start_R <= !busy_R;
				if (busy_R) stp_outMem <= stp_rWait;

				if (to_bram) begin
					ramClkA <= 1;
					to_bram <= 0;
				end
			end
			
			stp_rWait: begin
				start_R <= 0;
				if (!busy_R) begin	
					ramDataIn <= load_data;
					to_bram <= 1;
					if (load_addr + 1 < (_ds_y + 1) * `ds_resH) begin
						load_addr <= load_addr + 1;
						stp_outMem <= stp_rRead;
					end else stp_outMem <= stp_rEnd;
				end
			end
			
			stp_rEnd: begin
				if (saving_on == 1) stp_outMem <= stp_rIdle;
				if (to_bram) begin
					ramClkA <= 1;
					to_bram <= 0;
				end
			end
			
		endcase

		if (ramClkA) begin
			ramClkA <= 0;
			ramAddrIn <= ramAddrIn + 1;
		end
		
		ramAddrIn_old <= ramAddrIn;
	end

//////////////////////////////////////////////////////////////////////////////
//                                LINE BUFFER                               //
//////////////////////////////////////////////////////////////////////////////

	reg [7:0] saving_at = 0;

	always @(posedge clk) begin
		if (ramAddrIn_old == 255 && ramAddrIn == 0) begin
			saving_at <= (saving_at + 1 < `BRAM_ROW) ? saving_at + 1 : 0;
		end
	end
	
	wire [9:0] _ramAddrIn = ramAddrIn + saving_at * `BRAM_COL;
	
	wire [9:0] reading_at = (saving_at + 1 < `BRAM_ROW) ? saving_at + 1 : 0;
	
	wire [9:0] _addrOut = reading_at * `BRAM_COL + {2'b00, ds_x[7:0]};


endmodule

`timescale 1ns / 1ps
`include "consts.v"

module IS61WV5128BL (
	input wire clk, 
    input wire RamWEn,				// Write Enable Input (active Low)
	input wire RamCEn,				// Chip Enable Input (active Low)
	input wire RamOEn,				// Output Enable Input (active Low)
	input wire [`ADR:0] MemAdr, 	// Address Inputs
	inout wire [`DAT:0] MemDB		// Bidirectional Ports
);

    localparam AVAILABLE_BYTES = `ISSI_V * `ISSI_H; // ID + rows * cols

//=========================================================================

/*
    function integer log2 ( input integer value ); // floor(log2(x))
        reg [31:0] shifted;
        integer res;
        begin
            if (value < 2)
                log2 = value;
            else begin
                shifted = value-1;
                for (res=0; shifted>0; res=res+1) begin
                    shifted = shifted>>1;
                end
                log2 = res;
                if (2**log2 > value) log2 = res-1; // comment this line to make it: ceil(log2(x))
            end
        end
    endfunction

    localparam AVAILABLE_ADDR = log2(AVAILABLE_BYTES) + 1;
 	
    initial begin
        $display("AVAILABLE_BYTES = %d, ADDR_LEN = %d, MAX_ADDR = %d", AVAILABLE_BYTES, AVAILABLE_ADDR, 2 ** (AVAILABLE_ADDR));
    end
*/

//=========================================================================

	// Simu Memory  
	reg [`DAT:0] issi_ram [AVAILABLE_BYTES-1:0];
	generate
        genvar i;
        for(i = 0; i < AVAILABLE_BYTES; i = i + 1) initial issi_ram[i] = `DATz;
    endgenerate
    
//=============================================================================================================

	reg [`DAT:0] _MemDB = `DATz;
	wire [`ADR:0] _MemAdr = (MemAdr < AVAILABLE_BYTES) ? MemAdr[`ADR:0] : 0;
	
	reg RamOEn_then = 0; reg RamOEn_now = 0;
	reg RamWEn_then = 0; reg RamWEn_now = 0;
	
	always @(posedge clk) begin
		RamOEn_then <= RamOEn_now; RamOEn_now <= RamOEn;
		RamWEn_then <= RamWEn_now; RamWEn_now <= RamWEn;
	end

//=============================================================================================================

	localparam [1:0] 
		stp_off   = 2'b00,
		stp_on	  = 2'b01, 
		stp_read  = 2'b10,
		stp_write = 2'b11;
	
	reg [1:0] stp_state = stp_off;
	
	reg [`DAT:0] oldDB = `DATz;

	always @(posedge clk) begin

		case(stp_state)
		
			stp_off: begin
				oldDB <= `DATz;
				stp_state <= (RamCEn == 1) ? stp_off : stp_on;
			end
			
			stp_on: begin
				if ((RamOEn_then == 1 && RamOEn_now == 0) && (RamWEn_then == 1 && RamWEn_now == 1)) begin
					oldDB <= `DATz;
					stp_state <= stp_read;
				end else
				
				if (RamWEn_then == 1 && RamWEn_now == 0) begin
					oldDB <= `DATz;
					stp_state <= stp_write;
				end else 
				
				if (RamCEn == 1) stp_state <= stp_off;
			end
		
			stp_read: begin
				oldDB <= issi_ram[_MemAdr];
				stp_state <= stp_on;
			end
			
			stp_write: begin
				issi_ram[_MemAdr] <= MemDB;
				oldDB <= `DATz;
				stp_state <= stp_on;
			end
		
		endcase
	end
	
	assign MemDB = oldDB;
    
endmodule

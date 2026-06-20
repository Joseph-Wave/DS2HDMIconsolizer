`timescale 1ns / 1ps
`include "consts.v"

// True-Dual-Port BRAM with Byte-wide Write Enable No-Change mode

module bram (
    input wire clkA,
    input wire enA,
    input wire [`ADR:0] addrIn,
    input wire [`DAT:0] dataIn,
    
    input wire clkB,
    input wire enB,
    input wire [`ADR:0] addrOut,
   output wire [`DAT:0] dataOut
); 

	localparam MEM_SIZE = `BRAM_H * `BRAM_V;

    // Core Memory
    (* ram_style = "block", INIT = "0" *) reg [`DAT:0] bram_block [0:MEM_SIZE-1];
    
//  (* ram_style = "block" *) reg [`DAT:0] bram_block [MEM_SIZE-1:0];
//	generate
//        genvar i;
//        for(i = 0; i < MEM_SIZE; i = i + 1) begin initial bram_block[i] = 0; end
//	endgenerate
	
    // Port-A Operation
    always @ (posedge clkA) begin
    	if (enA) begin
    		if (addrIn < MEM_SIZE) bram_block[addrIn] <= dataIn;
    	end
    end
    
    // Port-B Operation
    reg [`DAT:0] _dataOut = 0;
    always @ (posedge clkB) begin
    	if (enB) begin
			if (addrOut >= MEM_SIZE) _dataOut <= 0;
			else _dataOut <= bram_block[addrOut];
        end
    end
    assign dataOut = _dataOut;

endmodule


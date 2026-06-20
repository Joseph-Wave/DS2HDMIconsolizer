`timescale 1ns / 1ps

module raw_data (
    input wire clk, 
    input wire integer addr,
    output wire [5:0] data
);

    reg [5:0] csv [297229-1:0];
        
    generate
        initial begin
		csv[0]=6'b100011;
        csv[1]=6'b100010;
        csv[2]=6'b100011;        
		// .... not usefull anymore
		csv[297226]=6'b100000;
        csv[297227]=6'b100001;
        csv[297228]=6'b100010;

        end
    endgenerate
    
    reg [5:0] data_t = 0;

    always @(posedge clk) begin
        data_t <= csv[addr];
    end
    
    assign data = data_t;

endmodule

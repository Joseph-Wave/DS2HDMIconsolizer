`timescale 1ns / 1ps
`include "consts.v"

module ds_timing (
	input wire i_clk,
	input wire signed [15:0] sx,
    input wire signed [15:0] sy,
	
	output wire signed [`BYT+1:0] ds_x,
	output wire signed [`BYT+1:0] ds_y
);  
	
	wire screen_on = 
		(sx >= `BLANK_X) && (sy >= `BLANK_Y) && (sx < `BLANK_X + `SCALE * `DS_H_RES) && (sy < `BLANK_Y + `SCALE * `DS_V_RES);
	
	wire signed [15:0] screen_x = screen_on ? sx - `BLANK_X : -1;
	reg signed [15:0] screen_x_old = -1;
	
	//wire signed [15:0] screen_y = screen_on ? sy - `BLANK_Y : -1;
	
	reg signed [`BYT+1:0] _ds_x = 0;
	reg signed [`BYT+1:0] _ds_y = 0;
	
	assign ds_x = (_ds_x < 0 || _ds_x >= `DS_H_RES || sx < `BLANK_X || (sx > `BLANK_X + `SCALE * `DS_H_RES)) ? -1 : _ds_x;
	assign ds_y = (_ds_y < 0 || _ds_y >= `DS_V_RES || sy < `BLANK_Y || (sy > `BLANK_Y + `SCALE * `DS_V_RES)) ? -1 : _ds_y;
	
	reg [`BYT:0] scale_counter_x = 0;
	reg [`BYT:0] scale_counter_y = 0;
	
	localparam [1:0] 
	    stp_idle    	= 2'b00, 
	    stp_line  	 	= 2'b01,
	    stp_lineCheck	= 2'b10;
	    
	reg [1:0] stp_scaler = stp_idle;
	
	always @(posedge i_clk) begin

	    case(stp_scaler)

	        stp_idle: begin
	        	if (screen_x_old != screen_x && screen_x == 0) begin
	        		scale_counter_x <= 0;
	        		_ds_x <= 0;
	        		stp_scaler <= stp_line;
	        	end else _ds_x <= -1;
	        end
	        
			stp_line : begin
				if (screen_x_old != screen_x && screen_x != -1) begin
					if (scale_counter_x + 1 < `SCALE) scale_counter_x <= scale_counter_x + 1;
					else begin
						scale_counter_x <= 0;
						_ds_x <= _ds_x + 1;
					end
				end
				else if (screen_x == -1) begin
					_ds_x <= -1;
					stp_scaler <= stp_lineCheck;
				end				
			end
			
			stp_lineCheck : begin
				if (scale_counter_y + 1 < `SCALE) scale_counter_y <= scale_counter_y + 1;
				else begin
					scale_counter_y <= 0;
					if (sy >= `BLANK_Y + `SCALE * `DS_V_RES - 1) _ds_y <= 0;
					else _ds_y <= _ds_y + 1;
				end
				stp_scaler <= stp_idle;
			end
	    
	    endcase
	    
	    screen_x_old <= screen_x;
	end

endmodule

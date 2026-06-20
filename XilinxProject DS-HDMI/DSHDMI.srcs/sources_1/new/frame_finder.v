`timescale 1ns / 1ps
`include "consts.v"

module frame_finder (
    input wire i_clk,
    input wire [4:0] 				video_in,	// Trigger singals from video ['GSP' 'GCK' 'DCLK' 'SPL' 'LS']
    output wire 					pulse_line,
    output wire 					pulse_px,
    output wire signed [`BYT+1:0] 	addr_px,
    output wire signed [`BYT+1:0] 	addr_line,
    output wire sync_go
);

/*	
	['GSP' 'GCK' 'DCLK' 'SPL' 'LS']		['extra/samplingCLK']
	  4     3     2      1     0			just for simu
	
	GSP: RiseUp for frame start
	GCK: RiseUp for line start
	DCLK: Pixel Clock (either Flip)
	SPL: RiseDown for pixel line start (after RiseDown wait one DCLK cycle or two pixels)
	LS: is just a positive pulse while GSP is low (with a duration of ~1 full DCLK cycle) 
		and triggers around the middle of the low state of GSP. Its just an insurance, 
		not really needed.
*/

	localparam integer COL2START = 0;
	localparam integer ROW2START = 0;
	
	reg GSP_then = 1; reg GSP_now = 1;
	reg GCK_then = 1; reg GCK_now = 1;
	reg SPL_then = 1; reg SPL_now = 1;
	reg DCLK_then = 0; reg DCLK_now = 0;
	
	always @(posedge i_clk) begin 
		GSP_now <= video_in[4]; GSP_then <= GSP_now;
		GCK_now <= video_in[3]; GCK_then <= GCK_now;
		DCLK_now <= video_in[2]; DCLK_then <= DCLK_now;
		SPL_now <= video_in[1]; SPL_then <= SPL_now;
	end
	
	(* keep = "true" *) wire unused_LS = video_in[0]; 
	
	wire dataClock = ((DCLK_then == 1) && (DCLK_now == 0)) || ((DCLK_then == 0) && (DCLK_now == 1));
	
	reg signed [`BYT+1:0] px_count = 0;
	reg [`BYT:0] row_count = 0;
	
	reg pulse_line_t = 0;
	reg store_sampling_t = 0;
	
	localparam [3:0] 
	    stp_idle =				4'b0000,
	    stp_newFrame =  		4'b0001, 
	    stp_rowIdle =   		4'b0010,
	    stp_rowWait =   		4'b0011,
	    stp_rowSampling = 		4'b0100,
	    stp_rowSamplingIdle = 	4'b0101,
	    stp_rowEnd =    		4'b0111;
	
	reg [3:0] stp_state = stp_idle;
	
	always @(posedge i_clk) begin
	
	    case(stp_state)
	        
	        stp_idle: begin
	           store_sampling_t <= 0;
				if ((GSP_then == 1) && (GSP_now == 0)) stp_state <= stp_newFrame;
	        end
	      	
	      	stp_newFrame: begin
	        	if ((GCK_then == 1) && (GCK_now == 0)) stp_state <= stp_rowIdle;
	       	end
	       	
	       	stp_rowIdle: begin
	       		pulse_line_t <= 0;
	       		store_sampling_t <= 0;
				if ((SPL_then == 1) && (SPL_now == 0)) stp_state <= stp_rowWait;
			end
			
			stp_rowWait: begin
				pulse_line_t <= 1;
				if ((DCLK_then == 1) && (DCLK_now == 0)) stp_state <= stp_rowSampling;
			end
			
			stp_rowSampling: begin	
				store_sampling_t <= 1;
				if (dataClock) begin
					if (px_count == `DS_H_RES - 1) begin
						px_count <= 0; // -1 to start the bram at addr=0 at pulse_px
						if (row_count == `DS_V_RES - 1) begin
                            stp_state <= stp_idle;
                            pulse_line_t <= 0;
                            row_count <= 0; // 0 to start the bram at addr=0 at pulse_px
                        end else begin
                            row_count <= row_count + 1;
                            stp_state <= stp_rowIdle;
                        end
					end else px_count <= px_count + 1;
				end
			end
	        
	    endcase
	end
    
    assign pulse_px = (dataClock && store_sampling_t && px_count != `DS_H_RES); // do not deny it
    assign pulse_line = pulse_line_t;
    
	assign addr_px = stp_state <= stp_rowIdle ? -1 : {1'b0, px_count};
	assign addr_line = stp_state <= stp_rowIdle ? -1 : {1'b0, row_count};
	
	// HDMI sync
	
	reg _sync_go = 0;
	
	always @(posedge i_clk) begin
		if (addr_line == ROW2START && addr_px == COL2START) _sync_go <= 1;
	end
	
	assign sync_go = _sync_go;
	
endmodule
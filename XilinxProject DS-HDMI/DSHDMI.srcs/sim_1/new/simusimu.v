`timescale 1ns / 1ps

/*
add_force {/simusimu/DS_clk} -radix bin {1 0ns} {0 26915ps} -repeat_every 53830ps
add_force {/simusimu/MAIN_clk} -radix bin {1 0ns} {0 5000ps} -repeat_every 10000ps
run all

save_wave_config {D:/Xilinx/Projects/XilinxProjectsDSHDMI/demo_behav.wcfg}

n25q32-3.3v-spix1_x2_x4 | mx25l3273f
*/

module simusimu (
    input wire DS_clk,
    input wire MAIN_clk
);

//////////////////////////////////////////////////////////////////////////////
//                      	      GET SAMPLES                     		    //
//////////////////////////////////////////////////////////////////////////////

	integer unsigned file, aline, sample;
	initial begin
		file = $fopen("../../../raw_video.txt", "r");
		#100;
		$display("Data Ready");
	end
	
	integer sample_count = 0;
	always @(posedge DS_clk) begin
		$fgets(aline, file);
		$sscanf(aline, "%d", sample);
		
		if (sample_count == 297229) begin
			sample_count <= 0;
		end else sample_count <= sample_count + 1;
	end

//////////////////////////////////////////////////////////////////////////////
//                      	       DEMO                         		    //
//////////////////////////////////////////////////////////////////////////////

    display_demo_dvi DEMO (
        .clk(MAIN_clk),
        .pin_control(sample[5:1]), // ['GSP' 'GCK' 'DCLK' 'SPL' 'LS' 'extra/samplingCLK']
        .pin_RGB(18'b111111_111111_111111)
    );

endmodule

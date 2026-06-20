`timescale 1ns / 1ps

`ifndef INCLUDED_FILE

	// Standards

	`define BYT 7

	`define DS_H_RES	256     // x = 256 px + 16 px (sync)
    `define DS_V_RES    192     // y = 192 lines + 3 lines (sync) 
	
	// Data size
	
	`define ADR	15 // 16-bit address // floor(log(256*192,2)) + 1 and -1 cause syntax
	`define DAT	17 // 18 bits // RGB-6bit // the 0 bit is alpha so it can be shinked from 18 to 15 bits total
										  // LOW means full color, HIGH means black
										  // Real color is only 15-bit RGB (5:5:5) meaning 32768 colors
	
	// Memory
	
	`define BRAM_H	256
	`define BRAM_V	192
	
	//https://tomverbeure.github.io/video_timings_calculator
	
	// |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
    // |                   |    640x480     |     800x600     |    1280x720     |   1920x1080    |
    // |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
    // |             SCALE |       2        |        3        |        3        |       5        |
    // |           BLANK_X |      64        |       16        |       256       |      320       |
    // |           BLANK_Y |      48        |       12        |        72       |       60       |
    // |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
    
    `define SCALE			5
    `define BLANK_X 		320 // starts 1 pixel screen after, 'cause the start reaction time of the state machine
    `define BLANK_Y			60 // theres no issue with this v sync cause the blank time is enough to catch up
    
    // |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
    // |                   |    640x480     |     800x600     |    1280x720     |   1920x1080    |
    // |        DMT        |  25.175 (25.2) |        40       |     74.250      |     148.5      |
    // |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
    // | CLOCK_MULT_MASTER |      31.5      |      10.0       |     37.125      |     37.125     |
    // |  CLOCK_DIV_MASTER |       5        |        1        |       5         |       5        |
    // |      CLOCK_DIV_5X |      5.0       |       5.0       |      2.0        |      1.0       |
    // |      CLOCK_DIV_1X |       25       |       25        |       10        |       5        |
    // |   CLOCK_IN_PERIOD |                       100 MHz = 10.0 ns                             |
    // |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||														   
    
    // |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||	
    // |                   |    640x480     |     800x600     |    1280x720     |   1920x1080    |  1920x1080@30   |
    // |      CEA-861      |  25.175 (25.2) |        40       |     74.250      |     148.5      |      74.25      |
    // |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
    // | CLOCK_MULT_MASTER |       x        |      50.0       |     61.875      |     61.875     |     61.875      |
    // |  CLOCK_DIV_MASTER |       x        |        1        |       1         |       1        |        1        |
    // |      CLOCK_DIV_5X |       x        |       3.0       |      2.0        |      1.0       |       2.0       |
    // |      CLOCK_DIV_1X |       x        |       15        |       10        |       5        |        10       |
    // |   CLOCK_IN_PERIOD |                               12MHz = 83.333 ns                                       |
    // |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
    
    // clk_1x = (CLOCK_IN * MULT_MASTER / DIV_MASTER) / DIV_1X
    // clk_5x = (CLOCK_IN * MULT_MASTER / DIV_MASTER) / DIV_5X
    
	`define CLOCK_MULT_MASTER	61.875	// master clock multiplier (2.000-64.000) // 600MHz IN is the min in for this speed class, (2.000-64.000)
	`define CLOCK_DIV_MASTER	1		// master clock divider (1-106)
	`define CLOCK_DIV_5X		1.0		// 5x clock divider (1.000-128.000)
	`define CLOCK_DIV_1X		5		// 1x clock divider (1-128)
	`define CLOCK_IN_PERIOD		83.333	// period of i_clk in ns (100 MHz = 10.0 ns)
	
    // ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||	
	// |                |    640x480     |     800x600     |    1280x720     |   1920x1080    |  1920x1080@30   |
	// ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
	// |          H_RES |      640       |       800       |      1280       |      1920      |       1920      |
	// |          V_RES |      480       |       600       |       720       |      1080      |       1080      |
	// |      TIME_H_FP |       16       |        40       |       110       |       88       |        88       |
	// |    TIME_H_SYNC |       96       |       128       |        40       |       44       |        44       |
	// |      TIME_H_BP |       48       |        88       |       220       |      148       |        148      |
	// |      TIME_V_FP |       10       |        1        |        5        |       4        |        4        |
	// |    TIME_V_SYNC |       2        |        4        |        5        |       4        |        5        |
	// |      TIME_V_BP |       33       |        23       |       20        |       36       |        36       |
	// |     TIME_H_POL |       0        |        1        |        1        |       1        |        1        |
	// |     TIME_V_POL |       0        |        1        |        1        |       1        |        1        |
	// ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
	
	`define H_RES		1920	// horizontal resolution (pixels)        
	`define V_RES		1080	// vertical resolution (lines)        
	`define TIME_H_FP	88		// horizontal front porch
	`define TIME_H_SYNC	44		// horizontal sync
	`define TIME_H_BP	148		// horizontal back porch
	`define TIME_V_FP	4		// vertical front porch
	`define TIME_V_SYNC	4		// vertical sync
	`define TIME_V_BP	36		// vertical back porch
	`define TIME_H_POL	1		// horizontal sync polarity (0:neg, 1:pos)
	`define TIME_V_POL	1		// vertical sync polarity (0:neg, 1:pos)
	
`endif

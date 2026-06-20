`timescale 1ns / 1ps
`default_nettype none

// Project F: Display Timings
// (C)2019 Will Green, Open Source Hardware released under the MIT License
// Learn more at https://projectf.io

module display_timings #(                                                           // 640x480  800x600 1280x720 1920x1080 1920x1080@30
    H_RES=0,                        // horizontal resolution (pixels)               //     640      800     1280      1920         1920        
    V_RES=0,                        // vertical resolution (lines)                  //     480      600      720      1080         1080        
    H_FP=0,                         // horizontal front porch                       //      16       40      110        88           88
    H_SYNC=0,                       // horizontal sync                              //      96      128       40        44           44
    H_BP=0,                         // horizontal back porch                        //      48       88      220       148          148
    V_FP=0,                         // vertical front porch                         //      10        1        5         4            4
    V_SYNC=0,                       // vertical sync                                //       2        4        5         5            5
    V_BP=0,                         // vertical back porch                          //      33       23       20        36           36
    H_POL=0,                        // horizontal sync polarity (0:neg, 1:pos)      //       0        1        1         1            1
    V_POL=0                         // vertical sync polarity (0:neg, 1:pos)        //       0        1        1         1            1
    )
    (
    input  wire i_clk,          	// pixel clock
    input  wire i_rst,              // reset: restarts frame (active high)
    output wire o_hs,               // horizontal sync
    output wire o_vs,               // vertical sync
    output wire o_de,               // display enable: high during active video
    output wire o_frame,            // high for one tick at the start of each frame
    output reg signed [15:0] o_sx,  // horizontal beam position (including blanking)
    output reg signed [15:0] o_sy   // vertical beam position (including blanking)
    );
    
    initial begin
    	o_sx <= 0;
    	o_sy <= 0;
    end

    // Horizontal: sync, active, and pixels
    localparam signed H_STA  = 0 - H_FP - H_SYNC - H_BP;    // horizontal start
    localparam signed HS_STA = H_STA + H_FP;                // sync start
    localparam signed HS_END = HS_STA + H_SYNC;             // sync end
    localparam signed HA_STA = 0;                           // active start
    localparam signed HA_END = H_RES - 1;                   // active end

    // Vertical: sync, active, and pixels
    localparam signed V_STA  = 0 - V_FP - V_SYNC - V_BP;    // vertical start
    localparam signed VS_STA = V_STA + V_FP;                // sync start
    localparam signed VS_END = VS_STA + V_SYNC;             // sync end
    localparam signed VA_STA = 0;                           // active start
    localparam signed VA_END = V_RES - 1;                   // active end

    // generate sync signals with correct polarity
    assign o_hs = H_POL ? (o_sx > HS_STA && o_sx <= HS_END)
        : ~(o_sx > HS_STA && o_sx <= HS_END);
    assign o_vs = V_POL ? (o_sy > VS_STA && o_sy <= VS_END)
        : ~(o_sy > VS_STA && o_sy <= VS_END);

    // display enable: high during active period
    assign o_de = (o_sx >= 0 && o_sy >= 0);

    // o_frame: high for one tick at the start of each frame
    assign o_frame = (o_sy == V_STA && o_sx == H_STA);

    always @ (posedge i_clk)
    begin
        if (i_rst)  // reset to start of frame
        begin
            o_sx <= H_STA;
            o_sy <= V_STA;
        end
        else
        begin
            if (o_sx == HA_END)  // end of line
            begin
                o_sx <= H_STA;
                if (o_sy == VA_END)  // end of frame
                    o_sy <= V_STA;
                else
                    o_sy <= o_sy + 16'sh1;
            end
            else
                o_sx <= o_sx + 16'sh1;
        end
    end
endmodule

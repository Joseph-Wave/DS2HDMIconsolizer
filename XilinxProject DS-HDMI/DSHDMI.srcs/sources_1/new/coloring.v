`timescale 1ns / 1ps
`include "consts.v"

module coloring (
	input wire i_clk,
	input wire i_menu, 					// TODO: explore the posibility of a menu

	input wire signed [15:0] sx,
    input wire signed [15:0] sy,
    
	input wire signed [`BYT+1:0] ds_x,
	input wire signed [`BYT+1:0] ds_y,
	
    input wire [`DAT:0] dataIn,
   output wire [23:0] dataOut
); 

//////////////////////////////////////////////////////////////////////////////
//                        Color bit-depth scaling                           //
//////////////////////////////////////////////////////////////////////////////

function [7:0] color_map (input [5:0] color); // output_8bit = (input_6bit * 255) / 63;
	begin
		case (color)
			/*
			6'b000000: color_map = 8'b0000_0000;
			6'b000010: color_map = 8'b0000_1000;
			6'b000100: color_map = 8'b0001_0000;
			6'b000110: color_map = 8'b0001_1001;
			6'b001000: color_map = 8'b0010_0001;
			6'b001010: color_map = 8'b0010_1001;
			6'b001100: color_map = 8'b0011_0001;
			6'b001110: color_map = 8'b0011_1010;
			
			6'b010000: color_map = 8'b0100_0010;
			6'b010010: color_map = 8'b0100_1010;
			6'b010100: color_map = 8'b0101_0010;
			6'b010110: color_map = 8'b0101_1010;
			6'b011000: color_map = 8'b0110_0011;
			6'b011010: color_map = 8'b0110_1011;
			6'b011100: color_map = 8'b0111_0011;
			6'b011110: color_map = 8'b0111_1011;
			
			6'b100000: color_map = 8'b1000_0100;
			6'b100010: color_map = 8'b1000_1100;
			6'b100100: color_map = 8'b1001_0100;
			6'b100110: color_map = 8'b1001_1100;
			6'b101000: color_map = 8'b1010_0101;
			6'b101010: color_map = 8'b1010_1101;
			6'b101100: color_map = 8'b1011_0101;
			6'b101110: color_map = 8'b1011_1101;
			
			6'b110000: color_map = 8'b1100_0101;
			6'b110010: color_map = 8'b1100_1110;
			6'b110100: color_map = 8'b1101_0110;
			6'b110110: color_map = 8'b1101_1110;
			6'b111000: color_map = 8'b1110_0110;
			6'b111010: color_map = 8'b1110_1111;
			6'b111100: color_map = 8'b1111_0111;
			6'b111110: color_map = 8'b1111_1111;
	        
	        default:  color_map = 8'b0000_0000; // 0 bit = HIGH -> Black 
			*/	        
	    
	        6'd0:  color_map = 8'd0;
            6'd1:  color_map = 8'd4;
            6'd2:  color_map = 8'd8;
            6'd3:  color_map = 8'd12;
            6'd4:  color_map = 8'd16;
            6'd5:  color_map = 8'd20;
            6'd6:  color_map = 8'd24;
            6'd7:  color_map = 8'd28;
            6'd8:  color_map = 8'd32;
            6'd9:  color_map = 8'd36;
            6'd10: color_map = 8'd40;
            6'd11: color_map = 8'd44;
            6'd12: color_map = 8'd48;
            6'd13: color_map = 8'd52;
            6'd14: color_map = 8'd56;
            6'd15: color_map = 8'd60;
            6'd16: color_map = 8'd64;
            6'd17: color_map = 8'd68;
            6'd18: color_map = 8'd72;
            6'd19: color_map = 8'd76;
            6'd20: color_map = 8'd80;
            6'd21: color_map = 8'd85;
            6'd22: color_map = 8'd89;
            6'd23: color_map = 8'd93;
            6'd24: color_map = 8'd97;
            6'd25: color_map = 8'd101;
            6'd26: color_map = 8'd105;
            6'd27: color_map = 8'd109;
            6'd28: color_map = 8'd113;
            6'd29: color_map = 8'd117;
            6'd30: color_map = 8'd121;
            6'd31: color_map = 8'd125;
            6'd32: color_map = 8'd129;
            6'd33: color_map = 8'd133;
            6'd34: color_map = 8'd137;
            6'd35: color_map = 8'd141;
            6'd36: color_map = 8'd145;
            6'd37: color_map = 8'd149;
            6'd38: color_map = 8'd153;
            6'd39: color_map = 8'd157;
            6'd40: color_map = 8'd161;
            6'd41: color_map = 8'd165;
            6'd42: color_map = 8'd169;
            6'd43: color_map = 8'd173;
            6'd44: color_map = 8'd177;
            6'd45: color_map = 8'd181;
            6'd46: color_map = 8'd185;
            6'd47: color_map = 8'd189;
            6'd48: color_map = 8'd193;
            6'd49: color_map = 8'd197;
            6'd50: color_map = 8'd201;
            6'd51: color_map = 8'd205;
            6'd52: color_map = 8'd209;
            6'd53: color_map = 8'd213;
            6'd54: color_map = 8'd217;
            6'd55: color_map = 8'd221;
            6'd56: color_map = 8'd225;
            6'd57: color_map = 8'd229;
            6'd58: color_map = 8'd233;
            6'd59: color_map = 8'd237;
            6'd60: color_map = 8'd241;
            6'd61: color_map = 8'd245;
            6'd62: color_map = 8'd249;
            6'd63: color_map = 8'd255;
            default:  color_map = 8'b0000_0000;
		endcase
	end
endfunction


function lazy_mod5 (input signed [15:0] num); // output_8bit = (input_6bit * 255) / 63;
	begin
		lazy_mod5 = 
			(num == 12'd0)  || (num == 12'd5)   || (num == 12'd10)  || (num == 12'd15)  || (num == 12'd20)  || (num == 12'd25)  ||
            (num == 12'd30) || (num == 12'd35)  || (num == 12'd40)  || (num == 12'd45)  || (num == 12'd50)  || (num == 12'd55)  ||
            (num == 12'd60) || (num == 12'd65)  || (num == 12'd70)  || (num == 12'd75)  || (num == 12'd80)  || (num == 12'd85)  ||
            (num == 12'd90) || (num == 12'd95)  || (num == 12'd100) || (num == 12'd105) || (num == 12'd110) || (num == 12'd115) ||
            (num == 12'd120)|| (num == 12'd125) || (num == 12'd130) || (num == 12'd135) || (num == 12'd140) || (num == 12'd145) ||
            (num == 12'd150)|| (num == 12'd155) || (num == 12'd160) || (num == 12'd165) || (num == 12'd170) || (num == 12'd175) ||
            (num == 12'd180)|| (num == 12'd185) || (num == 12'd190) || (num == 12'd195) || (num == 12'd200) || (num == 12'd205) ||
            (num == 12'd210)|| (num == 12'd215) || (num == 12'd220) || (num == 12'd225) || (num == 12'd230) || (num == 12'd235) ||
            (num == 12'd240)|| (num == 12'd245) || (num == 12'd250) || (num == 12'd255) || (num == 12'd260) || (num == 12'd265) ||
            (num == 12'd270)|| (num == 12'd275) || (num == 12'd280) || (num == 12'd285) || (num == 12'd290) || (num == 12'd295) ||
            (num == 12'd300)|| (num == 12'd305) || (num == 12'd310) || (num == 12'd315) || (num == 12'd320) || (num == 12'd325) ||
            (num == 12'd330)|| (num == 12'd335) || (num == 12'd340) || (num == 12'd345) || (num == 12'd350) || (num == 12'd355) ||
            (num == 12'd360)|| (num == 12'd365) || (num == 12'd370) || (num == 12'd375) || (num == 12'd380) || (num == 12'd385) ||
            (num == 12'd390)|| (num == 12'd395) || (num == 12'd400)|| (num == 12'd405) || (num == 12'd410)|| (num == 12'd415) ||
            (num == 12'd420)|| (num == 12'd425)|| (num == 12'd430)|| (num == 12'd435)|| (num == 12'd440)|| (num == 12'd445) ||
            (num == 12'd450)|| (num == 12'd455)|| (num == 12'd460)|| (num == 12'd465)|| (num == 12'd470)|| (num == 12'd475) ||
            (num == 12'd480)|| (num == 12'd485)|| (num == 12'd490)|| (num == 12'd495)|| (num == 12'd500)|| (num == 12'd505) ||
            (num == 12'd510)|| (num == 12'd515)|| (num == 12'd520)|| (num == 12'd525)|| (num == 12'd530)|| (num == 12'd535) ||
            (num == 12'd540)|| (num == 12'd545)|| (num == 12'd550)|| (num == 12'd555)|| (num == 12'd560)|| (num == 12'd565) ||
            (num == 12'd570)|| (num == 12'd575)|| (num == 12'd580)|| (num == 12'd585)|| (num == 12'd590)|| (num == 12'd595) ||
            (num == 12'd600)|| (num == 12'd605)|| (num == 12'd610)|| (num == 12'd615)|| (num == 12'd620)|| (num == 12'd625) ||
            (num == 12'd630)|| (num == 12'd635)|| (num == 12'd640)|| (num == 12'd645)|| (num == 12'd650)|| (num == 12'd655) ||
            (num == 12'd660)|| (num == 12'd665)|| (num == 12'd670)|| (num == 12'd675)|| (num == 12'd680)|| (num == 12'd685) ||
            (num == 12'd690)|| (num == 12'd695)|| (num == 12'd700)|| (num == 12'd705)|| (num == 12'd710)|| (num == 12'd715) ||
            (num == 12'd720)|| (num == 12'd725)|| (num == 12'd730)|| (num == 12'd735)|| (num == 12'd740)|| (num == 12'd745) ||
            (num == 12'd750)|| (num == 12'd755)|| (num == 12'd760)|| (num == 12'd765)|| (num == 12'd770)|| (num == 12'd775) ||
            (num == 12'd780)|| (num == 12'd785)|| (num == 12'd790)|| (num == 12'd795)|| (num == 12'd800)|| (num == 12'd805) ||
            (num == 12'd810)|| (num == 12'd815)|| (num == 12'd820)|| (num == 12'd825)|| (num == 12'd830)|| (num == 12'd835) ||
            (num == 12'd840)|| (num == 12'd845)|| (num == 12'd850)|| (num == 12'd855)|| (num == 12'd860)|| (num == 12'd865) ||
            (num == 12'd870)|| (num == 12'd875)|| (num == 12'd880)|| (num == 12'd885)|| (num == 12'd890)|| (num == 12'd895) ||
            (num == 12'd900)|| (num == 12'd905)|| (num == 12'd910)|| (num == 12'd915)|| (num == 12'd920)|| (num == 12'd925) ||
            (num == 12'd930)|| (num == 12'd935)|| (num == 12'd940)|| (num == 12'd945)|| (num == 12'd950)|| (num == 12'd955) ||
            (num == 12'd960)|| (num == 12'd965)|| (num == 12'd970)|| (num == 12'd975)|| (num == 12'd980)|| (num == 12'd985) ||
            (num == 12'd990)|| (num == 12'd995)|| (num == 12'd1000)|| (num == 12'd1005)|| (num == 12'd1010)|| (num == 12'd1015) ||
            (num == 12'd1020)|| (num == 12'd1025)|| (num == 12'd1030)|| (num == 12'd1035)|| (num == 12'd1040)|| (num == 12'd1045) ||
            (num == 12'd1050)|| (num == 12'd1055)|| (num == 12'd1060)|| (num == 12'd1065)|| (num == 12'd1070)|| (num == 12'd1075) ||
            (num == 12'd1080)|| (num == 12'd1085)|| (num == 12'd1090)|| (num == 12'd1095)|| (num == 12'd1100)|| (num == 12'd1105) ||
            (num == 12'd1110)|| (num == 12'd1115)|| (num == 12'd1120)|| (num == 12'd1125)|| (num == 12'd1130)|| (num == 12'd1135) ||
            (num == 12'd1140)|| (num == 12'd1145)|| (num == 12'd1150)|| (num == 12'd1155)|| (num == 12'd1160)|| (num == 12'd1165) ||
            (num == 12'd1170)|| (num == 12'd1175)|| (num == 12'd1180)|| (num == 12'd1185)|| (num == 12'd1190)|| (num == 12'd1195) ||
            (num == 12'd1200)|| (num == 12'd1205)|| (num == 12'd1210)|| (num == 12'd1215)|| (num == 12'd1220)|| (num == 12'd1225) ||
            (num == 12'd1230)|| (num == 12'd1235)|| (num == 12'd1240)|| (num == 12'd1245)|| (num == 12'd1250)|| (num == 12'd1255) ||
            (num == 12'd1260)|| (num == 12'd1265)|| (num == 12'd1270)|| (num == 12'd1275)|| (num == 12'd1280)|| (num == 12'd1285) ||
            (num == 12'd1290)|| (num == 12'd1295)|| (num == 12'd1300)|| (num == 12'd1305)|| (num == 12'd1310)|| (num == 12'd1315) ||
            (num == 12'd1320)|| (num == 12'd1325)|| (num == 12'd1330)|| (num == 12'd1335)|| (num == 12'd1340)|| (num == 12'd1345) ||
            (num == 12'd1350)|| (num == 12'd1355)|| (num == 12'd1360)|| (num == 12'd1365)|| (num == 12'd1370)|| (num == 12'd1375) ||
            (num == 12'd1380)|| (num == 12'd1385)|| (num == 12'd1390)|| (num == 12'd1395)|| (num == 12'd1400)|| (num == 12'd1405) ||
            (num == 12'd1410)|| (num == 12'd1415)|| (num == 12'd1420)|| (num == 12'd1425)|| (num == 12'd1430)|| (num == 12'd1435) ||
            (num == 12'd1440)|| (num == 12'd1445)|| (num == 12'd1450)|| (num == 12'd1455)|| (num == 12'd1460)|| (num == 12'd1465) ||
            (num == 12'd1470)|| (num == 12'd1475)|| (num == 12'd1480)|| (num == 12'd1485)|| (num == 12'd1490)|| (num == 12'd1495) ||
            (num == 12'd1500)|| (num == 12'd1505)|| (num == 12'd1510)|| (num == 12'd1515)|| (num == 12'd1520)|| (num == 12'd1525) ||
            (num == 12'd1530)|| (num == 12'd1535)|| (num == 12'd1540)|| (num == 12'd1545)|| (num == 12'd1550)|| (num == 12'd1555) ||
            (num == 12'd1560)|| (num == 12'd1565)|| (num == 12'd1570)|| (num == 12'd1575)|| (num == 12'd1580)|| (num == 12'd1585) ||
            (num == 12'd1590)|| (num == 12'd1595)|| (num == 12'd1600)|| (num == 12'd1605)|| (num == 12'd1610)|| (num == 12'd1615) ||
            (num == 12'd1620)|| (num == 12'd1625)|| (num == 12'd1630)|| (num == 12'd1635)|| (num == 12'd1640)|| (num == 12'd1645) ||
            (num == 12'd1650)|| (num == 12'd1655)|| (num == 12'd1660)|| (num == 12'd1665)|| (num == 12'd1670)|| (num == 12'd1675) ||
            (num == 12'd1680)|| (num == 12'd1685)|| (num == 12'd1690)|| (num == 12'd1695)|| (num == 12'd1700)|| (num == 12'd1705) ||
            (num == 12'd1710)|| (num == 12'd1715)|| (num == 12'd1720)|| (num == 12'd1725)|| (num == 12'd1730)|| (num == 12'd1735) ||
            (num == 12'd1740)|| (num == 12'd1745)|| (num == 12'd1750)|| (num == 12'd1755)|| (num == 12'd1760)|| (num == 12'd1765) ||
            (num == 12'd1770)|| (num == 12'd1775)|| (num == 12'd1780)|| (num == 12'd1785)|| (num == 12'd1790)|| (num == 12'd1795) ||
            (num == 12'd1800)|| (num == 12'd1805)|| (num == 12'd1810)|| (num == 12'd1815)|| (num == 12'd1820)|| (num == 12'd1825) ||
            (num == 12'd1830)|| (num == 12'd1835)|| (num == 12'd1840)|| (num == 12'd1845)|| (num == 12'd1850)|| (num == 12'd1855) ||
            (num == 12'd1860)|| (num == 12'd1865)|| (num == 12'd1870)|| (num == 12'd1875)|| (num == 12'd1880)|| (num == 12'd1885) ||
            (num == 12'd1890)|| (num == 12'd1895)|| (num == 12'd1900)|| (num == 12'd1905)|| (num == 12'd1910)|| (num == 12'd1915) ||
            (num == 12'd1920);
	end
endfunction

	wire Scanlines = i_menu && (lazy_mod5(sx-1) || lazy_mod5(sy)); // TODO: send to a more definitive file
				
	wire print = 
		(sx >= `BLANK_X + 2) && (sy >= `BLANK_Y) && 
		(sx <= `BLANK_X + `SCALE * `DS_H_RES + 1) && (sy <= `BLANK_Y + `SCALE * `DS_V_RES - 1);
		
	wire [`BYT:0] blue  = (!print || Scanlines) ? 
							(Scanlines && print) ? 
								color_map(dataIn[5:0]) >> 1 : 0 // 0 : 0 for full black lines
							: color_map(dataIn[5:0]); // color_map({dataIn[5:1], 1'b0}); // TODO: Find what alpha bit really does
	wire [`BYT:0] green  = (!print || Scanlines) ? 
							(Scanlines && print) ? 
								color_map(dataIn[11:6]) >> 1 : 0 
							: color_map(dataIn[11:6]);
	wire [`BYT:0] red   = (!print || Scanlines) ? 
							(Scanlines && print) ? 
								color_map(dataIn[17:12]) >> 1 : 0 
							: color_map(dataIn[17:12]);

	reg signed [15:0] old_sx = -3;
	reg [23:0] _dataOut; 
	
	always @(posedge i_clk) begin // this soften the timing restrictions
//		if (sx == 0) begin
//			old_sx = 0;
//			_dataOut <= {red, green, blue};
//		end else begin
			if (old_sx != sx) begin
				old_sx <= sx;
				_dataOut <= {red, green, blue};
			end
//		end
	end

	assign dataOut = _dataOut;

endmodule

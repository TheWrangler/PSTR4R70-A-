`timescale 1ns / 1ps

module pwr_rst
#(
	parameter [31 : 0] MAIN_CLOCK_PERIOD = 7,
	parameter [31 : 0] PWR_RST_DELAY = 100000000,
	parameter [0:0] PWR_RST_ACTIVE_LEVEL = 0
) 
(
	input clk,
	output reg rst
);
	
	localparam [31 : 0] DELAY_CLCOK_NUM = PWR_RST_DELAY / MAIN_CLOCK_PERIOD;
	
	reg [31 : 0] delay_clock_count = 0;
	
	always @ (posedge clk) begin
		if(delay_clock_count < DELAY_CLCOK_NUM) begin
			delay_clock_count <= delay_clock_count + 1;
			rst <= PWR_RST_ACTIVE_LEVEL;
		end
		else rst <= ~PWR_RST_ACTIVE_LEVEL;
	end
		
endmodule
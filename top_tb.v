`timescale 1ns / 1ps

module top_tb();

reg clk;
reg master_clk;
reg master_cs;
reg master_mosi;
wire master_miso;

wire [5:0] adf4159_clk;
wire [5:0] adf4159_data;
wire [5:0] adf4159_le;
reg [5:0] pll_lock;

reg freq_trig1;
reg freq_trig2;

wire [7:0] fs;
wire [7:0] vctrl;

top top_inst
(
	.clk(clk),

	//master spi
	.spi_clk(master_clk),
	.spi_cs(master_cs),
	.spi_mosi(master_mosi),
	.spi_miso(master_miso),

	//adf4159 spi
	.adf4159_clk(adf4159_clk),
	.adf4159_data(adf4159_data),
	.adf4159_le(adf4159_le),
	//adf4159 lock state
	.pll_lock(pll_lock),

	//trig
	.freq_trig1(freq_trig1),
	.freq_trig2(freq_trig2),

	//lo
	.fs(fs),
	.vctrl(vctrl)
);

initial begin                                               
   master_cs <= 1'b1;   
	freq_trig1	<= 1'b0;
	freq_trig2	<= 1'b0;
	clk <= 1'b0;
end 

always begin
	#(30) clk <= ~ clk;
end
                                                
endmodule
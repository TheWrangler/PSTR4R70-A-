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
wire [5:0] pll_lock;

reg freq_trig1;
reg freq_trig2;

reg [50:0] spi_data = {5'b00001,1'b1,4'b0100,25'h1123456,12'hccc,4'b0010};
reg [5:0] spi_data_bit_count;
reg [31:0] spi_start_delay;
reg spi_start;

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
	master_clk <= 1'b1; 
	
	freq_trig1	<= 1'b0;
	freq_trig2	<= 1'b0;
	clk <= 1'b0;
	
	spi_start_delay <= 0;
	spi_data_bit_count <= 0;
	spi_start<= 0;
end 

always begin
	#(30) clk <= ~ clk;
end

always @ (posedge clk)begin
	spi_start_delay <= spi_start_delay + 1;
	if(spi_start_delay == 200000000) begin
		spi_start_delay <= 0;
		spi_start <= 1;
		master_cs <= 0;
	end	
end

always begin
	if(spi_start) begin
		#(500) master_clk <= ~master_clk;	
	end
	else master_clk <= 1;
end

always @ (negedge master_clk) begin
	if(spi_data_bit_count < 50) begin
		master_mosi <= spi_data[0];
		spi_data = {1'b0,spi_data[50:1]};	
		spi_data_bit_count <= spi_data_bit_count + 1;
	end
end
                                                
endmodule
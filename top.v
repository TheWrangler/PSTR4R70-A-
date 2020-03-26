 `timescale 1ns / 1ps
 
 module top
 (
	input clk,
	
	//master spi
	input spi_clk,
	input spi_cs,
	input spi_mosi,
	output spi_miso,
	
	//adf4159 spi
	output [5:0] adf4159_clk,
	output [5:0] adf4159_data,
	output [5:0] adf4159_le,
	//adf4159 lock state
	output [5:0] pll_lock,
	input [5:0] pll_lock_i,
	
	//trig
	input freq_trig1,
	input freq_trig2,
	
	//lo
	output [7:0] fs,
	output [7:0] vctrl
 );
	
	wire rst;
	pwr_rst #(
		.MAIN_CLOCK_PERIOD(30),
		.PWR_RST_DELAY(1000000),
		.PWR_RST_ACTIVE_LEVEL(0)
	) 
	pwr_rst_inst(
		.clk(clk),
		.rst(rst)
	);
	
	wire [44:0] master_data;
	wire master_data_ready;
	wire master_ack;
	
	master_spi #(
		.MASTER_CMD_BIT_NUM(45),
		.MASTER_REPLY_BIT_NUM(6),
		.MASTER_CMD_SAMPLE_LEVEL(1)
	)
	master_spi_inst(
		.clk(clk),
		.rst(rst),
		
		.pll_lock(pll_lock),
		
		.spi_clk(spi_clk),
		.spi_cs(spi_cs),
		.spi_mosi(spi_mosi),
		.spi_miso(spi_miso),
		
		.data(master_data),
		.dready(master_data_ready),
		.ack(master_ack)
	);
	
	wire [5:0] adf4159_load;
	wire [5:0] adf4159_busy;
	wire [11:0] adf4159_int[5:0];
	wire [24:0] adf4159_frac[5:0];
	
	assign adf4159_int[5] = 44;
	assign adf4159_frac[5] = 31407723;
	assign adf4159_int[4] = 42;
	assign adf4159_frac[4] = 26843869;
	assign adf4159_int[3] = 188;
	assign adf4159_frac[3] = 3519526;
	assign adf4159_int[2] = 188;
	assign adf4159_frac[2] = 3519526;
	assign adf4159_int[1] = 98;
	assign adf4159_frac[1] = 9702969;
	assign adf4159_int[0] = 98;
	assign adf4159_frac[0] = 9702969;
	
	generate 
		genvar i;
		for(i=0;i<6;i=i+1) begin : adf4159_module_instanced
			adf4159 adf4159_inst
			(
				.clk(clk),
				.rst(rst),

				.load(adf4159_load[i]),
				.ints(adf4159_int[i]),
				.fracs(adf4159_frac[i]),
				.busy(adf4159_busy[i]),

				.spi_clk(adf4159_clk[i]),
				.spi_data(adf4159_data[i]),
				.spi_le(adf4159_le[i])
			);
		end
	endgenerate
	
	
	reg master_ack_reg = 1'b0;
	reg load_trig = 1'b0;
	reg [11:0] adf4159_int_reg[5:0];
	reg [24:0] adf4159_frac_reg[5:0];
	reg [3:0] adf4159_lo[5:0];
	reg [3:0] adf4159_no = 4'b000;
	reg [5:0] fsm_state = 6'd0;
	
	always @ (posedge clk) begin
		if(!rst) begin
			master_ack_reg <= 1'b0;
//			load_trig <= 1'b0;
//			adf4159_no <= 0;
			adf4159_no <= 5;
			
			fsm_state <= 6'd0;
		end
		else begin
			case(fsm_state)
				0 : begin
					if(master_data_ready) begin
						adf4159_no <= master_data[3:0];
						fsm_state <= 6'd1;
					end
				end
				1 : begin
					case(adf4159_no) 
						1 : begin
							adf4159_int_reg[0] <= master_data[15:4];
							adf4159_frac_reg[0] <= master_data[40:16];
							adf4159_lo[0] <= master_data[44:41];
						end
						2 : begin
							adf4159_int_reg[1] <= master_data[15:4];
							adf4159_frac_reg[1] <= master_data[40:16];
							adf4159_lo[1] <= master_data[44:41];
						end
						3 : begin
							adf4159_int_reg[2] <= master_data[15:4];
							adf4159_frac_reg[2] <= master_data[40:16];
							adf4159_lo[2] <= master_data[44:41];
						end
						4 : begin
							adf4159_int_reg[3] <= master_data[15:4];
							adf4159_frac_reg[3] <= master_data[40:16];
							adf4159_lo[3] <= master_data[44:41];
						end
						5 : begin
							adf4159_int_reg[4] <= master_data[15:4];
							adf4159_frac_reg[4] <= master_data[40:16];
							adf4159_lo[4] <= master_data[44:41];
						end
						6 : begin
							adf4159_int_reg[5] <= master_data[15:4];
							adf4159_frac_reg[5] <= master_data[40:16];
							adf4159_lo[5] <= master_data[44:41];
						end
					endcase
					master_ack_reg <= 1'b1;
//					load_trig = 1'b1;
					fsm_state <= 6'd2;
				end
				2 : begin
//					load_trig = 1'b0;
					if(!master_data_ready) begin
						master_ack_reg <= 1'b0;
						fsm_state <= 6'd0;
					end
				end
			endcase
		end
	end
	
	reg [1:0] freq_trig1_dege = 2'b11;
	reg [1:0] freq_trig2_dege = 2'b11;
	always @ (posedge clk) begin
		freq_trig1_dege <= {freq_trig1_dege[0],freq_trig1};
		freq_trig2_dege <= {freq_trig2_dege[0],freq_trig2};
	end
	
	//PPL1&2
	reg [5:0] adf4159_load_reg = 6'b000000;
	reg [5:0] fsm_load1_state = 6'd0;
	always @ (posedge clk) begin
		if(!rst) begin
			adf4159_load_reg[1:0] <= 2'b00;
			fsm_load1_state <= 6'd0;
		end
		else begin
			case(fsm_load1_state)
				0 : begin
					if(load_trig/*freq_trig1_dege == 2'b01*/) begin
						fsm_load1_state <= 6'd1;
					end
				end
				1 : begin
					if((adf4159_busy & 6'b000011) == 6'b000000) begin
						adf4159_load_reg[1:0] <= 2'b11;
						fsm_load1_state <= 6'd2;
					end
				end
				2 : begin
					if((adf4159_busy & 6'b000011) == 6'b000011) begin
						adf4159_load_reg[1:0] <= 2'b00;
						fsm_load1_state <= 6'd3;
					end
				end
				3 : begin
					fsm_load1_state <= 6'd0;
				end
			endcase
		end
	end
	
	//PLL3&4
	reg [5:0] fsm_load2_state = 6'd0;
	always @ (posedge clk) begin
		if(!rst) begin
			adf4159_load_reg[3:2] <= 2'b00;
			fsm_load2_state <= 6'd0;
		end
		else begin
			case(fsm_load2_state)
				0 : begin
					if(load_trig/*freq_trig2_dege == 2'b01*/) begin
						fsm_load2_state <= 6'd1;
					end
				end
				1 : begin
					if((adf4159_busy & 6'b001100) == 6'b000000) begin
						adf4159_load_reg[3:2] <= 2'b11;
						fsm_load2_state <= 6'd2;
					end
				end
				2 : begin
					if((adf4159_busy & 6'b001100) == 6'b001100) begin
						adf4159_load_reg[3:2] <= 2'b00;
						fsm_load2_state <= 6'd3;
					end
				end
				3 : begin
					fsm_load2_state <= 6'd0;
				end
			endcase
		end
	end
	
	reg [31:0] delay_count = 0;
	reg delay_enable = 1'b1;
	always @ (posedge clk) begin
		if(!rst) begin
			load_trig <= 1'b0;
			delay_count <= 32'd0;
			delay_enable = 1'b1;
		end
		else if(delay_enable) begin
			delay_count <= delay_count + 1;
			if(delay_count > 1002) begin
				delay_enable <= 1'b0;
				load_trig <= 1'b0;
			end
			else if(delay_count > 1000) begin
				load_trig <= 1'b1;
			end
		end
	end
		
	//PLL5&6
	reg [5:0] fsm_load3_state = 6'd0;
	reg [1:0] ad4159_no_mask = 2'b00;
	always @ (posedge clk) begin
		if(!rst) begin
			adf4159_load_reg[5:4] <= 2'b00;
			ad4159_no_mask <= 2'b00;
			fsm_load3_state <= 6'd0;
		end
		else begin
			case(fsm_load3_state)
				0 : begin
					if(load_trig == 1'b1) begin
						if(adf4159_no == 5) begin
							ad4159_no_mask <= 2'b01;
							fsm_load3_state <= 6'd1;
						end
						else if(adf4159_no == 6) begin
							ad4159_no_mask <= 2'b10;
							fsm_load3_state <= 6'd1;
						end
					end
				end
				1 : begin
					if((adf4159_busy[5:4] & ad4159_no_mask) != ad4159_no_mask) begin
						adf4159_load_reg[5:4] <= 2'b11/*adf4159_load_reg[5:4] | ad4159_no_mask*/;
						fsm_load3_state <= 6'd2;
					end
				end
				2 : begin
					if((adf4159_busy[5:4] & ad4159_no_mask) == ad4159_no_mask) begin
						adf4159_load_reg[5:4] <= 2'b00/*adf4159_load_reg[5:4] & (~ad4159_no_mask)*/;
						fsm_load3_state <= 6'd3;
					end
				end
				3 : begin
					fsm_load3_state <= 6'd0;
				end
			endcase
		end
	end
	
	assign master_ack = master_ack_reg;
	assign adf4159_load = adf4159_load_reg;
	
//	generate 
//		genvar j;
//		for(j=0;j<6;j=j+1) begin : int_frac_assign
//			assign adf4159_int[j] = adf4159_int_reg[j];
//			assign adf4159_frac[j] = adf4159_frac_reg[j];
//		end
//	endgenerate

	assign fs = 8'b00000000;
	//assign vctrl = 8'b1010_0101;
	assign vctrl = 8'b0101_1010;
	
	assign pll_lock = ~pll_lock_i;
 
 endmodule
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
	
	wire [50:0] master_data;
	wire master_data_ready;
	wire master_ack;
	
	master_spi #(
		.MASTER_CMD_BIT_NUM(51),
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
	wire [71:0] adf4159_int;
	wire [149:0] adf4159_frac;
	wire [5:0] adf4159_ref_doubled;//0-disable;1-enabled
	wire [29:0] adf4159_r_counter;
	wire [5:0] adf4159_prescaler;//0-4/5;1-8/9
	

	assign adf4159_prescaler[5] = 0;
	assign adf4159_prescaler[4] = 0;
	assign adf4159_prescaler[3] = 0;
	assign adf4159_prescaler[2] = 0;
	assign adf4159_prescaler[1] = 0;
	assign adf4159_prescaler[0] = 0;
	
	adf4159 adf4159_inst_1
	(
		.clk(clk),
		.rst(rst),

		.load(adf4159_load[0]),
		.ints(adf4159_int[11:0]),
		.fracs(adf4159_frac[24:0]),
		.ref_doubled(adf4159_ref_doubled[0]),
		.r_counter(adf4159_r_counter[4:0]),
		.prescaler(adf4159_prescaler[0]),
		
		.busy(adf4159_busy[0]),

		.spi_clk(adf4159_clk[0]),
		.spi_data(adf4159_data[0]),
		.spi_le(adf4159_le[0])
	);

	adf4159 adf4159_inst_2
	(
		.clk(clk),
		.rst(rst),

		.load(adf4159_load[1]),
		.ints(adf4159_int[23:12]),
		.fracs(adf4159_frac[49:25]),
		.ref_doubled(adf4159_ref_doubled[1]),
		.r_counter(adf4159_r_counter[9:5]),
		.prescaler(adf4159_prescaler[1]),
		
		.busy(adf4159_busy[1]),

		.spi_clk(adf4159_clk[1]),
		.spi_data(adf4159_data[1]),
		.spi_le(adf4159_le[1])
	);
	
	adf4159 adf4159_inst_3
	(
		.clk(clk),
		.rst(rst),

		.load(adf4159_load[2]),
		.ints(adf4159_int[35:24]),
		.fracs(adf4159_frac[74:50]),
		.ref_doubled(adf4159_ref_doubled[2]),
		.r_counter(adf4159_r_counter[14:10]),
		.prescaler(adf4159_prescaler[2]),
		
		.busy(adf4159_busy[2]),

		.spi_clk(adf4159_clk[2]),
		.spi_data(adf4159_data[2]),
		.spi_le(adf4159_le[2])
	);
	
	adf4159 adf4159_inst_4
	(
		.clk(clk),
		.rst(rst),

		.load(adf4159_load[3]),
		.ints(adf4159_int[47:36]),
		.fracs(adf4159_frac[99:75]),
		.ref_doubled(adf4159_ref_doubled[3]),
		.r_counter(adf4159_r_counter[19:15]),
		.prescaler(adf4159_prescaler[3]),
		
		.busy(adf4159_busy[3]),

		.spi_clk(adf4159_clk[3]),
		.spi_data(adf4159_data[3]),
		.spi_le(adf4159_le[3])
	);
	
	adf4159 adf4159_inst_5
	(
		.clk(clk),
		.rst(rst),

		.load(adf4159_load[4]),
		.ints(adf4159_int[59:48]),
		.fracs(adf4159_frac[124:100]),
		.ref_doubled(adf4159_ref_doubled[4]),
		.r_counter(adf4159_r_counter[24:20]),
		.prescaler(adf4159_prescaler[4]),
		
		.busy(adf4159_busy[4]),

		.spi_clk(adf4159_clk[4]),
		.spi_data(adf4159_data[4]),
		.spi_le(adf4159_le[4])
	);
	
	adf4159 adf4159_inst_6
	(
		.clk(clk),
		.rst(rst),

		.load(adf4159_load[5]),
		.ints(adf4159_int[71:60]),
		.fracs(adf4159_frac[149:125]),
		.ref_doubled(adf4159_ref_doubled[5]),
		.r_counter(adf4159_r_counter[29:25]),
		.prescaler(adf4159_prescaler[5]),
		
		.busy(adf4159_busy[5]),

		.spi_clk(adf4159_clk[5]),
		.spi_data(adf4159_data[5]),
		.spi_le(adf4159_le[5])
	);
	
	
	reg master_ack_reg = 1'b0;
	reg load_trig = 1'b0;
	
	reg [71:0] adf4159_int_reg;
	reg [149:0] adf4159_frac_reg;
	reg [5:0] adf4159_ref_doubled_reg;
	reg [29:0] adf4159_r_counter_reg;
	reg [23:0] adf4159_lo;
	
	reg [3:0] adf4159_no = 4'b000;
	reg [5:0] fsm_state = 6'd0;
	
	always @ (posedge clk) begin
		if(!rst) begin
			master_ack_reg <= 1'b0;
			load_trig <= 1'b0;
			adf4159_no <= 0;
			
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
							adf4159_int_reg[11:0] <= master_data[15:4];
							adf4159_frac_reg[24:0] <= master_data[40:16];
							adf4159_lo[3:0] <= master_data[44:41];
							adf4159_ref_doubled_reg[0] <= master_data[45];
							adf4159_r_counter_reg[4:0] <= master_data[50:46];
						end
						2 : begin
							adf4159_int_reg[23:12] <= master_data[15:4];
							adf4159_frac_reg[49:25] <= master_data[40:16];
							adf4159_lo[7:4] <= master_data[44:41];
							adf4159_ref_doubled_reg[1] <= master_data[45];
							adf4159_r_counter_reg[9:5] <= master_data[50:46];
						end
						3 : begin
							adf4159_int_reg[35:24] <= master_data[15:4];
							adf4159_frac_reg[74:50] <= master_data[40:16];
							adf4159_lo[11:8] <= master_data[44:41];
							adf4159_ref_doubled_reg[2] <= master_data[45];
							adf4159_r_counter_reg[14:10] <= master_data[50:46];
						end
						4 : begin
							adf4159_int_reg[47:36] <= master_data[15:4];
							adf4159_frac_reg[99:75] <= master_data[40:16];
							adf4159_lo[15:12] <= master_data[44:41];
							adf4159_ref_doubled_reg[3] <= master_data[45];
							adf4159_r_counter_reg[19:15] <= master_data[50:46];
						end
						5 : begin
							adf4159_int_reg[59:48] <= master_data[15:4];
							adf4159_frac_reg[124:100] <= master_data[40:16];
							adf4159_lo[19:16] <= master_data[44:41];
							adf4159_ref_doubled_reg[4] <= master_data[45];
							adf4159_r_counter_reg[24:20] <= master_data[50:46];
						end
						6 : begin
							adf4159_int_reg[71:60] <= master_data[15:4];
							adf4159_frac_reg[149:125] <= master_data[40:16];
							adf4159_lo[23:20] <= master_data[44:41];
							adf4159_ref_doubled_reg[5] <= master_data[45];
							adf4159_r_counter_reg[29:25] <= master_data[50:46];
						end
					endcase
					master_ack_reg <= 1'b1;
					load_trig = 1'b1;
					fsm_state <= 6'd2;
				end
				2 : begin
					load_trig = 1'b0;
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
					if(freq_trig1_dege == 2'b01) begin
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
					if(freq_trig2_dege == 2'b01) begin
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
						adf4159_load_reg[5:4] <= (adf4159_load_reg[5:4] | ad4159_no_mask);
						fsm_load3_state <= 6'd2;
					end
				end
				2 : begin
					if((adf4159_busy[5:4] & ad4159_no_mask) == ad4159_no_mask) begin
						adf4159_load_reg[5:4] <= (adf4159_load_reg[5:4] & (~ad4159_no_mask));
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
	

	assign adf4159_int = adf4159_int_reg;
	assign adf4159_frac = adf4159_frac_reg;
	assign adf4159_ref_doubled = adf4159_ref_doubled_reg;
	assign adf4159_r_counter = adf4159_r_counter_reg;


	assign fs = 8'b00000000;
	assign vctrl = 8'b0101_1010;
	
	assign pll_lock = ~pll_lock_i;
 
 endmodule
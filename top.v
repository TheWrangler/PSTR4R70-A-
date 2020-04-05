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
	wire [6:0] master_data_num;
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
		
		.pll_lock(pll_lock_i),
		
		.spi_clk(spi_clk),
		.spi_cs(spi_cs),
		.spi_mosi(spi_mosi),
		.spi_miso(spi_miso),
		
		.data(master_data),
		.data_num(master_data_num),
		.dready(master_data_ready),
		.ack(master_ack)
	);
	
	wire [5:0] adf4159_load;
	wire [5:0] adf4159_pre_load;
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
	
	generate 
		genvar i;
		for(i=0;i<6;i=i+1) begin : adf4159_module_instanced
			adf4159 adf4159_inst
			(
				.clk(clk),
				.rst(rst),

				.load(adf4159_load[i]),
				.pre_load(adf4159_pre_load[i]),
				.ints(adf4159_int[(i+1)*12-1:i*12]),
				.fracs(adf4159_frac[(i+1)*25-1:i*25]),
				.ref_doubled(adf4159_ref_doubled[i]),
				.r_counter(adf4159_r_counter[(i+1)*5-1:i*5]),
				.prescaler(adf4159_prescaler[i]),

				.busy(adf4159_busy[i]),

				.spi_clk(adf4159_clk[i]),
				.spi_data(adf4159_data[i]),
				.spi_le(adf4159_le[i])
			);
		end
	endgenerate
	
	
	reg master_ack_reg = 1'b0;
	reg [5:0] load_trig = 6'b000000;
	
	reg [71:0] adf4159_int_reg;
	reg [149:0] adf4159_frac_reg;
	reg [5:0] adf4159_ref_doubled_reg = 5'b000000;
	reg [29:0] adf4159_r_counter_reg = {5'd1,5'd1,5'd1,5'd1,5'd1,5'd1};
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
						if(master_data_num == 51) begin
							adf4159_no <= master_data[3:0];
							fsm_state <= 6'd1;
						end
						else if(master_data_num == 45) begin
							adf4159_no <= master_data[44:41];
							fsm_state <= 6'd1;
						end
						else fsm_state <= 6'd2;
					end
				end
				1 : begin
					case(adf4159_no) 
						1 : begin
							if(master_data_num == 51) begin
								adf4159_int_reg[11:0] <= master_data[15:4];
								adf4159_frac_reg[24:0] <= master_data[40:16];
								adf4159_lo[3:0] <= master_data[44:41];
								adf4159_ref_doubled_reg[0] <= master_data[45];
								adf4159_r_counter_reg[4:0] <= master_data[50:46];
							end
							else if(master_data_num == 45) begin
								adf4159_int_reg[11:0] <= master_data[40:29];
								adf4159_frac_reg[24:0] <= master_data[28:4];
								adf4159_lo[3:0] <= master_data[3:0];
							end
							load_trig <= 6'b000001;
						end
						2 : begin
							if(master_data_num == 51) begin
								adf4159_int_reg[23:12] <= master_data[15:4];
								adf4159_frac_reg[49:25] <= master_data[40:16];
								adf4159_lo[7:4] <= master_data[44:41];
								adf4159_ref_doubled_reg[1] <= master_data[45];
								adf4159_r_counter_reg[9:5] <= master_data[50:46];
							end
							else if(master_data_num == 45) begin
								adf4159_int_reg[23:12] <= master_data[40:29];
								adf4159_frac_reg[49:25] <= master_data[28:4];
								adf4159_lo[7:4] <= master_data[3:0];
							end
							load_trig <= 6'b000010;
						end
						3 : begin
							if(master_data_num == 51) begin
								adf4159_int_reg[35:24] <= master_data[15:4];
								adf4159_frac_reg[74:50] <= master_data[40:16];
								adf4159_lo[11:8] <= master_data[44:41];
								adf4159_ref_doubled_reg[2] <= master_data[45];
								adf4159_r_counter_reg[14:10] <= master_data[50:46];
							end
							else if(master_data_num == 45) begin
								adf4159_int_reg[35:24] <= master_data[40:29];
								adf4159_frac_reg[74:50] <= master_data[28:4];
								adf4159_lo[11:8] <= master_data[3:0];
							end
							load_trig <= 6'b000100;
						end
						4 : begin
							if(master_data_num == 51) begin
								adf4159_int_reg[47:36] <= master_data[15:4];
								adf4159_frac_reg[99:75] <= master_data[40:16];
								adf4159_lo[15:12] <= master_data[44:41];
								adf4159_ref_doubled_reg[3] <= master_data[45];
								adf4159_r_counter_reg[19:15] <= master_data[50:46];
							end
							else if(master_data_num == 45) begin
								adf4159_int_reg[47:36] <= master_data[40:29];
								adf4159_frac_reg[99:75] <= master_data[28:4];
								adf4159_lo[15:12] <= master_data[3:0];
							end
							load_trig <= 6'b001000;
						end
						5 : begin
							if(master_data_num == 51) begin
								adf4159_int_reg[59:48] <= master_data[15:4];
								adf4159_frac_reg[124:100] <= master_data[40:16];
								adf4159_lo[19:16] <= master_data[44:41];
								adf4159_ref_doubled_reg[4] <= master_data[45];
								adf4159_r_counter_reg[24:20] <= master_data[50:46];
							end
							else if(master_data_num == 45) begin
								adf4159_int_reg[59:48] <= master_data[40:29];
								adf4159_frac_reg[124:100] <= master_data[28:4];
								adf4159_lo[19:16] <= master_data[3:0];
							end
							load_trig <= 6'b010000;
						end
						6 : begin
							if(master_data_num == 51) begin
								adf4159_int_reg[71:60] <= master_data[15:4];
								adf4159_frac_reg[149:125] <= master_data[40:16];
								adf4159_lo[23:20] <= master_data[44:41];
								adf4159_ref_doubled_reg[5] <= master_data[45];
								adf4159_r_counter_reg[29:25] <= master_data[50:46];
							end
							else if(master_data_num == 45) begin
								adf4159_int_reg[71:60] <= master_data[40:29];
								adf4159_frac_reg[149:125] <= master_data[28:4];
								adf4159_lo[23:20] <= master_data[3:0];
							end
							load_trig <= 6'b100000;
						end
					endcase
					//load_trig = 1'b1;
					fsm_state <= 6'd2;
				end
				2 : begin
					master_ack_reg <= 1'b1;
					//load_trig = 1'b0;
					load_trig <= 6'b000000;
					fsm_state <= 6'd3;
				end
				3 : begin
					if(!master_data_ready) begin
						master_ack_reg <= 1'b0;
						fsm_state <= 6'd0;
					end
				end
			endcase
		end
	end
	
	assign adf4159_pre_load = load_trig;
	assign master_ack = master_ack_reg;
	assign adf4159_int = adf4159_int_reg;
	assign adf4159_frac = adf4159_frac_reg;
	assign adf4159_ref_doubled = adf4159_ref_doubled_reg;
	assign adf4159_r_counter = adf4159_r_counter_reg;
	
	
	
	reg [1:0] freq_trig1_dege = 2'b11;
	reg [1:0] freq_trig2_dege = 2'b11;
	reg freq_level_sample_1 = 1;
	reg freq_level_sample_2 = 1;
	reg [7:0] freq_level_1_sum = 8'd0;
	reg [7:0] freq_level_2_sum = 8'd0;
	reg [7:0] freq_count = 0;
	
	always @ (posedge clk) begin
		if(freq_count == 39) begin
			freq_count <= 0;
			
			if(freq_level_1_sum > 20)
				freq_level_sample_1 <= 1;
			else freq_level_sample_1 <= 0;
			
			if(freq_level_2_sum > 20)
				freq_level_sample_2 <= 1;
			else freq_level_sample_2 <= 0;
			
			freq_level_1_sum <= 0;
			freq_level_2_sum <= 0;
		end
		else begin
			freq_level_1_sum <= freq_level_1_sum + freq_trig1;
			freq_level_2_sum <= freq_level_2_sum + freq_trig2;
			freq_count <= freq_count + 1; 
		end
	end
	
	always @ (posedge clk) begin
		freq_trig1_dege <= {freq_trig1_dege[0],freq_level_sample_1};//tx
		freq_trig2_dege <= {freq_trig2_dege[0],freq_level_sample_2};//rx
	end
	
	wire [5:0] adf4159_rx_lo;
	wire [5:0] adf4159_tx_lo;
	
	assign adf4159_rx_lo = {1'b1,
									1'b0,
									(adf4159_lo[15:12] == 4'b0011),
									(adf4159_lo[11:8] == 4'b0001),
									(adf4159_lo[7:4] == 4'b0011),
									(adf4159_lo[3:0] == 4'b0001)};
	assign adf4159_tx_lo = {1'b0,
									1'b1,
									(adf4159_lo[15:12] == 4'b0110),
									(adf4159_lo[11:8] == 4'b0101),
									(adf4159_lo[7:4] == 4'b0110),
									(adf4159_lo[3:0] == 4'b0101)};
	
	//LO5\LO6\LO7
	reg [5:0] adf4159_tx_load_reg = 6'b000000;
	reg [5:0] adf4159_tx_load_temp_reg = 6'b000000;
	reg [5:0] fsm_load1_state = 6'd0;
	always @ (posedge clk) begin
		if(!rst) begin
			adf4159_tx_load_reg <= 6'b000000;
			fsm_load1_state <= 6'd0;
		end
		else begin
			case(fsm_load1_state)
				0 : begin
					if(freq_trig1_dege == 2'b01) begin
						adf4159_tx_load_temp_reg <= adf4159_tx_lo;
						fsm_load1_state <= 6'd1;
					end
				end
				1 : begin
					if((adf4159_busy & adf4159_tx_load_temp_reg) == 6'b000000) begin
						adf4159_tx_load_reg <= adf4159_tx_load_temp_reg;
						fsm_load1_state <= 6'd2;
					end
				end
				2 : begin
					if((adf4159_busy & adf4159_tx_load_temp_reg) == adf4159_tx_load_temp_reg) begin
						adf4159_tx_load_reg <= 6'b000000;
						fsm_load1_state <= 6'd3;
					end
				end
				3 : begin
					fsm_load1_state <= 6'd0;
				end
			endcase
		end
	end
	
	//LO1\LO2\LO3\LO4
	reg [5:0] adf4159_rx_load_reg = 6'b000000;
	reg [5:0] adf4159_rx_load_temp_reg = 6'b000000;
	reg [5:0] fsm_load2_state = 6'd0;
	always @ (posedge clk) begin
		if(!rst) begin
			adf4159_rx_load_reg <= 6'b000000;
			fsm_load2_state <= 6'd0;
		end
		else begin
			case(fsm_load2_state)
				0 : begin
					if(freq_trig2_dege == 2'b01) begin
						adf4159_rx_load_temp_reg <= adf4159_rx_lo;
						fsm_load2_state <= 6'd1;
					end
				end
				1 : begin
					if((adf4159_busy & adf4159_rx_load_temp_reg) == 6'b000000) begin
						adf4159_rx_load_reg <= adf4159_rx_load_temp_reg;
						fsm_load2_state <= 6'd2;
					end
				end
				2 : begin
					if((adf4159_busy & adf4159_rx_load_temp_reg) == adf4159_rx_load_temp_reg) begin
						adf4159_rx_load_reg <= 6'b000000;
						fsm_load2_state <= 6'd3;
					end
				end
				3 : begin
					fsm_load2_state <= 6'd0;
				end
			endcase
		end
	end
	
	
	assign adf4159_load = adf4159_tx_load_reg | adf4159_rx_load_reg;

	assign fs = 8'b00000000;
	assign vctrl = {(((adf4159_lo[7:4] == 4'b0011) ||(adf4159_lo[15:12] == 4'b0110)) ? 4'b0101:4'b1010),
							(((adf4159_lo[3:0] == 4'b0001) ||(adf4159_lo[11:8] == 4'b0101)) ? 4'b0101:4'b1010)};
	
	assign pll_lock[0] = ~pll_lock_i[0];
	assign pll_lock[1] = ~pll_lock_i[1];
	assign pll_lock[2] = ~pll_lock_i[2];
	assign pll_lock[3] = ~pll_lock_i[3];
	assign pll_lock[4] = ~pll_lock_i[4];
	assign pll_lock[5] = ~pll_lock_i[5];
 
 endmodule
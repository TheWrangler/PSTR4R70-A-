`timescale 1ns / 1ps

module adf4159
(
	input clk,
	input rst,
	
	input load,
	input pre_load,
	input [11:0] ints,
	input [24:0] fracs,
	input ref_doubled,
	input [4:0] r_counter,
	input prescaler,
	
	output reg busy,
	
	output spi_clk,
	output spi_data,
	output spi_le
);

	wire spi_load;
	wire [31:0] spi_reg_var;
	wire spi_busy;
	adf4159_spi adf4159_inst
	(
		.clk(clk),
		.rst(rst),
		
		.load(spi_load),
		.reg_var(spi_reg_var),
		
		.spi_clk(spi_clk),
		.spi_data(spi_data),
		.spi_le(spi_le),
		
		.busy(spi_busy)
	);
	
	//reg [351:0] reg_var = {32'h7,32'h6,32'h800006,32'h5,32'h800005,32'h104,32'h144,32'hC20403/*32'h1020403*/,32'h100800a/*32'h700800a*/,32'h71c8009,32'h30312500};
	reg [351:0] reg_var = {32'h7,32'h6,32'h800006,32'h5,32'h800005,32'h104,32'h144,32'h1020403,32'h700800a,32'h71c8009,32'h30312500};
	reg [351:0] reg_var_temp;
	reg [31:0] spi_reg_var_reg;
	
	reg [5:0] reg_count = 6'd0;
	reg [5:0] fsm_state = 6'd0;
	reg ad4159_spi_load = 1'b0;
	
//	always @ (posedge clk) begin
//		if(!rst) begin
//			reg_count <= 6'd0;
//			ad4159_spi_load <= 1'b0;
//			busy <= 1'b0;
//			fsm_state <= 6'd0;
//		end
//		else begin
//			case (fsm_state)
//				0 : begin
//					if(load) begin
//						reg_var_temp <= reg_var;
//						reg_count <= 6'd0;
//						fsm_state <= 6'd1;
//					end
//				end
//				1 : begin
//					reg_var_temp[14:3]= fracs[24:13];
//					reg_var_temp[59:47]= fracs[12:0];
//					reg_var_temp[26:15]= ints[11:0];
//					reg_var_temp[84] = ref_doubled;
//					reg_var_temp[83:79] = r_counter;
//					reg_var_temp[86] = prescaler;
//					busy <= 1'b1;
//					fsm_state <= 6'd2;
//				end
//				2 : begin
//					if(!spi_busy) begin
//						spi_reg_var_reg <= reg_var_temp[351:320];
//						ad4159_spi_load <= 1'b1;
//						reg_count <= reg_count +6'd1;
//						fsm_state <= 6'd3;
//					end	
//				end
//				3 : begin
//					if(spi_busy) begin
//						ad4159_spi_load <= 1'b0;
//						fsm_state <= 6'd4;
//					end
//				end
//				4 : begin
//					reg_var_temp = {reg_var_temp[319:0],32'h00000000};
//					if(reg_count < 6'd11)
//						fsm_state <= 6'd2;
//					else begin
//						busy <= 1'b0;
//						fsm_state <= 6'd0;
//					end
//				end
//			endcase
//		end
//	end
	
	always @ (posedge clk) begin
		if(!rst) begin
			spi_reg_var_reg <= 0;
			reg_count <= 6'd0;
			ad4159_spi_load <= 1'b0;
			busy <= 0;
			reg_var_temp <= reg_var;
			fsm_state <= 6'd0;
		end
		else begin
			case (fsm_state)
				//power up config 8 regs
				0:begin
					busy <= 1'b1;
					if(!spi_busy) begin
						spi_reg_var_reg <= reg_var_temp[351:320];
						ad4159_spi_load <= 1'b1;
						reg_count <= reg_count +6'd1;
						fsm_state <= 6'd1;
					end
				end
				1 : begin
					if(spi_busy) begin
						ad4159_spi_load <= 1'b0;
						fsm_state <= 6'd2;
					end
				end
				2 : begin
					reg_var_temp = {reg_var_temp[319:0],32'h00000000};
					if(reg_count < 6'd8)
						fsm_state <= 6'd0;
					else begin
						busy <= 1'b0;
						fsm_state <= 6'd3;
					end
				end
				3 : begin
					reg_var_temp <= reg_var;
					fsm_state <= 6'd4;
				end
				//load & pre-load
				4 : begin
					if(pre_load) begin
						busy <= 1'b1;
						fsm_state <= 6'd5;
					end
					else if(load) begin
						busy <= 1'b1;
						fsm_state <= 6'd9;
					end
				end
				5 : begin
					reg_var_temp[14:3]= fracs[24:13];
					reg_var_temp[59:47]= fracs[12:0];
					reg_var_temp[26:15]= ints[11:0];
					reg_var_temp[84] = ref_doubled;
					reg_var_temp[83:79] = r_counter;
					reg_var_temp[86] = prescaler;
					fsm_state <= 6'd6;
				end
				6 : begin
					if(!spi_busy) begin
						spi_reg_var_reg <= reg_var_temp[95:64];
						ad4159_spi_load <= 1'b1;
						fsm_state <= 6'd7;
					end	
				end
				7 : begin
					if(spi_busy) begin
						ad4159_spi_load <= 1'b0;
						fsm_state <= 6'd8;
					end
				end
				8 : begin
					if(!spi_busy) begin
						spi_reg_var_reg <= reg_var_temp[63:32];
						ad4159_spi_load <= 1'b1;
						fsm_state <= 6'd10;
					end
				end
				9 : begin
					if(!spi_busy) begin
						spi_reg_var_reg <= reg_var_temp[31:0];
						ad4159_spi_load <= 1'b1;
						fsm_state <= 6'd10;
					end
				end
				10 : begin
					if(spi_busy) begin
						ad4159_spi_load <= 1'b0;
						fsm_state <= 6'd11;
					end
				end
				11 : begin
					busy <= 1'b0;
					fsm_state <= 6'd4;
				end
			endcase
		end
	end
	
	assign spi_load = ad4159_spi_load;
	assign spi_reg_var = spi_reg_var_reg;
	
endmodule
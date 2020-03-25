`timescale 1ns / 1ps

module adf4159_spi
(
	input clk,
	input rst,
	
	input load,
	input [31:0] reg_var,
	
	output reg spi_clk,
	output reg spi_data,
	output reg spi_le,
	
	output reg busy
);
	localparam [5:0] load_bit_num = 32;

	reg [5:0] fsm_state = 0; 
	reg [5:0] load_bit_count = 6'd0;
	reg [load_bit_num-1:0] reg_var_temp;
	
	always @ (negedge clk) begin
		if(!rst) begin
			spi_clk <= 1'b1;
			spi_data <= 1'b0;
			spi_le <= 1'b1;
			load_bit_count <= 6'd0;
			busy <= 1'b0;
			fsm_state <= 0;
		end
		else begin
			case(fsm_state)
				0 : begin
					if(load) begin
						reg_var_temp <= reg_var;
						load_bit_count <= 6'd0;	
						busy <= 1'b1;
						fsm_state <= 1;
					end
				end
				1 : begin
					spi_le <= 1'b0;
					fsm_state <= 2;
				end
				2 : begin
					spi_data <= reg_var_temp[31];
					spi_clk <= 1'b0;
					load_bit_count <= load_bit_count + 1;
					fsm_state <= 3;
				end
				3 : begin
					reg_var_temp = {reg_var_temp[30:0],1'b0};
					spi_clk <= 1'b1;
					if(load_bit_count == load_bit_num)
						fsm_state <= 4;
					else fsm_state <= 2;
				end
				4 : begin
					spi_le <= 1'b1;
					busy <= 1'b0;
					fsm_state <= 0;
				end
			endcase		
		end
	end

endmodule
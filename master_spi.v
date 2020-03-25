`timescale 1ns / 1ps

module master_spi
#(
	parameter MASTER_CMD_BIT_NUM = 41,
	parameter MASTER_REPLY_BIT_NUM = 6,
	parameter MASTER_CMD_SAMPLE_LEVEL = 1
)
(
	input clk,
	input rst,
	
	input [MASTER_REPLY_BIT_NUM-1:0] pll_lock,
	
	input spi_clk,
	input spi_cs,
	input spi_mosi,
	output reg spi_miso,
	
	output reg [MASTER_CMD_BIT_NUM-1:0] data,
	output reg dready,
	input ack
);
	
	wire master_cmd_sample_level = MASTER_CMD_SAMPLE_LEVEL & 1'b1;
	reg slave_write_trig = 1'b0;
	reg [5:0] fsm_read_state = 6'd0;
	reg [5:0] mosi_bit_count = 6'd0;
	reg [5:0] miso_bit_count = 6'd0;
	always @ (posedge clk) begin
		if(!rst || spi_cs) begin
			data <= 40'd0;
			dready <= 1'b0;
			mosi_bit_count <= 6'd0;
			slave_write_trig <= 1'b0;
			fsm_read_state <= 6'd0;
		end
		else begin
			case(fsm_read_state)
				0 : begin
					if(spi_cs == 1'b0) begin
						mosi_bit_count <= 6'd0;
						fsm_read_state <= 6'd1;
					end
				end
				//read bit
				1 : begin
					if(spi_clk == ~master_cmd_sample_level)
						fsm_read_state <= 6'd2;
				end
				2 : begin
					if(spi_clk == master_cmd_sample_level) begin
						data <= {data[MASTER_CMD_BIT_NUM-2:0],spi_mosi};
						mosi_bit_count <= mosi_bit_count + 1;
						fsm_read_state <= 6'd3;
					end
				end
				//check cmd
				3 : begin
					if(mosi_bit_count == 4) begin
						if(data[3:0] == 4'b1000) begin
							slave_write_trig <= 1'b1;
							fsm_read_state <= 6'd6;
						end
						else fsm_read_state <= 6'd1;
					end
					else if(mosi_bit_count > MASTER_CMD_BIT_NUM)
						fsm_read_state <= 6'd4;
					else fsm_read_state <= 6'd1;
				end
				//read ready
				4 : begin
					dready <= 1'b1;
					fsm_read_state <= 6'd5;
				end
				5 : begin
					if(ack) begin
						dready <= 1'b0;
						fsm_read_state <= 6'd0;
					end
				end
				//dealy for slave write operation completed
				6 : begin
					slave_write_trig <= 1'b0;
					if(miso_bit_count == MASTER_REPLY_BIT_NUM)
						fsm_read_state <= 6'd0;
				end
			endcase
		end
	end
	
	//slave reply routine
	reg [5:0] fsm_write_state = 6'd0;
	reg [MASTER_REPLY_BIT_NUM-1:0] pll_lock_state;
	always @ (negedge clk) begin
		if(!rst || spi_cs) begin
			spi_miso <= 1'b0;
			miso_bit_count = 6'd0;
			fsm_write_state <= 6'd0;
		end
		else begin
			case(fsm_write_state)
				0 : begin
					if(slave_write_trig == 1'b1) begin
						pll_lock_state <= pll_lock;
						miso_bit_count <= 6'd0;
						fsm_write_state <= 6'd1;
					end
				end
				1 : begin
					if(spi_clk == master_cmd_sample_level)
						fsm_write_state <= 6'd2;
				end
				2 : begin
					if(spi_clk == ~master_cmd_sample_level) begin
						spi_miso <= pll_lock_state[0];
						miso_bit_count <= miso_bit_count + 1;
						fsm_write_state <= 6'd3;
					end
				end
				3 : begin
					pll_lock_state <= {1'b0,pll_lock_state[MASTER_REPLY_BIT_NUM-1:1]};
					if(miso_bit_count == MASTER_REPLY_BIT_NUM)
						fsm_write_state <= 6'd4;
					else fsm_write_state <= 6'd1;
				end
				4 : begin
					if(slave_write_trig == 1'b0)
						fsm_write_state <= 6'd0;
				end
			endcase
		end
	end
	
endmodule
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
	output reg [6:0] data_num,
	output reg dready,
	input ack
);

	reg [2:0] spi_clk_sample = 0;
	reg [2:0] spi_cs_sample = 0;
	reg spi_clk_level = 1;
	reg spi_cs_level = 1;
	
	always @ (posedge clk) begin
		if(!rst) begin
			spi_clk_sample <= 3'b111;
			spi_cs_sample <= 3'b111;
			spi_clk_level <= 1;
			spi_cs_level <= 1;
		end
		else begin
			spi_clk_sample <= {spi_clk_sample[1:0],spi_clk};
			if(spi_clk_sample >= 4)
				spi_clk_level <= 1;
			else spi_clk_level <= 0;
			
			spi_cs_sample <= {spi_cs_sample[1:0],spi_cs};
			if(spi_cs_sample >= 4)
				spi_cs_level <= 1;
			else spi_cs_level <= 0;
		end
	end
	
	
	
	wire master_cmd_sample_level = MASTER_CMD_SAMPLE_LEVEL & 1'b1;
	reg slave_write_trig = 1'b0;
	reg [5:0] fsm_read_state = 6'd0;
	reg [6:0] miso_bit_count = 7'd0;
	always @ (posedge clk) begin
		if(!rst) begin
			data <= 40'd0;
			dready <= 1'b0;
			data_num <= 7'd0;
			slave_write_trig <= 1'b0;
			fsm_read_state <= 6'd0;
		end
		else if(spi_cs_level == 1'b1) begin
			fsm_read_state <= 6'd0;
			slave_write_trig <= 1'b0;
			if(ack == 1'b1) begin
				data_num <= 0;
				dready <= 1'b0;
			end
			else if(data_num != 0)
				dready <= 1'b1;
		end
		else begin
			case(fsm_read_state)
				0 : begin
					if(spi_cs_level == 1'b0) begin
						data_num <= 7'd0;
						fsm_read_state <= 6'd1;
					end
				end
				//read bit
				1 : begin
					if(spi_clk_level == 1'b0)
						fsm_read_state <= 6'd2;
					else fsm_read_state <= 6'd1;
				end
				2 : begin
					if(spi_clk_level == 1'b1)
						fsm_read_state <= 6'd3;
					else fsm_read_state <= 6'd2;
				end
				3 : begin
					data <= {spi_mosi,data[MASTER_CMD_BIT_NUM-1:1]};
					data_num <= data_num + 1;
					fsm_read_state <= 6'd4;
				end
				//check cmd
				4 : begin
					if(data_num == 4) begin
						if(data[MASTER_CMD_BIT_NUM-1:MASTER_CMD_BIT_NUM-4] == 4'b1000) begin
							slave_write_trig <= 1'b1;
							fsm_read_state <= 6'd5;
						end
						else fsm_read_state <= 6'd1;
					end
					else fsm_read_state <= 6'd1;
				end
				//dealy for slave write operation completed
				5 : begin
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
		if(!rst) begin
			spi_miso <= 1'b0;
			miso_bit_count = 7'd0;
			fsm_write_state <= 6'd0;
		end
		else if(spi_cs_level == 1'b1) begin
			fsm_write_state <= 6'd0;
			miso_bit_count <= 7'd0;
		end
		else begin
			case(fsm_write_state)
				0 : begin
					if(slave_write_trig == 1'b1) begin
						pll_lock_state <= pll_lock;
						miso_bit_count <= 7'd0;
						fsm_write_state <= 6'd1;
					end
				end
				1 : begin
					if(spi_clk_level == master_cmd_sample_level)
						fsm_write_state <= 6'd2;
				end
				2 : begin
					if(spi_clk_level == ~master_cmd_sample_level) begin
						spi_miso <= pll_lock_state[0];
						miso_bit_count <= miso_bit_count + 1;
						fsm_write_state <= 6'd3;
					end
				end
				3 : begin
					pll_lock_state <= {1'b0,pll_lock_state[MASTER_REPLY_BIT_NUM-1:1]};
					if(miso_bit_count == MASTER_REPLY_BIT_NUM)
						fsm_write_state <= 6'd0;
					else fsm_write_state <= 6'd1;
				end
			endcase
		end
	end
	
endmodule
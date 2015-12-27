`include "defines.v"
`timescale 1ns/1ps
module flash_driver (
	input clk,
	input rst,
	input ce,
	input [`FlashAddrBusWord] addr, 
	input [`FlashDataBus] data_in, 
	output [`FlashDataBus] data_out, 

	input enable_read, 
	input enable_erase, 
	input enable_write, 

	output [`FlashAddrBus] flash_addr, 
	inout [`FlashDataBus] flash_data, 
	output [`FlashCtrlBus] flash_ctl, 
	output reg ack,
	output wire[7:0] state_o
	);

	assign state_o = {ack, ce, enable_read, enable_write, state};

	reg busy;
	assign data_out = flash_data;
	reg flash_oe, flash_we;

	wire flash_byte = 1, flash_vpen = 1, flash_rp = 1, flash_ce = 0;

	reg [21:0] addr_latch;
	assign flash_addr = {enable_read ? addr : addr_latch, 1'b0};
	reg [15:0] data_to_write, data_in_latch;

	assign flash_data = flash_oe ? data_to_write : {16{1'bz}};

	assign flash_ctl = {
		flash_byte, 
		flash_ce, 
		2'b0, 		//ce1 ce2
		flash_oe, 
		flash_rp, 
		flash_vpen, 
		flash_we
	};

	reg [3:0] state;
	localparam
		IDLE = 4'b0000, 
		WRITE1 = 4'b0001,
		WRITE2 = 4'b0011, 
		WRITE3 = 4'b0010, 
		ERASE1 = 4'b0110, 
		ERASE2 = 4'b0111, 
		ERASE3 = 4'b0101, 
		READ1 = 4'b0100, 
		READ2 = 4'b1100, 
		READ3 = 4'b1101,
		READ4 = 4'b1111, 
		SR1 = 4'b1110, 
		SR2 = 4'b1010, 
		SR3 = 4'b1011, 
		SR4 = 4'b1001,
		END = 4'b1000;

	reg [2:0] read_wait_cnt;

	always @ (*) begin
		if (rst == `RstEnable || ce == `False_v) begin
			ack <= 1'b1;
		end else begin
			case (state)
				IDLE: begin
					ack <= 1'b0;
				end
				END: begin
					ack <= 1'b1;
				end
				default: begin
					ack <= 1'b0;
				end
			endcase
		end
	end

	always @ (posedge clk) begin
		if (rst == `RstEnable || ce == `False_v) begin
			state <= IDLE;
		end else begin
			case (state)
				IDLE: begin
					addr_latch <= addr;
					flash_oe <= 1;
					flash_we <= 1;
					busy <= 0;
					if (enable_write) begin
						data_in_latch <= data_in;
						flash_we <= 0;
						data_to_write <= 16'h0040;
						state <= WRITE1;
						busy <= 1;
					end else if (enable_erase) begin
						flash_we <= 0;
						data_to_write <= 16'h0020;
						state <= ERASE1;
						busy <= 1;
					end else if (enable_read) begin
						flash_we <= 0;
						data_to_write <= 16'h00ff;
						state <= READ1;
						busy <= 1;
					end
				end
				
				WRITE1: begin
					flash_we <= 1;
					state <= WRITE2;
				end
				WRITE2: begin
					flash_we <= 0;
					data_to_write <= data_in_latch;
					state <= WRITE3;
				end
				WRITE3: begin
					flash_we <= 1;
					state <= SR1;
				end

				ERASE1: begin
					flash_we <= 1;
					state <= ERASE2;
				end
				ERASE2: begin
					flash_we <= 0;
					data_to_write <= 16'h00d0;
					state <= ERASE3;
				end
				ERASE3: begin
					flash_we <= 1;
					state <= SR1;
				end

				READ1: begin
					flash_we <= 1;
					state <= READ2;
				end
				READ2: begin
					flash_oe <= 0;
					state <= READ3;
					read_wait_cnt <= 0;
				end
				READ3: begin
					if (read_wait_cnt[2]) begin
						busy <= 0;
						state <= READ4;
					end else begin
						read_wait_cnt <= read_wait_cnt + 1'b1;
					end
				end
				READ4: begin
					// if (!enable_read)
					state <= END;
				end

				//wait for sr[7] becomes 1
				SR1: begin
					flash_we <= 0;
					data_to_write <= 16'h0070;
					state <= SR2;
				end
				SR2: begin
					flash_we <= 1;
					state <= SR3;
				end
				SR3: begin
					flash_oe <= 0;
					state <= SR4;
				end
				SR4: begin
					flash_oe <= 1;
					if (flash_data[7]) begin
						state <= END;
						busy <= 0;
					end
					else
						state <= SR1;
				end
				END: begin
					// flash_oe <= 1;
					// flash_we <= 1;
					if(!ce)
						state <= IDLE;
				end
				default:
					state <= IDLE;
			endcase
		end
	end

endmodule

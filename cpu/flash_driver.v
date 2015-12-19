`include "defines.v"
module flash_driver (
	input clk,    
	input [`FlashAddrBusWord] addr, 
	input [`FlashDataBus] data_in, 
	output [`FlashDataBus] data_out, 

	input enable_read, 
	input enable_erase, 
	input enable_write, 

	output [`FlashAddrBus] flash_addr, 
	inout [`FlashDataBus] flash_data, 
	output [`FlashCtrlBus] flash_ctl, 
	output reg ack
	);

	reg busy;
	assign data_out = flash_data;
	reg flash_oe, flash_we;

	wire flash_byte = 1, flash_vpen = 1, flash_ce = 0, flash_rp = 1;

	reg [`FlashAddrBusWord] addr_latch;
	assign flash_addr = {enable_read ? addr : addr_latch, 1'b0};
	reg [`FlashDataBus] data_to_write, data_in_latch;

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
		SR4 = 4'b1001;

	reg [2:0] read_wait_cnt;
	always @ (posedge clk) begin
		case (state)
			IDLE: begin
				ack <= 1'b1;
				addr_latch <= addr;
				if (enable_write == 1'b1) begin
					ack <= 1'b1;
					data_in_latch <= data_in;
					flash_we <= 1'b0;
					data_to_write <= 16'h0040;
					state <= WRITE1;
					busy <= 1'b1;
				end else if (enable_erase == 1'b1) begin
					ack <= 1'b1;
					flash_we <= 1'b0;
					data_to_write <= 16'h0020;
					state <= ERASE1;
					busy <= 1'b1;
				end else if (enable_read == 1'b1) begin
					ack <= 1'b0;
					flash_we <= 1'b0;
					data_to_write <= 16'h00ff;
					state <= READ1;
					busy <= 1'b1;
				end else begin
					flash_oe <= 1'b1;
					flash_we <= 1'b1;
					busy <= 1'b0;
				end
			end
			
			WRITE1: begin
				flash_we <= 1'b1;
				state <= WRITE2;
			end
			WRITE2: begin
				flash_we <= 1'b0;
				data_to_write <= data_in_latch;
				state <= WRITE3;
			end
			WRITE3: begin
				flash_we <= 1'b1;
				state <= SR1;
			end

			ERASE1: begin
				flash_we <= 1'b1;
				state <= ERASE2;
			end
			ERASE2: begin
				flash_we <= 1'b0;
				data_to_write <= 16'h00d0;
				state <= ERASE3;
			end
			ERASE3: begin
				flash_we <= 1'b1;
				state <= SR1;
			end

			READ1: begin
				flash_we <= 1'b1;
				state <= READ2;
			end
			READ2: begin
				flash_oe <= 1'b0;
				state <= READ3;
				read_wait_cnt <= 3'b000;
			end
			READ3: begin
				if (read_wait_cnt[2]) begin
					busy <= 1'b0;
					state <= READ4;
				end else begin
					read_wait_cnt <= read_wait_cnt + 1'b1;
				end
			end
			READ4: begin
				if (!enable_read) begin
					state <= IDLE;
				end
			end

			//wait for sr[7] becomes 1
			SR1: begin
				flash_we <= 1'b0;
				data_to_write <= 16'h0070;
				state <= SR2;
			end
			SR2: begin
				flash_we <= 1'b1;
				state <= SR3;
			end
			SR3: begin
				flash_oe <= 1'b0;
				state <= SR4;
			end
			SR4: begin
				flash_oe <= 1'b1;
				if (flash_data[7]) begin
					state <= IDLE;
					ack <= 1'b1;
					busy <= 1'b0;
				end
				else
					state <= SR1;
			end
			default:
				state <= IDLE;
		endcase
	end

endmodule

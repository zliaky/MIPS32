`timescale 1ns/1ps
`include "defines.v"
module data_ram(
	input			wire					clk,
	input			wire					rst,
	input			wire					ce,
	input			wire					we,
	input			wire[`DataAddrBus]		addr,
	input			wire[`DataBus]			data_i,
	output			reg[`DataBus]			data_o,
	output			reg						ack
	);

	//定义四个字节数组
	// reg[31:0] data_mem[0:`DataMemNum-1];
	reg[31:0] data_mem[0:`DataMemNum-1];

	initial begin
		`include "input.v"
	end

	localparam IDLE = 1'b0, WRITE = 1'b1;
	reg state;

	initial state = IDLE;

	always @ (*) begin
		if (rst == `RstEnable) begin
			ack <= 1'b1;
		end else begin
			if (ce == `ChipDisable) begin
				ack <= 1'b1;
			end else begin
				case (state)
					IDLE: begin
						ack <= 1'b1;
						if (we == `WriteEnable) begin
							ack <= 1'b0;
						end
					end
					WRITE: begin
						ack <= 1'b1;
					end
				endcase
			end
		end
	end

	always @ (posedge clk) begin
		if (rst == `RstDisable) begin
			if (ce == `ChipDisable) begin
				// data_o <= `ZeroWord;
			end else begin
				case (state)
					IDLE: begin
						if (we == `WriteEnable) begin
							state <= WRITE;
						end
						// end else begin
							data_o <= data_mem[addr[`DataMemNumLog2+1:2]];
						// end
					end
					WRITE: begin
						data_mem[addr[`DataMemNumLog2+1:2]] <= data_i;
						state <= IDLE;
					end
				endcase
			end
		end
	end


	// always @ (posedge clk) begin
	// 	if (rst == `RstEnable) begin
	// 		ack <= 1'b1;
	// 		data_o <= `ZeroWord;
	// 	end else begin
	// 		if (ce == `ChipDisable) begin
	// 			ack <= 1'b1;
	// 			data_o <= `ZeroWord;
	// 		end else begin
	// 			case (state)
	// 				IDLE: begin
	// 					ack <= 1'b1;
	// 					if (we == `WriteEnable) begin
	// 						ack <= 1'b0;
	// 						state <= WRITE;
	// 					end else begin
	// 						data_o <= data_mem[addr[`DataMemNumLog2+1:2]];
	// 					end
	// 				end
	// 				WRITE: begin
	// 					data_mem[addr[`DataMemNumLog2+1:2]] <= data_i;
	// 					ack <= 1'b1;
	// 					state <= IDLE;
	// 				end
	// 			endcase
	// 		end
	// 	end
	// end

endmodule

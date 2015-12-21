`include "defines.v"
module ctrl(
	input		wire					rst,
	input		wire					stallreq_from_if,
	input		wire					stallreq_from_id,
	input		wire					stallreq_from_ex,
	input		wire					stallreq_from_mem,
	// input 		wire					stallreq_from_wishbone,

	//来自MEM模块的输入信号
	input		wire[31:0]				excepttype_i,
	input		wire[`RegBus]			cp0_epc_i,

	output		reg[`RegBus]			new_pc,
	output		reg						flush,

	output		reg[5:0]				stall
	);

	always @ (*) begin
		new_pc <= `ZeroWord;
		if (rst == `RstEnable) begin
			flush <= 1'b0;
			stall <= 6'b111111;
			new_pc <= `ZeroWord;
		end else if (excepttype_i != `ZeroWord) begin
			flush <= 1'b1;
			stall <= 6'b000000;
			case (excepttype_i)
				32'h000000f: begin				//interrupt
					new_pc <= 32'h00008020;
				end
				32'h0000001: begin				//TLB Modified
					new_pc <= 32'h00008040;
				end
				32'h0000002: begin				//TLBL
					new_pc <= 32'h00008040;
				end
				32'h0000003: begin				//TLBS
					new_pc <= 32'h00008040;
				end
				32'h0000004: begin				//ADEL
					new_pc <= 32'h00008040;
				end
				32'h0000005: begin				//ADES
					new_pc <= 32'h00008040;
				end
				32'h0000008: begin				//Syscall
					new_pc <= 32'h00008040;
				end
				32'h000000a: begin				//RI
					new_pc <= 32'h00008040;
				end
				32'h000000b: begin				//Co-Processor Unavailable
					new_pc <= 32'h00008040;
				end
				32'h0000017: begin				//Watch
					new_pc <= 32'h00008040;
				end
				32'h000000e: begin				//eret
					new_pc <= cp0_epc_i;
				end
				default: begin
				end
			endcase
		end else if (stallreq_from_mem == `Stop) begin
			flush <= 1'b0;
			stall <= 6'b011111;
		end else if (stallreq_from_ex == `Stop) begin
			flush <= 1'b0;
			stall <= 6'b001111;
		end else if (stallreq_from_id == `Stop) begin
			flush <= 1'b0;
			stall <= 6'b000111;
		end else if (stallreq_from_if == `Stop) begin
			flush <= 1'b0;
			stall <= 6'b000111;
		end else begin
			flush <= 1'b0;
			stall <= 6'b000000;
			new_pc <= `ZeroWord;
		end
	end

endmodule

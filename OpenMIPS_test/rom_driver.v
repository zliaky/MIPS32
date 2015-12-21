`include "defines.v"
module rom_driver(
	input clk,
	input rst,
	input ce,
	input [`RomAddrBus] addr,
	output reg[`InstBus] inst,
	output ack
	);

	assign ack = 1'b1;

	//当复位信号无效时，根据输入的地址，给出指令存储器ROM中对应的元素
	always @ (posedge clk) begin
		if (ce == `ChipDisable || rst == `RstEnable) begin
			inst <= `ZeroWord;
		end else begin
			case (addr)
				`include "rom_inst.v"
				default: inst <= 32'h00000000;
			endcase
		end
	end

endmodule

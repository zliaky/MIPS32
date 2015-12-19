`include "defines.v"
module rom_driver(
	input ce,
	input [`RomAddrBus] addr,
	output reg[`InstBus] inst,
	output reg ack
	);

	//当复位信号无效时，根据输入的地址，给出指令存储器ROM中对应的元素
	always @ (*) begin
		if (ce == `ChipDisable) begin
			inst <= `ZeroWord;
			ack <= 1'b0;
		end else begin
			//inst <= inst_mem[addr[`InstMemNumLog2+1:2]];
			inst <= 32'h11111111;
			ack <= 1'b1;
		end
	end

endmodule

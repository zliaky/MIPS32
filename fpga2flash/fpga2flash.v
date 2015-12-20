`include "defines.v"
module fpga2flash(
	input clk,
	input rst,

	output [15:0] led,
	input [31:0] sw_dip,

	output [`FlashAddrBus] flash_addr, 
	inout [`FlashDataBus] flash_data, 
	output [`FlashCtrlBus] flash_ctl, 

	output [`DigSegDataBus] segdisp0,
	output [`DigSegDataBus] segdisp1
	);

	reg[`FlashAddrBusWord] addr_i;
	reg[`FlashDataBus] data_i;
	wire[`FlashDataBus] data_o;
	reg enable_read;
	reg enable_erase;
	reg enable_write;
	reg[31:0] pc;

	assign led = data_o;

	digseg_driver digseg0(data_o[3:0], segdisp0);
	digseg_driver digseg1(data_o[7:4], segdisp1);

	always @ (*) begin
		enable_read <= 1'b0;
		enable_erase <= 1'b0;
		enable_write <= 1'b0;
		if (sw_dip[31] == 1'b1) begin
			enable_read <= 1'b1;
			enable_erase <= 1'b0;
			enable_write <= 1'b0;
		end else if (sw_dip[30] == 1'b1) begin
			enable_read <= 1'b0;
			enable_erase <= 1'b1;
			enable_write <= 1'b0;
		end else if (sw_dip[29]) begin
			enable_read <= 1'b0;
			enable_erase <= 1'b0;
			enable_write <= 1'b1;	
		end
	end
	
	reg[4:0] counter;
	
	always @ (posedge clk) begin
		if (rst == 1'b0) begin
			pc <= 32'b0;
			counter <= 5'b0;
		end else if (enable_write == 1'b1) begin		//write
			if (counter[4] == 1'b1) begin
				counter <= 5'b0;			
				case (pc)
					`include "input.v"
					default: pc <= 32'h00000000;
				endcase
			end else begin
				counter <= counter + 1'b1;
			end
		end else if (enable_read == 1'b1) begin
			addr_i <= sw_dip[`FlashAddrBusWord];
		end else if (enable_erase == 1'b1) begin
			if (counter[4] == 1'b1) begin
				addr_i <= pc[`FlashAddrBusWord];
				pc <= pc + 1'b1;
				counter <= 5'b0;
			end else begin
				counter <= counter + 1'b1;
			end
		end
	end

	flash_driver flash0(
	.clk(clk),
	.addr(addr_i),
	.data_in(data_i),
	.data_out(data_o),

	.enable_read(enable_read),
	.enable_erase(enable_erase),
	.enable_write(enable_write),

	.flash_addr(flash_addr),
	.flash_data(flash_data),
	.flash_ctl(flash_ctl)
	);

endmodule

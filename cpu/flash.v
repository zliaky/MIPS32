`include "defines.v"
module flash (
	input clk,
	input rst,

	input [`WB_AddrBus] bus_addr_i,
	input [`WB_DataBus] bus_data_i,
	output [`WB_DataBus] bus_data_o,
	input bus_select_i,
	input bus_we_i,
	output bus_ack_o,

	output [`FlashAddrBus] flash_addr, 
	inout [`FlashDataBus] flash_data, 
	output [`FlashCtrlBus] flash_ctl
	);

	wire[`FlashDataBus] output_data;

	assign bus_data_o = {{16{1'b0}}, output_data};

	flash_driver flash_driver0(
		.clk(bus_clk_i), .addr(bus_addr_i[`FlashAddrBusWord]), .data_in(bus_data_i[`FlashDataBus]), 
		.data_out(output_data), .enable_erase(1'b0), 
		.enable_read(!bus_we_i), .enable_write(1'b0),
		.flash_ctl(flash_ctl), .flash_addr(flash_addr), .flash_data(flash_data), 
		.ack(bus_ack_o)
	);

endmodule

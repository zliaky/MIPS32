`include "defines.v"
module digseg(
	input clk,
	input rst,

	input [`WB_AddrBus] bus_addr_i,
	input [`WB_DataBus] bus_data_i,
	output [`WB_DataBus] bus_data_o,
	input bus_select_i,
	input bus_we_i,
	output bus_ack_o,

	output [`DigSegDataBus] seg0,
	output [`DigSegDataBus] seg1
	);

	wire ack1, ack0;
	assign bus_ack_o = ack1 & ack0;

	digseg_driver digseg_driver0(
		bus_data_i[`DigSegAddrBus], seg0, 
		ack0, bus_select_i, bus_we_i
	);

	digseg_driver digseg_driver1(
		bus_data_i[7:4], seg1,
		ack1, bus_select_i, bus_we_i
	);

	assign bus_data_o = {18'b0, seg1, seg0};

endmodule

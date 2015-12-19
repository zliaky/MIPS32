`include "defines.v"
module rom(
	input clk,
	input rst,

	input [`WB_AddrBus] bus_addr_i,
	input [`WB_DataBus] bus_data_i,
	output [`WB_DataBus] bus_data_o,
	input bus_select_i,
	input bus_we_i,
	output bus_ack_o
	);

	rom_driver rom_driver0(
		bus_select_i, {2'b00, bus_addr_i[11:2]}, 
		bus_data_o, bus_ack_o
	);

endmodule

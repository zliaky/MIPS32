`include "defines.v"
module ram (
	input clk,
	input rst,

	input [`WB_AddrBus] bus_addr_i,
	input [`WB_DataBus] bus_data_i,
	output [`WB_DataBus] bus_data_o,
	input bus_select_i,
	input bus_we_i,
	output bus_ack_o,

	output [`DataMemNumLog2-2:0] baseram_addr,
	inout [`DataBus] baseram_data,
	output baseram_ce,
	output baseram_oe,
	output baseram_we,

	output [`DataMemNumLog2-2:0] extram_addr,
	inout [`DataBus] extram_data,
	output extram_ce,
	output extram_oe,
	output extram_we
	);

	ram_driver ram_driver0(
		clk, rst, 
		bus_select_i, !bus_we_i, bus_we_i, 
		{bus_addr_i[`DataMemNumLog2-2], bus_addr_i[`DataMemNumLog2-2:0]}, bus_data_i, bus_data_o,
		baseram_addr, baseram_data, 
		baseram_ce, baseram_oe, baseram_we, 
		extram_addr, extram_data, 
		extram_ce, extram_oe, extram_we, bus_ack_o
	);

endmodule

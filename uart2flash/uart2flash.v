`include "defines.v"

module uart2flash(
	input clk,
	input rst,

	// input [31:0] sw_dip,
	output [15:0] led,

	output 		[22:0] 				flash_addr, 
	inout 		[15:0] 				flash_data, 
	output 		[7:0] 				flash_ctl,

	output 		 					com_TxD, 
	input 							com_RxD, 

	output 		[0:6] 				segdisp0,
	output 		[0:6]				segdisp1
	);

	wire [`WB_AddrBus] flash_addr_i;
	wire [`WB_AddrBus] flash_data_i;
	wire [`WB_DataBus] flash_data_o;
	wire flash_ack_o;
	wire [7:0] state_o;
	wire [`WB_AddrBus] uart_addr_i;
	wire [`WB_DataBus] uart_data_i;
	wire [`WB_DataBus] uart_data_o;
	wire uart_ack_o;
	wire [3:0] state;
	wire tick;

	assign flash_addr_i = uart_data_o;
	assign led = uart_data_o[15:0];

	digseg_driver digseg0(uart_data_o[3:0], segdisp0);
	digseg_driver digseg1(uart_data_o[7:4], segdisp1);

	flash flash0(
	.clk(clk),
	.rst(rst),
	.bus_addr_i(flash_addr_i),
	.bus_data_i(flash_data_i),
	.bus_data_o(flash_data_o),
	.bus_select_i(uart_ack_o),
	.bus_we_i(1'b1),
	.bus_ack_o(flash_ack_o),
	.flash_addr(flash_addr), 
	.flash_data(flash_data), 
	.flash_ctl(flash_ctl),
	.state_o(state_o)
	);

	uart uart0(
	.clk(clk),
	.rst(rst),
	.bus_addr_i(uart_addr_i),
	.bus_data_i(uart_data_i),
	.bus_data_o(uart_data_o),
	.bus_select_i(1'b1),
	.bus_we_i(1'b0),
	.bus_ack_o(uart_ack_o),
	.com_TxD(com_TxD),
	.com_RxD(com_RxD),
	.TxD_state(state),
	.tick(tick)
	);
	
endmodule

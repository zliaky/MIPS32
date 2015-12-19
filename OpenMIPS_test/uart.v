`include "defines.v"
module uart(
	input clk,
	input rst,

	input [`WB_AddrBus] bus_addr_i,
	input [`WB_DataBus] bus_data_i,
	output [`WB_DataBus] bus_data_o,
	input bus_select_i,
	input bus_we_i,
	output bus_ack_o,

	output com_TxD,
	input com_RxD
	);

	localparam CLK_FREQ = 50000000,	// 50 MB
			BAUD = 115200;

	wire [`UartDataBus] data_in;
	wire [`UartDataBus] data_out;
	wire ack_in;
	wire ack_out;

	assign data_in = bus_data_i[`UartDataBus];
	assign bus_data_o = {{24{1'b0}}, data_out};
	assign bus_ack_o = (bus_we_i == `WriteEnable) ? ack_in : ack_out;

	uart_driver_transmitter #(.ClkFrequency(CLK_FREQ), .Baud(BAUD)) u0
	(.clk(clk), .TxD_start(bus_we_i & bus_select_i), .TxD_data(data_in),
	.TxD(com_TxD), .TxD_busy(), .ack(ack_in));

	uart_driver_receiver #(.ClkFrequency(CLK_FREQ), .Baud(BAUD)) u1
	(.clk(clk), .rst(!rst), .RxD(com_RxD),
	.RxD_data_ready(), .RxD_waiting_data(),
	.RxD_data(data_out), .ack(ack_out));

endmodule

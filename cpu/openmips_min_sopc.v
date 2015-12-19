`include "defines.v"
module openmips_min_sopc(
	input							clk,
	input							rst
	
	);

	wire[5:0]				int;
	wire					timer_int;

	wire[`RegBus]			wishbone_data_o;
	wire					wishbone_ack_i;
	wire[`RegBus]			wishbone_addr_o;
	wire[`RegBus]			wishbone_data_i;
	wire					wishbone_we_o;
	wire[15:0]				wishbone_select_o;
	wire					wishbone_stb_o;
	wire					wishbone_cyc_o;

	assign int = {5'b00000, timer_int};		//时钟中断作为一个中断输入

	//例化处理器OpenMIPS
	openmips openmips0(
		.clk(clk),
		.rst(rst),
		.int_i(int),						//中断输入

		.wishbone_data_i(wishbone_data_i),
		.wishbone_ack_i(wishbone_ack_i),
		.wishbone_addr_o(wishbone_addr_o),
		.wishbone_data_o(wishbone_data_o),
		.wishbone_we_o(wishbone_we_o),
		.wishbone_select_o(wishbone_select_o),

		.timer_int_o(timer_int)				//时钟中断输出
	);

	//例化总线部分
	data_ram data_ram0(
		.clk(clk),
		.rst(rst),
		.ce(wishbone_select_o[0]),
		.we(wishbone_we_o),
		.addr(wishbone_addr_o),
		.data_i(wishbone_data_o),
		.data_o(wishbone_data_i),
		.ack(wishbone_ack_i)
	);

endmodule

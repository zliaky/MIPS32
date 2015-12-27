`include "defines.v"
module openmips_min_sopc(
	input							clk,
	input							rst,
	input							clk_key,

	//RAM
	output		[19:0]				baseram_addr,
	inout		[31:0]				baseram_data,
	output							baseram_ce,
	output							baseram_oe,
	output							baseram_we,
	output		[19:0]				extram_addr,
	inout		[31:0]				extram_data,
	output							extram_ce,
	output							extram_oe,
	output							extram_we,

	//FLASH
	output		[22:0]				flash_addr,
	inout		[15:0]				flash_data,
	output		[7:0]				flash_ctl,

	//VGA

	//UART
	output							com_TxD,
	input							com_RxD,

	//segdisp
	output		[0:6]				segdisp0,
	output		[0:6]				segdisp1,

	input		[31:0]				select,
	output		reg[31:0]			data_o
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
	reg clk_4;
	reg counter = 0;
	always @ (posedge clk) begin
		if (counter == 1'b1) begin
			clk_4 <= ~clk_4;
			counter <= 1'b0;
		end else counter <= counter + 1'b1;
	end


	wire[31:0] output_data;
	reg clk_tmp;

	wire [7:0] state_o;
	wire [3:0] TxD_state;
	wire tick;
	reg break_flag;

	always @ (*) begin
		break_flag <= `False_v;
		if (select[6] == 1'b1) begin
			break_flag <= `True_v;
		end
		if (select[31] == 1'b1) begin
			clk_tmp <= clk_key;
			if (select[7] == 1'b1) begin
				data_o <= wishbone_data_i;
			end else if (select[8] == 1'b1) begin
				data_o <= {31'b0, wishbone_ack_i};
			end else if (select[9] == 1'b1) begin
				data_o <= wishbone_data_o;
			end else if (select[10] == 1'b1) begin
				data_o <= wishbone_addr_o;
			end else if (select[11] == 1'b1) begin
				data_o <= {16'b0, wishbone_select_o};
			end else if (select[12] == 1'b1) begin
				data_o <= {31'b0, rst};
			end else if (select[13] == 1'b1) begin
				data_o <= {24'b0, state_o};
			end else if (select[14] == 1'b1) begin
				data_o <= {28'b0, TxD_state};
			end else if (select[15] == 1'b1) begin
				data_o <= {31'b0, tick};
			end else begin
				if (select[16] == 1'b1) begin
					data_o <= {16'b0, output_data[15:0]};
				end else begin
					data_o <= {16'b0, output_data[31:16]};
				end
			end
		end else begin
			clk_tmp <= clk_4;
		end
	end

	//例化处理器OpenMIPS
	openmips openmips0(
		.clk(clk_tmp),
		.rst(rst),
		.int_i(int),						//中断输入

		.wishbone_data_i(wishbone_data_i),
		.wishbone_ack_i(wishbone_ack_i),
		.wishbone_addr_o(wishbone_addr_o),
		.wishbone_data_o(wishbone_data_o),
		.wishbone_we_o(wishbone_we_o),
		.wishbone_select_o(wishbone_select_o),

		.timer_int_o(timer_int),				//时钟中断输出
		.select(select),
		.data_o(output_data),
		.break_flag(break_flag)
	);

	//例化总线部分
	bus_top bus_top0(
		.clk(clk_tmp),
		.clk_uart(clk),
		.rst(rst),
		.wishbone_addr_i(wishbone_addr_o),
		.wishbone_data_i(wishbone_data_o),
		.wishbone_we_i(wishbone_we_o),
		.wishbone_select_i(wishbone_select_o),
		.wishbone_data_o(wishbone_data_i),
		.wishbone_ack_o(wishbone_ack_i),
		.ram_baseram_addr(baseram_addr),
		.ram_baseram_data(baseram_data),
		.ram_baseram_ce(baseram_ce),
		.ram_baseram_oe(baseram_oe),
		.ram_baseram_we(baseram_we),
		.ram_extram_addr(extram_addr),
		.ram_extram_data(extram_data),
		.ram_extram_ce(extram_ce),
		.ram_extram_oe(extram_oe),
		.ram_extram_we(extram_we),
		.flash_addr(flash_addr),
		.flash_data(flash_data),
		.flash_ctl(flash_ctl),
		.uart_com_TxD(com_TxD),
		.uart_com_RxD(com_RxD),
		.digseg_seg0(segdisp0),
		.digseg_seg1(segdisp1),
		.state_o(state_o),
		.TxD_state(TxD_state),
		.tick(tick)
	);

endmodule

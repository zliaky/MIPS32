module cpu_top(
	input clk,
	input rst,
	input clk_key,
	input [31:0] sw_dip,
	output reg[15:0] led,

	output 		[19:0] 				baseram_addr, 
	inout 		[31:0] 				baseram_data, 
	output 		 					baseram_ce, 
	output 		 					baseram_oe, 
	output 		 					baseram_we, 
	output 		[19:0] 				extram_addr, 
	inout 		[31:0] 				extram_data, 
	output 		 					extram_ce, 
	output 		 					extram_oe, 
	output 		 					extram_we, 

	output 		[22:0] 				flash_addr, 
	inout 		[15:0] 				flash_data, 
	output 		[7:0] 				flash_ctl,

	output 		 					com_TxD, 
	input 							com_RxD, 

	output 		[0:6] 				segdisp0,
	output 		[0:6]				segdisp1
	);

	wire[31:0] select;
	wire[31:0] regfile_data_o;

	assign select = sw_dip;

	always @ (posedge clk) begin
		led <= regfile_data_o[15:0];
	end

	openmips_min_sopc sopc(
	.clk(clk),
	.rst(!rst),
	.clk_key(clk_key),
	.baseram_addr(baseram_addr),
	.baseram_data(baseram_data),
	.baseram_ce(baseram_ce),
	.baseram_oe(baseram_oe),
	.baseram_we(baseram_we),
	.extram_addr(extram_addr),
	.extram_data(extram_data),
	.extram_ce(extram_ce),
	.extram_oe(extram_oe),
	.extram_we(extram_we),
	.flash_addr(flash_addr),
	.flash_data(flash_data),
	.flash_ctl(flash_ctl),
	.com_TxD(com_TxD),
	.com_RxD(com_RxD),
	.segdisp0(segdisp0),
	.segdisp1(segdisp1),
	.select(select),
	.data_o(regfile_data_o)
	);

endmodule

`include "defines.v"
module mmu(
	input		wire					clk,
	input		wire					rst,

	//TLB模块的接口
	input		wire[`RegBus]			tlb_addr_i,

	output		reg[`RegBus]			mmu_addr_o,
	output		reg[15:0]				mmu_select_o
	);

	/*********************		第一段：物理地址划分		*********************/
	always @ (*) begin
		if (rst == `RstEnable) begin
			mmu_select_o <= `WB_SELECT_ZERO;
		end else begin
			mmu_addr_o <= tlb_addr_i;
			if ((tlb_addr_i >= 32'h00000000) && (tlb_addr_i <= 32'h007fffff)) begin
				mmu_select_o <= `WB_SELECT_RAM;
			end else if ((tlb_addr_i >= 32'h1fc00000) && (tlb_addr_i <= 32'h1fc00fff)) begin
				mmu_select_o <= `WB_SELECT_ROM;
			end else if ((tlb_addr_i >= 32'h1e000000) && (tlb_addr_i <= 32'h1effffff)) begin
				mmu_select_o <= `WB_SELECT_FLASH;
			end else if ((tlb_addr_i >= 32'h1a000000) && (tlb_addr_i <= 32'h1a096000)) begin
				mmu_select_o <= `WB_SELECT_FLASH;
			end else if (tlb_addr_i == 32'h1fd003f8) begin
				mmu_select_o <= `WB_SELECT_UART;
			end else if (tlb_addr_i == 32'h1fd003fc) begin
				mmu_select_o <= `WB_SELECT_UART_STAT;
			end else if (tlb_addr_i == 32'h1fd00400) begin
				mmu_select_o <= `WB_SELECT_DIGSEG;
			end else if (tlb_addr_i == 32'h0f000000) begin
				mmu_select_o <= `WB_SELECT_PS2;
			end else begin
				mmu_select_o <= `WB_SELECT_ZERO;
			end
		end
	end

endmodule

`include "defines.v"
module mem_wb(
	input		wire					clk,
	input		wire					rst,
	input		wire[5:0]				stall,
	input		wire					flush,

	//访存阶段的结果
	input		wire[`RegAddrBus]		mem_wd,
	input		wire					mem_wreg,
	input		wire[`RegBus]			mem_wdata,
	input		wire[`RegBus]			mem_hi,
	input		wire[`RegBus]			mem_lo,
	input		wire					mem_whilo,

	input		wire					mem_cp0_reg_we,
	input		wire[4:0]				mem_cp0_reg_write_addr,
	input		wire[`RegBus]			mem_cp0_reg_data,

	//送到回写阶段的信息
	output		reg[`RegAddrBus]		wb_wd,
	output		reg						wb_wreg,
	output		reg[`RegBus]			wb_wdata,
	output		reg[`RegBus]			wb_hi,
	output		reg[`RegBus]			wb_lo,
	output		reg						wb_whilo,
	output		reg						wb_cp0_reg_we,
	output		reg[4:0]				wb_cp0_reg_write_addr,
	output		reg[`RegBus]			wb_cp0_reg_data
	);

	//（1）当stall[4]为Stop，stall[5]为NoStop时，表示访存阶段暂停，而写回阶段继续，所以使用空指令作为下一个周期进入回写阶段的指令
	//（2）当stall[4]为NoStop时，访存阶段继续，访存后的指令进入回写阶段
	//（3）其余情况下，保持回写阶段的寄存器wb_wd、wb_wreg、wb_data、wb_hi、wb_lo、wb_whilo不变
	always @ (posedge clk) begin
		if (rst == `RstEnable) begin
			wb_wd <= `NOPRegAddr;
			wb_wreg <= `WriteDisable;
			wb_wdata <= `ZeroWord;
			wb_hi <= `ZeroWord;
			wb_lo <= `ZeroWord;
			wb_whilo <= `WriteDisable;
			wb_cp0_reg_we <= `WriteDisable;
			wb_cp0_reg_write_addr <= 5'b00000;
			wb_cp0_reg_data <= `ZeroWord;
		end else if (flush == 1'b1) begin							//清除流水线
			wb_wd <= `NOPRegAddr;
			wb_wreg <= `WriteDisable;
			wb_wdata <= `ZeroWord;
			wb_hi <= `ZeroWord;
			wb_lo <= `ZeroWord;
			wb_whilo <= `WriteDisable;
			wb_cp0_reg_we <= `WriteDisable;
			wb_cp0_reg_write_addr <= 5'b00000;
			wb_cp0_reg_data <= `ZeroWord;
		end else if (stall[4] == `Stop && stall[5] == `NoStop) begin
			wb_wd <= `NOPRegAddr;
			wb_wreg <= `WriteDisable;
			wb_wdata <= `ZeroWord;
			wb_hi <= `ZeroWord;
			wb_lo <= `ZeroWord;
			wb_whilo <= `WriteDisable;
			wb_cp0_reg_we <= `WriteDisable;
			wb_cp0_reg_write_addr <= 5'b00000;
			wb_cp0_reg_data <= `ZeroWord;
		end else if (stall[4] == `NoStop) begin
			wb_wd <= mem_wd;
			wb_wreg <= mem_wreg;
			wb_wdata <= mem_wdata;
			wb_hi <= mem_hi;
			wb_lo <= mem_lo;
			wb_whilo <= mem_whilo;
			wb_cp0_reg_we <= mem_cp0_reg_we;
			wb_cp0_reg_write_addr <= mem_cp0_reg_write_addr;
			wb_cp0_reg_data <= mem_cp0_reg_data;
		end
	end

endmodule

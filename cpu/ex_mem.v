`include "defines.v"
module ex_mem(
	input		wire					clk,
	input		wire					rst,
	input		wire[5:0]				stall,
	input		wire					flush,

	//来自执行阶段的信息
	input		wire[`RegAddrBus]		ex_wd,
	input		wire					ex_wreg,
	input		wire[`RegBus]			ex_wdata,
	input		wire[`RegBus]			ex_hi,
	input		wire[`RegBus]			ex_lo,
	input		wire					ex_whilo,

	//为实现加载、存储指令而添加的输入接口
	input		wire[`AluOpBus]			ex_aluop,
	input		wire[`RegBus]			ex_mem_addr,
	input		wire[`RegBus]			ex_reg2,

	input		wire					ex_cp0_reg_we,
	input		wire[4:0]				ex_cp0_reg_write_addr,
	input		wire[`RegBus]			ex_cp0_reg_data,

	input		wire[31:0]				ex_excepttype,
	input		wire					ex_is_in_delayslot,
	input		wire[`RegBus]			ex_current_inst_address,

	//送到访存阶段的信息
	output		reg[`RegAddrBus]		mem_wd,
	output		reg						mem_wreg,
	output		reg[`RegBus]			mem_wdata,
	output		reg[`RegBus]			mem_hi,
	output		reg[`RegBus]			mem_lo,
	output		reg						mem_whilo,

	//为实现加载、存储指令而添加的输出接口
	output		reg[`AluOpBus]			mem_aluop,
	output		reg[`RegBus]			mem_mem_addr,
	output		reg[`RegBus]			mem_reg2,

	output		reg						mem_cp0_reg_we,
	output		reg[4:0]				mem_cp0_reg_write_addr,
	output		reg[`RegBus]			mem_cp0_reg_data,

	output		reg[31:0]				mem_excepttype,
	output		reg						mem_is_in_delayslot,
	output		reg[`RegBus]			mem_current_inst_address
	);

	//（1）当stall[3]为Stop，stall[4]为NoStop时，表示执行阶段暂停，而访存阶段继续，所以使用空指令作为下一个周期进入访存阶段的指令
	//（2）当stall[3]为NoStop时，执行阶段继续，执行后的指令进入访存阶段
	//（3）其余情况下，保持访存阶段的寄存器mem_wb、mem_wreg、mem_wdata、mem_hi、mem_lo、mem_whilo不变
	always @ (posedge clk) begin
		if (rst == `RstEnable) begin
			mem_wd <= `NOPRegAddr;
			mem_wreg <= `WriteDisable;
			mem_wdata <= `ZeroWord;
			mem_hi <= `ZeroWord;
			mem_lo <= `ZeroWord;
			mem_whilo <= `WriteDisable;
			mem_aluop <= `EXE_NOP_OP;
			mem_mem_addr <= `ZeroWord;
			mem_reg2 <= `ZeroWord;
			mem_cp0_reg_we <= `WriteDisable;
			mem_cp0_reg_write_addr <= 5'b00000;
			mem_cp0_reg_data <= `ZeroWord;
			mem_excepttype <= `ZeroWord;
			mem_is_in_delayslot <= `NotInDelaySlot;
			mem_current_inst_address <= `ZeroWord;
		end else if (flush == 1'b1) begin									//清除流水线
			mem_wd <= `NOPRegAddr;
			mem_wreg <= `WriteDisable;
			mem_wdata <= `ZeroWord;
			mem_hi <= `ZeroWord;
			mem_lo <= `ZeroWord;
			mem_whilo <= `WriteDisable;
			mem_aluop <= `EXE_NOP_OP;
			mem_mem_addr <= `ZeroWord;
			mem_reg2 <= `ZeroWord;
			mem_cp0_reg_we <= `WriteDisable;
			mem_cp0_reg_write_addr <= 5'b00000;
			mem_cp0_reg_data <= `ZeroWord;
			mem_excepttype <= `ZeroWord;
			mem_is_in_delayslot <= `NotInDelaySlot;
			mem_current_inst_address <= `ZeroWord;
		end else if (stall[3] == `Stop && stall[4] == `NoStop) begin		//执行阶段暂停，访存阶段没有暂停
			mem_wd <= `NOPRegAddr;
			mem_wreg <= `WriteDisable;
			mem_wdata <= `ZeroWord;
			mem_hi <= `ZeroWord;
			mem_lo <= `ZeroWord;
			mem_whilo <= `WriteDisable;
			mem_aluop <= `EXE_NOP_OP;
			mem_mem_addr <= `ZeroWord;
			mem_reg2 <= `ZeroWord;
			mem_cp0_reg_we <= `WriteDisable;
			mem_cp0_reg_write_addr <= 5'b00000;
			mem_cp0_reg_data <= `ZeroWord;
			mem_excepttype <= `ZeroWord;
			mem_is_in_delayslot <= `NotInDelaySlot;
			mem_current_inst_address <= `ZeroWord;
		end else if (stall[3] == `NoStop) begin								//执行阶段没有暂停
			mem_wd <= ex_wd;
			mem_wreg <= ex_wreg;
			mem_wdata <= ex_wdata;
			mem_hi <= ex_hi;
			mem_lo <= ex_lo;
			mem_whilo <= ex_whilo;
			mem_aluop <= ex_aluop;
			mem_mem_addr <= ex_mem_addr;
			mem_reg2 <= ex_reg2;
			mem_cp0_reg_we <= ex_cp0_reg_we;
			mem_cp0_reg_write_addr <= ex_cp0_reg_write_addr;
			mem_cp0_reg_data <= ex_cp0_reg_data;
			mem_excepttype <= ex_excepttype;
			mem_is_in_delayslot <= ex_is_in_delayslot;
			mem_current_inst_address <= ex_current_inst_address;
		end
	end

endmodule

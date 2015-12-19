`include "defines.v"
module id_ex(
	input		wire					clk,
	input		wire					rst,
	input		wire[5:0]				stall,
	input		wire					flush,

	//从译码阶段传递过来的信息
	input		wire[`AluOpBus]			id_aluop,
	input		wire[`AluSelBus]		id_alusel,
	input		wire[`RegBus]			id_reg1,
	input		wire[`RegBus]			id_reg2,
	input		wire[`RegAddrBus]		id_wd,
	input		wire					id_wreg,
	input		wire[`RegBus]			id_link_address,
	input		wire					id_is_in_delayslot,
	input		wire					next_inst_in_delayslot_i,
	input		wire[`RegBus]			id_inst,
	input		wire[`RegBus]			id_current_inst_address,
	input		wire[31:0]				id_excepttype,
	
	//传递到执行阶段的信息
	output		reg[`AluOpBus]			ex_aluop,
	output		reg[`AluSelBus]			ex_alusel,
	output		reg[`RegBus]			ex_reg1,
	output		reg[`RegBus]			ex_reg2,
	output		reg[`RegAddrBus]		ex_wd,
	output		reg						ex_wreg,
	output		reg[`RegBus]			ex_link_address,
	output		reg						ex_is_in_delayslot,
	output		reg						is_in_delayslot_o,
	output		reg[`RegBus]			ex_inst,
	output		reg[`RegBus]			ex_current_inst_address,
	output		reg[31:0]				ex_excepttype
	);

	//（1）当stall[2]为Stop，stall[3]为NoStop时，表示译码阶段暂停，而执行阶段继续，所以使用空指令作为下一个周期进入执行阶段的指令
	//（2）当stall[2]为NoStop时，译码阶段继续，译码后的指令进入执行阶段
	//（3）其余情况下，保持执行阶段的寄存器为ex_aluop、ex_alusel、ex_reg1、ex_reg2、ex_wd、ex_wreg不变
	always @ (posedge clk) begin
		if (rst == `RstEnable) begin
			ex_aluop <= `EXE_NOP_OP;
			ex_alusel <= `EXE_RES_NOP;
			ex_reg1 <= `ZeroWord;
			ex_reg2 <= `ZeroWord;
			ex_wd <= `NOPRegAddr;
			ex_wreg <= `WriteDisable;
			ex_link_address <= `ZeroWord;
			ex_is_in_delayslot <= `NotInDelaySlot;
			is_in_delayslot_o <= `NotInDelaySlot;
			ex_inst <= `ZeroWord;
			ex_excepttype <= `ZeroWord;
			ex_current_inst_address <= `ZeroWord;
		end else if (flush == 1'b1) begin									//清除流水线
			ex_aluop <= `EXE_NOP_OP;
			ex_alusel <= `EXE_RES_NOP;
			ex_reg1 <= `ZeroWord;
			ex_reg2 <= `ZeroWord;
			ex_wd <= `NOPRegAddr;
			ex_wreg <= `WriteDisable;
			ex_excepttype <= `ZeroWord;
			ex_link_address <= `ZeroWord;
			ex_inst <= `ZeroWord;
			ex_is_in_delayslot <= `NotInDelaySlot;
			is_in_delayslot_o <= `NotInDelaySlot;
			ex_current_inst_address <= `ZeroWord;
		end else if (stall[2] == `Stop && stall[3] == `NoStop) begin		//译码阶段暂停，执行阶段没有暂停
			ex_aluop <= `EXE_NOP_OP;
			ex_alusel <= `EXE_RES_NOP;
			ex_reg1 <= `ZeroWord;
			ex_reg2 <= `ZeroWord;
			ex_wd <= `NOPRegAddr;
			ex_wreg <= `WriteDisable;
			ex_link_address <= `ZeroWord;
			ex_is_in_delayslot <= `NotInDelaySlot;
			ex_inst <= `ZeroWord;
			ex_excepttype <= `ZeroWord;
			ex_current_inst_address <= `ZeroWord;
		end else if (stall[2] == `NoStop) begin								//译码阶段没有暂停
			ex_aluop <= id_aluop;
			ex_alusel <= id_alusel;
			ex_reg1 <= id_reg1;
			ex_reg2 <= id_reg2;
			ex_wd <= id_wd;
			ex_wreg <= id_wreg;
			ex_link_address <= id_link_address;
			ex_is_in_delayslot <= id_is_in_delayslot;
			is_in_delayslot_o <= next_inst_in_delayslot_i;
			//在译码阶段没有暂停的情况下，直接将ID模块的输入通过接口ex_inst输出
			ex_inst <= id_inst;
			ex_excepttype <= id_excepttype;
			ex_current_inst_address <= id_current_inst_address;
		end
	end

endmodule

`include "defines.v"
module id(
	input		wire					rst,
	input		wire[`InstAddrBus]		pc_i,
	input		wire[`InstBus]			inst_i,

	input		wire[`AluOpBus]			ex_aluop_i,

	//读取的Regfile的值
	input		wire[`RegBus]			reg1_data_i,
	input		wire[`RegBus]			reg2_data_i,

	//处于执行阶段的指令的运算结果
	input		wire					ex_wreg_i,
	input		wire[`RegBus]			ex_wdata_i,
	input		wire[`RegAddrBus]		ex_wd_i,

	//处于访存阶段的指令的运算结果
	input		wire					mem_wreg_i,
	input		wire[`RegBus]			mem_wdata_i,
	input		wire[`RegAddrBus]		mem_wd_i,

	//如果上一条指令是转移指令，那么下一条指令进入译码阶段的时候，输入变量is_in_delayslot_i为true，表示是延迟槽指令，反之为false
	input		wire					is_in_delayslot_i,

	//输出到Regfile的信息
	output		reg						reg1_read_o,
	output		reg						reg2_read_o,
	output		reg[`RegAddrBus]		reg1_addr_o,
	output		reg[`RegAddrBus]		reg2_addr_o,

	//送到执行阶段的信息
	output		reg[`AluOpBus]			aluop_o,
	output		reg[`AluSelBus]			alusel_o,

	//送到执行阶段的源操作数1、源操作数2
	output		reg[`RegBus]			reg1_o,
	output		reg[`RegBus]			reg2_o,
	output		reg[`RegAddrBus]		wd_o,
	output		reg						wreg_o,

	output		wire[`RegBus]			inst_o,

	output		reg						next_inst_in_delayslot_o,

	output		reg						branch_flag_o,
	output		reg[`RegBus]			branch_target_address_o,
	output		reg[`RegBus]			link_addr_o,
	output		reg						is_in_delayslot_o,

	output		wire[31:0]				excepttype_o,
	output		wire[`RegBus]			current_inst_address_o,

	output		wire					stallreq
	);

	//取得指令的指令码，功能码
	wire[5:0] op = inst_i[31:26];
	wire[4:0] op2 = inst_i[10:6];
	wire[5:0] op3 = inst_i[5:0];
	wire[4:0] op4 = inst_i[20:16];

	//保存指令执行需要的立即数
	reg[`RegBus] imm;

	//指示指令是否有效
	reg instvalid;

	wire[`RegBus] pc_plus_8;
	wire[`RegBus] pc_plus_4;

	wire[`RegBus] imm_sll2_signedext;

	//要读取的寄存器1是否与上一条指令存在load相关
	reg stallreq_for_reg1_loadrelate;

	//要读取的寄存器2是否与上一条指令在load相关
	reg stallreq_for_reg2_loadrelate;

	//上一条指令是否是加载指令
	wire pre_inst_is_load;

	reg excepttype_is_syscall;			//是否是系统调用异常SYSCALL
	reg excepttype_is_eret;				//是否是异常返回指令eret
	reg excepttype_is_cpu;				//是否是访问不存在的协处理器异常CpU
	reg[4:0] cp0_reg_addr;

	assign pc_plus_8 = pc_i + 8;		//保存当前译码阶段指令后面第二条指令的地址
	assign pc_plus_4 = pc_i + 4;		//保存当前译码阶段指令后面紧接着的指令的地址

	//imm_sll2_signedext对应分支指令中的offset左移两位，再符号扩展至32位的值
	assign imm_sll2_signedext = {{14{inst_i[15]}}, inst_i[15:0], 2'b00};  

	//stallreq_for_reg1_loadrelate为Stop或者stallreq_for_reg2_loadrelate为Stop，都表示存在load相关，
	//从而要求流水线暂停，设置stallreq为top
	assign stallreq = stallreq_for_reg1_loadrelate | stallreq_for_reg2_loadrelate;

	//依据输入信号ex_aluop_i的值，判断上一条指令是否是加载指令，如果是加载指令，那么置pre_inst_is_load为1，反之置为0
	assign pre_inst_is_load = ((ex_aluop_i == `EXE_LB_OP) ||
								(ex_aluop_i == `EXE_LBU_OP)||
								(ex_aluop_i == `EXE_LH_OP) ||
								(ex_aluop_i == `EXE_LHU_OP)||
								(ex_aluop_i == `EXE_LW_OP) ||
								(ex_aluop_i == `EXE_LWR_OP)||
								(ex_aluop_i == `EXE_LWL_OP)||
								(ex_aluop_i == `EXE_LL_OP) ||
								(ex_aluop_i == `EXE_SC_OP)) ? 1'b1 : 1'b0;

	assign inst_o = inst_i;

	//excepttype_o的第8bit表示是否是syscall指令引起的系统调用异常，第10bit表示是否是无效指令引起的异常，第11bit表示是否是访问不存在的协处理器引起的异常，第12bit表示是否是eret指令，
	//eret指令可以认为是一种特殊的异常（返回异常）
	assign excepttype_o = {19'b0, excepttype_is_eret, excepttype_is_cpu, instvalid, 1'b0, excepttype_is_syscall, 8'b0};

	//输入信号pc_i就是当前处于译码阶段的指令的地址
	assign current_inst_address_o = pc_i;

/************				第一段：对指令进行译码				************/
	always @ (*) begin
		if (rst == `RstEnable) begin
			aluop_o <= `EXE_NOP_OP;
			alusel_o <= `EXE_RES_NOP;
			wd_o <= `NOPRegAddr;
			wreg_o <= `WriteDisable;
			instvalid <= `InstValid;
			reg1_read_o <= 1'b0;
			reg2_read_o <= 1'b0;
			reg1_addr_o <= `NOPRegAddr;
			reg2_addr_o <= `NOPRegAddr;
			imm <= 32'h0;
			link_addr_o <= `ZeroWord;
			branch_target_address_o <= `ZeroWord;
			branch_flag_o <= `NotBranch;
			next_inst_in_delayslot_o <= `NotInDelaySlot;
			excepttype_is_syscall <= `False_v;
			excepttype_is_eret <= `False_v;
			excepttype_is_cpu <= `False_v;
			cp0_reg_addr <= 5'b00000;
		end else begin
			aluop_o <= `EXE_NOP_OP;
			alusel_o <= `EXE_RES_NOP;
			wd_o <= inst_i[15:11];
			wreg_o <= `WriteDisable;
			instvalid <= `InstInvalid;
			reg1_read_o <= 1'b0;
			reg2_read_o <= 1'b0;
			reg1_addr_o <= inst_i[25:21];		//默认通过Regfile读端口1读取的寄存器地址
			reg2_addr_o <= inst_i[20:16];		//默认通过Regfile读端口2读取的寄存器地址
			imm <= `ZeroWord;
			link_addr_o <= `ZeroWord;
			branch_target_address_o <= `ZeroWord;
			branch_flag_o <= `NotBranch;
			next_inst_in_delayslot_o <= `NotInDelaySlot;
			excepttype_is_syscall <= `False_v;	//默认没有系统调用异常
			excepttype_is_eret <= `False_v;		//默认不是eret指令
			excepttype_is_cpu <= `False_v;		//默认没有访问不存在的协处理器异常
			cp0_reg_addr <= 5'b00000;
			
			case (op)
				`EXE_SPECIAL_INST: begin		//指令码是SPECIAL
					case (op2)
						5'b00000: begin				//依据功能码判断是哪种指令
							case (op3)
								`EXE_OR: begin			//or指令
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_OR_OP;
									alusel_o <= `EXE_RES_LOGIC;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instvalid <= `InstValid;
								end
								`EXE_AND: begin			//and指令
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_AND_OP;
									alusel_o <= `EXE_RES_LOGIC;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instvalid <= `InstValid;
								end
								`EXE_XOR: begin			//xor指令
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_XOR_OP;
									alusel_o <= `EXE_RES_LOGIC;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instvalid <= `InstValid;
								end
								`EXE_NOR: begin			//nor指令
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_NOR_OP;
									alusel_o <= `EXE_RES_LOGIC;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instvalid <= `InstValid;
								end
								`EXE_SLLV: begin		//sllv指令
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_SLL_OP;
									alusel_o <= `EXE_RES_SHIFT;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instvalid <= `InstValid;
								end
								`EXE_SRLV: begin		//slrv指令
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_SRL_OP;
									alusel_o <= `EXE_RES_SHIFT;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instvalid <= `InstValid;
								end
								`EXE_SRAV: begin		//srav指令
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_SRA_OP;
									alusel_o <= `EXE_RES_SHIFT;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instvalid <= `InstValid;
								end
								`EXE_MFHI: begin		//mfhi指令
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_MFHI_OP;
									alusel_o <= `EXE_RES_MOVE;
									reg1_read_o <= 1'b0;
									reg2_read_o <= 1'b0;
									instvalid <= `InstValid;
								end
								`EXE_MFLO: begin		//mflo指令
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_MFLO_OP;
									alusel_o <= `EXE_RES_MOVE;
									reg1_read_o <= 1'b0;
									reg2_read_o <= 1'b0;
									instvalid <= `InstValid;
								end
								`EXE_MTHI: begin		//mthi指令
									wreg_o <= `WriteDisable;
									aluop_o <= `EXE_MTHI_OP;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b0;
									instvalid <= `InstValid;
								end
								`EXE_MTLO: begin		//mtlo指令
									wreg_o <= `WriteDisable;
									aluop_o <= `EXE_MTLO_OP;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b0;
									instvalid <= `InstValid;
								end
								`EXE_MOVN: begin		//movn指令
									aluop_o <= `EXE_MOVN_OP;
									alusel_o <= `EXE_RES_MOVE;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instvalid <= `InstValid;
									//reg2_o的值就是地址为rt的通用寄存器的值
									if (reg2_o != `ZeroWord) begin
										wreg_o <= `WriteEnable;
									end else begin
										wreg_o <= `WriteDisable;
									end
								end
								`EXE_MOVZ: begin		//movz指令
									aluop_o <= `EXE_MOVZ_OP;
									alusel_o <= `EXE_RES_MOVE;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instvalid <= `InstValid;
									//reg2_o的值就是地址为rt的通用寄存器的值
									if (reg2_o == `ZeroWord) begin
										wreg_o <= `WriteEnable;
									end else begin
										wreg_o <= `WriteDisable;
									end
								end
								`EXE_SLT: begin			//slt指令
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_SLT_OP;
									alusel_o <= `EXE_RES_ARITHMETIC;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instvalid <= `InstValid;
								end
								`EXE_SLTU: begin		//sltu指令
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_SLTU_OP;
									alusel_o <= `EXE_RES_ARITHMETIC;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instvalid <= `InstValid;
								end
								`EXE_ADD: begin			//add指令
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_ADD_OP;
									alusel_o <= `EXE_RES_ARITHMETIC;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instvalid <= `InstValid;
								end
								`EXE_ADDU: begin		//addu指令
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_ADDU_OP;
									alusel_o <= `EXE_RES_ARITHMETIC;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instvalid <= `InstValid;
								end
								`EXE_SUB: begin			//sub指令
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_SUB_OP;
									alusel_o <= `EXE_RES_ARITHMETIC;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instvalid <= `InstValid;
								end
								`EXE_SUBU: begin		//subu指令
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_SUBU_OP;
									alusel_o <= `EXE_RES_ARITHMETIC;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instvalid <= `InstValid;
								end
								`EXE_MULT: begin		//mult指令
									wreg_o <= `WriteDisable;
									aluop_o <= `EXE_MULT_OP;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instvalid <= `InstValid;
								end
								`EXE_MULTU: begin		//multu指令
									wreg_o <= `WriteDisable;
									aluop_o <= `EXE_MULTU_OP;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instvalid <= `InstValid;
								end
								`EXE_JR: begin 			//jr
									wreg_o <= `WriteDisable;
									aluop_o <= `EXE_JR_OP;
									alusel_o <= `EXE_RES_JUMP_BRANCH;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b0;
									link_addr_o <= `ZeroWord;
									branch_target_address_o <= reg1_o;
									branch_flag_o <= `Branch;
									next_inst_in_delayslot_o <= `InDelaySlot;
									instvalid <= `InstValid;
								end
								`EXE_JALR: begin
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_JALR_OP;
									alusel_o <= `EXE_RES_JUMP_BRANCH;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b0;
									wd_o <= inst_i[15:11];
									link_addr_o <= pc_plus_8;
									branch_target_address_o <= reg1_o;
									branch_flag_o <= `Branch;
									next_inst_in_delayslot_o <= `InDelaySlot;
									instvalid <= `InstValid;
								end
								default: begin
								end
							endcase
						end
						default: begin
						end
					endcase
					case (op3)
						`EXE_SYSCALL: begin
							wreg_o <= `WriteDisable;
							aluop_o <= `EXE_SYSCALL_OP;
							alusel_o <= `EXE_RES_NOP;
							reg1_read_o <= 1'b0;
							reg2_read_o <= 1'b0;
							instvalid <= `InstValid;
							excepttype_is_syscall <= `True_v;
						end
						default: begin
						end
					endcase
				end
				`EXE_ORI: begin			//ori指令
					//ori指令需要将结果写入目的寄存器，所以wreg_o为WriteEnable
					wreg_o <= `WriteEnable;

					//运算的子类型是逻辑“或”运算
					aluop_o <= `EXE_OR_OP;

					//运算类型是逻辑运算
					alusel_o <= `EXE_RES_LOGIC;

					//需要通过Regfile的读端口1读取寄存器
					reg1_read_o <= 1'b1;

					//不需要通过Regfile的读端口2读取寄存器
					reg2_read_o <= 1'b0;

					//指令执行需要的立即数
					imm <= {16'h0, inst_i[15:0]};

					//指令执行要写的目的寄存器地址
					wd_o <= inst_i[20:16];

					//ori指令是有效指令
					instvalid <= `InstValid;
				end
				`EXE_ANDI: begin		//andi指令
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_AND_OP;
					alusel_o <= `EXE_RES_LOGIC;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b0;
					imm <= {16'h0, inst_i[15:0]};
					wd_o <= inst_i[20:16];
					instvalid <= `InstValid;
				end
				`EXE_XORI: begin		//xori指令
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_XOR_OP;
					alusel_o <= `EXE_RES_LOGIC;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b0;
					imm <= {16'h0, inst_i[15:0]};
					wd_o <= inst_i[20:16];
					instvalid <= `InstValid;
				end
				`EXE_LUI: begin			//lui指令
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_OR_OP;
					alusel_o <= `EXE_RES_LOGIC;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b0;
					imm <= {inst_i[15:0], 16'h0};
					wd_o <= inst_i[20:16];
					instvalid <= `InstValid;
				end
				`EXE_SLTI: begin		//slti指令
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_SLT_OP;
					alusel_o <= `EXE_RES_ARITHMETIC;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b0;
					imm <= {{16{inst_i[15]}}, inst_i[15:0]};
					wd_o <= inst_i[20:16];
					instvalid <= `InstValid;
				end
				`EXE_SLTIU: begin		//sltiu指令
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_SLTU_OP;
					alusel_o <= `EXE_RES_ARITHMETIC;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b0;
					imm <= {{16{inst_i[15]}}, inst_i[15:0]};
					wd_o <= inst_i[20:16];
					instvalid <= `InstValid;
				end
				`EXE_ADDI: begin		//addi指令
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_ADDI_OP;
					alusel_o <= `EXE_RES_ARITHMETIC;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b0;
					imm <= {{16{inst_i[15]}}, inst_i[15:0]};
					wd_o <= inst_i[20:16];
					instvalid <= `InstValid;
				end
				`EXE_ADDIU: begin		//addiu指令
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_ADDIU_OP;
					alusel_o <= `EXE_RES_ARITHMETIC;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b0;
					imm <= {{16{inst_i[15]}}, inst_i[15:0]};
					wd_o <= inst_i[20:16];
					instvalid <= `InstValid;
				end
				`EXE_J: begin
					wreg_o <= `WriteDisable;
					aluop_o <= `EXE_J_OP;
					alusel_o <= `EXE_RES_JUMP_BRANCH;
					reg1_read_o <= 1'b0;
					reg2_read_o <= 1'b0;
					link_addr_o <= `ZeroWord;
					branch_flag_o <= `Branch;
					next_inst_in_delayslot_o <= `InDelaySlot;
					instvalid <= `InstValid;
					branch_target_address_o <= {pc_plus_4[31:28], inst_i[25:0], 2'b00};
				end
				`EXE_JAL: begin
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_JAL_OP;
					alusel_o <= `EXE_RES_JUMP_BRANCH;
					reg1_read_o <= 1'b0;
					reg2_read_o <= 1'b0;
					wd_o <= 5'b11111;
					link_addr_o <= pc_plus_8;
					branch_flag_o <= `Branch;
					next_inst_in_delayslot_o <= `InDelaySlot;
					instvalid <= `InstValid;
					branch_target_address_o <= {pc_plus_4[31:28], inst_i[25:0], 2'b00};
				end
				`EXE_BEQ: begin
					wreg_o <= `WriteDisable;
					aluop_o <= `EXE_BEQ_OP;
					alusel_o <= `EXE_RES_JUMP_BRANCH;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b1;
					instvalid <= `InstValid;
					if (reg1_o == reg2_o) begin
						branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
						branch_flag_o <= `Branch;
						next_inst_in_delayslot_o <= `InDelaySlot;
					end
				end
				`EXE_BGTZ: begin
					wreg_o <= `WriteDisable;
					aluop_o <= `EXE_BGTZ_OP;
					alusel_o <= `EXE_RES_JUMP_BRANCH;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b0;
					instvalid <= `InstValid;
					if ((reg1_o[31] == 1'b0) && (reg1_o != `ZeroWord)) begin
						branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
						branch_flag_o <= `Branch;
						next_inst_in_delayslot_o <= `InDelaySlot;
					end
				end
				`EXE_BLEZ: begin
					wreg_o <= `WriteDisable;
					aluop_o <= `EXE_BLEZ_OP;
					alusel_o <= `EXE_RES_JUMP_BRANCH;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b0;
					instvalid <= `InstValid;
					if ((reg1_o[31] == 1'b1) || (reg1_o == `ZeroWord)) begin
						branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
						branch_flag_o <= `Branch;
						next_inst_in_delayslot_o <= `InDelaySlot;
					end
				end
				`EXE_BNE: begin
					wreg_o <= `WriteDisable;
					aluop_o <= `EXE_BLEZ_OP;
					alusel_o <= `EXE_RES_JUMP_BRANCH;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b1;
					instvalid <= `InstValid;
					if (reg1_o != reg2_o) begin
						branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
						branch_flag_o <= `Branch;
						next_inst_in_delayslot_o <= `InDelaySlot;
					end
				end
				`EXE_LB: begin
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_LB_OP;
					alusel_o <= `EXE_RES_LOAD_STORE;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b0;
					wd_o <= inst_i[20:16];
					instvalid <= `InstValid;
				end
				`EXE_LBU: begin
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_LBU_OP;
					alusel_o <= `EXE_RES_LOAD_STORE;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b0;
					wd_o <= inst_i[20:16];
					instvalid <= `InstValid;
				end
				`EXE_LH: begin
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_LH_OP;
					alusel_o <= `EXE_RES_LOAD_STORE;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b0;
					wd_o <= inst_i[20:16];
					instvalid <= `InstValid;
				end
				`EXE_LHU: begin
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_LHU_OP;
					alusel_o <= `EXE_RES_LOAD_STORE;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b0;
					wd_o <= inst_i[20:16];
					instvalid <= `InstValid;
				end
				`EXE_LW: begin
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_LW_OP;
					alusel_o <= `EXE_RES_LOAD_STORE;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b0;
					wd_o <= inst_i[20:16];
					instvalid <= `InstValid;
				end
				`EXE_LWL: begin
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_LWL_OP;
					alusel_o <= `EXE_RES_LOAD_STORE;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b1;
					wd_o <= inst_i[20:16];
					instvalid <= `InstValid;
				end
				`EXE_LWR: begin
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_LWR_OP;
					alusel_o <= `EXE_RES_LOAD_STORE;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b1;
					wd_o <= inst_i[20:16];
					instvalid <= `InstValid;
				end
				`EXE_SB: begin
					wreg_o <= `WriteDisable;
					aluop_o <= `EXE_SB_OP;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b1;
					instvalid <= `InstValid;
					alusel_o <= `EXE_RES_LOAD_STORE;
				end
				`EXE_SH: begin
					wreg_o <= `WriteDisable;
					aluop_o <= `EXE_SH_OP;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b1;
					instvalid <= `InstValid;
					alusel_o <= `EXE_RES_LOAD_STORE;
				end
				`EXE_SW: begin
					wreg_o <= `WriteDisable;
					aluop_o <= `EXE_SW_OP;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b1;
					instvalid <= `InstValid;
					alusel_o <= `EXE_RES_LOAD_STORE;
				end
				`EXE_SWL: begin
					wreg_o <= `WriteDisable;
					aluop_o <= `EXE_SWL_OP;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b1;
					instvalid <= `InstValid;
					alusel_o <= `EXE_RES_LOAD_STORE;
				end
				`EXE_SWR: begin
					wreg_o <= `WriteDisable;
					aluop_o <= `EXE_SWR_OP;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b1;
					instvalid <= `InstValid;
					alusel_o <= `EXE_RES_LOAD_STORE;
				end
				`EXE_REGIMM_INST: begin
					case (op4)
						`EXE_BGEZ: begin
							wreg_o <= `WriteDisable;
							aluop_o <= `EXE_BGEZ_OP;
							alusel_o <= `EXE_RES_JUMP_BRANCH;
							reg1_read_o <= 1'b1;
							reg2_read_o <= 1'b0;
							instvalid <= `InstValid;
							if (reg1_o[31] == 1'b0) begin
								branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
								branch_flag_o <= `Branch;
								next_inst_in_delayslot_o <= `InDelaySlot;
							end
						end
						`EXE_BGEZAL: begin
							wreg_o <= `WriteEnable;
							aluop_o <= `EXE_BGEZAL_OP;
							alusel_o <= `EXE_RES_JUMP_BRANCH;
							reg1_read_o <= 1'b1;
							reg2_read_o <= 1'b0;
							link_addr_o <= pc_plus_8;
							wd_o <= 5'b11111;
							instvalid <= `InstValid;
							if (reg1_o[31] == 1'b0) begin
								branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
								branch_flag_o <= `Branch;
								next_inst_in_delayslot_o <= `InDelaySlot;
							end
						end
						`EXE_BLTZ: begin
							wreg_o <= `WriteDisable;
							aluop_o <= `EXE_BLTZ_OP;
							alusel_o <= `EXE_RES_JUMP_BRANCH;
							reg1_read_o <= 1'b1;
							reg2_read_o <= 1'b0;
							instvalid <= `InstValid;
							if (reg1_o[31] == 1'b1) begin
								branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
								branch_flag_o <= `Branch;
								next_inst_in_delayslot_o <= `InDelaySlot;
							end
						end
						`EXE_BLTZAL: begin
							wreg_o <= `WriteEnable;
							aluop_o <= `EXE_BLTZAL_OP;
							alusel_o <= `EXE_RES_JUMP_BRANCH;
							reg1_read_o <= 1'b1;
							reg2_read_o <= 1'b0;
							link_addr_o <= pc_plus_8;
							wd_o <= 5'b11111;
							instvalid <= `InstValid;
							if (reg1_o[31] == 1'b1) begin
								branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
								branch_flag_o <= `Branch;
								next_inst_in_delayslot_o <= `InDelaySlot;
							end
						end
						default: begin
						end
					endcase
				end
				`EXE_SPECIAL2_INST: begin		//op等于SPECIAL2
					case (op3)
						`EXE_CLZ: begin			//clz
							wreg_o <= `WriteEnable;
							aluop_o <= `EXE_CLZ_OP;
							alusel_o <= `EXE_RES_ARITHMETIC;
							reg1_read_o <= 1'b1;
							reg2_read_o <= 1'b0;
							instvalid <= `InstValid;
						end
						`EXE_CLO: begin			//clo
							wreg_o <= `WriteEnable;
							aluop_o <= `EXE_CLO_OP;
							alusel_o <= `EXE_RES_ARITHMETIC;
							reg1_read_o <= 1'b1;
							reg2_read_o <= 1'b0;
							instvalid <= `InstValid;
						end
						`EXE_MUL: begin			//mul
							wreg_o <= `WriteEnable;
							aluop_o <= `EXE_MUL_OP;
							alusel_o <= `EXE_RES_MUL;
							reg1_read_o <= 1'b1;
							reg2_read_o <= 1'b1;
							instvalid <= `InstValid;
						end
						default: begin
						end
					endcase
				end
				default: begin
				end
			endcase

			if (inst_i[31:21] == 11'b00000000000) begin
				if (op3 == `EXE_SLL) begin				//sll指令
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_SLL_OP;
					alusel_o <= `EXE_RES_SHIFT;
					reg1_read_o <= 1'b0;
					reg2_read_o <= 1'b1;
					imm[4:0] <= inst_i[10:6];
					wd_o <= inst_i[15:11];
					instvalid <= `InstValid;
				end else if (op3 == `EXE_SRL) begin		//srl指令
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_SRL_OP;
					alusel_o <= `EXE_RES_SHIFT;
					reg1_read_o <= 1'b0;
					reg2_read_o <= 1'b1;
					imm[4:0] <= inst_i[10:6];
					wd_o <= inst_i[15:11];
					instvalid <= `InstValid;
				end else if (op3 == `EXE_SRA) begin		//sra指令
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_SRA_OP;
					alusel_o <= `EXE_RES_SHIFT;
					reg1_read_o <= 1'b0;
					reg2_read_o <= 1'b1;
					imm[4:0] <= inst_i[10:6];
					wd_o <= inst_i[15:11];
					instvalid <= `InstValid;
				end
			end

			if (inst_i == `EXE_ERET) begin
				wreg_o <= `WriteDisable;
				aluop_o <= `EXE_ERET_OP;
				alusel_o <= `EXE_RES_NOP;
				reg1_read_o <= 1'b0;
				reg2_read_o <= 1'b0;
				instvalid <= `InstValid;
				excepttype_is_eret <= `True_v;
			end else if (inst_i[31:21] == 11'b01000000000 && inst_i[10:0] == 11'b00000000000) begin
				aluop_o <= `EXE_MFC0_OP;
				alusel_o <= `EXE_RES_MOVE;
				wd_o <= inst_i[20:16];
				wreg_o <= `WriteEnable;
				instvalid <= `InstValid;
				reg1_read_o <= 1'b0;
				reg2_read_o <= 1'b0;
				cp0_reg_addr <= inst_i[15:11];
				if (cp0_reg_addr != `CP0_REG_INDEX && cp0_reg_addr != `CP0_REG_ENTRYLO0 && cp0_reg_addr != `CP0_REG_ENTRYLO1 &&
					cp0_reg_addr != `CP0_REG_BADVADDR && cp0_reg_addr != `CP0_REG_COUNT && cp0_reg_addr != `CP0_REG_ENTRYHI &&
					cp0_reg_addr != `CP0_REG_COMPARE && cp0_reg_addr != `CP0_REG_STATUS && cp0_reg_addr != `CP0_REG_CAUSE &&
					cp0_reg_addr != `CP0_REG_EPC && cp0_reg_addr != `CP0_REG_EBASE) begin
					excepttype_is_cpu <= `True_v;
				end else begin
				end
			end else if (inst_i[31:21] == 11'b01000000100 && inst_i[10:0] == 11'b00000000000) begin
				aluop_o <= `EXE_MTC0_OP;
				alusel_o <= `EXE_RES_NOP;
				wreg_o <= `WriteDisable;
				instvalid <= `InstValid;
				reg1_read_o <= 1'b1;
				reg1_addr_o <= inst_i[20:16];
				reg2_read_o <= 1'b0;
				cp0_reg_addr <= inst_i[15:11];
				if (cp0_reg_addr != `CP0_REG_INDEX && cp0_reg_addr != `CP0_REG_ENTRYLO0 && cp0_reg_addr != `CP0_REG_ENTRYLO1 &&
					cp0_reg_addr != `CP0_REG_COUNT && cp0_reg_addr != `CP0_REG_ENTRYHI && cp0_reg_addr != `CP0_REG_COMPARE &&
					cp0_reg_addr != `CP0_REG_STATUS && cp0_reg_addr != `CP0_REG_CAUSE && cp0_reg_addr != `CP0_REG_EPC &&
					cp0_reg_addr != `CP0_REG_EBASE) begin
					excepttype_is_cpu <= `True_v;
				end else begin
				end
			end else if (inst_i == 32'b01000010000000000000000000000010) begin
				aluop_o <= `EXE_TLBWI_OP;
				alusel_o <= `EXE_RES_NOP;
				wreg_o <= `WriteDisable;
				instvalid <= `InstValid;
				reg1_read_o <= 1'b0;
				reg2_read_o <= 1'b0;
			end else if (inst_i[31:26] == 32'b101111) begin	//cache
				wreg_o <= `WriteEnable;
				aluop_o <= `EXE_NOP_OP;
				alusel_o <= `EXE_RES_NOP;
				reg1_read_o <= 1'b0;
				reg2_read_o <= 1'b0;
				instvalid <= `InstValid;
			end
		end
	end

/************			第二段：确定进行运算的源操作数2			************/
	//给reg1_o赋值的过程增加了两种情况：
	//1. 如果Regfile模块读端口1要读取的寄存器就是执行阶段要写的目的寄存器，
	//   那么直接把执行阶段的结果ex_wdata_i作为reg1_o的值；
	//2. 如果Regfile模块读端口1要读取的寄存器就是访存阶段要写的目的寄存器，
	//   那么直接把访存阶段的结果mem_wdata_i作为reg1_o的值；
	//////////////////////////
	//如果上一条指令是加载指令，且该加载指令要加载到目的寄存器就是当前指令要通过regfile模块读端口1读取的通用寄存器，那么表示存在load相关，
	//设置stallreq_for_reg1_loadrelate为Stop
	always @ (*) begin
		stallreq_for_reg1_loadrelate <= `NoStop;
		reg1_o <= `ZeroWord;
		if (rst == `RstEnable) begin
			reg1_o <= `ZeroWord;
		end else if (pre_inst_is_load == 1'b1 && ex_wd_i == reg1_addr_o && reg1_read_o == 1'b1) begin
			stallreq_for_reg1_loadrelate <= `Stop;
		end else if ((reg1_read_o == 1'b1) && (ex_wreg_i == 1'b1) && (ex_wd_i == reg1_addr_o)) begin
			reg1_o <= ex_wdata_i;
		end else if ((reg1_read_o == 1'b1) && (mem_wreg_i == 1'b1) && (mem_wd_i == reg1_addr_o)) begin
			reg1_o <= mem_wdata_i;
		end else if (reg1_read_o == 1'b1) begin
			reg1_o <= reg1_data_i;				//Regfile读端口1的输出值
		end else if (reg1_read_o == 1'b0) begin
			reg1_o <= imm;						//立即数
		end else begin
			reg1_o <= `ZeroWord;
		end
	end

/************			第三段：确定进行运算的源操作数2			************/
	//给reg2_o赋值的过程增加了两种情况：
	//1. 如果Regfile模块读端口2要读取的寄存器就是执行阶段要写的目的寄存器，
	//   那么直接把执行阶段的结果ex_wdata_i作为reg2_o的值；
	//2. 如果Regfile模块读端口2要读取的寄存器就是访存阶段要写的目的寄存器，
	//   那么直接把访存阶段的结果mem_wdata_i作为reg2_o的值；
	/////////////////////////
	//如果上一条指令是加载指令，且该加载指令要加载到目的寄存器就是当前指令要通过regfile模块读端口2读取的通用寄存器，那么表示存在load相关，
	//设置stall_req_for_reg2_loadrelate为Stop
	always @ (*) begin
		stallreq_for_reg2_loadrelate <= `NoStop;
		reg2_o <= `ZeroWord;
		if (rst == `RstEnable) begin
			reg2_o <= `ZeroWord;
		end else if (pre_inst_is_load == 1'b1 && ex_wd_i == reg2_addr_o && reg2_read_o == 1'b1) begin
				stallreq_for_reg2_loadrelate <= `Stop;
		end else if ((reg2_read_o == 1'b1) && (ex_wreg_i == 1'b1) && (ex_wd_i == reg2_addr_o)) begin
			reg2_o <= ex_wdata_i;
		end else if ((reg2_read_o == 1'b1) && (mem_wreg_i == 1'b1) && (mem_wd_i == reg2_addr_o)) begin
			reg2_o <= mem_wdata_i;
		end else if (reg2_read_o == 1'b1) begin
			reg2_o <= reg2_data_i;				//Regfile读端口2的输出值
		end else if (reg2_read_o == 1'b0) begin
			reg2_o <= imm;						//立即数
		end else begin
			reg2_o <= `ZeroWord;
		end
	end

	//输出变量is_in_delayslot_o表示当前译码阶段指令是否是延迟槽指令
	always @ (*) begin
		if (rst == `RstEnable) begin
			is_in_delayslot_o <= `NotInDelaySlot;
		end else begin
			is_in_delayslot_o <= is_in_delayslot_i;
		end
	end

endmodule

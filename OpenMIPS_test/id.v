`include "defines.v"
module id(
	input		wire					rst,
	input		wire[`InstAddrBus]		pc_i,
	input		wire[`InstBus]			inst_i,

	input		wire[`AluOpBus]			ex_aluop_i,

	//��ȡ��Regfile��ֵ
	input		wire[`RegBus]			reg1_data_i,
	input		wire[`RegBus]			reg2_data_i,

	//����ִ�н׶ε�ָ���������
	input		wire					ex_wreg_i,
	input		wire[`RegBus]			ex_wdata_i,
	input		wire[`RegAddrBus]		ex_wd_i,

	//���ڷô�׶ε�ָ���������
	input		wire					mem_wreg_i,
	input		wire[`RegBus]			mem_wdata_i,
	input		wire[`RegAddrBus]		mem_wd_i,

	//�����һ��ָ����ת��ָ���ô��һ��ָ���������׶ε�ʱ���������is_in_delayslot_iΪtrue����ʾ���ӳٲ�ָ���֮Ϊfalse
	input		wire					is_in_delayslot_i,

	//�����Regfile����Ϣ
	output		reg						reg1_read_o,
	output		reg						reg2_read_o,
	output		reg[`RegAddrBus]		reg1_addr_o,
	output		reg[`RegAddrBus]		reg2_addr_o,

	//�͵�ִ�н׶ε���Ϣ
	output		reg[`AluOpBus]			aluop_o,
	output		reg[`AluSelBus]			alusel_o,

	//�͵�ִ�н׶ε�Դ������1��Դ������2
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

	//ȡ��ָ���ָ���룬������
	wire[5:0] op = inst_i[31:26];
	wire[4:0] op2 = inst_i[10:6];
	wire[5:0] op3 = inst_i[5:0];
	wire[4:0] op4 = inst_i[20:16];

	//����ָ��ִ����Ҫ��������
	reg[`RegBus] imm;

	//ָʾָ���Ƿ���Ч
	reg instvalid;

	wire[`RegBus] pc_plus_8;
	wire[`RegBus] pc_plus_4;

	wire[`RegBus] imm_sll2_signedext;

	//Ҫ��ȡ�ļĴ���1�Ƿ�����һ��ָ�����load���
	reg stallreq_for_reg1_loadrelate;

	//Ҫ��ȡ�ļĴ���2�Ƿ�����һ��ָ����load���
	reg stallreq_for_reg2_loadrelate;

	//��һ��ָ���Ƿ��Ǽ���ָ��
	wire pre_inst_is_load;

	reg excepttype_is_syscall;			//�Ƿ���ϵͳ�����쳣SYSCALL
	reg excepttype_is_eret;				//�Ƿ����쳣����ָ��eret
	reg excepttype_is_cpu;				//�Ƿ��Ƿ��ʲ����ڵ�Э�������쳣CpU
	reg[4:0] cp0_reg_addr;

	assign pc_plus_8 = pc_i + 8;		//���浱ǰ����׶�ָ�����ڶ���ָ��ĵ�ַ
	assign pc_plus_4 = pc_i + 4;		//���浱ǰ����׶�ָ���������ŵ�ָ��ĵ�ַ

	//imm_sll2_signedext��Ӧ��ָ֧���е�offset������λ���ٷ�����չ��32λ��ֵ
	assign imm_sll2_signedext = {{14{inst_i[15]}}, inst_i[15:0], 2'b00};  

	//stallreq_for_reg1_loadrelateΪStop����stallreq_for_reg2_loadrelateΪStop������ʾ����load��أ�
	//�Ӷ�Ҫ����ˮ����ͣ������stallreqΪtop
	assign stallreq = stallreq_for_reg1_loadrelate | stallreq_for_reg2_loadrelate;

	//���������ź�ex_aluop_i��ֵ���ж���һ��ָ���Ƿ��Ǽ���ָ�����Ǽ���ָ���ô��pre_inst_is_loadΪ1����֮��Ϊ0
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

	//excepttype_o�ĵ�8bit��ʾ�Ƿ���syscallָ�������ϵͳ�����쳣����10bit��ʾ�Ƿ�����Чָ��������쳣����11bit��ʾ�Ƿ��Ƿ��ʲ����ڵ�Э������������쳣����12bit��ʾ�Ƿ���eretָ�
	//eretָ�������Ϊ��һ��������쳣�������쳣��
	assign excepttype_o = {19'b0, excepttype_is_eret, excepttype_is_cpu, instvalid, 1'b0, excepttype_is_syscall, 8'b0};

	//�����ź�pc_i���ǵ�ǰ��������׶ε�ָ��ĵ�ַ
	assign current_inst_address_o = pc_i;

/************				��һ�Σ���ָ���������				************/
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
			reg1_addr_o <= inst_i[25:21];		//Ĭ��ͨ��Regfile���˿�1��ȡ�ļĴ�����ַ
			reg2_addr_o <= inst_i[20:16];		//Ĭ��ͨ��Regfile���˿�2��ȡ�ļĴ�����ַ
			imm <= `ZeroWord;
			link_addr_o <= `ZeroWord;
			branch_target_address_o <= `ZeroWord;
			branch_flag_o <= `NotBranch;
			next_inst_in_delayslot_o <= `NotInDelaySlot;
			excepttype_is_syscall <= `False_v;	//Ĭ��û��ϵͳ�����쳣
			excepttype_is_eret <= `False_v;		//Ĭ�ϲ���eretָ��
			excepttype_is_cpu <= `False_v;		//Ĭ��û�з��ʲ����ڵ�Э�������쳣
			cp0_reg_addr <= 5'b00000;
			
			case (op)
				`EXE_SPECIAL_INST: begin		//ָ������SPECIAL
					case (op2)
						5'b00000: begin				//���ݹ������ж�������ָ��
							case (op3)
								`EXE_OR: begin			//orָ��
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_OR_OP;
									alusel_o <= `EXE_RES_LOGIC;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instvalid <= `InstValid;
								end
								`EXE_AND: begin			//andָ��
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_AND_OP;
									alusel_o <= `EXE_RES_LOGIC;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instvalid <= `InstValid;
								end
								`EXE_XOR: begin			//xorָ��
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_XOR_OP;
									alusel_o <= `EXE_RES_LOGIC;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instvalid <= `InstValid;
								end
								`EXE_NOR: begin			//norָ��
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_NOR_OP;
									alusel_o <= `EXE_RES_LOGIC;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instvalid <= `InstValid;
								end
								`EXE_SLLV: begin		//sllvָ��
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_SLL_OP;
									alusel_o <= `EXE_RES_SHIFT;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instvalid <= `InstValid;
								end
								`EXE_SRLV: begin		//slrvָ��
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_SRL_OP;
									alusel_o <= `EXE_RES_SHIFT;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instvalid <= `InstValid;
								end
								`EXE_SRAV: begin		//sravָ��
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_SRA_OP;
									alusel_o <= `EXE_RES_SHIFT;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instvalid <= `InstValid;
								end
								`EXE_MFHI: begin		//mfhiָ��
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_MFHI_OP;
									alusel_o <= `EXE_RES_MOVE;
									reg1_read_o <= 1'b0;
									reg2_read_o <= 1'b0;
									instvalid <= `InstValid;
								end
								`EXE_MFLO: begin		//mfloָ��
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_MFLO_OP;
									alusel_o <= `EXE_RES_MOVE;
									reg1_read_o <= 1'b0;
									reg2_read_o <= 1'b0;
									instvalid <= `InstValid;
								end
								`EXE_MTHI: begin		//mthiָ��
									wreg_o <= `WriteDisable;
									aluop_o <= `EXE_MTHI_OP;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b0;
									instvalid <= `InstValid;
								end
								`EXE_MTLO: begin		//mtloָ��
									wreg_o <= `WriteDisable;
									aluop_o <= `EXE_MTLO_OP;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b0;
									instvalid <= `InstValid;
								end
								`EXE_MOVN: begin		//movnָ��
									aluop_o <= `EXE_MOVN_OP;
									alusel_o <= `EXE_RES_MOVE;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instvalid <= `InstValid;
									//reg2_o��ֵ���ǵ�ַΪrt��ͨ�üĴ�����ֵ
									if (reg2_o != `ZeroWord) begin
										wreg_o <= `WriteEnable;
									end else begin
										wreg_o <= `WriteDisable;
									end
								end
								`EXE_MOVZ: begin		//movzָ��
									aluop_o <= `EXE_MOVZ_OP;
									alusel_o <= `EXE_RES_MOVE;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instvalid <= `InstValid;
									//reg2_o��ֵ���ǵ�ַΪrt��ͨ�üĴ�����ֵ
									if (reg2_o == `ZeroWord) begin
										wreg_o <= `WriteEnable;
									end else begin
										wreg_o <= `WriteDisable;
									end
								end
								`EXE_SLT: begin			//sltָ��
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_SLT_OP;
									alusel_o <= `EXE_RES_ARITHMETIC;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instvalid <= `InstValid;
								end
								`EXE_SLTU: begin		//sltuָ��
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_SLTU_OP;
									alusel_o <= `EXE_RES_ARITHMETIC;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instvalid <= `InstValid;
								end
								`EXE_ADD: begin			//addָ��
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_ADD_OP;
									alusel_o <= `EXE_RES_ARITHMETIC;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instvalid <= `InstValid;
								end
								`EXE_ADDU: begin		//adduָ��
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_ADDU_OP;
									alusel_o <= `EXE_RES_ARITHMETIC;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instvalid <= `InstValid;
								end
								`EXE_SUB: begin			//subָ��
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_SUB_OP;
									alusel_o <= `EXE_RES_ARITHMETIC;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instvalid <= `InstValid;
								end
								`EXE_SUBU: begin		//subuָ��
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_SUBU_OP;
									alusel_o <= `EXE_RES_ARITHMETIC;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instvalid <= `InstValid;
								end
								`EXE_MULT: begin		//multָ��
									wreg_o <= `WriteDisable;
									aluop_o <= `EXE_MULT_OP;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instvalid <= `InstValid;
								end
								`EXE_MULTU: begin		//multuָ��
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
				`EXE_ORI: begin			//oriָ��
					//oriָ����Ҫ�����д��Ŀ�ļĴ���������wreg_oΪWriteEnable
					wreg_o <= `WriteEnable;

					//��������������߼�"��"����
					aluop_o <= `EXE_OR_OP;

					//�����������߼�����
					alusel_o <= `EXE_RES_LOGIC;

					//��Ҫͨ��Regfile�Ķ��˿�1��ȡ�Ĵ���
					reg1_read_o <= 1'b1;

					//����Ҫͨ��Regfile�Ķ��˿�2��ȡ�Ĵ���
					reg2_read_o <= 1'b0;

					//ָ��ִ����Ҫ��������
					imm <= {16'h0, inst_i[15:0]};

					//ָ��ִ��Ҫд��Ŀ�ļĴ�����ַ
					wd_o <= inst_i[20:16];

					//oriָ������Чָ��
					instvalid <= `InstValid;
				end
				`EXE_ANDI: begin		//andiָ��
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_AND_OP;
					alusel_o <= `EXE_RES_LOGIC;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b0;
					imm <= {16'h0, inst_i[15:0]};
					wd_o <= inst_i[20:16];
					instvalid <= `InstValid;
				end
				`EXE_XORI: begin		//xoriָ��
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_XOR_OP;
					alusel_o <= `EXE_RES_LOGIC;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b0;
					imm <= {16'h0, inst_i[15:0]};
					wd_o <= inst_i[20:16];
					instvalid <= `InstValid;
				end
				`EXE_LUI: begin			//luiָ��
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_OR_OP;
					alusel_o <= `EXE_RES_LOGIC;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b0;
					imm <= {inst_i[15:0], 16'h0};
					wd_o <= inst_i[20:16];
					instvalid <= `InstValid;
				end
				`EXE_SLTI: begin		//sltiָ��
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_SLT_OP;
					alusel_o <= `EXE_RES_ARITHMETIC;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b0;
					imm <= {{16{inst_i[15]}}, inst_i[15:0]};
					wd_o <= inst_i[20:16];
					instvalid <= `InstValid;
				end
				`EXE_SLTIU: begin		//sltiuָ��
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_SLTU_OP;
					alusel_o <= `EXE_RES_ARITHMETIC;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b0;
					imm <= {{16{inst_i[15]}}, inst_i[15:0]};
					wd_o <= inst_i[20:16];
					instvalid <= `InstValid;
				end
				`EXE_ADDI: begin		//addiָ��
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_ADDI_OP;
					alusel_o <= `EXE_RES_ARITHMETIC;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b0;
					imm <= {{16{inst_i[15]}}, inst_i[15:0]};
					wd_o <= inst_i[20:16];
					instvalid <= `InstValid;
				end
				`EXE_ADDIU: begin		//addiuָ��
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
				`EXE_SPECIAL2_INST: begin		//op����SPECIAL2
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
				if (op3 == `EXE_SLL) begin				//sllָ��
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_SLL_OP;
					alusel_o <= `EXE_RES_SHIFT;
					reg1_read_o <= 1'b0;
					reg2_read_o <= 1'b1;
					imm[4:0] <= inst_i[10:6];
					wd_o <= inst_i[15:11];
					instvalid <= `InstValid;
				end else if (op3 == `EXE_SRL) begin		//srlָ��
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_SRL_OP;
					alusel_o <= `EXE_RES_SHIFT;
					reg1_read_o <= 1'b0;
					reg2_read_o <= 1'b1;
					imm[4:0] <= inst_i[10:6];
					wd_o <= inst_i[15:11];
					instvalid <= `InstValid;
				end else if (op3 == `EXE_SRA) begin		//sraָ��
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

/************			�ڶ��Σ�ȷ�����������Դ������2			************/
	//��reg1_o��ֵ�Ĺ������������������
	//1. ���Regfileģ����˿�1Ҫ��ȡ�ļĴ�������ִ�н׶�Ҫд��Ŀ�ļĴ�����
	//   ��ôֱ�Ӱ�ִ�н׶εĽ��ex_wdata_i��Ϊreg1_o��ֵ��
	//2. ���Regfileģ����˿�1Ҫ��ȡ�ļĴ������Ƿô�׶�Ҫд��Ŀ�ļĴ�����
	//   ��ôֱ�Ӱѷô�׶εĽ��mem_wdata_i��Ϊreg1_o��ֵ��
	//////////////////////////
	//�����һ��ָ���Ǽ���ָ��Ҹü���ָ��Ҫ���ص�Ŀ�ļĴ������ǵ�ǰָ��Ҫͨ��regfileģ����˿�1��ȡ��ͨ�üĴ�������ô��ʾ����load��أ�
	//����stallreq_for_reg1_loadrelateΪStop
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
			reg1_o <= reg1_data_i;				//Regfile���˿�1�����ֵ
		end else if (reg1_read_o == 1'b0) begin
			reg1_o <= imm;						//������
		end else begin
			reg1_o <= `ZeroWord;
		end
	end

/************			�����Σ�ȷ�����������Դ������2			************/
	//��reg2_o��ֵ�Ĺ������������������
	//1. ���Regfileģ����˿�2Ҫ��ȡ�ļĴ�������ִ�н׶�Ҫд��Ŀ�ļĴ�����
	//   ��ôֱ�Ӱ�ִ�н׶εĽ��ex_wdata_i��Ϊreg2_o��ֵ��
	//2. ���Regfileģ����˿�2Ҫ��ȡ�ļĴ������Ƿô�׶�Ҫд��Ŀ�ļĴ�����
	//   ��ôֱ�Ӱѷô�׶εĽ��mem_wdata_i��Ϊreg2_o��ֵ��
	/////////////////////////
	//�����һ��ָ���Ǽ���ָ��Ҹü���ָ��Ҫ���ص�Ŀ�ļĴ������ǵ�ǰָ��Ҫͨ��regfileģ����˿�2��ȡ��ͨ�üĴ�������ô��ʾ����load��أ�
	//����stall_req_for_reg2_loadrelateΪStop
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
			reg2_o <= reg2_data_i;				//Regfile���˿�2�����ֵ
		end else if (reg2_read_o == 1'b0) begin
			reg2_o <= imm;						//������
		end else begin
			reg2_o <= `ZeroWord;
		end
	end

	//�������is_in_delayslot_o��ʾ��ǰ����׶�ָ���Ƿ����ӳٲ�ָ��
	always @ (*) begin
		if (rst == `RstEnable) begin
			is_in_delayslot_o <= `NotInDelaySlot;
		end else begin
			is_in_delayslot_o <= is_in_delayslot_i;
		end
	end

endmodule

`include "defines.v"
module ex(
	input		wire					rst,

	//����׶��͵�ִ�н׶ε���Ϣ
	input		wire[`AluOpBus]			aluop_i,
	input		wire[`AluSelBus]		alusel_i,
	input		wire[`RegBus]			reg1_i,
	input		wire[`RegBus]			reg2_i,
	input		wire[`RegAddrBus]		wd_i,
	input		wire					wreg_i,

	//inst_i��ֵ�ǵ�ǰ����ִ�н׶ε�ָ��
	input		wire[`RegBus]			inst_i,
	input		wire[31:0]				excepttype_i,
	input		wire[`RegBus]			current_inst_address_i,

	//HILOģ�������HI��LO�Ĵ�����ֵ
	input		wire[`RegBus]			hi_i,
	input		wire[`RegBus]			lo_i,

	//��д�׶ε�ָ���Ƿ�ҪдHI��LO�����ڼ��HI��LO�Ĵ��������������������
	input		wire[`RegBus]			wb_hi_i,
	input		wire[`RegBus]			wb_lo_i,
	input		wire					wb_whilo_i,
	
	//�ô�׶ε�ָ���Ƿ�ҪдHI��LO�����ڼ��HI��LO�Ĵ��������������������
	input		wire[`RegBus]			mem_hi_i,
	input		wire[`RegBus]			mem_lo_i,
	input		wire					mem_whilo_i,

	//����ִ�н׶ε�ת��ָ��Ҫ����ķ��ص�ַ
	input		wire[`RegBus]			link_address_i,

	//��ǰִ�н׶ε�ָ���Ƿ�λ���ӳٲ�
	input		wire					is_in_delayslot_i,

	//�ô�׶ε�ָ���Ƿ�ҪдCP0�еļĴ�������������������
	input		wire					mem_cp0_reg_we,
	input		wire[4:0]				mem_cp0_reg_write_addr,
	input		wire[`RegBus]			mem_cp0_reg_data,

	//��д�׶ε�ָ���Ƿ�ҪдCP0�еļĴ�����Ҳ����������������
	input		wire					wb_cp0_reg_we,
	input		wire[4:0]				wb_cp0_reg_write_addr,
	input		wire[`RegBus]			wb_cp0_reg_data,

	//��CP0ֱ�����������ڶ�ȡ����ָ���Ĵ�����ֵ
	input		wire[`RegBus]			cp0_reg_data_i,
	output		reg[4:0]				cp0_reg_read_addr_o,

	//����ˮ����һ�����ݣ�����дCP0�е�ָ���Ĵ���
	output		reg						cp0_reg_we_o,
	output		reg[4:0]				cp0_reg_write_addr_o,
	output		reg[`RegBus]			cp0_reg_data_o,

	output		reg[`RegAddrBus]		wd_o,
	output		reg						wreg_o,
	output		reg[`RegBus]			wdata_o,

	//����ִ�н׶ε�ָ���HI��LO�Ĵ�����д��������
	output		reg[`RegBus]			hi_o,
	output		reg[`RegBus]			lo_o,
	output		reg						whilo_o,

	output		wire[31:0]				excepttype_o,
	output		wire					is_in_delayslot_o,
	output		wire[`RegBus]			current_inst_address_o,

	//Ϊ���ء��洢ָ��׼���Ľӿ�
	output		wire[`AluOpBus]			aluop_o,
	output		wire[`RegBus]			mem_addr_o,
	output		wire[`RegBus]			reg2_o,

	output		reg						stallreq
	);

	reg[`RegBus] logicout;					//�����߼�����Ľ��
	reg[`RegBus] shiftres;					//������λ����Ľ��
	reg[`RegBus] moveres;					//�����ƶ������Ľ��
	reg[`RegBus] HI;						//����HI�Ĵ���������ֵ
	reg[`RegBus] LO;						//����LO�Ĵ���������ֵ

	wire ov_sum;							//����������
	wire reg1_eq_reg2;						//��һ���������Ƿ���ڵڶ���������
	wire reg1_lt_reg2;						//��һ���������Ƿ�С�ڵڶ���������
	reg[`RegBus] arithmeticres;				//������������Ľ��
	wire[`RegBus] reg2_i_mux;				//��������ĵڶ���������reg2_i�Ĳ���
	wire[`RegBus] reg1_i_not;				//��������ĵ�һ��������reg1_i�ķ����ֵ
	wire[`RegBus] result_sum;				//����ӷ����
	wire[`RegBus] opdata1_mult;				//�˷������еı�����
	wire[`RegBus] opdata2_mult;				//�˷������еĳ���
	wire[`DoubleRegBus] hilo_temp; 			//��ʱ����˷���������Ϊ64λ
	reg[`DoubleRegBus] mulres;				//����˷���������Ϊ64λ

	//aluop_o�ᴫ�ݵ��ô�׶Σ���ʱ��������ȷ�����ء��洢����
	assign aluop_o = aluop_i;

	//mem_addr_o�ᴫ�ݵ��ô�׶Σ��Ǽ��ء��洢ָ���Ӧ�Ĵ洢����ַ���˴���reg1_i���Ǽ��أ�
	//�洢ָ���е�ַΪbase��ͨ�üĴ�����ֵ��inst_i[15:0]����ָ���е�offset
	assign mem_addr_o = reg1_i + {{16{inst_i[15]}}, inst_i[15:0]};

	//reg2_i�Ǵ洢ָ��Ҫ�洢�����ݣ�����lwl��lwrָ��Ҫ���ص�Ŀ�ļĴ����ĵ�ԭʼֵ��
	//����ֵͨ��reg2_o�ӿڴ��ݵ��ô�׶�
	assign reg2_o = reg2_i;

	//ִ�н׶�������쳣��Ϣ��������׶ε��쳣��Ϣ
	assign excepttype_o = excepttype_i;

	//��ǰָ���Ƿ����ӳٲ���
	assign is_in_delayslot_o = is_in_delayslot_i;

	//��ǰ����ִ�н׶�ָ��ĵ�ַ
	assign current_inst_address_o = current_inst_address_i;

	//����aluop_iָʾ�����������ͽ�������
	always @ (*) begin
		if (rst == `RstEnable) begin
			logicout <= `ZeroWord;
		end else begin
			case (aluop_i)
				`EXE_OR_OP: begin			//�߼�������
					logicout <= reg1_i | reg2_i;
				end
				`EXE_AND_OP: begin			//�߼�������
					logicout <= reg1_i & reg2_i;
				end
				`EXE_NOR_OP: begin			//�߼��������
					logicout <= ~(reg1_i | reg2_i);
				end
				`EXE_XOR_OP: begin			//�߼��������
					logicout <= reg1_i ^ reg2_i;
				end
				default: begin
					logicout <= `ZeroWord;
				end
			endcase
		end
	end
	
	always @ (*) begin
		if (rst == `RstEnable) begin
			shiftres <= `ZeroWord;
		end else begin
			case (aluop_i)
				`EXE_SLL_OP: begin			//�߼�����
					shiftres <= reg2_i << reg1_i[4:0];
				end
				`EXE_SRL_OP: begin			//�߼�����
					shiftres <= reg2_i >> reg1_i[4:0];
				end
				`EXE_SRA_OP: begin			//��������
					shiftres <= ({32{reg2_i[31]}} << (6'd32 - {1'b0, reg1_i[4:0]})) | reg2_i >> reg1_i[4:0];
				end
				default: begin
					shiftres <= `ZeroWord;
				end
			endcase
		end
	end

	//��1������Ǽ��������з��űȽ����㣬��ôreg2_i_mux���ڵڶ���������
	//	reg2_i�Ĳ��룬����reg2_i_mux�͵��ڵڶ���������reg2_i
	assign reg2_i_mux = ((aluop_i == `EXE_SUB_OP) ||
						 (aluop_i == `EXE_SUBU_OP) ||
						 (aluop_i == `EXE_SLT_OP)) ?
						 (~reg2_i)+1 : reg2_i;

	//��2�������������
	//		A.����Ǽӷ����㣬��ʱreg2_i_mux���ǵڶ���������reg2_i������result_sum���Ǽӷ�����Ľ��
	//		B.����Ǽ������㣬��ʱreg2_i_mux�ǵڶ���������reg2_i�Ĳ��룬����result_sum���Ǽ�������Ľ��
	//		C.������з��űȽ��������㣬��ʱreg2_i_muxҲ�ǵڶ���������reg2_i�Ĳ��룬����result_sumҲ�Ǽ�������Ľ����
	//		  ����ͨ���жϼ����Ľ���Ƿ�С��0�������жϵ�һ��������reg1_i�Ƿ�С�ڵڶ���������reg2_i
	assign result_sum = reg1_i + reg2_i_mux;

	//��3�������Ƿ�������ӷ�ָ�add��addi��������ָ�sub��ִ�е�ʱ����Ҫ�ж��Ƿ���������������������֮һʱ���������
	//		A.reg1_iΪ������reg2_i_muxΪ��������������֮��Ϊ����
	//		B.reg1_iΪ������reg2_i_muxΪ��������������֮��Ϊ����
	assign ov_sum = ((!reg1_i[31] && !reg2_i_mux[31]) && result_sum[31]) ||
					((reg1_i[31] && reg2_i_mux[31]) && (!result_sum[31]));

	//��4�����������1�Ƿ�С�ڲ�����2�������������
	//		A.aluop_iΪEXE_SLT_OP��ʾ�з��űȽ����㣬��ʱ�ַ�3�����
	//			A1.reg1_iΪ������reg2_iΪ��������Ȼreg1_iС��reg2_i
	//			A2.reg1_iΪ������reg2_iΪ����������reg1_i��ȥreg2_i��ֵС��0����result_sumΪ��������ʱҲ��reg1_iС��reg2_i
	//			A3.reg1_iΪ������reg2_iΪ����������reg1_i��ȥreg2_i��ֵС��0����result_sumΪ��������ʱҲ��reg1_iС��reg2_i
	//		B.�޷������Ƚϵ�ʱ��ֱ��ʹ�ñȽ�������Ƚ�reg1_i��reg2_i
	assign reg1_lt_reg2 = ((aluop_i == `EXE_SLT_OP)) ?
						  ((reg1_i[31] && !reg2_i[31]) ||
						   (!reg1_i[31] && !reg2_i[31] && result_sum[31]) ||
						   (reg1_i[31] && reg2_i[31] && result_sum[31]))
						  : (reg1_i < reg2_i);

	//��5���Բ�����1��λȡ��������reg1_i_not
	assign reg1_i_not = ~reg1_i;

	//�õ����µ�HI��LO�Ĵ�����ֵ���˴�Ҫ��������������
	always @ (*) begin
		if (rst == `RstEnable) begin
			{HI, LO} <= {`ZeroWord, `ZeroWord};
		end else if (mem_whilo_i == `WriteEnable) begin
			{HI, LO} <= {mem_hi_i, mem_lo_i};	//�ô�׶ε�ָ��ҪдHI��LO�Ĵ���
		end else if (wb_whilo_i == `WriteEnable) begin
			{HI, LO} <= {wb_hi_i, wb_lo_i};		//��д�׶ε�ָ��ҪдHI��LO�Ĵ���
		end else begin
			{HI, LO} <= {hi_i, lo_i};
		end
	end

	//MFHI��MFLO��MOVN��MOVZָ��
	always @ (*) begin
		if (rst == `RstEnable) begin
			moveres <= `ZeroWord;
			cp0_reg_read_addr_o <= 5'b00000;
		end else begin
			moveres <= `ZeroWord;
			cp0_reg_read_addr_o <= 5'b00000;
			case (aluop_i)
				`EXE_MFHI_OP: begin
					//�����mfhiָ���ô��HI��ֵ��Ϊ�ƶ������Ľ��
					moveres <= HI;
				end
				`EXE_MFLO_OP: begin
					//�����mfloָ���ô��LO��ֵ��Ϊ�ƶ������Ľ��
					moveres <= LO;
				end
				`EXE_MOVZ_OP: begin
					//�����movzָ���ô��reg1_i��ֵ��Ϊ�ƶ������Ľ��
					moveres <= reg1_i;
				end
				`EXE_MOVN_OP: begin
					//�����movnָ���ô��reg1_i��ֵ��Ϊ�ƶ������Ľ��
					moveres <= reg1_i;
				end
				`EXE_MFC0_OP: begin
					//Ҫ��CP0�ж�ȡ�ļĴ����ĵ�ַ
					cp0_reg_read_addr_o <= inst_i[15:11];

					//��ȡ����CP0��ָ���Ĵ�����ֵ
					moveres <= cp0_reg_data_i;

					//�ж��Ƿ�����������
					if (mem_cp0_reg_we == `WriteEnable && mem_cp0_reg_write_addr == inst_i[15:11]) begin
						moveres <= mem_cp0_reg_data;		//��ô�׶δ����������
					end else if (wb_cp0_reg_we == `WriteEnable && wb_cp0_reg_write_addr == inst_i[15:11]) begin
						moveres <= wb_cp0_reg_data;
					end
				end
				default: begin
				end
			endcase
		end
	end

	//����alusel_iָʾ���������ͣ�ѡ��һ����������Ϊ���ս��
	always @ (*) begin
		if (rst == `RstEnable) begin
			arithmeticres <= `ZeroWord;
		end else begin
			case (aluop_i)							//aluop_i������������
				`EXE_SLT_OP, `EXE_SLTU_OP: begin
					arithmeticres <= reg1_lt_reg2;	//�Ƚ�����
				end
				`EXE_ADD_OP, `EXE_ADDU_OP, `EXE_ADDI_OP, `EXE_ADDIU_OP: begin
					arithmeticres <= result_sum;	//�ӷ�����
				end
				`EXE_SUB_OP, `EXE_SUBU_OP: begin
					arithmeticres <= result_sum;	//��������
				end
				`EXE_CLZ_OP: begin
					arithmeticres <= reg1_i[31] ? 0 : reg1_i[30] ? 1 :
									 reg1_i[29] ? 2 : reg1_i[28] ? 3 :
									 reg1_i[27] ? 4 : reg1_i[26] ? 5 :
									 reg1_i[25] ? 6 : reg1_i[24] ? 7 :
									 reg1_i[23] ? 8 : reg1_i[22] ? 9 :
									 reg1_i[21] ? 10 : reg1_i[20] ? 11 :
									 reg1_i[19] ? 12 : reg1_i[18] ? 13 :
									 reg1_i[17] ? 14 : reg1_i[16] ? 15 :
									 reg1_i[15] ? 16 : reg1_i[14] ? 17 :
									 reg1_i[13] ? 18 : reg1_i[12] ? 19 :
									 reg1_i[11] ? 20 : reg1_i[10] ? 21 :
									 reg1_i[9] ? 22 : reg1_i[8] ? 23 :
									 reg1_i[7] ? 24 : reg1_i[6] ? 25 :
									 reg1_i[5] ? 26 : reg1_i[4] ? 27 :
									 reg1_i[3] ? 28 : reg1_i[2] ? 29 :
									 reg1_i[1] ? 30 : reg1_i[0] ? 31 : 32;
				end
				`EXE_CLO_OP: begin
					arithmeticres <= (reg1_i_not[31] ? 0 :
									  reg1_i_not[30] ? 1 :
									  reg1_i_not[29] ? 2 :
									  reg1_i_not[28] ? 3 :
									  reg1_i_not[27] ? 4 :
									  reg1_i_not[26] ? 5 :
									  reg1_i_not[25] ? 6 :
									  reg1_i_not[24] ? 7 :
									  reg1_i_not[23] ? 8 :
									  reg1_i_not[22] ? 9 :
									  reg1_i_not[21] ? 10 :
									  reg1_i_not[20] ? 11 :
									  reg1_i_not[19] ? 12 :
									  reg1_i_not[18] ? 13 :
									  reg1_i_not[17] ? 14 :
									  reg1_i_not[16] ? 15 :
									  reg1_i_not[15] ? 16 :
									  reg1_i_not[14] ? 17 :
									  reg1_i_not[13] ? 18 :
									  reg1_i_not[12] ? 19 :
									  reg1_i_not[11] ? 20 :
									  reg1_i_not[10] ? 21 :
									  reg1_i_not[9] ? 22 :
									  reg1_i_not[8] ? 23 :
									  reg1_i_not[7] ? 24 :
									  reg1_i_not[6] ? 25 :
									  reg1_i_not[5] ? 26 :
									  reg1_i_not[4] ? 27 :
									  reg1_i_not[3] ? 28 :
									  reg1_i_not[2] ? 29 :
									  reg1_i_not[1] ? 30 :
									  reg1_i_not[0] ? 31 : 32);
				end
				default: begin
					arithmeticres <= `ZeroWord;
				end
			endcase

		end
	end

	//���г˷�����
	//��1��ȡ�ó˷�����ı�������������з��ų˷��ұ������Ǹ�������ôȡ����
	assign opdata1_mult = (((aluop_i == `EXE_MUL_OP) || (aluop_i == `EXE_MULT_OP)) &&
							(reg1_i[31] == 1'b1)) ? (~reg1_i + 1) : reg1_i;

	//��2��ȡ�ó˷�����ĳ�����������з��ų˷��ҳ����Ǹ�������ôȡ����
	assign opdata2_mult = (((aluop_i == `EXE_MUL_OP) || (aluop_i == `EXE_MULT_OP)) &&
							(reg2_i[31] == 1'b1)) ? (~reg2_i + 1) : reg2_i;

	//��3���õ���ʱ�˷�����������ڱ���hilo_temp��
	assign hilo_temp = opdata1_mult * opdata2_mult;

	//��4������ʱ�˷�����������������յĳ˷���������ڱ���mulres�У���Ҫ�����㣺
	//		A.������з��ų˷�ָ��mult��mul����ô��Ҫ������ʱ�˷���������£�
	//			A1.������������������һ��һ������ô��Ҫ����ʱ�˷����hilo_temp���룬��Ϊ���յĳ˷��������������mulres
	//			A2.��������������ͬ�ţ���ôhilo_temp��ֵ����Ϊ���յĳ˷��������������mulres
	//		B.������޷��ų˷�ָ��multu����ôhilo_temp��ֵ����Ϊ���յĳ˷��������������mulres
	always @ (*) begin
		if (rst == `RstEnable) begin
			mulres <= {`ZeroWord, `ZeroWord};
		end else if ((aluop_i == `EXE_MULT_OP) || (aluop_i == `EXE_MUL_OP)) begin
			if (reg1_i[31] ^ reg2_i[31] == 1'b1) begin
				mulres <= ~hilo_temp + 1;
			end else begin
				mulres <= hilo_temp;
			end
		end else begin
			mulres <= hilo_temp;
		end
	end

	//ȷ��Ҫд��Ŀ�ļĴ���������
	always @ (*) begin
		wd_o <= wd_i;							//wd_o����wd_i��Ҫд��Ŀ�ļĴ�����ַ
		//�����add��addi��sub��subiָ��ҷ����������ô����wreg_oΪWriteDisable����ʾ��дĿ�ļĴ���
		if (((aluop_i == `EXE_ADD_OP) || (aluop_i == `EXE_ADDI_OP) ||
			 (aluop_i == `EXE_SUB_OP)) && (ov_sum == 1'b1)) begin
			wreg_o <= `WriteDisable;
		end else begin
			wreg_o <= wreg_i;					//wreg_o����wreg_i����ʾ�Ƿ�ҪдĿ�ļĴ���
		end
		case (alusel_i)							//wdata_o�д��������
			`EXE_RES_LOGIC: begin
				wdata_o <= logicout;			//ѡ���߼�������Ϊ����������
			end
			`EXE_RES_SHIFT: begin
				wdata_o <= shiftres;			//ѡ����λ������Ϊ����������
			end
			`EXE_RES_MOVE: begin
				wdata_o <= moveres;				//ѡ���ƶ�������Ϊ����������
			end
			`EXE_RES_ARITHMETIC: begin			//���˷���ļ���������ָ��
				wdata_o <= arithmeticres;
			end
			`EXE_RES_MUL: begin					//�˷�ָ��mul
				wdata_o <= mulres[31:0];
			end
			`EXE_RES_JUMP_BRANCH: begin
				wdata_o <= link_address_i;
			end
			default: begin
				wdata_o <= `ZeroWord;
			end
		endcase
	end

	//ȷ����HI��LO�Ĵ����Ĳ�����Ϣ
	//�����MTHI��MTLOָ���ô��Ҫ����whilo_o��hi_o��lo_i��ֵ
	always @ (*) begin
		if (rst == `RstEnable) begin
			whilo_o <= `WriteDisable;
			hi_o <= `ZeroWord;
			lo_o <= `ZeroWord;
		end else if ((aluop_i == `EXE_MULT_OP) ||
					 (aluop_i == `EXE_MULTU_OP)) begin		//mult��multuָ��
			whilo_o <= `WriteEnable;
			hi_o <= mulres[63:32];
			lo_o <= mulres[31:0];
		end else if (aluop_i == `EXE_MTHI_OP) begin
			whilo_o <= `WriteEnable;
			hi_o <= reg1_i;
			lo_o <= LO;
		end else if (aluop_i == `EXE_MTLO_OP) begin
			whilo_o <= `WriteEnable;
			hi_o <= HI;
			lo_o <= reg1_i;
		end else begin
			whilo_o <= `WriteDisable;
			hi_o <= `ZeroWord;
			lo_o <= `ZeroWord;
		end
	end

	//����mtc0ָ���ִ�н��
	always @ (*) begin
		if (rst == `RstEnable) begin
			cp0_reg_write_addr_o <= 5'b00000;
			cp0_reg_we_o <= `WriteDisable;
			cp0_reg_data_o <= `ZeroWord;
		end else if (aluop_i == `EXE_MTC0_OP) begin
			cp0_reg_write_addr_o <= inst_i[15:11];
			cp0_reg_we_o <= `WriteEnable;
			cp0_reg_data_o <= reg1_i;
		end else begin
			cp0_reg_write_addr_o <= 5'b00000;
			cp0_reg_we_o <= `WriteDisable;
			cp0_reg_data_o <= `ZeroWord;
		end
	end

endmodule

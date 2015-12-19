`include "defines.v"
module mem(
	input		wire					rst,

	//����ִ�н׶ε���Ϣ
	input		wire[`RegAddrBus]		wd_i,
	input		wire					wreg_i,
	input		wire[`RegBus]			wdata_i,
	input		wire[`RegBus]			hi_i,
	input		wire[`RegBus]			lo_i,
	input		wire					whilo_i,
	input		wire[`AluOpBus]			aluop_i,
	input		wire[`RegBus]			mem_addr_i,
	input		wire[`RegBus]			reg2_i,

	//����MMUģ�����Ϣ
	input		wire[`RegBus]			mem_data_i,

	input		wire					cp0_reg_we_i,
	input		wire[4:0]				cp0_reg_write_addr_i,
	input		wire[`RegBus]			cp0_reg_data_i,

	//����ִ�н׶�
	input		wire[31:0]				excepttype_i,
	input		wire					is_in_delayslot_i,
	input		wire[`RegBus]			current_inst_address_i,

	//CP0�ĸ����Ĵ�����ֵ������һ�������µ�ֵ��Ҫ��ֹ��д�׶�ָ��дCP0
	input		wire[`RegBus]			cp0_bad_v_addr_i,
	input		wire[`RegBus]			cp0_status_i,
	input		wire[`RegBus]			cp0_cause_i,
	input		wire[`RegBus]			cp0_epc_i,
	input		wire[`RegBus]			cp0_index_i,
	input		wire[`RegBus]			cp0_entry_lo_0_i,
	input		wire[`RegBus]			cp0_entry_lo_1_i,
	input		wire[`RegBus]			cp0_entry_hi_i,

	//���Ի�д�׶ε�ָ���CP0�Ĵ�����д��Ϣ����������������
	input		wire					wb_cp0_reg_we,
	input		wire[4:0]				wb_cp0_reg_write_addr,
	input		wire[`RegBus]			wb_cp0_reg_data,

	//����MMUģ���TLB�쳣��Ϣ
	input		wire					excepttype_is_tlbm_i,
	input		wire					excepttype_is_tlbl_i,
	input		wire					excepttype_is_tlbs_i,

	//�ô�׶εĽ��
	output		reg[`RegAddrBus]		wd_o,
	output		reg						wreg_o,
	output		reg[`RegBus]			wdata_o,
	output		reg[`RegBus]			hi_o,
	output		reg[`RegBus]			lo_o,
	output		reg						whilo_o,

	output		reg						cp0_reg_we_o,
	output		reg[4:0]				cp0_reg_write_addr_o,
	output		reg[`RegBus]			cp0_reg_data_o,

	//�͵�MMU����Ϣ
	output		reg[`RegBus]			mem_addr_o,
	output		wire					mem_we_o,
	output		reg[3:0]				mem_sel_o,
	output		reg[`RegBus]			mem_data_o,
	output		reg						mem_ce_o,

	//�͵�CP0�Ĵ�������Ϣ
	output		reg[31:0]				excepttype_o,
	output		wire[`RegBus]			cp0_epc_o,
	output		wire					is_in_delayslot_o,

	output		wire[`RegBus]			current_inst_address_o,
	output		reg[`RegBus]			bad_v_addr_o,

	//�͵�TLBģ�����Ϣ
	output		reg						tlb_we_o,
	output		reg[`TLBIndexBus]		tlb_index_o,
	output		reg[`TLBDataBus]		tlb_data_o

	//�͵�CTRLģ�����Ϣ
	// output		reg 					stall_req
	);

	wire[`RegBus] zero32;
	reg mem_we;

	reg[`RegBus] cp0_bad_v_addr;		//��������CP0��BadVAddr�Ĵ���������ֵ
	reg[`RegBus] cp0_status;			//��������CP0��Status�Ĵ���������ֵ
	reg[`RegBus] cp0_cause;				//��������CP0��Cause�Ĵ���������ֵ
	reg[`RegBus] cp0_epc;				//��������CP0��EPC�Ĵ���������ֵ

	reg[`RegBus] cp0_index;				//��������CP0��Index�Ĵ���������ֵ
	reg[`RegBus] cp0_entry_lo_0;		//��������CP0��EntryLo0�Ĵ���������ֵ
	reg[`RegBus] cp0_entry_lo_1;		//��������CP0��EntryLo1�Ĵ���������ֵ
	reg[`RegBus] cp0_entry_hi;			//��������CP0��EntryHi�Ĵ���������ֵ

	reg excepttype_is_adel;				//�Ƿ��Ƕ����ʷǶ����쳣ADEL
	reg excepttype_is_ades;				//�Ƿ���д���ʷǶ����쳣ADES
	reg excepttype_is_watch;			//�Ƿ���Watch����쳣Watch

	wire[31:0] excepttype;

	assign zero32 = `ZeroWord;

	//�ô�׶�ָ���Ƿ����ӳٲ�ָ��
	assign is_in_delayslot_o = is_in_delayslot_i;
	assign current_inst_address_o = current_inst_address_i;

	//excepttype_o�ĵ�1bit��ʾ�Ƿ����ڴ��޸��쳣����2bit��ʾ�Ƿ��Ƕ�δ��TLB��ӳ����ڴ��ַ�쳣����3bit��ʾ�Ƿ���дδ��TLB��ӳ����ڴ��ַ�쳣��
	//��4bit��ʾ�Ƿ��Ƕ����ʷǶ����쳣ADEL����5bit��ʾ�Ƿ���д���ʷǶ����쳣����23bit��ʾ�Ƿ���Watch����쳣
	assign excepttype = {excepttype_i[31:24], excepttype_is_watch, excepttype_i[22:6], excepttype_is_ades, excepttype_is_adel, excepttype_is_tlbs_i, excepttype_is_tlbl_i, excepttype_is_tlbm_i, excepttype_i[0]};

	//mem_we_o��������ݴ洢������ʾ�Ƿ��Ƕ����ݴ洢����д����������������쳣����ô��Ҫȡ�������ݴ洢����д����
	assign mem_we_o = mem_we & (~(|excepttype_o));

	always @ (*) begin
		if (rst == `RstEnable) begin
			wd_o <= `NOPRegAddr;
			wreg_o <= `WriteDisable;
			wdata_o <= `ZeroWord;
			hi_o <= `ZeroWord;
			lo_o <= `ZeroWord;
			whilo_o <= `WriteDisable;
			mem_addr_o <= `ZeroWord;
			mem_we <= `WriteDisable;
			mem_sel_o <= 4'b0000;
			mem_data_o <= `ZeroWord;
			mem_ce_o <= `ChipDisable;
			cp0_reg_we_o <= `WriteDisable;
			cp0_reg_write_addr_o <= 5'b00000;
			cp0_reg_data_o <= `ZeroWord;
			bad_v_addr_o <= `ZeroWord;
			excepttype_is_adel <= `False_v;
			excepttype_is_ades <= `False_v;
			excepttype_is_watch <= `False_v;
			tlb_we_o <= `WriteDisable;
			tlb_data_o <= `ZeroWord;
			tlb_index_o <= 4'b0000;
		end else begin
			wd_o <= wd_i;
			wreg_o <= wreg_i;
			wdata_o <= wdata_i;
			hi_o <= hi_i;
			lo_o <= lo_i;
			whilo_o <= whilo_i;
			mem_we <= `WriteDisable;
			// mem_addr_o <= `ZeroWord;
			mem_sel_o <= 4'b1111;
			mem_data_o <= `ZeroWord;
			mem_ce_o <= `ChipDisable;
			cp0_reg_we_o <= cp0_reg_we_i;
			cp0_reg_write_addr_o <= cp0_reg_write_addr_i;
			cp0_reg_data_o <= cp0_reg_data_i;
			bad_v_addr_o <= `ZeroWord;
			excepttype_is_adel <= `False_v;			//Ĭ��û�з��������ʷǶ����쳣
			excepttype_is_ades <= `False_v;			//Ĭ��û�з���д���ʷǶ����쳣
			excepttype_is_watch <= `False_v;		//Ĭ��û�з���Watch����쳣
			tlb_we_o <= `WriteDisable;
			tlb_data_o <= `ZeroWord;
			tlb_index_o <= 4'b0000;
			case (aluop_i)
				`EXE_LB_OP: begin
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteDisable;
					mem_ce_o <= `ChipEnable;
					case (mem_addr_i[1:0])
						2'b11: begin
							wdata_o <= {{24{mem_data_i[31]}}, mem_data_i[31:24]};
							mem_sel_o <= 4'b1000;
						end
						2'b10: begin
							wdata_o <= {{24{mem_data_i[23]}}, mem_data_i[23:16]};
							mem_sel_o <= 4'b0100;
						end
						2'b01: begin
							wdata_o <= {{24{mem_data_i[15]}}, mem_data_i[15:8]};
							mem_sel_o <= 4'b0010;
						end
						2'b00: begin
							wdata_o <= {{24{mem_data_i[7]}}, mem_data_i[7:0]};
							mem_sel_o <= 4'b0001;
						end
						default: begin
							wdata_o <= `ZeroWord;
						end
					endcase
				end
				`EXE_LBU_OP: begin
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteDisable;
					mem_ce_o <= `ChipEnable;
					case (mem_addr_i[1:0])
						2'b11: begin
							wdata_o <= {{24{1'b0}}, mem_data_i[31:24]};
							mem_sel_o <= 4'b1000;
						end
						2'b10: begin
							wdata_o <= {{24{1'b0}}, mem_data_i[23:16]};
							mem_sel_o <= 4'b0100;
						end
						2'b01: begin
							wdata_o <= {{24{1'b0}}, mem_data_i[15:8]};
							mem_sel_o <= 4'b0010;
						end
						2'b00: begin
							wdata_o <= {{24{1'b0}}, mem_data_i[7:0]};
							mem_sel_o <= 4'b0001;
						end
						default: begin
							wdata_o <= `ZeroWord;
						end
					endcase
				end
				`EXE_LH_OP: begin
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteDisable;
					case (mem_addr_i[1:0])
						2'b10: begin
							mem_ce_o <= `ChipEnable;
							wdata_o <= {{16{mem_data_i[31]}}, mem_data_i[31:16]};
							mem_sel_o <= 4'b1100;
						end
						2'b00: begin
							mem_ce_o <= `ChipEnable;
							wdata_o <= {{16{mem_data_i[15]}}, mem_data_i[15:0]};
							mem_sel_o <= 4'b0011;
						end
						default: begin
							mem_ce_o <= `ChipDisable;
							wdata_o <= `ZeroWord;
							excepttype_is_adel <= `True_v;
							bad_v_addr_o <= mem_addr_i;
						end
					endcase
				end
				`EXE_LHU_OP: begin
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteDisable;
					case (mem_addr_i[1:0])
						2'b10: begin
							mem_ce_o <= `ChipEnable;
							wdata_o <= {{16{1'b0}}, mem_data_i[31:16]};
							mem_sel_o <= 4'b1100;
						end
						2'b00: begin
							mem_ce_o <= `ChipEnable;
							wdata_o <= {{16{1'b0}}, mem_data_i[15:0]};
							mem_sel_o <= 4'b0011;
						end
						default: begin
							mem_ce_o <= `ChipDisable;
							wdata_o <= `ZeroWord;
							excepttype_is_adel <= `True_v;
							bad_v_addr_o <= mem_addr_i;
						end
					endcase
				end
				`EXE_LW_OP: begin
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteDisable;
					case (mem_addr_i[1:0])
						2'b00: begin
							mem_ce_o <= `ChipEnable;
							wdata_o <= mem_data_i;
							mem_sel_o <= 4'b1111;
						end
						default: begin
							mem_ce_o <= `ChipDisable;
							wdata_o <= `ZeroWord;
							excepttype_is_adel <= `True_v;
							bad_v_addr_o <= mem_addr_i;
						end
					endcase
				end
				`EXE_LWL_OP: begin
					mem_addr_o <= {mem_addr_i[31:2], 2'b00};
					mem_we <= `WriteDisable;
					mem_sel_o <= 4'b1111;
					mem_ce_o <= `ChipEnable;
					case (mem_addr_i[1:0])
						2'b11: begin
							wdata_o <= mem_data_i[31:0];
						end
						2'b10: begin
							wdata_o <= {mem_data_i[23:0], reg2_i[7:0]};
						end
						2'b01: begin
							wdata_o <= {mem_data_i[15:0], reg2_i[15:0]};
						end
						2'b00: begin
							wdata_o <= {mem_data_i[7:0], reg2_i[23:0]};
						end
						default: begin
							wdata_o <= `ZeroWord;
						end
					endcase
				end
				`EXE_LWR_OP: begin
					mem_addr_o <= {mem_addr_i[31:2], 2'b00};
					mem_we <= `WriteDisable;
					mem_sel_o <= 4'b1111;
					mem_ce_o <= `ChipEnable;
					case (mem_addr_i[1:0])
						2'b11: begin
							wdata_o <= {reg2_i[31:8], mem_data_i[31:24]};
						end
						2'b10: begin
							wdata_o <= {reg2_i[31:16], mem_data_i[31:16]};
						end
						2'b01: begin
							wdata_o <= {reg2_i[31:24], mem_data_i[31:8]};
						end
						2'b00: begin
							wdata_o <= mem_data_i;
						end
						default: begin
							wdata_o <= `ZeroWord;
						end
					endcase
				end
				`EXE_SB_OP: begin
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteEnable;
					mem_data_o <= {reg2_i[7:0], reg2_i[7:0], reg2_i[7:0], reg2_i[7:0]};
					mem_ce_o <= `ChipEnable;
					case (mem_addr_i[1:0])
						2'b11: begin
							mem_sel_o <= 4'b1000;
						end
						2'b10: begin
							mem_sel_o <= 4'b0100;
						end
						2'b01: begin
							mem_sel_o <= 4'b0010;
						end
						2'b00: begin
							mem_sel_o <= 4'b0001;
						end
						default: begin
							mem_sel_o <= 4'b0000;
						end
					endcase
				end
				`EXE_SH_OP: begin
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteEnable;
					case (mem_addr_i[1:0])
						2'b10: begin
							mem_ce_o <= `ChipEnable;
							mem_data_o <= {reg2_i[15:0], reg2_i[15:0]};
							mem_sel_o <= 4'b1100;
						end
						2'b00: begin
							mem_ce_o <= `ChipEnable;
							mem_data_o <= {reg2_i[15:0], reg2_i[15:0]};
							mem_sel_o <= 4'b0011;
						end
						default: begin
							mem_ce_o <= `ChipDisable;
							mem_data_o <= `ZeroWord;
							mem_sel_o <= 4'b0000;
							excepttype_is_ades <= `True_v;
							bad_v_addr_o <= mem_addr_i;
						end
					endcase
				end
				`EXE_SW_OP: begin
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteEnable;
					case (mem_addr_i[1:0])
						2'b00: begin
							mem_ce_o <= `ChipEnable;
							mem_data_o <= reg2_i;
							mem_sel_o <= 4'b1111;
						end
						default: begin
							mem_ce_o <= `ChipDisable;
							mem_data_o <= `ZeroWord;
							mem_sel_o <= 4'b0000;
							excepttype_is_ades <= `True_v;
							bad_v_addr_o <= mem_addr_i;
						end
					endcase
				end
				`EXE_SWL_OP: begin
					mem_addr_o <= {mem_addr_i[31:2], 2'b00};
					mem_we <= `WriteEnable;
					mem_ce_o <= `ChipEnable;
					case (mem_addr_i[1:0])
						2'b11: begin
							mem_sel_o <= 4'b1111;
							mem_data_o <= reg2_i;
						end
						2'b10: begin
							mem_sel_o <= 4'b0111;
							mem_data_o <= {zero32[7:0], reg2_i[31:8]};
						end
						2'b01: begin
							mem_sel_o <= 4'b0011;
							mem_data_o <= {zero32[15:0], reg2_i[31:16]};
						end
						2'b00: begin
							mem_sel_o <= 4'b0001;
							mem_data_o <= {zero32[23:0], reg2_i[31:24]};
						end
						default: begin
							mem_sel_o <= 4'b0000;
						end
					endcase
				end
				`EXE_SWR_OP: begin
					mem_addr_o <= {mem_addr_i[31:2], 2'b00};
					mem_we <= `WriteEnable;
					mem_ce_o <= `ChipEnable;
					case (mem_addr_i[1:0])
						2'b11: begin
							mem_sel_o <= 4'b1000;
							mem_data_o <= {reg2_i[7:0], zero32[23:0]};
						end
						2'b10: begin
							mem_sel_o <= 4'b1100;
							mem_data_o <= {reg2_i[15:0], zero32[15:0]};
						end
						2'b01: begin
							mem_sel_o <= 4'b1110;
							mem_data_o <= {reg2_i[23:0], zero32[7:0]};
						end
						2'b00: begin
							mem_sel_o <= 4'b1111;
							mem_data_o <= reg2_i[31:0];
						end
						default: begin
							mem_sel_o <= 4'b0000;
						end
					endcase
				end
				`EXE_TLBWI_OP: begin
					tlb_we_o <= `WriteEnable;
					tlb_data_o <= {1'b0, cp0_entry_hi[31:13], cp0_entry_lo_1[25:6], cp0_entry_lo_1[2:1], cp0_entry_lo_0[25:6], cp0_entry_lo_0[2:1]};
					tlb_index_o <= cp0_index[`TLBIndexWidth-1:0];
				end
				default: begin
				end
			endcase
		end
	end

	//�õ�CP0��Status�Ĵ���������ֵ
	//�жϵ�ǰ���ڻ�д�׶ε�ָ���Ƿ�ҪдCP0�е�Status�Ĵ��������Ҫд����ôҪд���ֵ����Status�Ĵ���������ֵ��
	//��֮����CP0ģ��ͨ��cp0_status_i�ӿڴ�������ݾ���Status�Ĵ���������ֵ
	always @ (*) begin
		if (rst == `RstEnable) begin
			cp0_status <= `ZeroWord;
		end else if ((wb_cp0_reg_we == `WriteEnable) && (wb_cp0_reg_write_addr == `CP0_REG_STATUS)) begin
			cp0_status <= wb_cp0_reg_data;
		end else begin
			cp0_status <= cp0_status_i;
		end
	end

	//�õ�CP0��EPC�Ĵ���������ֵ
	//�жϵ�ǰ���ڻ�д�׶ε�ָ���Ƿ�ҪдCP0��EPC�Ĵ��������Ҫд����ôҪд���ֵ����EPC�Ĵ���������ֵ��
	//��֮����CP0ģ��ͨ��cp0_reg_i�ӿڴ�������ݾ���EPC�Ĵ���������ֵ
	always @ (*) begin
		if (rst == `RstEnable) begin
			cp0_epc <= `ZeroWord;
		end else if ((wb_cp0_reg_we == `WriteEnable) && (wb_cp0_reg_write_addr == `CP0_REG_EPC)) begin
			cp0_epc <= wb_cp0_reg_data;
		end else begin
			cp0_epc <= cp0_epc_i;
		end
	end

	//��EPC�Ĵ���������ֵͨ���ӿ�cp0_epc_o���
	assign cp0_epc_o = cp0_epc;

	//�õ�CP0��Cause�Ĵ���������ֵ
	//�жϵ�ǰ���ڻ�д�׶ε�ָ���Ƿ�ҪдCP0�е�Cause�Ĵ��������Ҫд����ôҪд���ֵ����Cause�Ĵ���������ֵ��
	//����Ҫע��һ�㣺Cause�Ĵ���ֻ�м����ֶ��ǿ�д��
	//��֮����CP0ģ��ͨ��cp0_cause_i�ӿڴ�������ݾ���Cause�Ĵ���������ֵ
	always @ (*) begin
		if (rst == `RstEnable) begin
			cp0_cause <= `ZeroWord;
		end else if ((wb_cp0_reg_we == `WriteEnable) && (wb_cp0_reg_write_addr == `CP0_REG_CAUSE)) begin
			cp0_cause <= wb_cp0_reg_data;
		end else begin
			cp0_cause <= cp0_cause_i;
		end
	end

	//�õ�CP0��Index�Ĵ���������ֵ
	//�жϵ�ǰ���ڻ�д�׶ε�ָ���Ƿ�ҪдCP0��Index�Ĵ��������Ҫд����ôҪд���ֵ����Index�Ĵ���������ֵ��
	//��֮����CP0ģ��ͨ��cp0_reg_i�ӿڴ�������ݾ���Index�Ĵ���������ֵ
	always @ (*) begin
		if (rst == `RstEnable) begin
			cp0_index <= `ZeroWord;
		end else if ((wb_cp0_reg_we == `WriteEnable) && (wb_cp0_reg_write_addr == `CP0_REG_INDEX)) begin
			cp0_index <= wb_cp0_reg_data;
		end else begin
			cp0_index <= cp0_index_i;
		end
	end

	//�õ�CP0��EntryLo0�Ĵ���������ֵ
	//�жϵ�ǰ���ڻ�д�׶ε�ָ���Ƿ�ҪдCP0��EntryLo0�Ĵ��������Ҫд����ôҪд���ֵ����EntryLo0�Ĵ���������ֵ��
	//��֮����CP0ģ��ͨ��cp0_reg_i�ӿڴ�������ݾ���EntryLo0�Ĵ���������ֵ
	always @ (*) begin
		if (rst == `RstEnable) begin
			cp0_entry_lo_0 <= `ZeroWord;
		end else if ((wb_cp0_reg_we == `WriteEnable) && (wb_cp0_reg_write_addr == `CP0_REG_ENTRYLO0)) begin
			cp0_entry_lo_0 <= wb_cp0_reg_data;
		end else begin
			cp0_entry_lo_0 <= cp0_entry_lo_0_i;
		end
	end

	//�õ�CP0��EntryLo1�Ĵ���������ֵ
	//�жϵ�ǰ���ڻ�д�׶ε�ָ���Ƿ�ҪдCP0��EntryLo1�Ĵ��������Ҫд����ôҪд���ֵ����EntryLo1�Ĵ���������ֵ��
	//��֮����CP0ģ��ͨ��cp0_reg_i�ӿڴ�������ݾ���EntryLo1�Ĵ���������ֵ
	always @ (*) begin
		if (rst == `RstEnable) begin
			cp0_entry_lo_1 <= `ZeroWord;
		end else if ((wb_cp0_reg_we == `WriteEnable) && (wb_cp0_reg_write_addr == `CP0_REG_ENTRYLO1)) begin
			cp0_entry_lo_1 <= wb_cp0_reg_data;
		end else begin
			cp0_entry_lo_1 <= cp0_entry_lo_1_i;
		end
	end

	//�õ�CP0��EntryHi�Ĵ���������ֵ
	//�жϵ�ǰ���ڻ�д�׶ε�ָ���Ƿ�ҪдCP0��EntryHi�Ĵ��������Ҫд����ôҪд���ֵ����EntryHi�Ĵ���������ֵ��
	//��֮����CP0ģ��ͨ��cp0_reg_i�ӿڴ�������ݾ���EntryHi�Ĵ���������ֵ
	always @ (*) begin
		if (rst == `RstEnable) begin
			cp0_entry_hi <= `ZeroWord;
		end else if ((wb_cp0_reg_we == `WriteEnable) && (wb_cp0_reg_write_addr == `CP0_REG_ENTRYHI)) begin
			cp0_entry_hi <= wb_cp0_reg_data;
		end else begin
			cp0_entry_hi <= cp0_entry_hi_i;
		end
	end

	//�������յ��쳣����
	always @ (*) begin
		if (rst == `RstEnable) begin
			excepttype_o <= `ZeroWord;
		end else begin
			excepttype_o <= `ZeroWord;
			if (current_inst_address_i != `ZeroWord) begin
				if (((cp0_cause[15:8] & (cp0_status[15:8])) != 8'h00) &&
					(cp0_status[1] == 1'b0) &&
					(cp0_status[0] == 1'b1)) begin
					excepttype_o <= `EXCEPTION_INTERRUPT;
				end else if (excepttype[1] == 1'b1) begin
					excepttype_o <= `EXCEPTION_TLBM;
				end else if (excepttype[2] == 1'b1) begin
					excepttype_o <= `EXCEPTION_TLBL;
				end else if (excepttype[3] == 1'b1) begin
					excepttype_o <= `EXCEPTION_TLBS;
				end else if (excepttype[4] == 1'b1) begin
					excepttype_o <= `EXCEPTION_ADEL;
				end else if (excepttype[5] == 1'b1) begin
					excepttype_o <= `EXCEPTION_ADES;
				end else if (excepttype[8] == 1'b1) begin
					excepttype_o <= `EXCEPTION_SYSCALL;
				end else if (excepttype[10] == 1'b1) begin
					excepttype_o <= `EXCEPTION_RI;
				end else if (excepttype[11] == 1'b1) begin
					excepttype_o <= `EXCEPTION_CPU;
				end else if (excepttype[23] == 1'b1) begin
					excepttype_o <= `EXCEPTION_WATCH;
				end else if (excepttype[12] == 1'b1) begin
					excepttype_o <= `EXCEPTION_ERET;
				end
			end
		end
	end

endmodule

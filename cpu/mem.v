`include "defines.v"
module mem(
	input		wire					rst,

	//来自执行阶段的信息
	input		wire[`RegAddrBus]		wd_i,
	input		wire					wreg_i,
	input		wire[`RegBus]			wdata_i,
	input		wire[`RegBus]			hi_i,
	input		wire[`RegBus]			lo_i,
	input		wire					whilo_i,
	input		wire[`AluOpBus]			aluop_i,
	input		wire[`RegBus]			mem_addr_i,
	input		wire[`RegBus]			reg2_i,

	//来自MMU模块的信息
	input		wire[`RegBus]			mem_data_i,

	input		wire					cp0_reg_we_i,
	input		wire[4:0]				cp0_reg_write_addr_i,
	input		wire[`RegBus]			cp0_reg_data_i,

	//来自执行阶段
	input		wire[31:0]				excepttype_i,
	input		wire					is_in_delayslot_i,
	input		wire[`RegBus]			current_inst_address_i,

	//CP0的各个寄存器的值，但不一定是最新的值，要防止回写阶段指令写CP0
	input		wire[`RegBus]			cp0_bad_v_addr_i,
	input		wire[`RegBus]			cp0_status_i,
	input		wire[`RegBus]			cp0_cause_i,
	input		wire[`RegBus]			cp0_epc_i,
	input		wire[`RegBus]			cp0_index_i,
	input		wire[`RegBus]			cp0_entry_lo_0_i,
	input		wire[`RegBus]			cp0_entry_lo_1_i,
	input		wire[`RegBus]			cp0_entry_hi_i,

	//来自回写阶段的指令对CP0寄存器的写信息，用来检测数据相关
	input		wire					wb_cp0_reg_we,
	input		wire[4:0]				wb_cp0_reg_write_addr,
	input		wire[`RegBus]			wb_cp0_reg_data,

	//来自MMU模块的TLB异常信息
	input		wire					excepttype_is_tlbm_i,
	input		wire					excepttype_is_tlbl_i,
	input		wire					excepttype_is_tlbs_i,

	//访存阶段的结果
	output		reg[`RegAddrBus]		wd_o,
	output		reg						wreg_o,
	output		reg[`RegBus]			wdata_o,
	output		reg[`RegBus]			hi_o,
	output		reg[`RegBus]			lo_o,
	output		reg						whilo_o,

	output		reg						cp0_reg_we_o,
	output		reg[4:0]				cp0_reg_write_addr_o,
	output		reg[`RegBus]			cp0_reg_data_o,

	//送到MMU的信息
	output		reg[`RegBus]			mem_addr_o,
	output		wire					mem_we_o,
	output		reg[3:0]				mem_sel_o,
	output		reg[`RegBus]			mem_data_o,
	output		reg						mem_ce_o,

	//送到CP0寄存器的信息
	output		reg[31:0]				excepttype_o,
	output		wire[`RegBus]			cp0_epc_o,
	output		wire					is_in_delayslot_o,

	output		wire[`RegBus]			current_inst_address_o,
	output		reg[`RegBus]			bad_v_addr_o,

	//送到TLB模块的信息
	output		reg						tlb_we_o,
	output		reg[`TLBIndexBus]		tlb_index_o,
	output		reg[`TLBDataBus]		tlb_data_o

	//送到CTRL模块的信息
	// output		reg 					stall_req
	);

	wire[`RegBus] zero32;
	reg mem_we;

	reg[`RegBus] cp0_bad_v_addr;		//用来保存CP0中BadVAddr寄存器的最新值
	reg[`RegBus] cp0_status;			//用来保存CP0中Status寄存器的最新值
	reg[`RegBus] cp0_cause;				//用来保存CP0中Cause寄存器的最新值
	reg[`RegBus] cp0_epc;				//用来保存CP0中EPC寄存器的最新值

	reg[`RegBus] cp0_index;				//用来保存CP0中Index寄存器的最新值
	reg[`RegBus] cp0_entry_lo_0;		//用来保存CP0中EntryLo0寄存器的最新值
	reg[`RegBus] cp0_entry_lo_1;		//用来保存CP0中EntryLo1寄存器的最新值
	reg[`RegBus] cp0_entry_hi;			//用来保存CP0中EntryHi寄存器的最新值

	reg excepttype_is_adel;				//是否是读访问非对齐异常ADEL
	reg excepttype_is_ades;				//是否是写访问非对齐异常ADES
	reg excepttype_is_watch;			//是否是Watch监控异常Watch

	wire[31:0] excepttype;

	assign zero32 = `ZeroWord;

	//访存阶段指令是否是延迟槽指令
	assign is_in_delayslot_o = is_in_delayslot_i;
	assign current_inst_address_o = current_inst_address_i;

	//excepttype_o的第1bit表示是否是内存修改异常，第2bit表示是否是读未在TLB中映射的内存地址异常，第3bit表示是否是写未在TLB中映射的内存地址异常，
	//第4bit表示是否是读访问非对齐异常ADEL，第5bit表示是否是写访问非对齐异常，第23bit表示是否是Watch监控异常
	assign excepttype = {excepttype_i[31:24], excepttype_is_watch, excepttype_i[22:6], excepttype_is_ades, excepttype_is_adel, excepttype_is_tlbs_i, excepttype_is_tlbl_i, excepttype_is_tlbm_i, excepttype_i[0]};

	//mem_we_o输出到数据存储器，表示是否是对数据存储器的写操作，如果发生了异常，那么需要取消对数据存储器的写操作
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
			excepttype_is_adel <= `False_v;			//默认没有发生读访问非对齐异常
			excepttype_is_ades <= `False_v;			//默认没有发生写访问非对齐异常
			excepttype_is_watch <= `False_v;		//默认没有发生Watch监控异常
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

	//得到CP0中Status寄存器的最新值
	//判断当前处于回写阶段的指令是否要写CP0中的Status寄存器，如果要写，那么要写入的值就是Status寄存器的最新值，
	//反之，从CP0模块通过cp0_status_i接口传入的数据就是Status寄存器的最新值
	always @ (*) begin
		if (rst == `RstEnable) begin
			cp0_status <= `ZeroWord;
		end else if ((wb_cp0_reg_we == `WriteEnable) && (wb_cp0_reg_write_addr == `CP0_REG_STATUS)) begin
			cp0_status <= wb_cp0_reg_data;
		end else begin
			cp0_status <= cp0_status_i;
		end
	end

	//得到CP0中EPC寄存器的最新值
	//判断当前处于会写阶段的指令是否要写CP0中EPC寄存器，如果要写，那么要写入的值就是EPC寄存器的最新值，
	//反之，从CP0模块通过cp0_reg_i接口传入的数据就是EPC寄存器的最新值
	always @ (*) begin
		if (rst == `RstEnable) begin
			cp0_epc <= `ZeroWord;
		end else if ((wb_cp0_reg_we == `WriteEnable) && (wb_cp0_reg_write_addr == `CP0_REG_EPC)) begin
			cp0_epc <= wb_cp0_reg_data;
		end else begin
			cp0_epc <= cp0_epc_i;
		end
	end

	//将EPC寄存器的最新值通过接口cp0_epc_o输出
	assign cp0_epc_o = cp0_epc;

	//得到CP0中Cause寄存器的最新值
	//判断当前处于会写阶段的指令是否要写CP0中的Cause寄存器，如果要写，那么要写入的值就是Cause寄存器的最新值，
	//不过要注意一点：Cause寄存器只有几个字段是可写的
	//反之，从CP0模块通过cp0_cause_i接口传入的数据就是Cause寄存器的最新值
	always @ (*) begin
		if (rst == `RstEnable) begin
			cp0_cause <= `ZeroWord;
		end else if ((wb_cp0_reg_we == `WriteEnable) && (wb_cp0_reg_write_addr == `CP0_REG_CAUSE)) begin
			cp0_cause <= wb_cp0_reg_data;
		end else begin
			cp0_cause <= cp0_cause_i;
		end
	end

	//得到CP0中Index寄存器的最新值
	//判断当前处于会写阶段的指令是否要写CP0中Index寄存器，如果要写，那么要写入的值就是Index寄存器的最新值，
	//反之，从CP0模块通过cp0_reg_i接口传入的数据就是Index寄存器的最新值
	always @ (*) begin
		if (rst == `RstEnable) begin
			cp0_index <= `ZeroWord;
		end else if ((wb_cp0_reg_we == `WriteEnable) && (wb_cp0_reg_write_addr == `CP0_REG_INDEX)) begin
			cp0_index <= wb_cp0_reg_data;
		end else begin
			cp0_index <= cp0_index_i;
		end
	end

	//得到CP0中EntryLo0寄存器的最新值
	//判断当前处于会写阶段的指令是否要写CP0中EntryLo0寄存器，如果要写，那么要写入的值就是EntryLo0寄存器的最新值，
	//反之，从CP0模块通过cp0_reg_i接口传入的数据就是EntryLo0寄存器的最新值
	always @ (*) begin
		if (rst == `RstEnable) begin
			cp0_entry_lo_0 <= `ZeroWord;
		end else if ((wb_cp0_reg_we == `WriteEnable) && (wb_cp0_reg_write_addr == `CP0_REG_ENTRYLO0)) begin
			cp0_entry_lo_0 <= wb_cp0_reg_data;
		end else begin
			cp0_entry_lo_0 <= cp0_entry_lo_0_i;
		end
	end

	//得到CP0中EntryLo1寄存器的最新值
	//判断当前处于会写阶段的指令是否要写CP0中EntryLo1寄存器，如果要写，那么要写入的值就是EntryLo1寄存器的最新值，
	//反之，从CP0模块通过cp0_reg_i接口传入的数据就是EntryLo1寄存器的最新值
	always @ (*) begin
		if (rst == `RstEnable) begin
			cp0_entry_lo_1 <= `ZeroWord;
		end else if ((wb_cp0_reg_we == `WriteEnable) && (wb_cp0_reg_write_addr == `CP0_REG_ENTRYLO1)) begin
			cp0_entry_lo_1 <= wb_cp0_reg_data;
		end else begin
			cp0_entry_lo_1 <= cp0_entry_lo_1_i;
		end
	end

	//得到CP0中EntryHi寄存器的最新值
	//判断当前处于会写阶段的指令是否要写CP0中EntryHi寄存器，如果要写，那么要写入的值就是EntryHi寄存器的最新值，
	//反之，从CP0模块通过cp0_reg_i接口传入的数据就是EntryHi寄存器的最新值
	always @ (*) begin
		if (rst == `RstEnable) begin
			cp0_entry_hi <= `ZeroWord;
		end else if ((wb_cp0_reg_we == `WriteEnable) && (wb_cp0_reg_write_addr == `CP0_REG_ENTRYHI)) begin
			cp0_entry_hi <= wb_cp0_reg_data;
		end else begin
			cp0_entry_hi <= cp0_entry_hi_i;
		end
	end

	//给出最终的异常类型
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

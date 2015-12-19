`include "defines.v"
module cp0_reg(
	input			wire				clk,
	input			wire				rst,

	input			wire				we_i,
	input			wire[4:0]			waddr_i,
	input			wire[4:0]			raddr_i,
	input			wire[`RegBus]		data_i,

	input			wire[31:0]			excepttype_i,
	input			wire[5:0]			int_i,
	input			wire[`RegBus]		current_inst_addr_i,
	input			wire[`RegBus]		bad_v_addr_i,
	input			wire				is_in_delayslot_i,

	output			reg[`RegBus]		data_o,
	output			reg[`RegBus]		index_o,
	output			reg[`RegBus]		entry_lo_0_o,
	output			reg[`RegBus]		entry_lo_1_o,
	output			reg[`RegBus]		bad_v_addr_o,
	output			reg[`RegBus]		count_o,
	output			reg[`RegBus]		entry_hi_o,
	output			reg[`RegBus]		compare_o,
	output			reg[`RegBus]		status_o,
	output			reg[`RegBus]		cause_o,
	output			reg[`RegBus]		epc_o,
	output			reg[`RegBus]		ebase_o,

	output			reg					timer_int_o
	);

	/*********************		第一段：对CP0中寄存器的写操作		*********************/
	always @ (posedge clk) begin
		if (rst == `RstEnable) begin

			//Index寄存器的初始值，为0
			index_o <= `ZeroWord;

			//EntryLo0寄存器的初始值
			entry_lo_0_o <= `ZeroWord;

			//EntryLo1寄存器的初始值
			entry_lo_1_o <= `ZeroWord;

			//BadVAddr寄存器的初始值
			bad_v_addr_o <= `ZeroWord;

			//Count寄存器的初始值，为0
			count_o <= `ZeroWord;

			//EntryHi寄存器的初始值
			entry_hi_o <= `ZeroWord;

			//Compare寄存器的初始值，为0
			compare_o <= `ZeroWord;

			//Status寄存器的初始值，其中CU字段为4'b0001，表示协处理器CP0存在
			status_o <= 32'b00010000000000000000000000000000;

			//Cause寄存器的初始值
			cause_o <= `ZeroWord;

			//EPC寄存器的初始值
			epc_o <= `ZeroWord;

			//EBase寄存器的初始值
			ebase_o <= 32'b10000000000000000000000000000000;			

			timer_int_o <= `InterruptNotAssert;

		end else begin

			count_o <= count_o + 1;				//Count寄存器的值在每个时钟周期加1
			cause_o[15:10] <= int_i;			//Cause寄存器的第10~15bit保持外部中断声明

			//当Compare寄存器不为0，且Count寄存器的值等于Compare寄存器的值时，将输出信号timer_int_o置为1，表示时钟中断发生
			if (compare_o != `ZeroWord && count_o == compare_o) begin
				timer_int_o <= `InterruptAssert;
			end

			if (we_i == `WriteEnable) begin
				case (waddr_i)
					`CP0_REG_INDEX: begin		//写Index寄存器
						//31位检测故障，当TLBP指令没有在TLB中寻得匹配的时候置为1
						//30:6位固定为0
						index_o[5:0] <= data_i[5:0];
					end
					`CP0_REG_ENTRYLO0: begin	//写EntryLo0寄存器
						//31:30位和29:26位固定为0
						//25:6位对应物理地址的31:12位
						entry_lo_0_o[25:6] <= data_i[25:6];

						//5:3位为页面一致性属性
						entry_lo_0_o[5:3] <= data_i[5:3];

						//2,1,0分别为已使用或写使能位、有效位、全局位
						entry_lo_0_o[2:0] <= data_i[2:0];
					end
					`CP0_REG_ENTRYLO1: begin	//写EntryLo1寄存器
						//31:30位和29:26位固定为0
						//25:6位对应物理地址的31:12位
						entry_lo_1_o[25:6] <= data_i[25:6];

						//5:3位为页面一致性属性
						entry_lo_1_o[5:3] <= data_i[5:3];

						//2,1,0分别为已使用或写使能位、有效位、全局位
						entry_lo_1_o[2:0] <= data_i[2:0];
					end
					`CP0_REG_BADVADDR: begin	//写BadVAddr寄存器
						bad_v_addr_o <= data_i;
					end
					`CP0_REG_COUNT: begin		//写Count寄存器
						count_o <= data_i;
					end
					`CP0_REG_ENTRYHI: begin		//写EntryHi寄存器
						entry_hi_o[31:13] <= data_i[31:13];
						entry_hi_o[7:0] <= data_i[7:0];
					end
					`CP0_REG_COMPARE: begin		//写Compare寄存器
						compare_o <= data_i;
						timer_int_o <= `InterruptNotAssert;
					end
					`CP0_REG_STATUS: begin		//写Status寄存器
						status_o <= data_i;
					end
					`CP0_REG_CAUSE: begin		//写Cause寄存器
						//Cause寄存器只有IP[1:0]、IV、WP字段是可写的
						cause_o[9:8] <= data_i[9:8];
						cause_o[23] <= data_i[23];
						cause_o[22] <= data_i[22];
					end
					`CP0_REG_EPC: begin			//写EPC寄存器
						epc_o <= data_i;
					end
					`CP0_REG_EBASE: begin		//写EBase寄存器
						//写入时该位忽略，读取时返回0
						ebase_o[31] <= data_i[31];

						//指定异常的基地址
						ebase_o[29:12] <= data_i[29:12];

						//这9位由外部设置，对每个CPU都是唯一的，这个区域的值由连接到内核的SI.CPUNum[9:0]静态输入管脚设置
						ebase_o[9:0] <= data_i[9:0];
					end
					default: begin
					end
				endcase
			end

			case (excepttype_i)
				`EXCEPTION_INTERRUPT: begin
					if (is_in_delayslot_i == `InDelaySlot) begin
						epc_o <= current_inst_addr_i - 4;
						cause_o[31] <= 1'b1;	//Cause的Branch Delayslot
					end else begin
						epc_o <= current_inst_addr_i;
						cause_o[31] <= 1'b0;
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b00000;
				end
				`EXCEPTION_TLBM: begin
					if (status_o[1] == 1'b0) begin
						if (is_in_delayslot_i == `InDelaySlot) begin
							epc_o <= current_inst_addr_i - 4;
							cause_o[31] <= 1'b1;
						end else begin
							epc_o <= current_inst_addr_i;
							cause_o[31] <= 1'b0;
						end
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b00001;
					bad_v_addr_o <= bad_v_addr_i;
				end
				`EXCEPTION_TLBL: begin
					if (status_o[1] == 1'b0) begin
						if (is_in_delayslot_i == `InDelaySlot) begin
							epc_o <= current_inst_addr_i - 4;
							cause_o[31] <= 1'b1;
						end else begin
							epc_o <= current_inst_addr_i;
							cause_o[31] <= 1'b0;
						end
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b00010;
					bad_v_addr_o <= bad_v_addr_i;
				end
				`EXCEPTION_TLBS: begin
					if (status_o[1] == 1'b0) begin
						if (is_in_delayslot_i == `InDelaySlot) begin
							epc_o <= current_inst_addr_i - 4;
							cause_o[31] <= 1'b1;
						end else begin
							epc_o <= current_inst_addr_i;
							cause_o[31] <= 1'b0;
						end
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b00011;
					bad_v_addr_o <= bad_v_addr_i;
				end
				`EXCEPTION_ADEL: begin
					if (status_o[1] == 1'b0) begin
						if (is_in_delayslot_i == `InDelaySlot) begin
							epc_o <= current_inst_addr_i - 4;
							cause_o[31] <= 1'b1;
						end else begin
							epc_o <= current_inst_addr_i;
							cause_o[31] <= 1'b0;
						end
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b00100;
					bad_v_addr_o <= bad_v_addr_i;
				end
				`EXCEPTION_ADES: begin
					if (status_o[1] == 1'b0) begin
						if (is_in_delayslot_i == `InDelaySlot) begin
							epc_o <= current_inst_addr_i - 4;
							cause_o[31] <= 1'b1;
						end else begin
							epc_o <= current_inst_addr_i;
							cause_o[31] <= 1'b0;
						end
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b00101;
					bad_v_addr_o <= bad_v_addr_i;
				end
				`EXCEPTION_SYSCALL: begin
					if (status_o[1] == 1'b0) begin						//EXL字段，0表示异常未发生
						if (is_in_delayslot_i == `InDelaySlot) begin	//如果当前指令在延迟槽中
							epc_o <= current_inst_addr_i - 4;
							cause_o[31] <= 1'b1;						//BD字段，1表示在延迟槽中
						end else begin
							epc_o <= current_inst_addr_i;
							cause_o[31] <= 1'b0;
						end
					end
					status_o[1] <= 1'b1;								//EXL字段，1表示异常发生
					cause_o[6:2] <= 5'b01000;
				end
				`EXCEPTION_RI: begin
					if (status_o[1] == 1'b0) begin
						if (is_in_delayslot_i == `InDelaySlot) begin
							epc_o <= current_inst_addr_i - 4;
							cause_o[31] <= 1'b1;
						end else begin
							epc_o <= current_inst_addr_i;
							cause_o[31] <= 1'b0;
						end
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b01010;
				end
				`EXCEPTION_CPU: begin
					if (status_o[1] == 1'b0) begin
						if (is_in_delayslot_i == `InDelaySlot) begin
							epc_o <= current_inst_addr_i - 4;
							cause_o[31] <= 1'b1;
						end else begin
							epc_o <= current_inst_addr_i;
							cause_o[31] <= 1'b0;
						end
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b01011;
				end
				`EXCEPTION_WATCH: begin
					if (status_o[1] == 1'b0) begin
						if (is_in_delayslot_i == `InDelaySlot) begin
							epc_o <= current_inst_addr_i - 4;
							cause_o[31] <= 1'b1;
						end else begin
							epc_o <= current_inst_addr_i;
							cause_o[31] <= 1'b0;
						end
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b10111;
				end
				`EXCEPTION_ERET: begin				//eret
					status_o[1] <= 1'b0;
				end
				default: begin
				end
			endcase
		end
	end

	/*********************		第二段：对CP0中寄存器的读操作		*********************/
	always @ (*) begin
		if (rst == `RstEnable) begin
			data_o <= `ZeroWord;
		end else begin
			data_o <= `ZeroWord;
			case (raddr_i)
				`CP0_REG_INDEX: begin			//读Index寄存器
					data_o <= index_o;
				end
				`CP0_REG_ENTRYLO0: begin		//读EntryLo0寄存器
					data_o <= entry_lo_0_o;
				end
				`CP0_REG_ENTRYLO1: begin		//读EntryLo1寄存器
					data_o <= entry_lo_1_o;
				end
				`CP0_REG_BADVADDR: begin		//读BadVAddr寄存器
					data_o <= bad_v_addr_o;
				end
				`CP0_REG_COUNT: begin			//读Count寄存器
					data_o <= count_o;
				end
				`CP0_REG_ENTRYHI: begin			//读EntryHi寄存器
					data_o <= entry_hi_o;
				end
				`CP0_REG_COMPARE: begin			//读Compare寄存器
					data_o <= compare_o;
				end
				`CP0_REG_STATUS: begin			//读Status寄存器
					data_o <= status_o;
				end
				`CP0_REG_CAUSE: begin			//读Cause寄存器
					data_o <= cause_o;
				end
				`CP0_REG_EPC: begin				//读EPC寄存器
					data_o <= epc_o;
				end
				`CP0_REG_EBASE: begin			//读EBase寄存器
					data_o <= ebase_o;
				end
				default: begin
				end
			endcase
		end
	end

endmodule

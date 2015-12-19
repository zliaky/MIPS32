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

	/*********************		��һ�Σ���CP0�мĴ�����д����		*********************/
	always @ (posedge clk) begin
		if (rst == `RstEnable) begin

			//Index�Ĵ����ĳ�ʼֵ��Ϊ0
			index_o <= `ZeroWord;

			//EntryLo0�Ĵ����ĳ�ʼֵ
			entry_lo_0_o <= `ZeroWord;

			//EntryLo1�Ĵ����ĳ�ʼֵ
			entry_lo_1_o <= `ZeroWord;

			//BadVAddr�Ĵ����ĳ�ʼֵ
			bad_v_addr_o <= `ZeroWord;

			//Count�Ĵ����ĳ�ʼֵ��Ϊ0
			count_o <= `ZeroWord;

			//EntryHi�Ĵ����ĳ�ʼֵ
			entry_hi_o <= `ZeroWord;

			//Compare�Ĵ����ĳ�ʼֵ��Ϊ0
			compare_o <= `ZeroWord;

			//Status�Ĵ����ĳ�ʼֵ������CU�ֶ�Ϊ4'b0001����ʾЭ������CP0����
			status_o <= 32'b00010000000000000000000000000000;

			//Cause�Ĵ����ĳ�ʼֵ
			cause_o <= `ZeroWord;

			//EPC�Ĵ����ĳ�ʼֵ
			epc_o <= `ZeroWord;

			//EBase�Ĵ����ĳ�ʼֵ
			ebase_o <= 32'b10000000000000000000000000000000;			

			timer_int_o <= `InterruptNotAssert;

		end else begin

			count_o <= count_o + 1;				//Count�Ĵ�����ֵ��ÿ��ʱ�����ڼ�1
			cause_o[15:10] <= int_i;			//Cause�Ĵ����ĵ�10~15bit�����ⲿ�ж�����

			//��Compare�Ĵ�����Ϊ0����Count�Ĵ�����ֵ����Compare�Ĵ�����ֵʱ��������ź�timer_int_o��Ϊ1����ʾʱ���жϷ���
			if (compare_o != `ZeroWord && count_o == compare_o) begin
				timer_int_o <= `InterruptAssert;
			end

			if (we_i == `WriteEnable) begin
				case (waddr_i)
					`CP0_REG_INDEX: begin		//дIndex�Ĵ���
						//31λ�����ϣ���TLBPָ��û����TLB��Ѱ��ƥ���ʱ����Ϊ1
						//30:6λ�̶�Ϊ0
						index_o[5:0] <= data_i[5:0];
					end
					`CP0_REG_ENTRYLO0: begin	//дEntryLo0�Ĵ���
						//31:30λ��29:26λ�̶�Ϊ0
						//25:6λ��Ӧ�����ַ��31:12λ
						entry_lo_0_o[25:6] <= data_i[25:6];

						//5:3λΪҳ��һ��������
						entry_lo_0_o[5:3] <= data_i[5:3];

						//2,1,0�ֱ�Ϊ��ʹ�û�дʹ��λ����Чλ��ȫ��λ
						entry_lo_0_o[2:0] <= data_i[2:0];
					end
					`CP0_REG_ENTRYLO1: begin	//дEntryLo1�Ĵ���
						//31:30λ��29:26λ�̶�Ϊ0
						//25:6λ��Ӧ�����ַ��31:12λ
						entry_lo_1_o[25:6] <= data_i[25:6];

						//5:3λΪҳ��һ��������
						entry_lo_1_o[5:3] <= data_i[5:3];

						//2,1,0�ֱ�Ϊ��ʹ�û�дʹ��λ����Чλ��ȫ��λ
						entry_lo_1_o[2:0] <= data_i[2:0];
					end
					`CP0_REG_BADVADDR: begin	//дBadVAddr�Ĵ���
						bad_v_addr_o <= data_i;
					end
					`CP0_REG_COUNT: begin		//дCount�Ĵ���
						count_o <= data_i;
					end
					`CP0_REG_ENTRYHI: begin		//дEntryHi�Ĵ���
						entry_hi_o[31:13] <= data_i[31:13];
						entry_hi_o[7:0] <= data_i[7:0];
					end
					`CP0_REG_COMPARE: begin		//дCompare�Ĵ���
						compare_o <= data_i;
						timer_int_o <= `InterruptNotAssert;
					end
					`CP0_REG_STATUS: begin		//дStatus�Ĵ���
						status_o <= data_i;
					end
					`CP0_REG_CAUSE: begin		//дCause�Ĵ���
						//Cause�Ĵ���ֻ��IP[1:0]��IV��WP�ֶ��ǿ�д��
						cause_o[9:8] <= data_i[9:8];
						cause_o[23] <= data_i[23];
						cause_o[22] <= data_i[22];
					end
					`CP0_REG_EPC: begin			//дEPC�Ĵ���
						epc_o <= data_i;
					end
					`CP0_REG_EBASE: begin		//дEBase�Ĵ���
						//д��ʱ��λ���ԣ���ȡʱ����0
						ebase_o[31] <= data_i[31];

						//ָ���쳣�Ļ���ַ
						ebase_o[29:12] <= data_i[29:12];

						//��9λ���ⲿ���ã���ÿ��CPU����Ψһ�ģ���������ֵ�����ӵ��ں˵�SI.CPUNum[9:0]��̬����ܽ�����
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
						cause_o[31] <= 1'b1;	//Cause��Branch Delayslot
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
					if (status_o[1] == 1'b0) begin						//EXL�ֶΣ�0��ʾ�쳣δ����
						if (is_in_delayslot_i == `InDelaySlot) begin	//�����ǰָ�����ӳٲ���
							epc_o <= current_inst_addr_i - 4;
							cause_o[31] <= 1'b1;						//BD�ֶΣ�1��ʾ���ӳٲ���
						end else begin
							epc_o <= current_inst_addr_i;
							cause_o[31] <= 1'b0;
						end
					end
					status_o[1] <= 1'b1;								//EXL�ֶΣ�1��ʾ�쳣����
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

	/*********************		�ڶ��Σ���CP0�мĴ����Ķ�����		*********************/
	always @ (*) begin
		if (rst == `RstEnable) begin
			data_o <= `ZeroWord;
		end else begin
			data_o <= `ZeroWord;
			case (raddr_i)
				`CP0_REG_INDEX: begin			//��Index�Ĵ���
					data_o <= index_o;
				end
				`CP0_REG_ENTRYLO0: begin		//��EntryLo0�Ĵ���
					data_o <= entry_lo_0_o;
				end
				`CP0_REG_ENTRYLO1: begin		//��EntryLo1�Ĵ���
					data_o <= entry_lo_1_o;
				end
				`CP0_REG_BADVADDR: begin		//��BadVAddr�Ĵ���
					data_o <= bad_v_addr_o;
				end
				`CP0_REG_COUNT: begin			//��Count�Ĵ���
					data_o <= count_o;
				end
				`CP0_REG_ENTRYHI: begin			//��EntryHi�Ĵ���
					data_o <= entry_hi_o;
				end
				`CP0_REG_COMPARE: begin			//��Compare�Ĵ���
					data_o <= compare_o;
				end
				`CP0_REG_STATUS: begin			//��Status�Ĵ���
					data_o <= status_o;
				end
				`CP0_REG_CAUSE: begin			//��Cause�Ĵ���
					data_o <= cause_o;
				end
				`CP0_REG_EPC: begin				//��EPC�Ĵ���
					data_o <= epc_o;
				end
				`CP0_REG_EBASE: begin			//��EBase�Ĵ���
					data_o <= ebase_o;
				end
				default: begin
				end
			endcase
		end
	end

endmodule

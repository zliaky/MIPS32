`include "defines.v"

module pc_reg(
	input		wire					clk,
	input		wire					rst,
	input		wire[5:0]				stall,		//���Կ���ģ��CTRL
	input		wire					flush,
	input		wire[`RegBus]			new_pc,
	input		wire					branch_flag_i,
	input		wire[`RegBus]			branch_target_address_i,
	output		reg[`InstAddrBus]		pc,
	output		reg						ce,
	output		reg[`InstAddrBus]		next_pc,
	output		reg[`InstAddrBus]		latch_pc
	);

	// reg[`InstAddrBus] latch_pc;

	always @ (*) begin
		if (rst == `RstEnable) begin
			ce <= `ChipDisable;						//��λʱָ��洢������
		end else begin
			ce <= `ChipEnable;						//��λ������ָ��洢��ʹ��
		end
	end

	always @ (posedge clk) begin
		pc <= latch_pc;
	end

	always @ (*) begin
		if (ce == `ChipDisable) begin
			next_pc <= 32'hbfbffffc;				//ָ��洢������ʱ��PCΪ0
			latch_pc <= 32'hbfbffffc;
			// next_pc <= 32'h7ffffffc;
			// latch_pc <= 32'h7ffffffc;
			// next_pc <= 32'h00000000;
			// latch_pc <= 32'h00000000;
		end else begin
			if (flush == 1'b1) begin				//�����ź�flushΪ1��ʾ�쳣����������CTRLģ��������쳣����������ڵ�ַnew_pc��ȡִָ��
				next_pc <= new_pc;
				latch_pc <= new_pc;
			end else begin
				if (branch_flag_i == `Branch) begin
					next_pc <= branch_target_address_i;
				end else begin
					next_pc <= pc + 4'h4;			//ָ��洢��ʹ��ʱ��PC��ֵÿʱ�����ڼ�4
				end
				if (stall[0] == `NoStop) begin
					latch_pc <= next_pc;
				end else begin
					latch_pc <= pc;
				end
			end
		end
	end

endmodule

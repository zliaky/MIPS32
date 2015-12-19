`include "defines.v"

module pc_reg(
	input		wire					clk,
	input		wire					rst,
	input		wire[5:0]				stall,		//来自控制模块CTRL
	input		wire					flush,
	input		wire[`RegBus]			new_pc,
	input		wire					branch_flag_i,
	input		wire[`RegBus]			branch_target_address_i,
	output		reg[`InstAddrBus]		pc,
	output		reg						ce,
	output		reg[`InstAddrBus]		next_pc
	);

	reg[`InstAddrBus] latch_pc;

	always @ (*) begin
		if (rst == `RstEnable) begin
			ce <= `ChipDisable;						//复位时指令存储器禁用
		end else begin
			ce <= `ChipEnable;						//复位结束后，指令存储器使能
		end
	end

	always @ (posedge clk) begin
		pc <= latch_pc;
	end

	always @ (*) begin
		if (ce == `ChipDisable) begin
			next_pc <= 32'h00000000;				//指令存储器禁用时，PC为0
			latch_pc <= 32'h00000000;
		end else begin
			if (flush == 1'b1) begin				//输入信号flush为1表示异常发生，将从CTRL模块给出的异常处理例程入口地址new_pc处取指执行
				next_pc <= new_pc;
				latch_pc <= new_pc;
			end else begin
				if (branch_flag_i == `Branch) begin
					next_pc <= branch_target_address_i;
				end else begin
					next_pc <= pc + 4'h4;			//指令存储器使能时，PC的值每时钟周期加4
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

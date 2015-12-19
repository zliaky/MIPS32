`include "defines.v"

module regfile(
	input		wire					clk,
	input		wire					rst,
	
	//д�˿�
	input		wire					we,
	input		wire[`RegAddrBus]		waddr,
	input		wire[`RegBus]			wdata,
	
	//���˿�1
	input		wire					re1,
	input		wire[`RegAddrBus]		raddr1,
	output		reg[`RegBus]			rdata1,
	
	//���˿�2
	input		wire					re2,
	input		wire[`RegAddrBus]		raddr2,
	output		reg[`RegBus]			rdata2,

	input		wire[`RegAddrBus] 		select,
	output 		reg[`RegBus]			output_data
	);

/************			��һ�Σ�����32��32λ�Ĵ���		************/
	reg[`RegBus]	regs[0:`RegNum-1];

	always @ (*) begin
		output_data <= regs[select];
	end

/************			�ڶ��Σ�д����				************/
	always @ (posedge clk) begin
		if (rst == `RstEnable) begin
			regs[0] <= 32'h00000000;
			regs[1] <= 32'h00000000;
			regs[2] <= 32'h00000000;
			regs[3] <= 32'h00000000;
			regs[4] <= 32'h00000000;
			regs[5] <= 32'h00000000;
			regs[6] <= 32'h00000000;
			regs[7] <= 32'h00000000;
			regs[8] <= 32'h00000000;
			regs[9] <= 32'h00000000;
			regs[10] <= 32'h00000000;
			regs[11] <= 32'h00000000;
			regs[12] <= 32'h00000000;
			regs[13] <= 32'h00000000;
			regs[14] <= 32'h00000000;
			regs[15] <= 32'h00000000;
			regs[16] <= 32'h00000000;
			regs[17] <= 32'h00000000;
			regs[18] <= 32'h00000000;
			regs[19] <= 32'h00000000;
			regs[20] <= 32'h00000000;
			regs[21] <= 32'h00000000;
			regs[22] <= 32'h00000000;
			regs[23] <= 32'h00000000;
			regs[24] <= 32'h00000000;
			regs[25] <= 32'h00000000;
			regs[26] <= 32'h00000000;
			regs[27] <= 32'h00000000;
			regs[28] <= 32'h00000000;
			regs[29] <= 32'h00000000;
			regs[30] <= 32'h00000000;
			regs[31] <= 32'h00000000;
		end else begin
			if ((we == `WriteEnable) && (waddr != `RegNumLog2'h0)) begin
				regs[waddr] <= wdata;
			end
		end
	end

/************			�����Σ����˿�1�Ķ�����			************/
	always @ (*) begin
		if (rst == `RstEnable) begin
			rdata1 <= `ZeroWord;
		end else if (raddr1 == `RegNumLog2'h0) begin
			rdata1 <= `ZeroWord;
		end else if ((raddr1 == waddr) &&
					(we == `WriteEnable) &&
					(re1 == `ReadEnable)) begin
			//raddr1�Ƕ�������waddr��д��ַ��we��дʹ�ܡ�wdata��Ҫд�������
			rdata1 <= wdata;
		end else if (re1 == `ReadEnable) begin
			rdata1 <= regs[raddr1];
		end else begin
			rdata1 <= `ZeroWord;
		end
	end

/************			���ĶΣ����˿�2�Ķ�����			************/
	always @ (*) begin
		if (rst == `RstEnable) begin
			rdata2 <= `ZeroWord;
		end else if (raddr2 == `RegNumLog2'h0) begin
			rdata2 <= `ZeroWord;
		end else if ((raddr2 == waddr) &&
					(we == `WriteEnable) &&
					(re2 == `ReadEnable)) begin
			//raddr2�Ƕ�������waddr��д��ַ��we��дʹ�ܡ�wdata��Ҫд�������
			rdata2 <= wdata;
		end else if (re2 == `ReadEnable) begin
			rdata2 <= regs[raddr2];
		end else begin
			rdata2 <= `ZeroWord;
		end
	end

endmodule

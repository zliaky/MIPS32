`include "defines.v"
module mem_wb(
	input		wire					clk,
	input		wire					rst,
	input		wire[5:0]				stall,
	input		wire					flush,

	//�ô�׶εĽ��
	input		wire[`RegAddrBus]		mem_wd,
	input		wire					mem_wreg,
	input		wire[`RegBus]			mem_wdata,
	input		wire[`RegBus]			mem_hi,
	input		wire[`RegBus]			mem_lo,
	input		wire					mem_whilo,

	input		wire					mem_cp0_reg_we,
	input		wire[4:0]				mem_cp0_reg_write_addr,
	input		wire[`RegBus]			mem_cp0_reg_data,

	//�͵���д�׶ε���Ϣ
	output		reg[`RegAddrBus]		wb_wd,
	output		reg						wb_wreg,
	output		reg[`RegBus]			wb_wdata,
	output		reg[`RegBus]			wb_hi,
	output		reg[`RegBus]			wb_lo,
	output		reg						wb_whilo,
	output		reg						wb_cp0_reg_we,
	output		reg[4:0]				wb_cp0_reg_write_addr,
	output		reg[`RegBus]			wb_cp0_reg_data
	);
	//��1����stall[4]ΪStop��stall[5]ΪNoStopʱ����ʾ�ô�׶���ͣ����д�ؽ׶μ���������ʹ�ÿ�ָ����Ϊ��һ�����ڽ����д�׶ε�ָ��
	//��2����stall[4]ΪNoStopʱ���ô�׶μ������ô���ָ������д�׶�
	//��3����������£����ֻ�д�׶εļĴ���wb_wd��wb_wreg��wb_data��wb_hi��wb_lo��wb_whilo����
	always @ (posedge clk) begin
		if (rst == `RstEnable) begin
			wb_wd <= `NOPRegAddr;
			wb_wreg <= `WriteDisable;
			wb_wdata <= `ZeroWord;
			wb_hi <= `ZeroWord;
			wb_lo <= `ZeroWord;
			wb_whilo <= `WriteDisable;
			wb_cp0_reg_we <= `WriteDisable;
			wb_cp0_reg_write_addr <= 5'b00000;
			wb_cp0_reg_data <= `ZeroWord;
		end else if (flush == 1'b1) begin							//�����ˮ��
			wb_wd <= `NOPRegAddr;
			wb_wreg <= `WriteDisable;
			wb_wdata <= `ZeroWord;
			wb_hi <= `ZeroWord;
			wb_lo <= `ZeroWord;
			wb_whilo <= `WriteDisable;
			wb_cp0_reg_we <= `WriteDisable;
			wb_cp0_reg_write_addr <= 5'b00000;
			wb_cp0_reg_data <= `ZeroWord;
		end else if (stall[4] == `Stop && stall[5] == `NoStop) begin
			wb_wd <= `NOPRegAddr;
			wb_wreg <= `WriteDisable;
			wb_wdata <= `ZeroWord;
			wb_hi <= `ZeroWord;
			wb_lo <= `ZeroWord;
			wb_whilo <= `WriteDisable;
			wb_cp0_reg_we <= `WriteDisable;
			wb_cp0_reg_write_addr <= 5'b00000;
			wb_cp0_reg_data <= `ZeroWord;
		end else if (stall[4] == `NoStop) begin
			wb_wd <= mem_wd;
			wb_wreg <= mem_wreg;
			wb_wdata <= mem_wdata;
			wb_hi <= mem_hi;
			wb_lo <= mem_lo;
			wb_whilo <= mem_whilo;
			wb_cp0_reg_we <= mem_cp0_reg_we;
			wb_cp0_reg_write_addr <= mem_cp0_reg_write_addr;
			wb_cp0_reg_data <= mem_cp0_reg_data;
		end
	end

endmodule

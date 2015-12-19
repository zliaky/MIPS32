`include "defines.v"

module if_id(
	input		wire					clk,
	input		wire					rst,
	input		wire[5:0]				stall,
	input		wire					flush,

	//����ȡָ�׶ε��źţ����к궨��InstBus��ʾָ���ȣ�Ϊ32
	input		wire[`InstAddrBus]		if_pc,
	input		wire[`InstBus]			if_inst,

	//��Ӧ����׶ε��ź�
	output		reg[`InstAddrBus]		id_pc,
	output		reg[`InstBus]			id_inst
	);

	//��1����stall[1]ΪStop��stall[2]λNoStopʱ����ʾȡָ�׶���ͣ��������׶μ���������ʹ�ÿ�ָ����Ϊ��һ�����ڽ�������׶ε�ָ��
	//��2����stall[1]λNoStopʱ��ȡָ�׶μ�����ȡ�õ�ָ���������׶�
	//��3����������£���������׶εļĴ���id_pc��id_inst����
	always @ (posedge clk) begin
		if (rst == `RstEnable) begin
			id_pc <= `ZeroWord;						//��λ��ʱ��pcΪ0
			id_inst <= `ZeroWord;					//��λ��ʱ��ָ��ҲΪ0����ʵ���ǿ�ָ��
		end else if (flush == 1'b1) begin			//flushΪ1��ʾ�쳣������Ҫ�����ˮ�ߣ����Ը�λid_pc,id_inst�Ĵ�����ֵ
			id_pc <= `ZeroWord;
			id_inst <= `ZeroWord;
		end else if (stall[1] == `Stop && stall[2] == `NoStop) begin
			id_pc <= `ZeroWord;
			id_inst <= `ZeroWord;
		end else if (stall[1] == `NoStop) begin
			id_pc <= if_pc;							//����ʱ�����´���ȡָ�׶ε�ֵ
			id_inst <= if_inst;
		end
	end

endmodule

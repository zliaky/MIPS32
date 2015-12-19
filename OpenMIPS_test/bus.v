`include "defines.v"

module bus(
	//master interface
	input 		wire[`WB_DataBus]	m_data_i,
	input		wire[`WB_AddrBus]	m_addr_i,
	input		wire				m_we_i,
	input		wire[`WB_SelectBus]	m_select_i,
	output		reg[`WB_DataBus]	m_data_o,
	output		reg					m_ack_o,

	//slave 0 interface
	output		wire[`WB_DataBus]	s0_data_o,
	output		wire[`WB_AddrBus]	s0_addr_o,
	output		wire				s0_we_o,
	output		wire				s0_select_o,
	input		wire[`WB_DataBus]	s0_data_i,
	input		wire				s0_ack_i,

	//slave 1 interface
	output		wire[`WB_DataBus]	s1_data_o,
	output		wire[`WB_AddrBus]	s1_addr_o,
	output		wire				s1_we_o,
	output		wire				s1_select_o,
	input		wire[`WB_DataBus]	s1_data_i,
	input		wire				s1_ack_i,

	//slave 2 interface
	output		wire[`WB_DataBus]	s2_data_o,
	output		wire[`WB_AddrBus]	s2_addr_o,
	output		wire				s2_we_o,
	output		wire				s2_select_o,
	input		wire[`WB_DataBus]	s2_data_i,
	input		wire				s2_ack_i,

	//slave 3 interface
	output		wire[`WB_DataBus]	s3_data_o,
	output		wire[`WB_AddrBus]	s3_addr_o,
	output		wire				s3_we_o,
	output		wire				s3_select_o,
	input		wire[`WB_DataBus]	s3_data_i,
	input		wire				s3_ack_i,

	//slave 4 interface
	output		wire[`WB_DataBus]	s4_data_o,
	output		wire[`WB_AddrBus]	s4_addr_o,
	output		wire				s4_we_o,
	output		wire				s4_select_o,
	input		wire[`WB_DataBus]	s4_data_i,
	input		wire				s4_ack_i,

	//slave 5 interface
	output		wire[`WB_DataBus]	s5_data_o,
	output		wire[`WB_AddrBus]	s5_addr_o,
	output		wire				s5_we_o,
	output		wire				s5_select_o,
	input		wire[`WB_DataBus]	s5_data_i,
	input		wire				s5_ack_i,

	//slave 6 interface
	output		wire[`WB_DataBus]	s6_data_o,
	output		wire[`WB_AddrBus]	s6_addr_o,
	output		wire				s6_we_o,
	output		wire				s6_select_o,
	input		wire[`WB_DataBus]	s6_data_i,
	input		wire				s6_ack_i,

	//slave 7 interface
	output		wire[`WB_DataBus]	s7_data_o,
	output		wire[`WB_AddrBus]	s7_addr_o,
	output		wire				s7_we_o,
	output		wire				s7_select_o,
	input		wire[`WB_DataBus]	s7_data_i,
	input		wire				s7_ack_i
);

//address & data pass
assign s0_addr_o = m_addr_i;
assign s1_addr_o = m_addr_i;
assign s2_addr_o = m_addr_i;
assign s3_addr_o = m_addr_i;
assign s4_addr_o = m_addr_i;
assign s5_addr_o = m_addr_i;
assign s6_addr_o = m_addr_i;
assign s7_addr_o = m_addr_i;

assign s0_select_o = m_select_i[0];
assign s1_select_o = m_select_i[1];
assign s2_select_o = m_select_i[2];
assign s3_select_o = m_select_i[3];
assign s4_select_o = m_select_i[4];
assign s5_select_o = m_select_i[5];
assign s6_select_o = m_select_i[6];
assign s7_select_o = m_select_i[7];

always @ (*) begin
	case(m_select_i)
		16'h0001:	m_data_o <= s0_data_i;
		16'h0002:	m_data_o <= s1_data_i;
		16'h0004:	m_data_o <= s2_data_i;
		16'h0008:	m_data_o <= s3_data_i;
		16'h0010:	m_data_o <= s4_data_i;
		16'h0020:	m_data_o <= s5_data_i;
		16'h0040:	m_data_o <= s6_data_i;
		16'h0080:	m_data_o <= s7_data_i;
	endcase
end

assign s0_data_o = m_data_i;
assign s1_data_o = m_data_i;
assign s2_data_o = m_data_i;
assign s3_data_o = m_data_i;
assign s4_data_o = m_data_i;
assign s5_data_o = m_data_i;
assign s6_data_o = m_data_i;
assign s7_data_o = m_data_i;

assign s0_we_o = m_we_i;
assign s1_we_o = m_we_i;
assign s2_we_o = m_we_i;
assign s3_we_o = m_we_i;
assign s4_we_o = m_we_i;
assign s5_we_o = m_we_i;
assign s6_we_o = m_we_i;
assign s7_we_o = m_we_i;

always @ (*) begin
	case(m_select_i)
		16'h0001:	m_ack_o <= s0_ack_i;
		16'h0002:	m_ack_o <= s1_ack_i;
		16'h0004:	m_ack_o <= s2_ack_i;
		16'h0008:	m_ack_o <= s3_ack_i;
		16'h0010:	m_ack_o <= s4_ack_i;
		16'h0020:	m_ack_o <= s5_ack_i;
		16'h0040:	m_ack_o <= s6_ack_i;
		16'h0080:	m_ack_o <= s7_ack_i;
		default:	m_ack_o <= 1'b0;
	endcase
end

endmodule

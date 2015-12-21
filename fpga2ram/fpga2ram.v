module fpga2ram(
	input clk,
	input rst,

	output [15:0] led,
	input [31:0] sw_dip,

	output [19:0] baseram_addr,
	inout [31:0] baseram_data,
	output baseram_ce,
	output baseram_oe,
	output baseram_we,

	output [19:0] extram_addr,
	inout [31:0] extram_data,
	output extram_ce,
	output extram_oe,
	output extram_we 
	);

	reg[31:0] bus_addr_i;
	reg[31:0] bus_data_i;
	wire[31:0] bus_data_o;
	wire bus_we_i;
	wire bus_ack_o;
	reg[31:0] pc;

	assign led = bus_data_o[15:0];
	assign bus_we_i = sw_dip[31];
	
	always @ (posedge clk) begin
		if (bus_we_i == 1'b1) begin		//write
			case (pc)
				`include "input.v"
				default: pc <= 32'h00000000;
			endcase
		end else begin
			bus_addr_i <= {12'b0, sw_dip[19:0]};
		end
	end

	ram ram0 (
		clk, rst,
		bus_addr_i,
		bus_data_i,
		bus_data_o,
		1'b1,
		bus_we_i,
		bus_ack_o,

		baseram_addr,
		baseram_data,
		baseram_ce,
		baseram_oe,
		baseram_we,

		extram_addr,
		extram_data,
		extram_ce,
		extram_oe,
		extram_we
	);

endmodule

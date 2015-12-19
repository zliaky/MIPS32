`include "defines.v"
module digseg_driver(
	input [`DigSegAddrBus] data_i,
	output reg[`DigSegDataBus] seg_o,
	output ack, 
	input ce,
	input we
	);

	assign ack = 1'b1;
	always @ (*) begin
		if (ce == 1'b0 || we == 1'b0) begin
			seg_o <= 7'b1111110;
		end else begin
			case (data_i)
				4'b0000: seg_o <= 7'b1111110;
				4'b0001: seg_o <= 7'b0110000;
				4'b0010: seg_o <= 7'b1101101;
				4'b0011: seg_o <= 7'b1111001;
				4'b0100: seg_o <= 7'b0110011;
				4'b0101: seg_o <= 7'b1011011;
				4'b0110: seg_o <= 7'b1011111;
				4'b0111: seg_o <= 7'b1110000;
				4'b1000: seg_o <= 7'b1111111;
				4'b1001: seg_o <= 7'b1110011;
				4'b1010: seg_o <= 7'b1110111;
				4'b1011: seg_o <= 7'b0011111;
				4'b1100: seg_o <= 7'b1001110;
				4'b1101: seg_o <= 7'b0111101;
				4'b1110: seg_o <= 7'b1001111;
				4'b1111: seg_o <= 7'b1000111;
			endcase
		end
	end

endmodule

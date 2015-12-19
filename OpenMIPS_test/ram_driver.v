`include "defines.v"
module ram_driver (
	input clk,    // Clock
	input rst,
	input enable,
	input read_enable,
	input write_enable,
	
	input [`DataMemNumLog2-1:0] addr,
	input [`DataBus] data_in,
	output [`DataBus] data_out,

	output reg[`DataMemNumLog2-2:0] baseram_addr,
	inout [`DataBus] baseram_data,
	output reg baseram_ce,
	output reg baseram_oe,
	output reg baseram_we,
	output reg[`DataMemNumLog2-2:0] extram_addr,
	inout [`DataBus] extram_data,
	output reg extram_ce,
	output reg extram_oe,
	output reg extram_we,
	output wire ack
);

	wire ram_selector = addr[20];

	reg[`DataBus] base_data_latch = 0;
	reg[`DataBus] extra_data_latch = 0;

	assign baseram_data = baseram_oe ? base_data_latch : {32{1'bz}}, 
		extram_data = extram_oe ? extra_data_latch : {32{1'bz}};
		
	reg base_state;
	reg extra_state;
	localparam IDLE = 1'b0, WRITE1 = 1'b1;

	wire[`DataBus] extra_data_out;
	wire[`DataBus] base_data_out;
	assign data_out = ram_selector ? extra_data_out : base_data_out;
	assign base_data_out = baseram_data;
	assign extra_data_out = extram_data;
	
	reg extra_ack;
	reg base_ack;
	assign ack = ram_selector ? extra_ack : base_ack;

	always @ (*) begin
		if (rst == `RstEnable) begin
			base_ack <= 1'b1;
		end
		if (ram_selector == 1'b0) begin			//base
			case (base_state)
				IDLE: begin
					base_ack <= 1'b1;
					if(enable == 1'b1) begin
						if (read_enable == 1'b1) begin
							base_ack <= 1'b1;
						end else if (write_enable == 1'b1) begin
							base_ack <= 1'b0;
						end
					end
				end
				WRITE1: begin
					base_ack <= 1'b1;
				end
			endcase
		end
	end

	always @ (*) begin
		if (rst == `RstEnable) begin
			extra_ack <= 1'b1;
		end
		if (ram_selector == 1'b1) begin			//extra
			case (extra_state)
				IDLE: begin
					extra_ack <= 1'b1;
					if (enable == 1'b1) begin
						if (read_enable == 1'b1) begin
							extra_ack <= 1'b1;
						end else if (write_enable == 1'b1) begin
							extra_ack <= 1'b0;
						end
					end
				end
				WRITE1: begin
					extra_ack <= 1'b1;
				end
			endcase
		end
	end

	always @ (posedge clk) begin
		if (ram_selector == 1'b0) begin			//base
			case (base_state)
				IDLE: begin
					baseram_ce <= 1'b1;
					baseram_oe <= 1'b1;
					baseram_we <= 1'b1;
					baseram_addr <= addr[`DataMemNumLog2-2:0];
					// base_data_out <= baseram_data;
					if(enable == 1'b1) begin
						if (read_enable == 1'b1) begin
							baseram_ce <= 1'b0;
							baseram_oe <= 1'b0;
							baseram_we <= 1'b1;
							baseram_addr <= addr[`DataMemNumLog2-2:0];
							// base_data_out <= baseram_data;
						end else if (write_enable == 1'b1) begin
							baseram_ce <= 1'b0;
							baseram_oe <= 1'b1;
							baseram_we <= 1'b0;
							baseram_addr <= addr[`DataMemNumLog2-2:0];
							base_data_latch <= data_in;
							base_state <= WRITE1;
						end else begin
							baseram_oe <= 1'b1;
							baseram_we <= 1'b1;
						end
					end
				end
				WRITE1: begin
					baseram_ce <= 1'b1;
					baseram_we <= 1'b1;
					baseram_oe <= 1'b1;
					base_state <= IDLE;
				end
			endcase
		end
	end

	always @ (posedge clk) begin
		if (ram_selector == 1'b1) begin			//extra
			case (extra_state)
				IDLE: begin
					extram_ce <= 1'b1;
					extram_oe <= 1'b1;
					extram_we <= 1'b1;
					extram_addr <= addr[`DataMemNumLog2-2:0];
					//extra_data_out <= extram_data;
					if (enable == 1'b1) begin
						if (read_enable == 1'b1) begin
							extram_ce <= 1'b0;
							extram_oe <= 1'b0;
							extram_we <= 1'b1;
							extram_addr <= addr[`DataMemNumLog2-2:0];
							//extra_data_out <= extram_data;
						end else if (write_enable == 1'b1) begin
							extram_ce <= 1'b0;
							extram_oe <= 1'b1;
							extram_we <= 1'b0;
							extram_addr <= addr[`DataMemNumLog2-2:0];
							extra_data_latch <= data_in;
							extra_state <= WRITE1;
						end else begin
							extram_oe <= 1'b1;
							extram_we <= 1'b1;
						end
					end
				end
				WRITE1: begin
					extram_ce <= 1'b1;
					extram_we <= 1'b1;
					extram_oe <= 1'b1;
					extra_state <= IDLE;
				end
			endcase
		end
	end

endmodule

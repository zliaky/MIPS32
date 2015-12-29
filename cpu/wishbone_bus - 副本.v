`include "defines.v"

module wishbone_bus(
	input		wire					clk,
	input		wire					rst,

	//À´×ÔctrlÄ£¿é
	input		wire[5:0]				stall_i,
	input		wire					flush_i,

	//IFÄ£¿éµÄ½Ó¿Ú
	input		wire					if_ce_i,
	input		wire[`RegBus]			if_data_i,
	input		wire[`RegBus]			if_addr_i,
	input		wire					if_we_i,
	input		wire[3:0]				if_sel_i,
	output		reg[`RegBus]			if_data_o,

	output		wire					stall_req_if,

	//MEMÄ£¿éµÄ½Ó¿Ú
	input		wire					mem_ce_i,
	input		wire[`RegBus]			mem_data_i,
	input		wire[`RegBus]			mem_addr_i,
	input		wire					mem_we_i,
	input		wire[3:0]				mem_sel_i,
	output		reg[`RegBus]			mem_data_o,

	output		reg						stall_req_mem,

	//TLBÄ£¿éµÄ½Ó¿Ú
	output		reg						tlb_ce,
	output		reg						tlb_write_o,
	output		reg[`RegBus]			tlb_addr_o,

	//MMUÄ£¿éµÄ½Ó¿Ú
	input		wire[`RegBus]			mmu_addr_i,
	input		wire[15:0]				mmu_select_i,

	//Wishbone²àµÄ½Ó¿Ú
	output		reg[`RegBus]			wishbone_data_o,
	output		reg[`RegBus]			wishbone_addr_o,
	output		reg						wishbone_we_o,
	output		reg[15:0]				wishbone_select_o,
	input		wire[`RegBus]			wishbone_data_i,
	input		wire					wishbone_ack_i
	);

	// reg[`RegBus] mem_wdata;

	reg	if_ack;
	reg	memw_ack;
	reg memr_ack;

	reg flag;
	reg flag2;
	reg if_cancel;
	reg[31:0] wishbone_data_latch;
	
	initial wishbone_data_latch = 32'h00000000;
	initial flag = `False_v;
	initial flag2 = `False_v;
	initial if_cancel = `False_v;

	wire[3:0] state;
	assign state = {flag2 ? 1'b1 : mem_ce_i, memw_ack, memr_ack, if_ack};

	always @ (*) begin
		if (rst == `RstEnable) begin
			wishbone_data_o <= `ZeroWord;
			wishbone_addr_o <= `ZeroWord;
			wishbone_we_o <= `WriteDisable;
			wishbone_select_o <= `WB_SELECT_ZERO;
		end else begin
			if (wishbone_ack_i == `False_v) begin
			end else if (if_ack == `False_v) begin
				wishbone_data_o <= `ZeroWord;
				wishbone_addr_o <= mmu_addr_i;
				wishbone_we_o <= `WriteDisable;
				wishbone_select_o <= mmu_select_i;
			end else if (memr_ack == `False_v) begin
				wishbone_data_o <= `ZeroWord;
				wishbone_addr_o <= mmu_addr_i;
				wishbone_we_o <= `WriteDisable;
				wishbone_select_o <= mmu_select_i;
			end else if (memw_ack == `False_v) begin
				wishbone_data_o <= mem_data_i;
				if (mem_sel_i[3] == 1'b0) begin
					wishbone_data_o[31:24] <= wishbone_data_i[31:24];
				end
				if (mem_sel_i[2] == 1'b0) begin
					wishbone_data_o[23:16] <= wishbone_data_i[23:16];
				end
				if (mem_sel_i[1] == 1'b0) begin
					wishbone_data_o[15:8] <= wishbone_data_i[15:8];
				end
				if (mem_sel_i[0] == 1'b0) begin
					wishbone_data_o[7:0] <= wishbone_data_i[7:0];
				end
				wishbone_addr_o <= mmu_addr_i;
				wishbone_we_o <= `WriteEnable;
				wishbone_select_o <= mmu_select_i;
			end else begin
				wishbone_data_o <= `ZeroWord;
				wishbone_addr_o <= mmu_addr_i;
				wishbone_we_o <= `WriteDisable;
				wishbone_select_o <= mmu_select_i;
			end
		end
	end

	always @ (*) begin
		if (rst == `RstEnable) begin
			tlb_ce <= `ChipDisable;
			tlb_write_o <= `False_v;
			tlb_addr_o <= `ZeroWord;
		end else begin
			if (wishbone_ack_i == `False_v) begin
			end else if (if_ack == `False_v) begin
				tlb_ce <= `ChipEnable;
				tlb_write_o <= `False_v;
				tlb_addr_o <= if_addr_i;
			end else if (memr_ack == `False_v) begin
				tlb_ce <= `ChipEnable;
				tlb_write_o <= `False_v;
				tlb_addr_o <= mem_addr_i;
			end else if (memw_ack == `False_v) begin
				tlb_ce <= `ChipEnable;
				tlb_write_o <= `True_v;
				tlb_addr_o <= mem_addr_i;
			end else begin
				tlb_ce <= `ChipEnable;
				tlb_write_o <= `False_v;
				tlb_addr_o <= if_addr_i;
			end
		end
	end

	always @ (posedge clk) begin
		if (rst == `RstEnable) begin
			if_ack <= `False_v;
			memw_ack <= `True_v;
			memr_ack <= `True_v;
		end else if (stall_i == 6'b000111) begin
			flag2 <= `False_v;
			flag <= `True_v;
			if_ack <= `True_v;
			if_cancel <= `True_v;
		end else begin
			if (wishbone_ack_i == `True_v) begin
				case (state)
					4'b1001: begin
						memr_ack <= `True_v;
					end
					4'b1011: begin
						if(stall_i != 6'b000111) if_cancel <= `False_v;
						memw_ack <= `True_v;
					end
					4'b1101: begin
						if(stall_i != 6'b000111) if_cancel <= `False_v;
						memr_ack <= `True_v;
					end
					4'b1110: begin
						if_ack <= `True_v;
						if (mem_we_i == `WriteEnable) begin
							memw_ack <= `False_v;
							if (mem_sel_i == 4'b1111) begin
								memr_ack <= `True_v;
							end else begin
								memr_ack <= `False_v;
							end
						end else begin
							memw_ack <= `True_v;
							memr_ack <= `False_v;
						end
					end
					4'b1111: begin
						if_ack <= `False_v;
						flag2 <= `False_v;
						if(flag == `True_v) begin
							flag <= `False_v;
							flag2 <= `True_v;
						end
					end
					default: begin
						if_ack <= `False_v;
						memw_ack <= `True_v;
						memr_ack <= `True_v;
					end
				endcase
			end else begin
				//do nothing
			end
		end
	end

	assign stall_req_if = `NoStop;

	always @ (*) begin
		if (rst == `RstEnable) begin
		end else if (wishbone_ack_i == `False_v) begin
			stall_req_mem <= `Stop;
		end else begin
			case (state)
				4'b0000: stall_req_mem <= `NoStop;
				4'b0001: stall_req_mem <= `NoStop;
				4'b0010: stall_req_mem <= `NoStop;
				4'b0011: stall_req_mem <= `NoStop;
				4'b0100: stall_req_mem <= `NoStop;
				4'b0101: stall_req_mem <= `NoStop;
				4'b0110: stall_req_mem <= `NoStop;
				4'b0111: stall_req_mem <= `NoStop;
				4'b1000: stall_req_mem <= `NoStop;
				4'b1001: stall_req_mem <= `Stop;
				4'b1010: stall_req_mem <= `NoStop;
				4'b1011: stall_req_mem <= `Stop;
				4'b1100: stall_req_mem <= `NoStop;
				4'b1101: stall_req_mem <= `Stop;
				4'b1110: stall_req_mem <= `Stop;
				4'b1111: stall_req_mem <= `NoStop;
			endcase
		end
	end

	always @ (*) begin
		if (rst == `RstEnable) begin
			if_data_o <= `ZeroWord;
			mem_data_o <= `ZeroWord;
		end else begin
			if (wishbone_ack_i == `True_v) begin
				if (if_ack <= `False_v) begin
					if (if_cancel == `False_v) begin
						if_data_o <= wishbone_data_i;
					end
				end else begin
					mem_data_o <= wishbone_data_i;
				end
			end
		end
	end

endmodule

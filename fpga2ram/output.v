32'h00000000: begin bus_data_i <= 32'h34011100; bus_addr_i <= {12'b0, pc[19:0]}; pc <= pc + 1'b1; end
32'h00000001: begin bus_data_i <= 32'h34210020; bus_addr_i <= {12'b0, pc[19:0]}; pc <= pc + 1'b1; end
32'h00000002: begin bus_data_i <= 32'h34214400; bus_addr_i <= {12'b0, pc[19:0]}; pc <= pc + 1'b1; end
32'h00000003: begin bus_data_i <= 32'h34214444; bus_addr_i <= {12'b0, pc[19:0]}; pc <= pc + 1'b1; end

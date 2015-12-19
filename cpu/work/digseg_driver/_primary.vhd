library verilog;
use verilog.vl_types.all;
entity digseg_driver is
    port(
        data_i          : in     vl_logic_vector(3 downto 0);
        seg_o           : out    vl_logic_vector(0 to 6);
        ack             : out    vl_logic;
        ce              : in     vl_logic;
        we              : in     vl_logic
    );
end digseg_driver;

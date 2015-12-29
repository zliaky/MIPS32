library verilog;
use verilog.vl_types.all;
entity data_ram is
    port(
        clk             : in     vl_logic;
        rst             : in     vl_logic;
        ce              : in     vl_logic;
        we              : in     vl_logic;
        addr            : in     vl_logic_vector(31 downto 0);
        data_i          : in     vl_logic_vector(31 downto 0);
        data_o          : out    vl_logic_vector(31 downto 0);
        ack             : out    vl_logic
    );
end data_ram;

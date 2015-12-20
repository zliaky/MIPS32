library verilog;
use verilog.vl_types.all;
entity openmips is
    port(
        clk             : in     vl_logic;
        rst             : in     vl_logic;
        int_i           : in     vl_logic_vector(5 downto 0);
        wishbone_data_i : in     vl_logic_vector(31 downto 0);
        wishbone_ack_i  : in     vl_logic;
        wishbone_addr_o : out    vl_logic_vector(31 downto 0);
        wishbone_data_o : out    vl_logic_vector(31 downto 0);
        wishbone_we_o   : out    vl_logic;
        wishbone_select_o: out    vl_logic_vector(15 downto 0);
        timer_int_o     : out    vl_logic
    );
end openmips;

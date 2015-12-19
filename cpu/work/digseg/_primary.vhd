library verilog;
use verilog.vl_types.all;
entity digseg is
    port(
        clk             : in     vl_logic;
        rst             : in     vl_logic;
        bus_addr_i      : in     vl_logic_vector(31 downto 0);
        bus_data_i      : in     vl_logic_vector(31 downto 0);
        bus_data_o      : out    vl_logic_vector(31 downto 0);
        bus_select_i    : in     vl_logic;
        bus_we_i        : in     vl_logic;
        bus_ack_o       : out    vl_logic;
        seg0            : out    vl_logic_vector(0 to 6);
        seg1            : out    vl_logic_vector(0 to 6)
    );
end digseg;

library verilog;
use verilog.vl_types.all;
entity flash is
    port(
        clk             : in     vl_logic;
        rst             : in     vl_logic;
        bus_addr_i      : in     vl_logic_vector(31 downto 0);
        bus_data_i      : in     vl_logic_vector(31 downto 0);
        bus_data_o      : out    vl_logic_vector(31 downto 0);
        bus_select_i    : in     vl_logic;
        bus_we_i        : in     vl_logic;
        bus_ack_o       : out    vl_logic;
        flash_addr      : out    vl_logic_vector(22 downto 0);
        flash_data      : inout  vl_logic_vector(15 downto 0);
        flash_ctl       : out    vl_logic_vector(7 downto 0)
    );
end flash;

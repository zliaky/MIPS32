library verilog;
use verilog.vl_types.all;
entity flash_driver is
    port(
        clk             : in     vl_logic;
        addr            : in     vl_logic_vector(21 downto 0);
        data_in         : in     vl_logic_vector(15 downto 0);
        data_out        : out    vl_logic_vector(15 downto 0);
        enable_read     : in     vl_logic;
        enable_erase    : in     vl_logic;
        enable_write    : in     vl_logic;
        flash_addr      : out    vl_logic_vector(22 downto 0);
        flash_data      : inout  vl_logic_vector(15 downto 0);
        flash_ctl       : out    vl_logic_vector(7 downto 0);
        ack             : out    vl_logic
    );
end flash_driver;

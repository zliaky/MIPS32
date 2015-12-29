library verilog;
use verilog.vl_types.all;
entity cp0_reg is
    port(
        clk             : in     vl_logic;
        rst             : in     vl_logic;
        we_i            : in     vl_logic;
        waddr_i         : in     vl_logic_vector(4 downto 0);
        raddr_i         : in     vl_logic_vector(4 downto 0);
        data_i          : in     vl_logic_vector(31 downto 0);
        excepttype_i    : in     vl_logic_vector(31 downto 0);
        int_i           : in     vl_logic_vector(5 downto 0);
        current_inst_addr_i: in     vl_logic_vector(31 downto 0);
        bad_v_addr_i    : in     vl_logic_vector(31 downto 0);
        is_in_delayslot_i: in     vl_logic;
        data_o          : out    vl_logic_vector(31 downto 0);
        index_o         : out    vl_logic_vector(31 downto 0);
        entry_lo_0_o    : out    vl_logic_vector(31 downto 0);
        entry_lo_1_o    : out    vl_logic_vector(31 downto 0);
        bad_v_addr_o    : out    vl_logic_vector(31 downto 0);
        count_o         : out    vl_logic_vector(31 downto 0);
        entry_hi_o      : out    vl_logic_vector(31 downto 0);
        compare_o       : out    vl_logic_vector(31 downto 0);
        status_o        : out    vl_logic_vector(31 downto 0);
        cause_o         : out    vl_logic_vector(31 downto 0);
        epc_o           : out    vl_logic_vector(31 downto 0);
        ebase_o         : out    vl_logic_vector(31 downto 0);
        timer_int_o     : out    vl_logic
    );
end cp0_reg;

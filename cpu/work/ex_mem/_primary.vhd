library verilog;
use verilog.vl_types.all;
entity ex_mem is
    port(
        clk             : in     vl_logic;
        rst             : in     vl_logic;
        stall           : in     vl_logic_vector(5 downto 0);
        flush           : in     vl_logic;
        ex_wd           : in     vl_logic_vector(4 downto 0);
        ex_wreg         : in     vl_logic;
        ex_wdata        : in     vl_logic_vector(31 downto 0);
        ex_hi           : in     vl_logic_vector(31 downto 0);
        ex_lo           : in     vl_logic_vector(31 downto 0);
        ex_whilo        : in     vl_logic;
        ex_aluop        : in     vl_logic_vector(7 downto 0);
        ex_mem_addr     : in     vl_logic_vector(31 downto 0);
        ex_reg2         : in     vl_logic_vector(31 downto 0);
        ex_cp0_reg_we   : in     vl_logic;
        ex_cp0_reg_write_addr: in     vl_logic_vector(4 downto 0);
        ex_cp0_reg_data : in     vl_logic_vector(31 downto 0);
        ex_excepttype   : in     vl_logic_vector(31 downto 0);
        ex_is_in_delayslot: in     vl_logic;
        ex_current_inst_address: in     vl_logic_vector(31 downto 0);
        mem_wd          : out    vl_logic_vector(4 downto 0);
        mem_wreg        : out    vl_logic;
        mem_wdata       : out    vl_logic_vector(31 downto 0);
        mem_hi          : out    vl_logic_vector(31 downto 0);
        mem_lo          : out    vl_logic_vector(31 downto 0);
        mem_whilo       : out    vl_logic;
        mem_aluop       : out    vl_logic_vector(7 downto 0);
        mem_mem_addr    : out    vl_logic_vector(31 downto 0);
        mem_reg2        : out    vl_logic_vector(31 downto 0);
        mem_cp0_reg_we  : out    vl_logic;
        mem_cp0_reg_write_addr: out    vl_logic_vector(4 downto 0);
        mem_cp0_reg_data: out    vl_logic_vector(31 downto 0);
        mem_excepttype  : out    vl_logic_vector(31 downto 0);
        mem_is_in_delayslot: out    vl_logic;
        mem_current_inst_address: out    vl_logic_vector(31 downto 0)
    );
end ex_mem;
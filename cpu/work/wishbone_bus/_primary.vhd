library verilog;
use verilog.vl_types.all;
entity wishbone_bus is
    port(
        clk             : in     vl_logic;
        rst             : in     vl_logic;
        stall_i         : in     vl_logic_vector(5 downto 0);
        flush_i         : in     vl_logic;
        if_ce_i         : in     vl_logic;
        if_data_i       : in     vl_logic_vector(31 downto 0);
        if_addr_i       : in     vl_logic_vector(31 downto 0);
        if_we_i         : in     vl_logic;
        if_sel_i        : in     vl_logic_vector(3 downto 0);
        if_data_o       : out    vl_logic_vector(31 downto 0);
        stall_req_if    : out    vl_logic;
        mem_ce_i        : in     vl_logic;
        mem_data_i      : in     vl_logic_vector(31 downto 0);
        mem_addr_i      : in     vl_logic_vector(31 downto 0);
        mem_we_i        : in     vl_logic;
        mem_sel_i       : in     vl_logic_vector(3 downto 0);
        mem_data_o      : out    vl_logic_vector(31 downto 0);
        stall_req_mem   : out    vl_logic;
        tlb_ce          : out    vl_logic;
        tlb_write_o     : out    vl_logic;
        tlb_addr_o      : out    vl_logic_vector(31 downto 0);
        mmu_addr_i      : in     vl_logic_vector(31 downto 0);
        mmu_select_i    : in     vl_logic_vector(15 downto 0);
        wishbone_data_o : out    vl_logic_vector(31 downto 0);
        wishbone_addr_o : out    vl_logic_vector(31 downto 0);
        wishbone_we_o   : out    vl_logic;
        wishbone_select_o: out    vl_logic_vector(15 downto 0);
        wishbone_data_i : in     vl_logic_vector(31 downto 0);
        wishbone_ack_i  : in     vl_logic
    );
end wishbone_bus;

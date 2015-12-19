library verilog;
use verilog.vl_types.all;
entity tlb is
    port(
        clk             : in     vl_logic;
        rst             : in     vl_logic;
        bus_addr_i      : in     vl_logic_vector(31 downto 0);
        bus_write_i     : in     vl_logic;
        tlb_ce          : in     vl_logic;
        tlb_addr        : out    vl_logic_vector(31 downto 0);
        tlb_we          : in     vl_logic;
        tlb_index       : in     vl_logic_vector(3 downto 0);
        tlb_data        : in     vl_logic_vector(63 downto 0);
        excepttype_is_tlbm: out    vl_logic;
        excepttype_is_tlbl: out    vl_logic;
        excepttype_is_tlbs: out    vl_logic
    );
end tlb;

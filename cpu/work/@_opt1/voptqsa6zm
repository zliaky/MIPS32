library verilog;
use verilog.vl_types.all;
entity mmu is
    port(
        clk             : in     vl_logic;
        rst             : in     vl_logic;
        tlb_addr_i      : in     vl_logic_vector(31 downto 0);
        mmu_addr_o      : out    vl_logic_vector(31 downto 0);
        mmu_select_o    : out    vl_logic_vector(15 downto 0)
    );
end mmu;

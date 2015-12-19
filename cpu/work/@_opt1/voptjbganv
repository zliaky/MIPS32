library verilog;
use verilog.vl_types.all;
entity id_ex is
    port(
        clk             : in     vl_logic;
        rst             : in     vl_logic;
        stall           : in     vl_logic_vector(5 downto 0);
        flush           : in     vl_logic;
        id_aluop        : in     vl_logic_vector(7 downto 0);
        id_alusel       : in     vl_logic_vector(2 downto 0);
        id_reg1         : in     vl_logic_vector(31 downto 0);
        id_reg2         : in     vl_logic_vector(31 downto 0);
        id_wd           : in     vl_logic_vector(4 downto 0);
        id_wreg         : in     vl_logic;
        id_link_address : in     vl_logic_vector(31 downto 0);
        id_is_in_delayslot: in     vl_logic;
        next_inst_in_delayslot_i: in     vl_logic;
        id_inst         : in     vl_logic_vector(31 downto 0);
        id_current_inst_address: in     vl_logic_vector(31 downto 0);
        id_excepttype   : in     vl_logic_vector(31 downto 0);
        ex_aluop        : out    vl_logic_vector(7 downto 0);
        ex_alusel       : out    vl_logic_vector(2 downto 0);
        ex_reg1         : out    vl_logic_vector(31 downto 0);
        ex_reg2         : out    vl_logic_vector(31 downto 0);
        ex_wd           : out    vl_logic_vector(4 downto 0);
        ex_wreg         : out    vl_logic;
        ex_link_address : out    vl_logic_vector(31 downto 0);
        ex_is_in_delayslot: out    vl_logic;
        is_in_delayslot_o: out    vl_logic;
        ex_inst         : out    vl_logic_vector(31 downto 0);
        ex_current_inst_address: out    vl_logic_vector(31 downto 0);
        ex_excepttype   : out    vl_logic_vector(31 downto 0)
    );
end id_ex;

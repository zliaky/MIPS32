library verilog;
use verilog.vl_types.all;
entity id is
    port(
        rst             : in     vl_logic;
        pc_i            : in     vl_logic_vector(31 downto 0);
        inst_i          : in     vl_logic_vector(31 downto 0);
        ex_aluop_i      : in     vl_logic_vector(7 downto 0);
        reg1_data_i     : in     vl_logic_vector(31 downto 0);
        reg2_data_i     : in     vl_logic_vector(31 downto 0);
        ex_wreg_i       : in     vl_logic;
        ex_wdata_i      : in     vl_logic_vector(31 downto 0);
        ex_wd_i         : in     vl_logic_vector(4 downto 0);
        mem_wreg_i      : in     vl_logic;
        mem_wdata_i     : in     vl_logic_vector(31 downto 0);
        mem_wd_i        : in     vl_logic_vector(4 downto 0);
        is_in_delayslot_i: in     vl_logic;
        reg1_read_o     : out    vl_logic;
        reg2_read_o     : out    vl_logic;
        reg1_addr_o     : out    vl_logic_vector(4 downto 0);
        reg2_addr_o     : out    vl_logic_vector(4 downto 0);
        aluop_o         : out    vl_logic_vector(7 downto 0);
        alusel_o        : out    vl_logic_vector(2 downto 0);
        reg1_o          : out    vl_logic_vector(31 downto 0);
        reg2_o          : out    vl_logic_vector(31 downto 0);
        wd_o            : out    vl_logic_vector(4 downto 0);
        wreg_o          : out    vl_logic;
        inst_o          : out    vl_logic_vector(31 downto 0);
        next_inst_in_delayslot_o: out    vl_logic;
        branch_flag_o   : out    vl_logic;
        branch_target_address_o: out    vl_logic_vector(31 downto 0);
        link_addr_o     : out    vl_logic_vector(31 downto 0);
        is_in_delayslot_o: out    vl_logic;
        excepttype_o    : out    vl_logic_vector(31 downto 0);
        current_inst_address_o: out    vl_logic_vector(31 downto 0);
        stallreq        : out    vl_logic
    );
end id;

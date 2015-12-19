library verilog;
use verilog.vl_types.all;
entity ctrl is
    port(
        rst             : in     vl_logic;
        stallreq_from_if: in     vl_logic;
        stallreq_from_id: in     vl_logic;
        stallreq_from_ex: in     vl_logic;
        stallreq_from_mem: in     vl_logic;
        excepttype_i    : in     vl_logic_vector(31 downto 0);
        cp0_epc_i       : in     vl_logic_vector(31 downto 0);
        new_pc          : out    vl_logic_vector(31 downto 0);
        flush           : out    vl_logic;
        stall           : out    vl_logic_vector(5 downto 0)
    );
end ctrl;

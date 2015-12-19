library verilog;
use verilog.vl_types.all;
entity inst_rom is
    port(
        ce              : in     vl_logic;
        addr            : in     vl_logic_vector(31 downto 0);
        inst            : out    vl_logic_vector(31 downto 0);
        ack             : out    vl_logic
    );
end inst_rom;

----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;


entity Karplus is
    generic ( s_rate: integer := 65536;
              bits  : integer := 16;
              p     : integer := 160);
    port    ( start : in  std_logic;
              octave: in  std_logic_vector (2 downto 0);
              clk   : in  std_logic;
              output: out std_logic_vector (bits-1 downto 0));
end Karplus;

architecture Behavioral of Karplus is
    type delay_line is array (0 to p-1) of std_logic_vector(bits-1 downto 0);
    signal delay : delay_line;
    
    signal output_int : std_logic_vector(bits-1 downto 0);
begin

process (clk)
    
begin
    if rising_edge(clk) then
        output_int <= std_logic_vector(unsigned('0' & delay(p-1)(bits-1 downto 1)) + unsigned('0' & delay(p-2)(bits-1 downto 1)));
    
        if start = '1' then
            delay <= (0 to p-2 => (bits-1 downto 0 => '0')) & (bits-1 downto 0 => '1');
        else
            delay <= output_int & delay(0 to p-2);
        end if;
    end if;
end process;

    output <= output_int;

end Behavioral;



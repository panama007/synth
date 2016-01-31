
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;


entity sigma_delta_DAC is
    generic ( n : integer := 16);
    port    ( K_clk   : in  std_logic;
              data_in : in  std_logic_vector(n-1 downto 0);
              data_out: out std_logic);
end sigma_delta_DAC;

architecture Behavioral of sigma_delta_DAC is
    signal dif : std_logic_vector(n-1 downto 0);
    signal integrated : std_logic_vector(n-1 downto 0);
    signal out_int : std_logic;
begin
    dif <= data_in - (n-1 downto 0 => out_int);
    out_int <= integrated(n-1);
    
process(K_clk, dif)
begin
    if rising_edge(K_clk) then
        integrated <= dif + integrated;
    end if;
end process;

end Behavioral;



library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;


entity sigma_delta_DAC is
    generic ( bits    : integer := 16);
    port    ( clk     : in  std_logic;
              data_in : in  std_logic_vector(bits-1 downto 0);
              data_out: out std_logic);
end sigma_delta_DAC;

architecture Behavioral of sigma_delta_DAC is
    --signal dif : std_logic_vector(n-1 downto 0);
    signal accumulator : unsigned(bits downto 0) := (others => '0');
    --signal out_int : std_logic;
begin
    --dif <= data_in - (n-1 downto 0 => out_int);
    data_out <= accumulator(bits);
    
process(clk)
begin
    if rising_edge(clk) then
        accumulator <= ('0' & accumulator(bits-1 downto 0)) + unsigned('0' & data_in);
    end if;
end process;

end Behavioral;


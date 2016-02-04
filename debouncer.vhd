
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

entity debouncer is
    generic (signals    : integer := 1);
    port    (bouncy     : in std_logic_vector(signals-1 downto 0);
             clk        : in std_logic;
             debounced  : out std_logic_vector(signals-1 downto 0));
end debouncer;

architecture Behavioral of debouncer is
    signal temp_signal  : std_logic_vector(signals-1 downto 0);
    signal debounce_ctr : unsigned(10 downto 0) := (others => '0');
begin
process (clk)
begin
    if rising_edge(clk) then
        if debounce_ctr(10) = '1' then
            debounced <= temp_signal;
        end if;
    
        if bouncy = temp_signal then
            debounce_ctr <= debounce_ctr + ((10 downto 1 => '0') & '1');
        else
            debounce_ctr <= (others => '0');
            temp_signal <= bouncy;
        end if;
    end if;
end process;
end Behavioral;


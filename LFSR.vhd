
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;



entity LFSR is
    generic ( bits  : integer := 17);
    port    ( clk   : in  std_logic;
              rand  : out std_logic_vector(bits-1 downto 0));
end LFSR;

architecture Behavioral of LFSR is
    constant taps : std_logic_vector(bits-1 downto 0) := "10010000000000000";

    signal rand_int : std_logic_vector(bits-1 downto 0) := (bits-2 downto 0 => '0') & '1';
begin
    rand <= rand_int;


process(clk)
    variable result : std_logic;
begin
    if rising_edge(clk) then
        result := '0';
        for i in 0 to bits-1 loop
            if taps(i) = '1' then
                result := result xor rand_int(i);
            end if;
        end loop;
        
        rand_int <= rand_int(bits-2 downto 0) & result;
    end if;
end process;
end Behavioral;


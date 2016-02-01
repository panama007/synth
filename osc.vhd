
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;


entity osc is
    generic ( bits  : integer := 16;
              n     : integer := 20);
    port    ( freq  : in  std_logic_vector (bits-1 downto 0);
              wave  : in  std_logic_vector (1 downto 0);
              clk   : in  std_logic;
              output: out std_logic_vector (bits-1 downto 0));
end osc;

architecture Behavioral of osc is
    signal cntr : std_logic_vector(n-1 downto 0) := (n-1 downto 0 => '0');
    
    signal cos : std_logic_vector(bits-1 downto 0);
begin

    CORDIC : entity work.CORDIC
        generic map (bits => bits, iters => bits)
        port map (clk => clk, angle => cntr(n-1 downto n-bits), cos => cos);


process (clk)
    
begin
    if rising_edge(clk) then
        --cntr := std_logic_vector(unsigned(cntr) + (resize(unsigned(freq),n) sll (n-bits)));
        cntr <= std_logic_vector(unsigned(cntr) + ((n-bits-1 downto 0 => '0') & unsigned(freq)));
    end if;
    
    if wave = "00" then
        output <= cos;
    elsif wave = "01" then
        output <= cntr(n-1 downto n-bits);
    elsif wave = "11" then
        if cntr(n-1) = '0' then
            output <= cntr(n-2 downto n-bits-1);
        else
            output <= std_logic_vector((n-2 downto n-bits-1 => '1') - unsigned(cntr(n-2 downto n-bits-1)));
        end if;
    elsif wave = "10" then
        output <= (bits-1 downto 0 => cntr(n-1));
    end if;
end process;
end Behavioral;


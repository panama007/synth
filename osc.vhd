
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;


entity osc is
    generic ( bits  : integer := 16;
              n     : integer := 20);
    port    ( freq  : in  std_logic_vector (bits-1 downto 0);
              wave  : in  std_logic_vector (1 downto 0);
              button: in std_logic;
              clk   : in  std_logic;
              CORDIC_clk : in std_logic;
              output: out std_logic_vector (bits-1 downto 0));
end osc;

architecture Behavioral of osc is
    signal cntr : std_logic_vector(n-1 downto 0) := (others => '0');
    signal output_int : std_logic_vector (bits-1 downto 0) := (others => '0');
    
    signal cos : std_logic_vector(bits-1 downto 0);
begin

    CORDIC : entity work.CORDIC
        generic map (bits => bits, iters => bits)
        port map (clk => CORDIC_clk, angle => cntr(n-1 downto n-bits), cos => cos);

    output <= output_int when button = '1' else
              (others => '0');
process (clk)
    
begin
    if rising_edge(clk) then
        --cntr := std_logic_vector(unsigned(cntr) + (resize(unsigned(freq),n) sll (n-bits)));
        cntr <= std_logic_vector(unsigned(cntr) + ((n-bits-1 downto 0 => '0') & unsigned(freq)));  
        
        if wave = "00" then
            output_int <= cos;
        elsif wave = "01" then
            output_int <= cntr(n-1 downto n-bits);
        elsif wave = "11" then
            if cntr(n-1) = '0' then
                output_int <= cntr(n-2 downto n-bits-1);
            else
                output_int <= std_logic_vector((n-2 downto n-bits-1 => '1') - unsigned(cntr(n-2 downto n-bits-1)));
            end if;
        elsif wave = "10" then
            output_int <= (bits-1 downto 0 => cntr(n-1));
        end if;
    end if;
end process;
end Behavioral;


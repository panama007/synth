
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;


entity osc is
    generic ( bits  : integer := 16;
              n     : integer := 20);
    port    ( freq  : in  std_logic_vector (bits-1 downto 0);
              wave  : in  std_logic_vector (1 downto 0);
              clk   : in  std_logic;
              CORDIC_clk : in std_logic;
              output: out std_logic_vector (bits-1 downto 0));
end osc;

architecture Behavioral of osc is
    signal output_int : std_logic_vector (bits-1 downto 0) := (others => '0');
    signal cos : std_logic_vector(bits-1 downto 0);
    
    signal cntr: std_logic_vector(n-1 downto 0) := (others => '0');
begin

    CORDIC : entity work.CORDIC
        generic map (bits => bits, iters => bits)
        port map (clk => CORDIC_clk, angle => cntr(n-1 downto n-bits), cos => cos);

    output <= output_int;
process (clk)
    
begin
    if rising_edge(clk) then
        cntr <= std_logic_vector(unsigned(cntr) + resize(unsigned(freq), n));
    
        case wave is
            when "00" => output_int <= cos; 
            when "01" => output_int <= cntr(n-1 downto n-bits);
            when "10" => output_int <= (bits-1 downto 0 => cntr(n-1));
            when others => 
                if cntr(n-1) = '0' then
                    output_int <= cntr(n-2 downto n-bits-1);
                else
                    output_int <= std_logic_vector((n-2 downto n-bits-1 => '1') - unsigned(cntr(n-2 downto n-bits-1)));
                end if;
        end case;
    end if;
end process;
end Behavioral;


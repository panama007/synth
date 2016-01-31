
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;



entity test_top is
    generic ( bits : integer := 16);
    port ( clk     : in std_logic;
           latch   : in std_logic;
           switches: in std_logic_vector(7 downto 0);
           keyboard: in std_logic_vector(11 downto 0);
           cathodes: out std_logic_vector(6 downto 0);
           anodes  : inout std_logic_vector(3 downto 0));
end test_top;

architecture Behavioral of test_top is
    signal freq : std_logic_vector(bits-1 downto 0);
    signal waveform : std_logic_vector(bits-1 downto 0);
begin
    freq <= keyboard(11) & keyboard(9) & (bits-3 downto 0 => '0');
    
    LCD : entity work.LCD_driver 
        generic map (bits => 16, clk_div => 10)
        port map (latch => clk, clk => clk, freq => freq, cathodes => cathodes, anodes => anodes);
    
    OSC : entity work.osc
        generic map (bits => 16, n => 20)    
        port map (freq => freq, wave => switches(1 downto 0), clk => clk, output => waveform);

end Behavioral;
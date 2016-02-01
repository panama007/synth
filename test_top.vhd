
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;



entity test_top is
    generic ( bits : integer := 16);
    port ( clk     : in std_logic;
           latch   : in std_logic;
           switches: in std_logic_vector(7 downto 0);
           keyboard: in std_logic_vector(11 downto 0);
           rotary1 : in std_logic_vector(1 downto 0);
           speaker : out std_logic;
           cathodes: out std_logic_vector(6 downto 0);
           anodes  : inout std_logic_vector(3 downto 0));
end test_top;

architecture Behavioral of test_top is
    signal freq : std_logic_vector(bits-1 downto 0);
    signal waveform : std_logic_vector(bits-1 downto 0);
    signal to_disp : std_logic_vector(bits-1 downto 0);
    signal test : std_logic_vector(2 downto 0);
    signal divided_clk : std_logic;
    
    constant div : integer := 2;
begin
    --freq <= keyboard(11) & keyboard(9) & (bits-3 downto 0 => '0');
    --to_disp <= test & (bits-4 downto 0 => '0') when switches(0) = '1' else
    to_disp <= freq;
    
    LCD : entity work.LCD_driver 
        generic map (bits => bits, clk_div => 10)
        port map (latch => clk, clk => clk, freq => to_disp, cathodes => cathodes, anodes => anodes);
    
    OSC : entity work.osc
        generic map (bits => bits, n => 20)    
        port map (freq => freq, wave => switches(1 downto 0), clk => divided_clk, output => waveform);
        
    ROT : entity work.rotary
        generic map (bits => bits)
        port map (AB => rotary1, freq => freq, clk => clk, test => test);
        
    DAC : entity work.sigma_delta_DAC
        generic map (bits => bits)
        port map (clk => clk, data_in => waveform, data_out => speaker);

process (clk)
    variable ctr : integer := 0;
begin
    if rising_edge(clk) then
        if ctr = 2**div then
            divided_clk <= not divided_clk;
            ctr := 0;
        end if;
        ctr := ctr + 1;        
    end if;
end process;
end Behavioral;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.my_constants.all;

entity display_top is
    port    ( clk       : in  std_logic;
              waveform  : in  std_logic_vector(bits2-1 downto 0);
              --voice_in  : in  voice_input;
              wave      : waves_array;
              mode      : std_logic_vector(2 downto 0);
              hsync, vsync : out std_logic;
              R, G      : out std_logic_vector(2 downto 0);
              B         : out std_logic_vector(1 downto 0));
end display_top;

architecture Behavioral of display_top is
    type x_delay_line is array (0 to 1) of integer range 0 to VGA_timings.htotal-1;
    type y_delay_line is array (0 to 1) of integer range 0 to VGA_timings.vtotal-1;

    signal x        : integer range 0 to VGA_timings.htotal-1;
    signal y        : integer range 0 to VGA_timings.vtotal-1;
    signal draw     : std_logic;
    signal draws    : std_logic_vector(0 to 1);
    
    signal x_d      : x_delay_line;
    signal y_d      : y_delay_line;

begin

    display_cont : entity work.display_cont 
        port map (clk => clk, x => x, y => y);
   
    VGA_cont : entity work.display 
        port map (clk => clk, hsync => hsync, vsync => vsync, red => R, green => G, blue => B, x => x_d(1), y => y_d(1), draw => draw);
     
    scope : entity work.oscilloscope
        port map (clk => clk, waveform => waveform, draw => draws(0), x => x, y => y);
        
    menu : entity work.display_menu
        port map (clk => clk, x => x, y => y, draw => draws(1), wave => wave, mode => mode);
    
    
    draw <= draws(0) when y_d(1) > 600 else
            draws(1);

process (clk)
begin
    if rising_edge(clk) then
        x_d <= x & x_d(0);
        y_d <= y & y_d(0);
    end if;
end process;
end Behavioral;



library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.my_constants.all;


entity display is
    port    ( clk           : in  std_logic;
              hsync, vsync  : out std_logic;
              red, green    : out std_logic_vector(2 downto 0);
              blue          : out std_logic_vector(1 downto 0);
              x             : in integer range 0 to VGA_timings.htotal-1;
              y             : in integer range 0 to VGA_timings.vtotal-1;
              draw          : in  std_logic);
end display;

architecture Behavioral of display is
    constant xres    : integer := VGA_timings.xres;
    constant yres    : integer := VGA_timings.yres;

    constant hfporch : integer := VGA_timings.hfporch;
    constant hspulse : integer := VGA_timings.hspulse;
    
    constant vfporch : integer := VGA_timings.vfporch;
    constant vspulse : integer := VGA_timings.vspulse;
    
    constant pulse   : std_logic := VGA_timings.pulse;
begin

process (clk)
begin
    if rising_edge(clk) then
        if x >= xres+hfporch and x < xres+hfporch+hspulse then
            hsync <= pulse;
        else
            hsync <= not pulse;
        end if;
        if y >= yres+vfporch and y < yres+vfporch+vspulse then
            vsync <= pulse;
        else
            vsync <= not pulse;
        end if;
        
        if x < xres and y < yres then
            red     <= (others => draw);
            green   <= (others => draw);
            blue    <= (others => draw);
        else
            red     <= (others => '0');
            green   <= (others => '0');
            blue    <= (others => '0');
        end if;
    end if;        
end process;
end Behavioral;
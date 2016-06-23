
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.fonts.all;
use work.my_constants.all;


entity display_cont is
    port    ( clk           : in  std_logic;
              x             : out integer range 0 to VGA_timings.htotal-1;
              y             : out integer range 0 to VGA_timings.vtotal-1);
end display_cont;

architecture Behavioral of display_cont is
    constant htotal  : integer := VGA_timings.htotal;
    constant vtotal  : integer := VGA_timings.vtotal;
        
    signal x_int : integer range 0 to htotal-1;
    signal y_int : integer range 0 to vtotal-1;

begin

    x <= x_int;
    y <= y_int;

process (clk)
begin
    if rising_edge(clk) then
        if x_int < htotal-1 then
            x_int <= x_int + 1;
        else
            x_int <= 0;
            if y_int < vtotal-1 then
                y_int <= y_int + 1;
            else
                y_int <= 0;
            end if;
        end if;
    end if;        
end process;
end Behavioral;
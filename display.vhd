
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.fonts.all;
use work.my_constants.all;


entity display is
    port    ( clk           : in  std_logic;
              hsync, vsync  : out std_logic;
              red, green    : out std_logic_vector(2 downto 0);
              blue          : out std_logic_vector(1 downto 0);
              x             : out integer range 0 to VGA_timings.xres;
              y             : out integer range 0 to VGA_timings.yres;
              draw          : in  std_logic);
end display;

architecture Behavioral of display is
    constant xres    : integer := VGA_timings.xres;
    constant yres    : integer := VGA_timings.yres;

    constant hfporch : integer := VGA_timings.hfporch;
    constant hspulse : integer := VGA_timings.hspulse;
    constant hbporch : integer := VGA_timings.hbporch;
    constant hjunk   : integer := hbporch+hfporch+hspulse;
    constant htotal  : integer := xres+hjunk;
    
    constant vfporch : integer := VGA_timings.vfporch;
    constant vspulse : integer := VGA_timings.vspulse;
    constant vbporch : integer := VGA_timings.vbporch;
    constant vjunk   : integer := vbporch+vfporch+vspulse;
    constant vtotal  : integer := yres+vjunk;
    
    constant pulse   : std_logic := VGA_timings.pulse;
        
    signal hpos : integer range 0 to htotal-1 := 0;
    signal vpos : integer range 0 to vtotal-1 := 0;
    
    
    --constant cols    : integer := xres/16;
    --constant rows    : integer := yres/16;
    
    --signal draw : std_logic := '0';
begin

process (clk)
begin
    if rising_edge(clk) then
        if hpos < htotal-1 then
            hpos <= hpos + 1;
        else
            hpos <= 0;
            if vpos < vtotal-1 then
                vpos <= vpos + 1;
            else
                vpos <= 0;
            end if;
        end if;
        
        if hpos >= hfporch and hpos < hfporch+hspulse then
            hsync <= pulse;
        else
            hsync <= not pulse;
        end if;
        if vpos >= vfporch and vpos < vfporch+vspulse then
            vsync <= pulse;
        else
            vsync <= not pulse;
        end if;
        
        --if hpos = (hjunk + xres/2) or vpos = (vjunk + yres/2) then
        red     <= (others => draw);
        green   <= (others => draw);
        blue    <= (others => draw);
--        else
--            red <= (others => '0');
--            green <= (others => '0');
--            blue <= (others => '0');
--        end if;
    end if;
    
    if (hpos >= hjunk and hpos < hjunk + xres) and (vpos > vjunk and vpos < vjunk + yres) then
        x <= hpos - hjunk;
        y <= vpos - vjunk;
    else
        x <= xres;
        y <= yres;
    end if;
        
end process;

--process (clk)
--begin 
--    if rising_edge(clk) then
--        --if hpos >= hjunk and hpos < hjunk + cols*16 and vpos > vjunk and vpos < vjunk + rows*16 then
--        --    draw <= PressStart2P((hpos-hjunk)/16+(vpos-vjunk)/16)((vpos-vjunk) mod 16)((hpos-hjunk) mod 16);
--        --else
--        --    draw <= '0';
--        --end if;
--        --draw <= VGA_array(hpos)(vpos);
--    end if;
--end process;
end Behavioral;
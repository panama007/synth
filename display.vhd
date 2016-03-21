
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;



entity display is
    generic ( xres    : integer := 800;
              yres    : integer := 600);
    port    ( clk     : in  std_logic;
              hsync, vsync  : out std_logic;
              red, green    : out std_logic_vector(2 downto 0);
              blue          : out std_logic_vector(1 downto 0));
end display;

architecture Behavioral of display is
    constant hfporch : integer := 40;
    constant hbporch : integer := 88;
    constant hspulse : integer := 128;
    constant hjunk   : integer := hbporch+hfporch+hspulse;
    constant htotal  : integer := xres+hjunk;
    
    constant vfporch : integer := 1;
    constant vbporch : integer := 23;
    constant vspulse : integer := 4;
    constant vjunk   : integer := vbporch+vfporch+vspulse;
    constant vtotal  : integer := yres+vjunk;
    
    signal hpos : integer range 0 to htotal-1 := 0;
    signal vpos : integer range 0 to vtotal-1 := 0;
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
            hsync <= '0';
        else
            hsync <= '1';
        end if;
        if vpos >= vfporch and vpos < vfporch+vspulse then
            vsync <= '0';
        else
            vsync <= '1';
        end if;
        
        if hpos = (hjunk + xres/2) or vpos = (vjunk + yres/2) then
            red <= (others => '1');
            green <= (others => '1');
            blue <= (others => '1');
        else
            red <= (others => '0');
            green <= (others => '0');
            blue <= (others => '0');
        end if;
    end if;
end process;
end Behavioral;


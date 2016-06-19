
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.all;

use work.my_constants.all;

entity oscilloscope is
    port    ( clk       : in  std_logic;
              x             : in  integer range 0 to VGA_timings.xres;
              y             : in  integer range 0 to VGA_timings.yres;
              waveform      : in  std_logic_vector(bits2-1 downto 0);
              draw          : out std_logic);
end oscilloscope;

architecture Behavioral of oscilloscope is
    constant scope_left     : integer := 200;
    constant scope_right    : integer := 1720;
    constant scope_top      : integer := 624;
    constant scope_bot      : integer := 880;
    
    constant scope_res      : integer := scope_bot - scope_top;
    constant scope_len      : integer := scope_right - scope_left;
    
    constant res_bits       : integer := integer(ceil(log2(real(scope_res))));
    
    constant clks_per_refr  : integer := 2475000;
    constant clks_per_sample: integer := 3072*5;

    type sample_array is array (0 to scope_len) of std_logic_vector(res_bits-1 downto 0);
    type samples_array is array (0 to 1) of sample_array;
    
    signal samples : samples_array;
    signal arr      : integer range 0 to 1;
    signal head     : integer range sample_array'range;
    signal disp_head: integer range sample_array'range;
    
    signal ind      : integer range 0 to (sample_array'high)*2;
    
    signal refr_ctr         : integer range 0 to clks_per_refr-1;
    signal sample_ctr       : integer range 0 to clks_per_sample-1;
begin

    ind <= (disp_head + x - scope_left) mod scope_len;

process (clk)
begin
    if rising_edge(clk) then
        if (y >= scope_top and y <= scope_bot) and (x >= scope_left and x <= scope_right) then
            if (x = scope_left or x = scope_right) or (y = scope_top or y = scope_bot) then
                draw <= '1';
            elsif y - scope_top = to_integer(unsigned(samples(1-arr)(ind))) then
                draw <= '1';
            else
                draw <= '0';
            end if;
        else
            draw <= '0';
        end if;
    end if;
end process;

process (clk)
begin
    if rising_edge(clk) then   
        if refr_ctr = clks_per_refr then
            refr_ctr <= 0;
            disp_head <= head;
            arr <= 1 - arr;
        else
            refr_ctr <= refr_ctr+1;
        end if;
        
        if sample_ctr = clks_per_sample then
            sample_ctr <= 0;
            
            samples(arr)(head) <= waveform(bits2-1 downto bits2-res_bits);
            
            if head = sample_array'high then
                head <= 0;
            else
                head <= head + 1;
            end if;
        else
            sample_ctr <= sample_ctr+1;
        end if;
    end if;
end process;
end Behavioral;
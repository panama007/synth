
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;


library UNISIM;
use UNISIM.VComponents.all;

use work.my_constants.all;

entity clocks is
    port ( clk     : in std_logic;
           VGA_clk : out std_logic;
           sampling_clk : out std_logic);
end clocks;

architecture Behavioral of clocks is
    constant div : integer := 11;                                -- 100 MHz / 2^div = Fs
    signal ctr : unsigned(div-1 downto 0) := (others => '0');   

    signal VGA_clk_int : std_logic;
begin

   -- DCM_SP: Digital Clock Manager
   --         Spartan-6
   -- Xilinx HDL Language Template, version 14.7

   DCM_SP_inst : DCM_SP
   generic map (
      CLKFX_DIVIDE => VGA_timings.clk_div,                     -- Divide value on CLKFX outputs - D - (1-32)
      CLKFX_MULTIPLY => VGA_timings.clk_mul,                   -- Multiply value on CLKFX outputs - M - (2-32)
      CLKIN_PERIOD => 10.0,                  -- Input clock period specified in nS
      CLK_FEEDBACK => "NONE"                  -- Feedback source (NONE, 1X, 2X)
   )
   port map (
      CLKFX => VGA_clk_int,       -- 1-bit output: Digital Frequency Synthesizer output (DFS)
      CLKIN => clk,       -- 1-bit input: Clock input
      RST => '0'            -- 1-bit input: Active high reset input
   );

   -- BUFG: Global Clock Buffer
   --       Spartan-6
   -- Xilinx HDL Language Template, version 14.7

   BUFG_inst : BUFG
   port map (
      O => VGA_clk, -- 1-bit output: Clock buffer output
      I => VGA_clk_int  -- 1-bit input: Clock buffer input
   );


process (clk)
begin
        -- little logic to produce the divded clock
    if rising_edge(clk) then
        ctr <= ctr + 1;
    end if;
    sampling_clk <= ctr(div-1);
end process;
end Behavioral;


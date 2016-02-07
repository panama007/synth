-------------------------------------------------------------------
--
-- Sigma Delta DAC-
--      This entity takes a "bits"-long digital PCM signal and
--      produces a 1-bit PDM encoding of it.
--
-------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;


-------------------------------------------------------------------
--
-- generics:
--      bits-
--          Number of bits the input has.
-- ports:
--      data_in-
--          input signal, PCM.
--      clk-
--          should use system clock, to get a meaningful measure of
--          density we should make many pulses for each sample.
--      data_out-
--          1-bit data out, PDM.
-------------------------------------------------------------------


entity sigma_delta_DAC is
    generic ( bits    : integer := 16);
    port    ( clk     : in  std_logic;
              data_in : in  std_logic_vector(bits-1 downto 0);
              data_out: out std_logic);
end sigma_delta_DAC;

architecture Behavioral of sigma_delta_DAC is
    -- we use a VERY simple architecture for this. We are simply
    --      accumulating the input, and outputting the overflow bit
    --      (notice accumulator has an extra bit).
    signal accumulator : unsigned(bits downto 0) := (others => '0');
begin
    -- output is the overflow bit.
    data_out <= accumulator(bits);
    
process(clk)
begin
    if rising_edge(clk) then
        -- accumulate.
        accumulator <= ('0' & accumulator(bits-1 downto 0)) + unsigned('0' & data_in);
    end if;
end process;

end Behavioral;


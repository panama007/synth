-------------------------------------------------------------------
--
-- Debouncer-
--      This entity takes a bouncy signal and returns the debounced
--      signal.
--
-------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

-------------------------------------------------------------------
--
-- generics:
--      signals-
--          Number of bits the input/output has.
-- port:
--      bouncy-
--          Input bouncy signal.
--      debounced-
--          Output debounced signal.
-------------------------------------------------------------------

entity debouncer is
    generic (signals    : integer := 1);
    port    (bouncy     : in std_logic_vector(signals-1 downto 0);
             clk        : in std_logic;
             debounced  : out std_logic_vector(signals-1 downto 0));
end debouncer;

architecture Behavioral of debouncer is
    -- this is the last value we saw on the bouncy signal
    signal temp_signal  : std_logic_vector(signals-1 downto 0);
    -- after 2^10 clocks of the same value on the signal, we change it
    signal debounce_ctr : unsigned(10 downto 0) := (others => '0');
begin
process (clk)
begin
    if rising_edge(clk) then
        if debounce_ctr(10) = '1' then -- 2^10 clocks passed, no change on input
            debounced <= temp_signal;
        end if;
    
        if bouncy = temp_signal then
            debounce_ctr <= debounce_ctr + ((10 downto 1 => '0') & '1');
        else                           -- signal bounced, reset counter
            debounce_ctr <= (others => '0');
            temp_signal <= bouncy;
        end if;
    end if;
end process;
end Behavioral;


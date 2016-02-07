-------------------------------------------------------------------
--
-- Envelope-
--      This entity takes a signal and multiplies it by an ADSR envelope.
--      Currently the envelope is precalculated, 1 ms for each of
--      A,D,R. The attack goes from 0 to full range, the decay
--      falls to the halfpoint, the release falls to 0. All linearly.
--
-------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

use work.my_constants.all;

-------------------------------------------------------------------
--
-- generics:
--      bits-
--          Number of bits the input/output has.
-- ports:
--      full_signal-
--          unadultered input signal, should be full range (0 to 2^bits).
--      clk-
--          should use sampling clock, since we are processing samples
--          and only need 1 clock for each.
--      button-
--          button to control the ADSR sequence.
--      env_signal-
--          output signal, input signal * ADSR waveform.
-------------------------------------------------------------------

entity envelope is
    generic (bits       : integer := 16);
    port    (full_signal: in std_logic_vector(bits-1 downto 0);
             clk        : in std_logic;
             button     : in std_logic;
             env_signal : out std_logic_vector(bits-1 downto 0));
end envelope;

architecture Behavioral of envelope is
    -- based off current constants, this is the number of samples we
    --      have in 1 millisecond.
    constant ms : integer := 391;
    -- goes from 0 to full in ~391 clocks
    constant slope1 : unsigned(11 downto 0) := to_unsigned(10, 12);
    -- goes from full to sustain in ~391 clocks
    constant slope2 : unsigned(11 downto 0) := to_unsigned(5, 12);
    -- goes from sustain to 0 in ~391 clocks
    constant slope3 : unsigned(11 downto 0) := to_unsigned(5, 12);

    -- states to see what section we're in.
    signal state : std_logic_vector(2 downto 0);
    -- signal * ADSR (factor).
    signal temp_signal : unsigned(bits-1+12 downto 0);
    -- the ADSR waveform, kinda like a sharkfin, but more linear.
    signal factor : unsigned(11 downto 0);
    -- counter so we know when it's been 1 ms.
    signal cntr : integer range 0 to ms;
    
    -- to see when we just pressed the button.
    signal old_button : std_logic := '0';
begin
    -- do the calculations
    temp_signal <= factor * unsigned(full_signal);
    env_signal <= std_logic_vector(temp_signal(bits-1+12 downto 12));

process (clk)
begin
    if rising_edge(clk) then
        cntr <= cntr + 1;
        
        case state is
            when "000" =>       -- waiting for a button press
                factor <= (others => '0');
                cntr <= 0;
                if button = '1' and old_button = '0' then
                    state <= "001";
                end if;
            when "001" =>       -- in attack
                if cntr < 391 then
                    factor <= factor + slope1;
                else
                    state <= "010";
                    cntr <= 0;
                end if;
            when "010" =>       -- in decay
                if cntr < 391 then
                    factor <= factor - slope2;
                else
                    state <= "011";
            when "011" =>       -- in sustain
                factor <= factor;
                if button = '0' and old_button = '1' then
                    state <= "100";
                end if;
            when others =>      -- in release
                if factor > slope3 then
                    factor <= factor - slope3;
                else
                    factor <= (others => '0');
                    state <= "000";
                end if;
        end case;
        
        old_button <= button;
    end if;
end process;
end Behavioral;


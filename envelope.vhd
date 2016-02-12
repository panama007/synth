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
             controls   : in controls_array;
             button     : in std_logic;
             env_signal : out std_logic_vector(bits-1 downto 0));
end envelope;

architecture Behavioral of envelope is
--    -- based off current constants, this is the number of samples we
--    --      have in 1 millisecond.
--    constant ms : integer := 391;
--    -- goes from 0 to full in ~391 clocks
--    constant slope1 : unsigned(11 downto 0) := to_unsigned(10, 12);
--    -- goes from full to sustain in ~391 clocks
--    constant slope2 : unsigned(11 downto 0) := to_unsigned(5, 12);
--    -- goes from sustain to 0 in ~391 clocks
--    constant slope3 : unsigned(11 downto 0) := to_unsigned(5, 12);
    constant min : integer := 390;
    constant max : integer := 390000;
    type ar is array of real;

    function gen_exp(res : integer)
        return real is
            variable exp : real := 1.0;
    begin
        for i in 0 to iters-1 loop
            run_prod := run_prod * (1.0 / sqrt(1.0 + 2.0 ** (-2 * i)));
        end loop;
        return exp;
    end gen_K; 

    -- states to see what section we're in.
    signal state : std_logic_vector(2 downto 0);
    -- signal * ADSR (factor).
    signal temp_signal : unsigned(bits-1+16 downto 0);
    -- the ADSR waveform, kinda like a sharkfin, but more linear.
    signal factor : unsigned(15 downto 0);
    
    --signal step : unsigned(15 downto 0);
    
    -- to see when we just pressed the button.
    --signal old_button : std_logic := '0';
begin
    -- do the calculations
    temp_signal <= factor * unsigned(full_signal);
    env_signal <= std_logic_vector(temp_signal(bits-1+12 downto 12));

process (clk, button)
    variable step : unsigned(15 downto 0);
begin
    if button = '0' then
        state <= "000";
    end if;

    if rising_edge(clk) then
        --cntr <= cntr + 1;
        
        case state is
            when "000" =>       -- waiting for a button press
                step := resize(shift_right(factor * controls(0), ADSR_res),16);
                factor <= (others => '0');
                
                if button = '1' then-- and old_button = '0' then
                    factor <= (15 downto ADSR_res+1 => '0') & '1' & (ADSR_res-1 downto 0 => '0');
                    state <= "001";
                end if;
                
            when "001" =>       -- in attack
                step := resize(shift_right(factor * controls(0), ADSR_res-1),16);
                
                if factor >= (15 downto 0 =>'1') - step then 
                    state <= "010";
                else
                    factor <= factor + step;
                end if;
                
            when "010" =>       -- in decay
                step := resize(shift_right(factor * controls(1), ADSR_res-1),16);
                
                if factor <= controls(2) & (15 downto ADSR_res => '0') then
                    state <= "011";
                else
                    factor <= factor - step;
                end if;
                
            when "011" =>       -- in sustain
                factor <= factor;
                if button = '0' then
                    state <= "100";
                end if;
                
            when others =>      -- in release
                step := resize(shift_right(factor * controls(3), ADSR_res),16);
                
                if factor <= step then
                    factor <= (others => '0');
                    state <= "000";
                else
                    factor <= factor - step;   
                end if;
        end case;
        
    end if;
end process;
end Behavioral;


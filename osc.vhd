-------------------------------------------------------------------
--
-- Osc(illator)-
--      This entity is capable of producing 4 different waves,
--      sinusoid, sawtooth, square, triangle.
--
-------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

-------------------------------------------------------------------
--
-- generics:
--      bits-
--          bits in the output.
--      n-
--          number of bits in our internal time counter.
--
-- ports:
--      freq-
--          frequency of oscillation. "bits"-long with 3 extra to
--          prevent overflow when we add up to 3 signed "bits"-long
--          waves and pass that result as "freq" here.
--      wave-
--          00 = sinusoid, 01 = sawtooth, 10 = square, 11 = tri
--      clk-
--          clock at sampling rate
--      CORDIC_clk-
--          system clock, giving the CORDIC entity time to calculate
--          each sample.
--      reset-
--          button triggering the sound, used to reset the counter
--          so we get the same sound each time.
--      output-
--          wave sample
-------------------------------------------------------------------

entity osc is
    generic ( bits  : integer := 16;
              n     : integer := 20);
    port    ( freq  : in  std_logic_vector (bits+2 downto 0);
              wave  : in  std_logic_vector (1 downto 0);
              clk   : in  std_logic;
              CORDIC_clk : in std_logic;
              reset : in std_logic;
              output: out std_logic_vector (bits-1 downto 0));
end osc;

architecture Behavioral of osc is
    signal output_int : signed(bits-1 downto 0) := (others => '0');
    signal cos : std_logic_vector(bits-1 downto 0);
    
    -- used to see when the reset is just pressed
    signal old_reset : std_logic := '0';
    -- used as 'time', higher resolution than frequency, so we can just add frequency
    --      without max frequency being aliased down due to overflow.
    signal cntr: signed(n-1 downto 0) := (others => '0');
begin

    -- hook up CORDIC. Use top "bits" from cntr so the frequency matches the other 3 waves.
    CORDIC : entity work.CORDIC
        generic map (bits => bits, iters => bits)
        port map (clk => CORDIC_clk, angle => std_logic_vector(cntr(n-1 downto n-bits)), cos => cos);

    output <= std_logic_vector(output_int);
process (clk)
    
begin
    if rising_edge(clk) then
        -- move our phase/time forward by freq.
        cntr <= cntr + resize(signed(freq), n);
        -- reset cntr when we first strike the reset.
        if reset = '1' and old_reset = '0' then
            cntr <= (others => '0');
        end if;
    
        -- output the 4 types of waves
        case wave is
            when "00" => output_int <= signed(cos); 
            when "01" => output_int <= cntr(n-1 downto n-bits);
            when "10" => output_int <= (bits-1 downto 0 => cntr(n-1));
            when others => 
                if cntr(n-1) = '0' then
                    output_int <= cntr(n-2 downto n-bits-1);
                else
                    output_int <= (n-2 downto n-bits-1 => '1') - cntr(n-2 downto n-bits-1);
                end if;
        end case;
        
        old_reset <= reset;
    end if;
end process;
end Behavioral;


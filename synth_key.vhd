-------------------------------------------------------------------
--
-- Synth Key-
--      This entity implements 1 voice for the synth. It implements
--      all the supported patches (some random patches I thought of,
--      I still have to figure out which ones actually sound good).
--      It also resets itself when the button input goes 0->1.
--
-------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

use work.my_constants.all;


-------------------------------------------------------------------
--
-- generics:
--      bits-
--          Number of bits the input has.
--      oscs-
--          Number of oscillator blocks we can interconnect.
-- ports:
--      clk-
--          The system clock, passed in to the oscillators for the
--          CORDIC.
--      divided_clk-
--          The sampling clock.
--      button-
--          This will reset the phase/time back to 0 so each time
--          we hit the key the voice will sound the same.
--      mod_index-
--          Most patches will make the frequency input to some
--          osc block a sum of its normal frequency, and an osc's
--          output. This index scales the osc output from 0 to 1
--          to produce different sounds.
--      wave-
--          Sinusoid, saw, square, triangle.
--      freq-
--          Base frequencies for each oscillator. As mentioned
--          before, the ACTUAL frequency input to the oscillator
--          will be this freq + some osc outputs.
--      mode-
--          Which patch is to be calculated. The architecture of the
--          oscillators.
--      output-
--          The output of the voice/synth key.
-------------------------------------------------------------------


entity synth_key is
    generic (bits   : integer := 16;
             oscs   : integer := 3);
    port    (clk        : in std_logic;
             divided_clk: in std_logic;
             button     : in std_logic;
             mod_index  : in mod_index_array;
             wave       : in waves_array;
             freq       : in freqs_array;
             mode       : in std_logic_vector(2 downto 0);
             output     : out std_logic_vector(bits_voice_out-1 downto 0));
end synth_key;

architecture Behavioral of synth_key is
    type temp_ar is array (0 to oscs-1) of std_logic_vector(bits+4+5 downto 0);
    
    -- signal to hold each oscillator's output
    signal waveforms : waveforms_array;
    -- signal after converting those waveforms from unsigned to signed
    signal signed_waveforms : waveforms_array;
    -- temp signal used in the conversion from unsigned to signed
    signal temp      : temp_ar;
    -- internal output, so we can register it
    signal output_int: std_logic_vector(bits_voice_out-1 downto 0);
    
    -- actual frequencies being fed into the oscillators.
    signal freqs     : freqs_array2;
begin
    
        unsigned2signed : for i in 0 to oscs-1 generate
            -- treat mod_index like a 4 bit number between 0 and 1 (or 15/16)
            temp(i) <= std_logic_vector(signed(resize(unsigned(mod_index(i)),5))*(signed(resize(unsigned(waveforms(i)), bits+1+4)) - to_signed(2**(bits+3), bits+5)));
            signed_waveforms(i) <= std_logic_vector(temp(i)(temp(i)'left downto temp(i)'left-bits+1));
        end generate unsigned2signed;

    
process (clk)
begin
    if rising_edge(clk) then
        -- depending on the patch, we'll have different connections into the oscs and as output. Refer to
        --      docs to see the patches.
        case mode is
            when "000" => 
                freqs(0)  <= std_logic_vector(resize(unsigned(freq(0)), bits+3));
                freqs(1)  <= std_logic_vector(resize(unsigned(freq(1)), bits+3));
                output_int <= std_logic_vector(resize(unsigned(waveforms(0)), bits_voice_out) + resize(unsigned(waveforms(1)), bits_voice_out));
            when "001" => 
                freqs(0) <= std_logic_vector(signed(std_logic_vector(resize(unsigned(freq(0)), bits+3))) + resize(signed(signed_waveforms(1)), bits+3));
                freqs(1) <= std_logic_vector(resize(unsigned(freq(1)), bits+3));
                output_int <= waveforms(0) & '0';
            when "010" => 
                freqs(0) <= std_logic_vector(signed(std_logic_vector(resize(unsigned(freq(0)), bits+3))) + resize(signed(signed_waveforms(0)), bits+3));
                freqs(1) <= std_logic_vector(resize(unsigned(freq(1)), bits+3));
                output_int <= std_logic_vector(resize(unsigned(waveforms(0)), bits_voice_out) + resize(unsigned(waveforms(1)), bits_voice_out));
            when "011" => 
                freqs(0) <= std_logic_vector(signed(std_logic_vector(resize(unsigned(freq(0)), bits+3))) + resize(signed(signed_waveforms(0)), bits+3) + resize(signed(signed_waveforms(1)), bits+3));
                freqs(1) <= std_logic_vector(resize(unsigned(freq(1)), bits+3));
                output_int <= waveforms(0) & '0';
            when "100" => 
                freqs(0) <= std_logic_vector(signed(std_logic_vector(resize(unsigned(freq(0)), bits+3))) + resize(signed(signed_waveforms(1)), bits+3));
                freqs(1) <= std_logic_vector(signed(std_logic_vector(resize(unsigned(freq(1)), bits+3))) + resize(signed(signed_waveforms(1)), bits+3));
                output_int <= waveforms(0) & '0';
            when "101" => 
                freqs(0) <= std_logic_vector(signed(std_logic_vector(resize(unsigned(freq(0)), bits+3))) + resize(signed(signed_waveforms(0)), bits+3));
                freqs(1) <= std_logic_vector(signed(std_logic_vector(resize(unsigned(freq(1)), bits+3))) + resize(signed(signed_waveforms(1)), bits+3));
                output_int <= std_logic_vector(resize(unsigned(waveforms(0)), bits_voice_out) + resize(unsigned(waveforms(1)), bits_voice_out));
            when others => 
                freqs(0) <= std_logic_vector(signed(std_logic_vector(resize(unsigned(freq(0)), bits+3))) + resize(signed(signed_waveforms(1)), bits+3));
                freqs(1) <= std_logic_vector(signed(std_logic_vector(resize(unsigned(freq(1)), bits+3))) + resize(signed(signed_waveforms(0)), bits+3));
                output_int <= std_logic_vector(resize(unsigned(waveforms(0)), bits_voice_out) + resize(unsigned(waveforms(1)), bits_voice_out));
        end case;  
    end if;
end process;
    
    output <= output_int;

    -- instantiate the oscillators, connecting them the the appropriate signals.
    oscillators : for i in 0 to oscs-1 generate
        OSC : entity work.osc
            generic map (bits => bits, n => 20)    
            port map (freq => freqs(i), wave => wave(i), clk => divided_clk, output => waveforms(i), CORDIC_clk => clk, reset => button);
    end generate oscillators;

end Behavioral;


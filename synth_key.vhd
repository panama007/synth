
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

use work.my_constants.all;

entity synth_key is
    generic (bits   : integer := 16;
             oscs   : integer := 3);
    port    (clk        : in std_logic;
             divided_clk: in std_logic;
             start      : in std_logic;
             wave       : in waves_array;
             freq       : in freqs_array;
             mode       : in std_logic_vector(2 downto 0);
             output     : out std_logic_vector(bits_voice_out-1 downto 0));
end synth_key;

architecture Behavioral of synth_key is
    signal waveforms : waveforms_array;
    signal signed_waveforms : waveforms_array;
    signal KSoutput  : std_logic_vector(bits-1 downto 0);
    signal output_int: std_logic_vector(bits_voice_out-1 downto 0);

    signal freqs     : freqs_array2;
    --KS : entity work.Karplus
      --  generic map (bits => bits, n => 20)    
        --port map (freq => freq(i), wave => wave(i), clk => divided_clk, output => waveforms(i), CORDIC_clk => clk);
    
begin
    
        blah : for i in 0 to oscs-1 generate
            signed_waveforms(i) <= std_logic_vector(resize(signed(resize(unsigned(waveforms(i)), bits+1)) - ("01" & (bits-2 downto 0 => '0')), bits));
        end generate blah;

    
process (clk)
--    variable cumsum : unsigned(bits_voice_out-1 downto 0);
begin
    if rising_edge(clk) then
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
        
--        for i in 0 to oscs-1 loop
--            angles(i) <= std_logic_vector(unsigned(angles(i)) + resize(unsigned(freq(i)), n));
--        end loop;
    end if;
end process;
    
    output <= output_int when start = '1' else
              (others => '0');

    oscillators : for i in 0 to oscs-1 generate
        OSC : entity work.osc
            generic map (bits => bits, n => 20)    
            port map (freq => freqs(i), wave => wave(i), clk => divided_clk, output => waveforms(i), CORDIC_clk => clk);
    end generate oscillators;

end Behavioral;


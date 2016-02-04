
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
             mode       : in std_logic;
             output     : out std_logic_vector(bits_voice_out-1 downto 0));
end synth_key;

architecture Behavioral of synth_key is
    signal waveforms : waveforms_array;
    signal KSoutput  : std_logic_vector(bits-1 downto 0);
    signal output_int: std_logic_vector(bits_voice_out-1 downto 0);

    signal angles    : angles_array := (0 to oscs-1 => (n-1 downto 0 => '0'));
    --KS : entity work.Karplus
      --  generic map (bits => bits, n => 20)    
        --port map (freq => freq(i), wave => wave(i), clk => divided_clk, output => waveforms(i), CORDIC_clk => clk);
    
begin
    
process (clk)
    variable cumsum : unsigned(bits_voice_out-1 downto 0);
begin
    if rising_edge(clk) then
        cumsum := (others => '0');
        for i in 0 to oscs-1 loop
            cumsum := cumsum + resize(unsigned(waveforms(i)), bits_voice_out);
        end loop;
        output_int <= std_logic_vector(cumsum);
        
        for i in 0 to oscs-1 loop
            angles(i) <= unsigned(angles(i)) + resize(unsigned(freq(i)), n);
        end loop;
    end if;
end process;
    
    output <= output_int when start = '1' else
              (others => '0');

    oscillators : for i in 0 to oscs-1 generate
        OSC : entity work.osc
            generic map (bits => bits, n => 20)    
            port map (angle => angles(i), wave => wave(i), clk => divided_clk, output => waveforms(i), CORDIC_clk => clk);
    end generate oscillators;

end Behavioral;


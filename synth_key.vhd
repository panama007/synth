
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;

package my_constants is
    constant bits   : integer := 16;
    constant bits_voice_out : integer := bits + ceil(log2(oscs));
    constant oscs   : integer := 3;
    constant voices : integer := 4; 

    type freqs_array        is array(0 to oscs-1) of std_logic_vector(bits-1 downto 0);
    type waveforms_array    is array(0 to oscs-1) of std_logic_vector(bits-1 downto 0);
    type rotaries_array     is array(0 to oscs-1) of std_logic_vector(1 downto 0);
    type waves_array        is array(0 to oscs-1) of std_logic_vector(1 downto 0);
    
end package my_constants;

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
             waveform   : out std_logic_vector(bits_voice_out-1 downto 0));
end synth_key;

architecture Behavioral of synth_key is
    signal waveforms : waveforms_array;
    signal KSoutput  : std_logic_vector(bits-1 downto 0);

    --KS : entity work.Karplus
      --  generic map (bits => bits, n => 20)    
        --port map (freq => freq(i), wave => wave(i), clk => divided_clk, output => waveforms(i), CORDIC_clk => clk);
    
    for i in 0 to oscs-1 generate
        OSC : entity work.osc
            generic map (bits => bits, n => 20)    
            port map (freq => freq(i), wave => wave(i), clk => divided_clk, output => waveforms(i), CORDIC_clk => clk);
    end generate;
begin
    
    waveform <= unsigned("00" & waveforms(0)) + unsigned("00" & waveforms(1)) + unsigned("00" & waveforms(2));


end Behavioral;


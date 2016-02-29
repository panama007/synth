
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

use work.my_constants.all;



entity FM_synth is
    generic (oscs, bits : integer);
    port (FM_in         : in FM_input;
          clk, div_clk, button  : in std_logic;
          output        : out signed(bits_voice_out-1 downto 0));
end FM_synth;

architecture Behavioral of FM_synth is
    signal osc_out : waveforms_array;
    
    type FM_record is record
        output  : signed(bits_voice_out-1 downto 0);
        freqs   : freqs_array2;
    end record;
    
    signal rin : FM_record;
    signal r   : FM_record  := (output => (others => '0'),
                                  freqs => (others => (others => '0')));
begin
    
    -- instantiate the oscillators, connecting them the the appropriate signals.
    oscillators : for i in 0 to oscs-1 generate
        OSC : entity work.osc
            generic map (bits => bits, n => 20)    
            port map (freq => r.freqs(i), wave => FM_in.wave(i), clk => div_clk, output => osc_out(i), CORDIC_clk => clk, reset => button);
    end generate oscillators;

    
    
process (r, FM_in, osc_out)
    variable v : FM_record;
begin
    v := r;

    case FM_in.mode is
        when "000" => 
            v.freqs(0)  := resize(FM_in.freq(0), bits+3);
            v.freqs(1)  := resize(FM_in.freq(1), bits+3);
            v.output := resize(osc_out(0), bits_voice_out) + resize(osc_out(1), bits_voice_out);
        when "001" => 
            v.freqs(0) := resize(FM_in.freq(0), bits+3) + resize(osc_out(1), bits+3);
            v.freqs(1) := resize(FM_in.freq(1), bits+3);
            v.output := osc_out(0) & '0';
        when "010" => 
            v.freqs(0) := resize(FM_in.freq(0), bits+3) + resize(osc_out(0), bits+3);
            v.freqs(1) := resize(FM_in.freq(1), bits+3);
            v.output := resize(osc_out(0), bits_voice_out) + resize(osc_out(1), bits_voice_out);
        when "011" => 
            v.freqs(0) := resize(FM_in.freq(0), bits+3) + resize(osc_out(0), bits+3) + resize(osc_out(1), bits+3);
            v.freqs(1) := resize(FM_in.freq(1), bits+3);
            v.output := osc_out(0) & '0';
        when "100" => 
            v.freqs(0) := resize(FM_in.freq(0), bits+3) + resize(osc_out(1), bits+3);
            v.freqs(1) := resize(FM_in.freq(1), bits+3) + resize(osc_out(1), bits+3);
            v.output := osc_out(0) & '0';
        when "101" => 
            v.freqs(0) := resize(FM_in.freq(0), bits+3) + resize(osc_out(0), bits+3);
            v.freqs(1) := resize(FM_in.freq(1), bits+3) + resize(osc_out(1), bits+3);
            v.output := resize(osc_out(0), bits_voice_out) + resize(osc_out(1), bits_voice_out);
        when others => 
            v.freqs(0) := resize(FM_in.freq(0), bits+3) + resize(osc_out(1), bits+3);
            v.freqs(1) := resize(FM_in.freq(1), bits+3) + resize(osc_out(0), bits+3);
            v.output := resize(osc_out(0), bits_voice_out) + resize(osc_out(1), bits_voice_out);
    end case;  
    
    rin <= v;
    
    output <= r.output;
end process;

process (div_clk)
begin
    if rising_edge(div_clk) then
        r <= rin;
    end if;
end process;
end Behavioral;



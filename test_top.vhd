
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

use work.my_constants.all;

entity test_top is
    generic ( bits : integer := 16;
              bits2: integer := 21);
    port ( clk     : in std_logic;
           latch   : in std_logic;
           switches: in std_logic_vector(7 downto 0);
           buttons : in std_logic_vector(voices-1 downto 0);
           rotaries: in rotaries_array;
           speaker : out std_logic;
           cathodes: out std_logic_vector(6 downto 0);
           anodes  : inout std_logic_vector(3 downto 0));
end test_top;

architecture Behavioral of test_top is
    type ar is array (0 to voices-1) of unsigned(bits-1 downto 0);
    type voice_outputs_array is array (0 to voices-1) of std_logic_vector(bits_voice_out-1 downto 0);
    type osc_freqs_array is array (0 to voices-1) of freqs_array;
    type octaves_array is array (0 to oscs-1) of integer range 0 to bits-1;

    signal base_freq    : std_logic_vector(bits-1 downto 0);
    signal waveform     : std_logic_vector(bits2-1 downto 0);
    signal to_disp      : std_logic_vector(bits-1 downto 0);
    signal test         : std_logic_vector(2 downto 0);
    signal divided_clk  : std_logic;
    signal voice_outputs: voice_outputs_array;
    signal osc_freqs    : osc_freqs_array;
    signal octave       : octaves_array;
    signal wave         : waves_array;
    signal mode         : std_logic_vector(2 downto 0);

    constant div : integer := 8;
    signal ctr : unsigned(div-1 downto 0) := (others => '0');
    
    function gen_notes(divisions : integer)
        return ar is
            variable notes_array : ar;
    begin
        for i in 0 to divisions-1 loop
            notes_array(i) := to_unsigned(integer(2.0**(real(i)/real(divisions)) * (2.0**(bits-1))), bits);
        end loop;
        return notes_array;
    end gen_notes; 

    constant notes : ar := gen_notes(voices);
begin
    mode <= switches(7 downto 5);
    to_disp <= "0000" & buttons;--std_logic_vector(to_unsigned(octave(0), 4)) & std_logic_vector(to_unsigned(octave(1), 4)) & '0' & mode & "00" & rotaries(1);
   
    wave_controls : for i in 0 to oscs-1 generate
        wave(i) <= switches(2*i+1 downto 2*i);
    end generate wave_controls;
   
    LCD : entity work.LCD_driver 
        generic map (bits => bits, clk_div => 10)
        port map (latch => clk, clk => clk, to_disp => to_disp, cathodes => cathodes, anodes => anodes);
    
    loop2 : for i in 0 to voices-1 generate
        loop1 : for j in 0 to oscs-1 generate
            osc_freqs(i)(j) <= std_logic_vector(shift_right(notes(i), bits-1-octave(j)));
        end generate loop1;
    
        VCS : entity work.synth_key
            generic map (bits => bits, oscs => oscs)    
            port map (freq => osc_freqs(i), wave => wave, divided_clk => divided_clk, output => voice_outputs(i), 
                      clk => clk, start => buttons(i), mode => mode);
    end generate loop2;    
        
    rots : for i in 0 to oscs-1 generate    
        ROT : entity work.rotary
            generic map (bits => bits)
            port map (AB => rotaries(i), clk => clk, oct => octave(i));
    end generate rots;
        
    DAC : entity work.sigma_delta_DAC
        generic map (bits => bits2)
        port map (clk => clk, data_in => waveform, data_out => speaker);

process (clk)
    variable cumsum : unsigned(bits2-1 downto 0);
begin
    if rising_edge(clk) then
        ctr <= ctr + ((div-1 downto 1 => '0') & '1');
    end if;
    divided_clk <= ctr(div-1);
    
    cumsum := (others => '0');
    for i in 0 to voices-1 loop
        cumsum := cumsum + resize(unsigned(voice_outputs(i)), bits2);
    end loop;
    waveform <= std_logic_vector(cumsum);
    
end process;
end Behavioral;

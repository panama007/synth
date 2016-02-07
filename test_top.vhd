
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
           rotaries: in rotaries_array(0 to 4);
           speaker : out std_logic;
           cathodes: out std_logic_vector(6 downto 0);
           anodes  : inout std_logic_vector(3 downto 0));
end test_top;

architecture Behavioral of test_top is
    type ar is array (0 to voices-1) of unsigned(bits-1 downto 0);
    type voice_outputs_array is array (0 to voices-1) of std_logic_vector(bits_voice_out-1 downto 0);
    type osc_freqs_array is array (0 to voices-1) of freqs_array;
    type octaves_array is array (0 to oscs-1) of integer range 0 to bits-1;
    type mod_index_array is array (0 to oscs-1) of unsigned(3 downto 0);

    signal waveform     : std_logic_vector(bits2-1 downto 0);   -- the output being fed into DAC.
    signal to_disp      : std_logic_vector(bits-1 downto 0);    -- number to display on 4-digit 7-segment LCD.
    signal divided_clk  : std_logic;                            -- sampling clock.
    signal voice_outputs: voice_outputs_array;                  -- output of each voice
    signal envelope_outputs : voice_outputs_array;
    signal osc_freqs    : osc_freqs_array;                      -- 2D frequency array, 1 for each pair (osc,voice)
    signal octave       : octaves_array;                        -- array of octave value, 1 per osc.
    signal wave         : waves_array;                          -- the type of wave for each osc. (cos/saw/square/tri)
    signal mode         : std_logic_vector(2 downto 0);         -- which FM "patch"
    signal db_buttons   : std_logic_vector(voices-1 downto 0);  -- debounced buttons
    signal mod_index    : mod_index_array;
    
    signal up_down      : rotaries_array;                       -- up/down output of rotary entity
    

    constant div : integer := 8;                                -- 100 MHz / 2^div = Fs
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
    to_disp <= "0000" & buttons;
   
    wave_controls : for i in 0 to oscs-1 generate
        wave(i) <= switches(2*i+1 downto 2*i);
    end generate wave_controls;
   
    DB : entity work.debouncer
        generic map (signals => voices)
        port map (bouncy => buttons, clk => clk, debounced => db_buttons);
   
    LCD : entity work.LCD_driver 
        generic map (bits => bits, clk_div => 10)
        port map (latch => clk, clk => clk, to_disp => to_disp, cathodes => cathodes, anodes => anodes);
    
    VCS : for i in 0 to voices-1 generate
        loop1 : for j in 0 to oscs-1 generate
            osc_freqs(i)(j) <= std_logic_vector(shift_right(notes(i), bits-1-octave(j)));
        end generate loop1;
    
        VC : entity work.synth_key
            generic map (bits => bits, oscs => oscs)    
            port map (freq => osc_freqs(i), wave => wave, divided_clk => divided_clk, output => voice_outputs(i), 
                      clk => clk, start => db_buttons(i), mode => mode, mod_index => std_logic_vector(mod_index(i)));
        
        ENV : entity work.envelope
            generic map (bits => bits_voice_out)
            port map (full_signal => voice_outputs(i), clk => divided_clk, env_signal => envelope_outputs(i));
            
    end generate loop2;    
        
    rots : for i in 0 to 4 generate    
        ROT : entity work.rotary
            generic map (bits => bits)
            port map (AB => rotaries(i), clk => clk, up_down => up_down(i));
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
        cumsum := cumsum + resize(unsigned(envelope_outputs(i)), bits2);
    end loop;
    waveform <= std_logic_vector(cumsum);
    
end process;

process (clk)
begin
    if rising_clock(clk) then
        case up_down(0) is
            when "01" =>
                if octave(0) > 0 then
                    octave(0) <= octave(0) - 1;
                end if;
            when "10" =>
                if octave(0) < bits-1 then
                    octave(0) <= octave(0) + 1;
                end if;
            when others => octave(0) <= octave(0);
        end case;
        
        case up_down(1) is
            when "01" =>
                if octave(1) > 0 then
                    octave(1) <= octave(1) - 1;
                end if;
            when "10" =>
                if octave(1) < bits-1 then
                    octave(1) <= octave(1) + 1;
                end if;
            when others => octave(1) <= octave(1);
        end case;
        
        case up_down(2) is
            when "01" =>
                if mod_index(0) > 0 then
                    mod_index(0) <= mod_index(0) - 1;
                end if;
            when "10" =>
                if mod_index(0) < 0xF then
                    mod_index(0) <= mod_index(0) + 1;
                end if;
            when others => mod_index(0) <= mod_index(0);
        end case;
        
        case up_down(3) is
            when "01" =>
                if mod_index(1) > 0 then
                    mod_index(1) <= mod_index(1) - 1;
                end if;
            when "10" =>
                if mod_index(1) < 0xF then
                    mod_index(1) <= mod_index(1) + 1;
                end if;
            when others => mod_index(1) <= mod_index(1);
        end case;
    end if;
end process;
end Behavioral;

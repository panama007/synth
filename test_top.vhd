-------------------------------------------------------------------
--
-- Top Entity-
--      This entity implements the whole system, it's the top block
--      it instantiates debouncers, synth keys, rotaries, the DAC,
--      and the LCD.
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
--          Number of bits the input frequency to the voice has.
--      bits2-
--          Number of bits the output to the DAC has. We need to add
--          multiple voice outputs, so need more bits to prevent
--          overflow.
-- ports:
--      clk-
--          The system clock.
--      switches-
--          The 8 switches on the FPGA dev board.
--      buttons-
--          The 12 buttons on the PCB, 1 for each voice.
--      rotaries-
--          The (currently 5) rotaries on the PCB.
--      speaker-
--          PDM output to the lowpass filter which powers the speaker.
--      cathodes-
--          cathodes of the 4-digit 7-segment LCD.
--      anodes-
--          anodes of the 4-digit 7-segment LCD.
-------------------------------------------------------------------


entity test_top is
    generic ( bits : integer := 16;
              bits2: integer := 21);
    port ( clk     : in std_logic;
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

    signal waveform     : std_logic_vector(bits2-1 downto 0);   -- the output being fed into DAC.
    signal to_disp      : std_logic_vector(bits-1 downto 0);    -- number to display on 4-digit 7-segment LCD.
    signal divided_clk  : std_logic;                            -- sampling clock.
    signal voice_outputs: voice_outputs_array;                  -- output of each voice
    signal envelope_outputs : voice_outputs_array;              -- output of voice after enveloping
    signal osc_freqs    : osc_freqs_array;                      -- 2D frequency array, 1 for each pair (osc,voice)
    signal octave       : octaves_array;                        -- array of octave value, 1 per osc.
    signal wave         : waves_array;                          -- the type of wave for each osc. (cos/saw/square/tri)
    signal mode         : std_logic_vector(2 downto 0);         -- which FM "patch"
    signal db_buttons   : std_logic_vector(voices-1 downto 0);  -- debounced buttons
    signal mod_index    : mod_index_array;                      -- array of modulation indeces, one per osc
    
    signal attack       : unsigned(ADSR_res-1 downto 0);
    signal decay        : unsigned(ADSR_res-1 downto 0);
    signal sustain      : unsigned(ADSR_res-1 downto 0);
    signal release      : unsigned(ADSR_res-1 downto 0);
    signal controls     : controls_array;
    
    signal up_down      : rotaries_array(0 to 4);                       -- up/down output of rotary entity
    
    signal page         : std_logic := '0';
    

    constant div : integer := 8;                                -- 100 MHz / 2^div = Fs
    signal ctr : unsigned(div-1 downto 0) := (others => '0');   
    
    -- generates the 12 frequencies we use. any other frequency is one of these shifted right
    --      by some integer. Equal temperament, 2^(i/12) for i in (0,11)
    function gen_notes(divisions : integer)
        return ar is
            variable notes_array : ar;
        begin
            for i in 0 to divisions-1 loop
                notes_array(i) := to_unsigned(integer(2.0**(real(i)/real(divisions)) * (2.0**(bits-1))), bits);
            end loop;
            return notes_array;
        end gen_notes; 
    -- store these notes
    constant notes : ar := gen_notes(voices);
begin
    -- control the FM patch with the top 3 switches.
    mode <= switches(7 downto 5);
    -- choose what to display.
    to_disp <= std_logic_vector(attack) & std_logic_vector(decay) & std_logic_vector(sustain) & std_logic_vector(release);--(15 downto voices => '0') & buttons;
    
    controls(0) <= attack;
    controls(1) <= decay;
    controls(2) <= sustain;
    controls(3) <= release;
   
    -- for each oscillator, use 2 switches to control the waveform (sin, saw...)
    wave_controls : for i in 0 to oscs-1 generate
        wave(i) <= switches(2*i+1 downto 2*i);
    end generate wave_controls;
   
    -- debounce the keyboard/buttons
    DB : entity work.debouncer
        generic map (signals => voices)
        port map (bouncy => buttons, clk => clk, debounced => db_buttons);
   
    -- instantiate the LCD driver
    LCD : entity work.LCD_driver 
        generic map (bits => bits, clk_div => 10)
        port map (clk => clk, to_disp => to_disp, cathodes => cathodes, anodes => anodes);
    
    -- instantiate the whole keyboard
    VCS : for i in 0 to voices-1 generate
        -- calculate the actual frequencies for each key. As mentioned, these will just be
        --      the precomputed 12, shifted down by some number of octaves.
        loop1 : for j in 0 to oscs-1 generate
            osc_freqs(i)(j) <= std_logic_vector(shift_right(notes(i), bits-1-octave(j)));
        end generate loop1;
    
        -- the voice, the synth key, the heart of the synth
        VC : entity work.synth_key
            generic map (bits => bits, oscs => oscs)    
            port map (freq => osc_freqs(i), wave => wave, divided_clk => divided_clk, output => voice_outputs(i), 
                      clk => clk, button => db_buttons(i), mode => mode, mod_index => mod_index);
        
        -- amplitude envelope for the voice output, synced to button press.
        ENV : entity work.envelope
            generic map (bits => bits_voice_out)
            port map (full_signal => voice_outputs(i), clk => divided_clk, env_signal => envelope_outputs(i), button => db_buttons(i), controls => controls);
            
    end generate VCS;    
        
    -- instantiate a rotary decoder for each rotary encoder.
    rots : for i in 0 to 4 generate    
        ROT : entity work.rotary
            port map (AB => rotaries(i), clk => clk, up_down => up_down(i));
    end generate rots;
        
    -- the DAC for the whole system's output.
    DAC : entity work.sigma_delta_DAC
        generic map (bits => bits2)
        port map (clk => clk, data_in => waveform, data_out => speaker);

process (clk)
    variable cumsum : unsigned(bits2-1 downto 0);   -- will sum all voice outputs
begin
    -- little logic to produce the divded clock
    if rising_edge(clk) then
        ctr <= ctr + ((div-1 downto 1 => '0') & '1');
    end if;
    divided_clk <= ctr(div-1);
    
    
    -- add up all voice outputs
    cumsum := (others => '0');
    for i in 0 to voices-1 loop
        cumsum := cumsum + resize(unsigned(envelope_outputs(i)), bits2);
    end loop;
    waveform <= std_logic_vector(cumsum);
    
end process;

-- process to decode rotary up_down signals and actually change
--      a variable, like frequency or modulation index.
--      The 5th rotary isn't doing anything, I plan on using it
--      to page through the different variables that can be changed
--      I.E. first page is frequency+mod index, second page is ADSR, etc
process (clk)
begin
    if rising_edge(clk) then
        case page is
            when '0' => 
                case up_down(0) is
                    -- down is high, up is low, decrease quantity
                    when "01" =>
                        if octave(0) > 0 then
                            octave(0) <= octave(0) - 1;
                        end if;
                    -- up is high, down is low, increase quantity
                    when "10" =>
                        if octave(0) < bits-1 then
                            octave(0) <= octave(0) + 1;
                        end if;
                    -- quantity is unchanged
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
                        if mod_index(0) < 15 then
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
                        if mod_index(1) < 15 then
                            mod_index(1) <= mod_index(1) + 1;
                        end if;
                    when others => mod_index(1) <= mod_index(1);
                end case;
                
            when others => 
                case up_down(0) is
                    -- down is high, up is low, decrease quantity
                    when "01" =>
                        if attack > 0 then
                            attack <= attack - 1;
                        end if;
                    -- up is high, down is low, increase quantity
                    when "10" =>
                        if attack < 15 then
                            attack <= attack + 1;
                        end if;
                    -- quantity is unchanged
                    when others => attack <= attack;
                end case;
                
                case up_down(1) is
                    when "01" =>
                        if decay > 0 then
                            decay <= decay - 1;
                        end if;
                    when "10" =>
                        if decay < 15 then
                            decay <= decay + 1;
                        end if;
                    when others => decay <= decay;
                end case;
                
                case up_down(2) is
                    when "01" =>
                        if sustain > 0 then
                            sustain <= sustain - 1;
                        end if;
                    when "10" =>
                        if sustain < 15 then
                            sustain <= sustain + 1;
                        end if;
                    when others => sustain <= sustain;
                end case;
                
                case up_down(3) is
                    when "01" =>
                        if release > 0 then
                            release <= release - 1;
                        end if;
                    when "10" =>
                        if release < 15 then
                            release <= release + 1;
                        end if;
                    when others => release <= release;
                end case;
        end case;
        
        case up_down(4) is
            when "01" =>
                page <= '0';
            when "10" =>
                page <= '1';
            when others => page <= page;
        end case;
    end if;
end process;
end Behavioral;

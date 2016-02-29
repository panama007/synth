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
    generic ( bits : integer := 16);
    port ( clk     : in std_logic;
           switches: in std_logic_vector(7 downto 0);
           buttons : in std_logic_vector(voices-1 downto 0);
           rotaries: in rotaries_array(0 to 4);
           MIDI_in : in std_logic;
           speaker : out std_logic;
           LEDS    : out std_logic_vector(7 downto 0);
           cathodes: out std_logic_vector(6 downto 0);
           anodes  : inout std_logic_vector(3 downto 0));
end test_top;

architecture Behavioral of test_top is
    type ar is array (0 to voices-1) of unsigned(bits-1 downto 0);
    type voice_outputs_array is array (0 to voices-1) of unsigned(bits_voice_out-1 downto 0);
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
    signal virtual_buttons   : std_logic_vector(voices-1 downto 0);
    signal mod_index    : mod_index_array;                      -- array of modulation indeces, one per osc
    --signal FM_in        : FM_record;
    
    signal up_down      : rotaries_array(0 to 4);                       -- up/down output of rotary entity
    
    signal page         : std_logic := '0';
    signal test         : std_logic := '0';
    signal test2        : std_logic_vector(bits_voice_out-1 downto 0);
    
    signal MIDI_rdy     : std_logic := '0';
    signal MIDI_en      : std_logic := '0';
    signal status, data1, data2 : std_logic_vector(7 downto 0);
    
    signal in_use       : std_logic_vector(0 to voices-1);
    

    constant div : integer := 8;                                -- 100 MHz / 2^div = Fs
    constant MIDI_div : integer := 3200;                    -- 100 MHz / 31.25 kHz
    constant ctr_bits : integer := integer(ceil(log2(real(MIDI_div))));
    signal ctr : unsigned(div-1 downto 0) := (others => '0');      
    signal MIDI_ctr : unsigned(ctr_bits-1 downto 0) := (others => '0');      
    
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
process (clk)
begin
    if rising_edge(clk) then
        if MIDI_rdy = '1' then
            --to_disp <= status & data2; 
            virtual_buttons(0) <= '1';
        else
            virtual_buttons(0) <= '0';
        end if;
    end if;
    

end process;
    -- control the FM patch with the top 3 switches.
    mode <= switches(7 downto 5);
    LEDS <= "00" & db_buttons(0) & virtual_buttons(0) & test & MIDI_rdy & MIDI_en & MIDI_in;
    to_disp <= test2(test2'left downto test2'left-15);
   
    --virtual_buttons(0) <= status = X"90" and data2 /= (7 downto 0 => '0') and MIDI_rdy = '1';
   
   
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
            osc_freqs(i)(j) <= signed(std_logic_vector(shift_right(notes(i), bits-1-octave(j))));
        end generate loop1;
    
        -- the voice, the synth key, the heart of the synth
        VC : entity work.voice
            generic map (bits => bits, oscs => oscs)    
            port map (voice_in.FM_in.freq => osc_freqs(i), voice_in.FM_in.wave => wave, voice_in.FM_in.mode => mode, voice_in.FM_in.mod_index => mod_index,
                      voice_in.button => virtual_buttons(i),  voice_in.synth_mode => switches(4), clk => clk, div_clk => divided_clk, test=>test2,
                      voice_out.output => envelope_outputs(i), voice_out.in_use => in_use(i));
        
        -- amplitude envelope for the voice output, synced to button press.
--        ENV : entity work.envelope
--            generic map (bits => bits_voice_out)
--            port map (full_signal => voice_outputs(i), clk => divided_clk, env_signal => envelope_outputs(i), button => db_buttons(i), controls => controls);
--            
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
        
    MID : entity work.MIDI_decoder
        port map (clk => clk, enable => MIDI_en, command_rdy => MIDI_rdy, status => status, data1 => data1, data2 => data2, MIDI_in => MIDI_in);

process (clk)
    variable cumsum : unsigned(bits2-1 downto 0);   -- will sum all voice outputs
begin
    -- little logic to produce the divded clock
    if rising_edge(clk) then
        ctr <= ctr + 1;
        if MIDI_ctr = MIDI_div-1 then 
            MIDI_ctr <= (others => '0');
            MIDI_en <= '1';
        else
            MIDI_ctr <= MIDI_ctr + 1;
            MIDI_en <= '0';
        end if;
    end if;
    divided_clk <= ctr(div-1);
    
    
    -- add up all voice outputs
    cumsum := (others => '0');
    for i in 0 to voices-1 loop
        cumsum := cumsum + resize(envelope_outputs(i), bits2);
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
    end if;
end process;
end Behavioral;

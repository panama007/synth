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

Library UNISIM;
use UNISIM.vcomponents.all;

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


entity synth_top is
    generic ( bits : integer := 16);
    port ( clk     : in std_logic;
           switches: in std_logic_vector(7 downto 0);
           --buttons : in std_logic_vector(voices-1 downto 0);
           --rotaries: in rotaries_array(0 to 4);
           MIDI_in : in std_logic;
           speaker : out std_logic;
           LEDS    : out std_logic_vector(7 downto 0);
           cathodes: out std_logic_vector(6 downto 0);
           anodes  : inout std_logic_vector(3 downto 0);
           hsync, vsync : out std_logic;
           R, G : out std_logic_vector(2 downto 0);
           B : out std_logic_vector(1 downto 0));
end synth_top;

architecture Behavioral of synth_top is
    type voice_outputs_array is array (0 to voices-1) of signed(bits_voice_out-1 downto 0);
    
    type octaves_array is array (0 to oscs-1) of integer range 0 to bits-1;

    signal waveform     : std_logic_vector(bits2-1 downto 0);   -- the output being fed into DAC.
    signal to_disp      : std_logic_vector(bits-1 downto 0);    -- number to display on 4-digit 7-segment LCD.
    signal sampling_clk  : std_logic;                            -- sampling clock.
    signal voice_outputs: voice_outputs_array;                  -- output of each voice
    signal envelope_outputs : voice_outputs_array;              -- output of voice after enveloping
    signal osc_freqs    : osc_freqs_array;                      -- 2D frequency array, 1 for each pair (osc,voice)
    signal octave       : octaves_array;                        -- array of octave value, 1 per osc.
    signal wave         : waves_array;                          -- the type of wave for each osc. (cos/saw/square/tri)
    signal mode         : std_logic_vector(2 downto 0);         -- which FM "patch"
    signal virtual_buttons   : std_logic_vector(0 to voices-1);
    signal mod_index    : mod_index_array;                      -- array of modulation indeces, one per osc
    --signal FM_in        : FM_record;
    
    --signal up_down      : rotaries_array(0 to 4);                       -- up/down output of rotary entity
    
    signal page         : std_logic := '0';
    signal test         : std_logic := '0';
    signal test2        : std_logic_vector(bits_voice_out-1 downto 0);
    
    signal MIDI_rdy     : std_logic := '0';
    signal status, data1, data2 : std_logic_vector(7 downto 0) := (others => '1');
    
    signal in_use       : std_logic_vector(0 to voices-1);
    
    signal VGA_clk      : std_logic;  
    
begin
process (clk)
begin
    if rising_edge(clk) then
        if MIDI_rdy = '1' then
            if switches(0) = '0' then
                to_disp <= status & data1; 
            else
                to_disp <= status & data2;  
            end if;
        end if;
    end if;
    

end process;
    -- control the FM patch with the top 3 switches.
    mode <= switches(7 downto 5);
    LEDS <= "0000" & virtual_buttons(0) & test & MIDI_rdy & MIDI_in;
    --to_disp <= test2(test2'left downto test2'left-15);
    --to_disp <= status & data1;
   
    --virtual_buttons(0) <= status = X"90" and data2 /= (7 downto 0 => '0') and MIDI_rdy = '1';
   
   
    -- for each oscillator, use 2 switches to control the waveform (sin, saw...)
    wave_controls : for i in 0 to oscs-1 generate
        wave(i) <= switches(2*i+1 downto 2*i);
    end generate wave_controls;

    CLKS : entity work.clocks
        port map (clk => clk, VGA_clk => VGA_clk, sampling_clk => sampling_clk);

    display : entity work.display_top
        port map (wave => wave, mode => mode, clk => VGA_clk, waveform => waveform, R => R, G => G, B => B, hsync => hsync, vsync => vsync);
     
    -- instantiate the LCD driver
    LCD : entity work.LCD_driver 
        generic map (bits => bits, clk_div => 10)
        port map (clk => clk, to_disp => to_disp, cathodes => cathodes, anodes => anodes);
    
    CTRL : entity work.voice_controller
        generic map (bits => bits, voices => voices)
        port map (clk => clk, MIDI_rdy => MIDI_rdy, status => status, data1 => data1, data2 => data2, freqs => osc_freqs,
                  start => virtual_buttons, in_use => in_use);
    
    -- instantiate the whole keyboard
    VCS : for i in 0 to voices-1 generate    
        -- the voice, the synth key, the heart of the synth
        VC : entity work.voice
            generic map (bits => bits, oscs => oscs)    
            port map (voice_in.FM_in.freq => osc_freqs(i), voice_in.FM_in.wave => wave, voice_in.FM_in.mode => mode, voice_in.FM_in.mod_index => mod_index,
                      voice_in.button => virtual_buttons(i),  voice_in.synth_mode => switches(4), clk => clk, div_clk => sampling_clk,
                      voice_out.output => envelope_outputs(i), voice_out.in_use => in_use(i));
        
        -- amplitude envelope for the voice output, synced to button press.
--        ENV : entity work.envelope
--            generic map (bits => bits_voice_out)
--            port map (full_signal => voice_outputs(i), clk => sampling_clk, env_signal => envelope_outputs(i), button => db_buttons(i), controls => controls);
--            
    end generate VCS;    
        
        
    -- the DAC for the whole system's output.
    DAC : entity work.sigma_delta_DAC
        generic map (bits => bits2)
        port map (clk => clk, data_in => waveform, data_out => speaker);
        
    MID : entity work.MIDI_decoder
        port map (clk => clk, command_rdy => MIDI_rdy, status => status, data1 => data1, data2 => data2, MIDI_in => MIDI_in);

process (clk)
    variable cumsum : signed(bits2-1 downto 0);   -- will sum all voice outputs
begin   
    -- add up all voice outputs
    cumsum := (others => '0');
    for i in 0 to voices-1 loop
        cumsum := cumsum + resize(envelope_outputs(i), bits2);
    end loop;
    waveform <= std_logic_vector(cumsum);
    
end process;
end Behavioral;

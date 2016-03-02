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


entity voice is
    generic (bits       : integer := bits;
             oscs       : integer := oscs;
             duration   : integer := 1;
             sample_rate: integer := 10**8/2**8);
    port    (voice_in   : in voice_input;
             clk,div_clk: in std_logic;
             --test       : out std_logic_vector(bits_voice_out-1 downto 0);
             voice_out  : out voice_output);
end voice;

architecture Behavioral of voice is
    constant ctr_bits : integer := integer(ceil(log2(real(sample_rate*duration))))+1;
    type state_type is (off, playing);

    signal FM_output : signed(bits_voice_out-1 downto 0);
    signal KS_output : unsigned(bits_voice_out-1 downto 0);
    
    type voice_record is record
        button : std_logic;
        internal_button : std_logic;
        state  : state_type;
        ctr    : integer range 0 to 2**ctr_bits-1;
        output : unsigned(bits_voice_out-1 downto 0);
        in_use : std_logic;
    end record;
 
    signal rin : voice_record;
    signal r : voice_record := (button => '0',
                                  internal_button => '0',
                                  state => off,
                                  ctr => 0,
                                  output => (others => '0'),
                                  in_use => '0');
begin
    FM : entity work.FM_synth
        generic map (oscs=>oscs, bits=>bits)
        port map    (FM_in=>voice_in.FM_in, clk=>clk, div_clk=>div_clk, output=>FM_output, button=>r.internal_button);
        
    KS : entity work.Karplus
        generic map ( bits=>bits_voice_out, p=>150)
        port map ( clk=>clk, div_clk=>div_clk, start=>r.internal_button, output=>KS_output);
    
    --test <= std_logic_vector(KS_output);
    
process (r, voice_in, KS_output, FM_output)
    variable v : voice_record;
begin
    v := r; v.ctr := r.ctr+1;

    if r.state = playing then
        if voice_in.synth_mode = '1' then
            v.output := KS_output;
        else
            v.output := to_unsigned(to_integer(FM_output) + 2**(FM_output'length-1), bits_voice_out);
        end if;

        v.in_use := '1';
    else
        v.output := (others => '0');
        v.in_use := '0';
    end if;
    
    case r.state is
        when off =>
            if voice_in.button = '1' and r.button = '0' then
                v.state := playing;
            end if;
            v.internal_button := '0';
        when playing =>
            if r.ctr = 2**(ctr_bits-1) then
                v.state := off;
            end if;
            v.internal_button := '1';
    end case;
    
    v.button := voice_in.button;

    rin <= v;
    voice_out.in_use <= r.in_use;
    voice_out.output <= r.output;
end process;

process (div_clk)
begin
    if rising_edge(div_clk) then
        r <= rin;
    end if;
end process;

end Behavioral;


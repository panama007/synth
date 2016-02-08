-------------------------------------------------------------------
--
-- My Constants-
--      This package contains definitions for constants and types
--      I use in the entities. Some of the naming could be improved.
--
-------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.MATH_REAL.all;


-------------------------------------------------------------------
--
-- constants:
--      oscs-
--          Number of oscillator blocks inside each voice.
--      voices-
--          Number of voices. Essentially, number of keys that can be
--          pressed simultaneously.
--
--      bits-
--          Number of bits the CORDIC takes as input/output. Also the
--          size of the oscillator output.
--      bits_voice_out-
--          Added bits depending on how many oscillator outputs would
--          be added together potentially.
--      n-
--          number of bits used in the oscillator's internal phase.
--
-- types:
--      freqs_array-
--          array of raw frequency inputs to the oscillator blocks,
--          this is just a constant coming from the rotaries.
--      freqs_array2-
--          array of frequency inputs to the oscillator blocks, 
--          after having added waveforms, depending on the particular
--          patch.
--      waveforms_array-
--          array for the oscillator outputs.
--      rotaries_array-
--          array, 2 bits wide since not only is the input to the 
--          rotary entity 2 bits wide, but so is its output.
--          The number of rotary encoders I'm using isn't directly
--          tied to the number of oscillators, and is still being
--          finalized, which is why it's not a set width.
--      waves_array-
--          array for the wave type input to each oscillator.
--          can be sinusoid, saw, square, tri.
--
-------------------------------------------------------------------


package my_constants is
    constant oscs   : integer := 2;
    constant voices : integer := 5; 
    
    constant bits   : integer := 16;
    constant bits_voice_out : integer := bits + integer(ceil(log2(real(oscs))));
    constant n      : integer := 20;

    type freqs_array        is array(0 to oscs-1) of std_logic_vector(bits-1 downto 0);
    type freqs_array2       is array(0 to oscs-1) of std_logic_vector(bits+2 downto 0);
    type waveforms_array    is array(0 to oscs-1) of std_logic_vector(bits-1 downto 0);
    type rotaries_array     is array(natural range <>) of std_logic_vector(1 downto 0);
    type waves_array        is array(0 to oscs-1) of std_logic_vector(1 downto 0);
    type mod_index_array    is array(0 to oscs-1) of unsigned(3 downto 0);
    --type angles_array       is array(0 to oscs-1) of std_logic_vector(n-1 downto 0);
    
end package my_constants;

package body my_constants is
 
end my_constants;

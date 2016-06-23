
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.my_constants.all;

entity voice_controller is
    generic ( voices : integer := 2;
              bits   : integer := 16;
              pb_bits: integer := 4);
--              controls: integer := 4);
    port ( clk, MIDI_rdy     : in std_logic;
           status, data1, data2 : in std_logic_vector(7 downto 0);
           in_use : in std_logic_vector(0 to voices-1);
           freqs : out osc_freqs_array;
           start : out std_logic_vector(0 to voices-1)
           --mode : out std_logic
           --FM_in
           );
end voice_controller;

architecture Behavioral of voice_controller is
    type keys_array is array (0 to voices-1) of std_logic_vector(7 downto 0);
    type ar is array (0 to 12*2**pb_bits-1) of unsigned(bits-1 downto 0);

    type vc_record is record
        freqs : osc_freqs_array;
        start : std_logic_vector(0 to voices-1);
        pitch_bend : integer range -64 to 63;
        keys  : keys_array;
    end record;

    signal r, rin : vc_record;
    
    
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
    constant notes : ar := gen_notes(12*2**pb_bits);
begin

process (MIDI_rdy, status, data1, data2, in_use, r)
    variable v : vc_record;
    variable oct, note, oct2, note2 : integer;
begin
    v := r;

    if MIDI_rdy = '1' then
        case status(7 downto 4) is
            when x"9" =>
                if data2 = x"00" then
                    for i in 0 to voices-1 loop
                        if data1 = r.keys(i) then
                            v.start(i) := '0';
                        end if;
                    end loop;
                else
                    for i in 0 to voices-1 loop
                        if in_use(i) = '0' then
                            v.keys(i) := data1;
                            v.start(i) := '1';
                            exit;
                        end if;
                    end loop;
                end if;
            when x"E" =>
                v.pitch_bend := to_integer(unsigned(data2(6 downto 0))) - 64;
            when others => null;
                   
        end case;
    end if;
    
    for i in 0 to voices-1 loop
        oct := (to_integer(unsigned(r.keys(i)))*2**pb_bits + v.pitch_bend)/ 2**pb_bits / 12 ;
        oct2 := ((to_integer(unsigned(r.keys(i)))+3)*2**pb_bits + v.pitch_bend)/ 2**pb_bits / 12 ;
        
        note := (to_integer(unsigned(r.keys(i)))*2**pb_bits + v.pitch_bend) mod (2**pb_bits * 12) ;
        note2 := ((to_integer(unsigned(r.keys(i)))+3)*2**pb_bits + v.pitch_bend) mod (2**pb_bits * 12) ;
        
        v.freqs(i)(0) := signed(std_logic_vector(shift_right(notes(note), 10-oct)));
        v.freqs(i)(1) := signed(std_logic_vector(shift_right(notes(note), 10-oct)));
        --v.freqs(i)(1) := signed(std_logic_vector(shift_right(notes(note2), 10-oct2)));
    end loop;
    
    rin <= v;

    freqs <= r.freqs;
    start <= r.start;
end process;

process (clk)
begin
    if rising_edge(clk) then
        r <= rin;
    end if;
end process;
end Behavioral;


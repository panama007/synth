
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;



entity synth_key is
    generic (bits   : integer := 16;
             voices : integer := 3);
    port    (clk : in std_logic;
             oct : out integer range 0 to bits-1;
             freq: out std_logic_vector(bits-1 downto 0));
end synth_key;

architecture Behavioral of synth_key is
    keyboard : for i in 0 to voices-1 generate
        OSC : entity work.osc
            generic map (bits => bits, n => 20)    
            port map (freq => std_logic_vector(shift_right(to_unsigned(integer(notes(i) * (2.0**(bits-1))), bits), bits-1-octave)), 
                      wave => switches(1 downto 0), clk => divided_clk, output => waveforms(i), CORDIC_clk => clk, button => buttons(i));
    end generate keyboard;
begin

    

end Behavioral;


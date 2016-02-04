
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;



entity test_top is
    generic ( bits : integer := 16;
              bits2: integer := 20;
              tones: integer := 5);
    port ( clk     : in std_logic;
           latch   : in std_logic;
           switches: in std_logic_vector(7 downto 0);
           buttons : in std_logic_vector(tones-1 downto 0);
           rotary1 : in std_logic_vector(1 downto 0);
           rotary2 : in std_logic_vector(1 downto 0);
           rotary3 : in std_logic_vector(1 downto 0);
           rotary4 : in std_logic_vector(1 downto 0);
           speaker : out std_logic;
           cathodes: out std_logic_vector(6 downto 0);
           anodes  : inout std_logic_vector(3 downto 0));
end test_top;

architecture Behavioral of test_top is
    type ar is array (0 to tones-1) of real;
    type ar2 is array (0 to tones-1) of std_logic_vector(bits-1 downto 0);

    signal freq : std_logic_vector(bits-1 downto 0);
    signal waveform : std_logic_vector(bits2-1 downto 0);
    signal to_disp : std_logic_vector(bits-1 downto 0);
    signal test : std_logic_vector(2 downto 0);
    signal divided_clk : std_logic;
    signal waveforms : ar2;
    signal octave : integer range 0 to bits-1;
    
    constant div : integer := 8;
    signal ctr : unsigned(div-1 downto 0) := (others => '0');
    
    function gen_notes(divisions : integer)
        return ar is
            variable notes_array : ar;
    begin
        for i in 0 to divisions-1 loop
            notes_array(i) := 2.0 ** (real(i)/real(divisions));
        end loop;
        return notes_array;
    end gen_notes; 

    constant notes : ar := gen_notes(tones);
begin
    --freq <= keyboard(11) & keyboard(9) & (bits-3 downto 0 => '0');
    --to_disp <= test & (bits-4 downto 0 => '0') when switches(0) = '1' else
    to_disp <= freq;--switches(1 downto 0) & (bits-3 downto 0 => '0');--freq;
   
    LCD : entity work.LCD_driver 
        generic map (bits => bits, clk_div => 10)
        port map (latch => clk, clk => clk, to_disp => to_disp, cathodes => cathodes, anodes => anodes);
    
    keyboard : for i in 0 to tones-1 generate
        OSC : entity work.osc
            generic map (bits => bits, n => 20)    
            port map (freq => std_logic_vector(shift_right(to_unsigned(integer(notes(i) * (2.0**(bits-1))), bits), bits-1-octave)), 
                      wave => switches(1 downto 0), clk => divided_clk, output => waveforms(i), CORDIC_clk => clk, button => buttons(i));
    end generate keyboard;    
        
    ROT : entity work.rotary
        generic map (bits => bits)
        port map (AB => rotary1, freq => freq, clk => clk, oct => octave);
        
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
    for i in 0 to tones-1 loop
        cumsum := cumsum + ((bits2-bits-1 downto 0 => '0') & unsigned(waveforms(i)));
    end loop;
    waveform <= std_logic_vector(cumsum);
    
end process;
end Behavioral;

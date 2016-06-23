
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.my_constants.all;
use work.fonts.all;

entity display_menu is
    port    ( clk       : in  std_logic;
              x         : in  integer range 0 to VGA_timings.htotal-1;
              y         : in  integer range 0 to VGA_timings.vtotal-1;
              --voice_in  : in  voice_input;
              wave      : waves_array;
              mode      : std_logic_vector(2 downto 0);
              draw      : out std_logic);
end display_menu;

architecture Behavioral of display_menu is
    constant letter_width : integer := font(0)(0)'length;
    constant letter_height : integer := font(0)'length;
    
    constant wave_str : string := "Wave";
    constant mode_str : string := "Mode";
    --constant wave_str : string := 'Wave';
      
    constant n : integer := oscs + 1;
    constant len : integer := 8;
    constant dx : integer := 5;
    constant dy : integer := 7;
      
    type msg_type is array (integer range <>) of integer range 0 to 95;
    type wave_msgs_type is array (0 to 3) of msg_type(0 to len-1);
    type msgs_type is array (0 to n-1) of msg_type(0 to len-1);
    
    function conv(c : character) return integer is
    begin
        return character'pos(c)-32;
    end function;
    
    function conv_str(s : string) return msg_type is
        variable ret : msg_type(0 to s'length-1);
    begin
        for i in ret'range loop
            ret(i) := conv(s(i+1));
        end loop;
        return ret;
    end function;
    
    function create_msgs return msgs_type is
        variable msg : msg_type(0 to len-1);
        variable res : msgs_type;
    begin
        
        for i in 0 to oscs-1 loop
            for j in 0 to wave_str'length-1 loop
                msg(j) := conv(wave_str(j+1));
            end loop;
            msg(wave_str'length to msg'high) :=  conv(' ') & (i+16) & conv(':') & conv(' ');
            res(i) := msg;
        end loop;
        for j in 0 to mode_str'length-1 loop
            msg(j) := conv(mode_str(j+1));
        end loop;
        msg(mode_str'length) :=  conv(':');
        for j in mode_str'length+1 to len-1 loop
            msg(j) := conv(' ');
        end loop;
        res(oscs) := msg;
        return res;
    end function;
    
    constant msgs : msgs_type := create_msgs;
    constant wave_msgs : wave_msgs_type := (conv_str("Sinusoid"), conv_str("Sawtooth"), conv_str("Square  "), conv_str("Triangle"));
    
    constant FM_title : msg_type(0 to 11) := conv_str("FM Synthesis");
    
    
    --constant wave_msgs 
    signal x_d      : integer range 0 to VGA_timings.htotal;
    signal y_d      : integer range 0 to VGA_timings.vtotal;
    signal x_offset : integer range 0 to VGA_timings.htotal;
    signal x_offset2 : integer range 0 to VGA_timings.htotal;
    signal y_offset : integer range 0 to VGA_timings.vtotal;
    
    -- FM_in.wave
    -- FM_in.mode
begin

    x_offset <= x_d - letter_width*dx;
    y_offset <= y_d - letter_height*dy;
    x_offset2 <= x_d - letter_width*(dx+len);

process (clk)
    
begin
    if rising_edge(clk) then   
        x_d <= x;
        y_d <= y;
        
        if (x_d >= letter_width*dx and x_d < letter_width*(dx+len)) then
            if (y_d >= letter_height*dy and y_d < letter_height*(dy+n)) then
                draw <= font(msgs(y_offset/letter_height)(x_offset/letter_width))(y_offset mod letter_height)(x_offset mod letter_width);
            else
                draw <= '0';
            end if;  
        elsif (x_d >= letter_width*(dx+len) and x_d < letter_width*(dx+2*len)) then
            for i in 0 to oscs-1 loop
                if (y_d >= letter_height*(dy+i) and y_d < letter_height*(dy+i+1)) then
                    draw <= font(wave_msgs(to_integer(unsigned(wave(i))))(x_offset2/letter_width))(y_offset mod letter_height)(x_offset2 mod letter_width);
                end if;
            end loop;
        else
            draw <= '0';
        end if;
    end if;
end process;
end Behavioral;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;



entity MIDI is
    port ( clk, MIDI_in : in    std_logic;
           data_rdy     : out   std_logic);
           --command      : out   std_logic_vector(3 downto 0);
           --note         : out   integer range 0 to 127);
end MIDI;

architecture Behavioral of MIDI is
    type state is (waiting, start, read_status, read_data1, read_data2, 
                   read_stop_wait, read_stop_data1, read_stop_data2);
    signal cur_state : state := waiting;
    
    signal status : std_logic_vector(6 downto 0);
    signal data1 : std_logic_vector(6 downto 0);
    signal data2 : std_logic_vector(6 downto 0);
begin
process (clk)
begin
    if rising_edge(clk) then
        case state is
            when waiting =>
                if MIDI_in = '0' then       -- saw start bit
                    state <= start;
                else
                    state <= waiting;
                end if;
                
            when start =>
                if MIDI_in = '1' then       -- status byte
                    state <= read_status;
                    
                    status <= (6 downto 1 => '0') & '1';
                else                        -- data byte
                    state <= read_data1;
                    
                    data1 <= (6 downto 1 => '0') & '1';
                end if;   
                
            when read_status =>
                status <= status(5 downto 0) & MIDI_in;
                
                if status(6) = '1' then       -- last bit
                    state <= read_stop_data1;
                else                        -- data byte
                    state <= read_status;
                end if;
                
            when read_data1 =>
                data1 <= data1(5 downto 0) & MIDI_in;
                
                if data1(6) = '1' then       -- last bit
                    if status(6 downto 4) = "101" then
                        done <= '1';
                        state <= read_stop_wait;
                    else
                        state <= read_stop_data2;
                    end if;
                    
                else                        -- data byte
                    state <= read_data1;
                end if;
                
            when read_data2 =>
                data2 <= data2(5 downto 0) & MIDI_in;
                
                if data2(6) = '1' then       -- last bit
                    done <= '1';
                    state <= read_stop_wait;                    
                else                        -- data byte
                    state <= read_data2;
                end if;    
            
            when read_stop_data1 =>
                state <= read_data1;
             
            when read_stop_wait =>
                done <= '0';
                state <= waiting;
                
            when read_stop_data2 =>
                data2 <= (6 downto 1 => '0') & '1';
                state <= read_data2;
            
        end case;
    end if;
end process;

end Behavioral;


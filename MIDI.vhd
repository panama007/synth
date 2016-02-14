
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;



entity MIDI is
    port ( clk, MIDI_in, enable : in    std_logic;
           data_rdy     : out   std_logic;
           status       : out   std_logic_vector(6 downto 0);
           data1        : out   std_logic_vector(6 downto 0);
           data2        : out   std_logic_vector(6 downto 0));
           --command      : out   std_logic_vector(3 downto 0);
           --note         : out   integer range 0 to 127);
end MIDI;

architecture Behavioral of MIDI is
    type state is (waiting, start, read_status, read_data1, read_data2, read_stop_wait, read_stop_data1, 
                    read_stop_data2, read_start_data1, read_start_data2, read_zero_data1, read_zero_data2);
    signal cur_state : state := waiting;
    
    signal status_int : std_logic_vector(6 downto 0);
    signal data1_int : std_logic_vector(6 downto 0);
    signal data2_int : std_logic_vector(6 downto 0);
    signal data_rdy_int : std_logic := '0';
begin
    status <= status_int;
    data1 <= data1_int;
    data2 <= data2_int;
    data_rdy <= data_rdy_int;

process (clk)
begin
    if rising_edge(clk) and enable='1' then
        case cur_state is
            when waiting =>
                data_rdy_int <= '0';
                if MIDI_in = '0' then       -- saw start bit
                    cur_state <= start;
                else
                    cur_state <= waiting;
                end if;
                
            when start =>
                if MIDI_in = '1' then       -- status byte
                    cur_state <= read_status;
                    
                    status_int <= (6 downto 1 => '0') & '1';
                else                        -- data byte
                    cur_state <= read_data1;
                    
                    data1_int <= (6 downto 1 => '0') & '1';
                end if;   
                
            when read_status =>
                status_int <= status_int(5 downto 0) & MIDI_in;
                
                if status_int(6) = '1' then       -- last bit
                    cur_state <= read_stop_data1;
                else                        -- data byte
                    cur_state <= read_status;
                end if;
                
            when read_data1 =>
                data1_int <= data1_int(5 downto 0) & MIDI_in;
                
                if data1_int(6) = '1' then       -- last bit
                    if status_int(6 downto 4) = "101" then
                        data_rdy_int <= '1';
                        cur_state <= read_stop_wait;
                    else
                        cur_state <= read_stop_data2;
                    end if;
                    
                else                        -- data byte
                    cur_state <= read_data1;
                end if;
                
            when read_data2 =>
                data2_int <= data2_int(5 downto 0) & MIDI_in;
                
                if data2_int(6) = '1' then       -- last bit
                    cur_state <= read_stop_wait;                    
                else                        -- data byte
                    cur_state <= read_data2;
                end if;    
            
            when read_stop_data1 =>
                cur_state <= read_start_data1;
            when read_start_data1 =>
                cur_state <= read_zero_data1;
            when read_zero_data1 =>
                data1_int <= (6 downto 1 => '0') & '1';
                cur_state <= read_data1;                 
            
            when read_stop_data2 =>
                cur_state <= read_start_data2;
            when read_start_data2 =>
                cur_state <= read_zero_data2;
            when read_zero_data2 =>
                data2_int <= (6 downto 1 => '0') & '1';
                cur_state <= read_data2; 
                
            when read_stop_wait =>
                data_rdy_int <= '1';      
                cur_state <= waiting;
            
        end case;
    end if;
end process;

end Behavioral;



library IEEE;
use IEEE.STD_LOGIC_1164.ALL;



entity MIDI is
    port ( clk, MIDI_in, enable : in    std_logic;
           data_rdy    : out   std_logic;
           data        : out   std_logic_vector(7 downto 0));
end MIDI;

architecture Behavioral of MIDI is
    type state is (waiting, read_data);
    signal cur_state : state := waiting;
    
    signal data_int : std_logic_vector(7 downto 0);
    signal delay_line : std_logic_vector(2 downto 0) := (others => '1');
    signal ctr  : integer range 0 to 8;
begin
    data <= data_int;
    --data_rdy <= data_rdy_int;

process (clk)

begin
    if rising_edge(clk) and enable='1' then
        delay_line <= delay_line(1 downto 0) & MIDI_in;
    
        case cur_state is
            when waiting =>
                data_rdy <= '0';
                if delay_line(2) = '0' then
                    ctr <= 0;
                    cur_state <= read_data;
                end if;
            when read_data =>
                ctr <= ctr + 1;
                if ctr = 8 then
                    data_rdy <= '1';
                    cur_state <= waiting;
                else
                    data_int <= delay_line(2) & data_int(7 downto 1);
                end if;
        end case;
    end if;
end process;

end Behavioral;


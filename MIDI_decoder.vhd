
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;



entity MIDI_decoder is
    port ( clk, enable, MIDI_in : in  std_logic;
           command_rdy          : out std_logic;
           status, data1, data2 : out std_logic_vector(7 downto 0));
end MIDI_decoder;

architecture Behavioral of MIDI_decoder is
    type state_type is (init, waiting, expecting_data2);

    type reg_type is record
        state  : state_type;
        status : std_logic_vector(7 downto 0);
        data1  : std_logic_vector(7 downto 0);
        data2  : std_logic_vector(7 downto 0);
        rdy    : std_logic;
    end record;
    
    signal r, rin : reg_type;
    signal data_rdy : std_logic;
    signal data : std_logic_vector(7 downto 0);
begin

    u0 : entity work.MIDI 
        port map ( clk=>clk, MIDI_in=>MIDI_in, enable=>enable, data_rdy=>data_rdy, data=>data);

process (r, data, data_rdy)
    variable v : reg_type;
begin
    v := r; v.rdy := '0';
    
    case v.state is
        when init =>
            if data_rdy = '1' then
                if data(7) = '1' then
                    v.status := data;
                    v.state := waiting;
                end if;
            end if;
        when waiting =>
            if data_rdy = '1' then
                if data(7) = '1' then
                    v.status := data;
                    v.state := waiting;
                else
                    v.data1 := data;
                    if r.status(7 downto 5) = "110" or (r.status(7 downto 2) = "111100" and r.status(0) = '1') then
                        v.state := waiting;
                        v.rdy := '1';
                    else
                        v.state := expecting_data2;
                    end if;
                end if;
            end if;
        when expecting_data2 =>
            if data_rdy = '1' then
                if data(7) = '1' then
                    v.status := data;
                    v.state := waiting;
                else
                    v.data2 := data;
                    v.state := waiting;
                    v.rdy := '1';
                end if;
            end if;
    end case;
    
    rin <= v;
    
    status <= r.status;
    data1 <= r.data1;
    data2 <= r.data2;
    command_rdy <= r.rdy;
end process;

process (clk)
begin
    if rising_edge(clk) and enable='1' then
        r <= rin;
    end if;
end process;
end Behavioral;


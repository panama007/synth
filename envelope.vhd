
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

use work.my_constants.all;

entity envelope is
    generic (bits       : integer := 16);
    port    (full_signal: in std_logic_vector(bits-1 downto 0);
             clk        : in std_logic;
             button     : in std_logic;
             env_signal : out std_logic_vector(bits-1 downto 0));
end envelope;

architecture Behavioral of envelope is
    constant ms : integer := 391;
    constant slope1 : unsigned(11 downto 0) := to_unsigned(10, 12);
    constant slope2 : unsigned(11 downto 0) := to_unsigned(5, 12);
    constant slope3 : unsigned(11 downto 0) := to_unsigned(5, 12);

    signal state : std_logic_vector(2 downto 0);
    signal temp_signal : unsigned(bits-1+12 downto 0);
    signal factor : unsigned(11 downto 0);
    signal cntr : integer range 0 to ms;
    
    signal old_button : std_logic := '0';
begin

    temp_signal <= factor * unsigned(full_signal);
    env_signal <= std_logic_vector(temp_signal(bits-1+12 downto 12));

process (clk)
begin
    if rising_edge(clk) then
        cntr <= cntr + 1;
        
        case state is
            when "000" => 
                factor <= (others => '0');
                cntr <= 0;
                if button = '1' and old_button = '0' then
                    state <= "001";
                end if;
            when "001" => 
                if cntr < 391 then
                    factor <= factor + slope1;
                else
                    state <= "010";
                    cntr <= 0;
                end if;
            when "010" => 
                if cntr < 391 then
                    factor <= factor - slope2;
                else
                    state <= "011";
            when "011" => 
                factor <= factor;
                if button = '0' and old_button = '1' then
                    state <= "100";
                end if;
            when others =>
                if factor > slope3 then
                    factor <= factor - slope3;
                else
                    factor <= (others => '0');
                    state <= "000";
                end if;
        end case;
        
        old_button <= button;
    end if;
end process;
end Behavioral;



library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity rotary is
    generic (bits: integer := 16);
    port    (AB  : in std_logic_vector(1 downto 0);
             freq: out std_logic_vector(bits-1 downto 0));
end rotary;

architecture Behavioral of LCD_driver is
    signal freq_int : std_logic_vector(bits-1 downto 0) := (bits-1 downto 1 => '0') & '1';
    signal state    : std_logic_vector(1 downto 0) := "000";
begin

process (clk) 
begin
    if rising_edge(clk) then
        case state is
            when "000" => 
                case AB is
                    when "01" => state <= "001";
                    when "10" => state <= "111";
                    when others => state <= "000"; 
            when "001" => 
                case AB is
                    when "11" => state <= "010";
                    when "00" => state <= "000";
                    when others => state <= "001"; 
            when "010" => 
                case AB is
                    when "10" => state <= "011";
                    when "01" => state <= "001";
                    when others => state <= "010";
            when "011" => 
                case AB is
                    when "00" => 
                        state <= "000";
                        if not freq_int(bits-1) then 
                            freq_int <= freq_int sll 1;
                        end if;
                    when "11" => state <= "010";
                    when others => state <= "011";
                    
                     
            when "101" => 
                case AB is
                    when "00" => 
                        state <= "000";
                        if not freq_int(0) then 
                            freq_int <= freq_int srl 1;
                        end if;
                    when "11" => state <= "110";
                    when others => state <= "101"; 
            when "110" => 
                case AB is
                    when "01" => state <= "101";
                    when "10" => state <= "111";
                    when others => state <= "110"; 
            when "111" => 
                case AB is
                    when "11" => state <= "110";
                    when "00" => state <= "000";
                    when others => state <= "111"; 
            
            when others => state <= "000";
        end case;
    end if;
    
    freq <= freq_int;
end process;

end Behavioral;


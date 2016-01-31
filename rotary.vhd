
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

entity rotary is
    generic (bits: integer := 16);
    port    (AB  : in std_logic_vector(1 downto 0);
             clk : in std_logic;
             test: out std_logic_vector(2 downto 0);
             freq: out std_logic_vector(bits-1 downto 0));
end rotary;

architecture Behavioral of rotary is
    signal freq_int : std_logic_vector(bits-1 downto 0) := (bits-1 downto 1 => '0') & '1';
    signal current_state    : std_logic_vector(2 downto 0) := "000";
    signal next_state    : std_logic_vector(2 downto 0) := "000";
    
    signal debounced_AB : std_logic_vector(1 downto 0);
    signal temp_AB      : std_logic_vector(1 downto 0);
    signal debounce_ctr : unsigned(10 downto 0) := (others => '0');
begin
    test <= current_state;
    freq <= freq_int;

process (clk)
begin
    if rising_edge(clk) then
        if debounce_ctr(10) = '1' then
            debounced_AB <= temp_AB;
        end if;
    
        if AB = temp_AB then
            debounce_ctr <= debounce_ctr + ((10 downto 1 => '0') & '1');
        else
            debounce_ctr <= (others => '0');
            temp_AB <= AB
        end if;
    end if;
end process;

process (debounced_AB) 
begin
    case current_state is
        when "000" => 
            case debounced_AB is
                when "01" => next_state <= "001";
                when "10" => next_state <= "111";
                when others => next_state <= "000"; 
            end case;
        when "001" => 
            case debounced_AB is
                when "11" => next_state <= "010";
                when "00" => next_state <= "000";
                when others => next_state <= "001"; 
            end case;
        when "010" => 
            case debounced_AB is
                when "10" => next_state <= "011";
                when "01" => next_state <= "001";
                when others => next_state <= "010"; 
            end case;
        when "011" => 
            case debounced_AB is
                when "00" => 
                    next_state <= "000";
                    freq_int <= (others => '0');
                    --if freq_int(bits-1) = '0' then 
                        --freq_int <= freq_int(bits-2 downto 0) & '0';
                        
                    --end if;
                when "11" => next_state <= "010";
                when others => next_state <= "011"; 
            end case;
                
                 
        when "101" => 
            case debounced_AB is
                when "00" =>
                    next_state <= "000";
                    freq_int <= (others => '1');
                    --if freq_int(0) = '0' then 
                        --freq_int <= '0' & freq_int(bits-1 downto 1);
                        
                    --end if;
                when "11" => next_state <= "110";
                when others => next_state <= "101"; 
            end case; 
        when "110" => 
            case debounced_AB is
                when "01" => next_state <= "101";
                when "10" => next_state <= "111";
                when others => next_state <= "110"; 
            end case; 
        when "111" => 
            case debounced_AB is
                when "11" => next_state <= "110";
                when "00" => next_state <= "000";
                when others => next_state <= "111"; 
            end case; 
        
        when others => next_state <= "000";
    end case;
end process;

process (clk)
begin
    if rising_edge(clk) then
        current_state <= next_state;
    end if;
end process;
end Behavioral;


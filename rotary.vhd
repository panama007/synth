-------------------------------------------------------------------
--
-- Rotary-
--      This entity interfaces with 2-bit rotary encoders and
--      outputs up or down when it's turned right or left.
--
-------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;
use ieee.math_real.all;

-------------------------------------------------------------------
--
-- ports:
--      AB-
--          coming from the rotary encoder. In a detent both are low
--          when turned to the right, the B signal goes up first,
--          then A, then B goes low, then A.
--      up_down-
--          when turned to the right will become "10" for a clock.
--          when turned to the left will become "01" for a clock.
--          otherwise, assume it hasn't moved.
-------------------------------------------------------------------


entity rotary is
    port    (AB  : in std_logic_vector(1 downto 0);
             clk : in std_logic;
             up_down  : out std_logic_vector(1 downto 0));
end rotary;

architecture Behavioral of rotary is
    -- need a state machine to decode which way we moved.
    signal state        : std_logic_vector(2 downto 0) := "000";
    -- like any switch, this is bouncy, need to debounce it.
    signal debounced_AB : std_logic_vector(1 downto 0);
begin

    -- debounce the rotary.
    DB : entity work.debouncer
        generic map (signals => 2)
        port map (clk => clk, bouncy => AB, debounced => debounced_AB);

process (clk) 
begin
    if rising_edge(clk) then
        case state is
            -- we are at a detent.
            when "000" => 
                up_down <= "00";
                case debounced_AB is
                    when "01" => state <= "001";
                    when "10" => state <= "111";
                    when others => state <= "000"; 
                end case;
                
            -- states starting in 0 are to the right of the detent.
            when "001" => 
                case debounced_AB is
                    when "11" => state <= "010";
                    when "00" => state <= "000";
                    when others => state <= "001"; 
                end case;
            when "010" => 
                case debounced_AB is
                    when "10" => state <= "011";
                    when "01" => state <= "001";
                    when others => state <= "010"; 
                end case;
            when "011" => 
                case debounced_AB is
                    -- went from a detent to the next clockwise detent.
                    when "00" => 
                        state <= "000";
                        up_down <= "10";
                    when "11" => state <= "010";
                    when others => state <= "011"; 
                end case;
                    
            -- these states are to the left of the detent.
            when "101" => 
                case debounced_AB is
                    -- went from a detent to the next ccw detent.
                    when "00" =>
                        state <= "000";
                        up_down <= "01";
                    when "11" => state <= "110";
                    when others => state <= "101"; 
                end case; 
            when "110" => 
                case debounced_AB is
                    when "01" => state <= "101";
                    when "10" => state <= "111";
                    when others => state <= "110"; 
                end case; 
            when "111" => 
                case debounced_AB is
                    when "11" => state <= "110";
                    when "00" => state <= "000";
                    when others => state <= "111"; 
                end case; 
            
            when others => state <= "000";
        end case;
    end if;
end process;

end Behavioral;


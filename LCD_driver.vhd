-------------------------------------------------------------------
--
-- LCD Driver-
--      This entity takes a 16 bit number input and displays the
--      4 hex characters on the 4-digit 7-segment display.
--
-------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-------------------------------------------------------------------
--
-- generics:
--      bits-
--          Number of bits the input has. Maybe shouldn't be a
--          generic, or the generic should be number of characters.
--      clk_div-
--          log2 of the number of clock cycles each character is
--          illuminated for, since we're time muxing them.
-- ports:
--      to_disp- 
--          The 16-bit number to be displayed in hex on the LCD.
--      cathodes/anodes-
--          What actually controls the LCD. anodes is inout so we
--          can use it to see which digit we're currently on.
-------------------------------------------------------------------


entity LCD_driver is
    generic ( bits    : integer := 16;
              clk_div : integer := 10);  -- div clk by 2^10
    port    ( clk     : in  std_logic;
              to_disp : in  std_logic_vector(bits-1 downto 0);
              cathodes: out std_logic_vector(6 downto 0);
              anodes  : inout std_logic_vector(3 downto 0));
end LCD_driver;

architecture Behavioral of LCD_driver is
    -- each digit has 7 segments to illuminate.
    type display is array (0 to 3) of std_logic_vector(6 downto 0);
    signal numbers : display;
    
    -- to see when it's time to switch to next digit.
    signal counter : unsigned(clk_div-1 downto 0);
    
begin

process (clk) 
begin
    if rising_edge(clk) then
        for i in 0 to 3 loop
            -- translate the number to 7-segments and store it
            case to_disp(4*i+3 downto 4*i) is
                when "0000" => numbers(i) <="1000000";
                when "0001" => numbers(i) <="1111001";
                when "0010" => numbers(i) <="0100100";
                when "0011" => numbers(i) <="0110000"; 
                when "0100" => numbers(i) <="0011001"; 
                when "0101" => numbers(i) <="0010010"; 
                when "0110" => numbers(i) <="0000010";  
                when "0111" => numbers(i) <="1111000";  
                when "1000" => numbers(i) <="0000000";  
                when "1001" => numbers(i) <="0010000";  
                when "1010" => numbers(i) <="0001000";  
                when "1011" => numbers(i) <="0000011";  
                when "1100" => numbers(i) <="1000110";  
                when "1101" => numbers(i) <="0100001";  
                when "1110" => numbers(i) <="0000110";  
                when "1111" => numbers(i) <="0001110";  
                when others => numbers(i) <="1111111";
            end case;
        end loop;
    end if;
end process;

process (clk)
begin
    if rising_edge(clk) then
        -- go to the next digit every 2^clk_div clocks
        if (counter = (clk_div-1 downto 0 => '0')) then
            if (anodes(0)='0') then 
              anodes(0) <= '1';	 
              cathodes <= numbers(1);
              anodes(1) <= '0';
            elsif (anodes(1)='0') then 
              anodes(1) <= '1';	 	 
              cathodes <= numbers(2);
              anodes(2) <= '0';
            elsif (anodes(2)='0') then 
              anodes(2) <= '1';	 
              cathodes <= numbers(3);
              anodes(3) <= '0';
            elsif (anodes(3)='0') then 
              anodes(3) <= '1';
              cathodes <= numbers(0);
              anodes(0) <= '0';
            end if;
        end if;
        
        counter <= counter + ((clk_div-2 downto 0 => '0') & '1');
    end if;
end process;

end Behavioral;


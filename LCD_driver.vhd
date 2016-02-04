
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity LCD_driver is
    generic ( bits    : integer := 16;
              clk_div : integer := 10);  -- div clk by 2^10
    port    ( latch   : in  std_logic;
              clk     : in  std_logic;
              to_disp : in  std_logic_vector(bits-1 downto 0);
              cathodes: out std_logic_vector(6 downto 0);
              anodes  : inout std_logic_vector(3 downto 0));
end LCD_driver;

architecture Behavioral of LCD_driver is
    type display is array (0 to 3) of std_logic_vector(6 downto 0);
    signal numbers : display;
    
    signal counter : unsigned(clk_div-1 downto 0);
    
begin

process (clk) 
begin
    if rising_edge(clk) then
            for i in 0 to 3 loop
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
                    when others=> numbers(i) <="1111111";
                end case;
            end loop;
        --end if;
        --last_state <= latch;
    end if;
end process;

process (clk)
begin
    if rising_edge(clk) then
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


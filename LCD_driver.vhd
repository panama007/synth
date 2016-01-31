
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity LCD_driver is
    generic ( bits    : integer := 16;
              clk_div : integer := 10);  -- div clk by 2^10
    port    ( latch   : in  std_logic;
              clk     : in  std_logic;
              freq    : in  std_logic_vector(bits-1 downto 0);
              cathodes: out std_logic_vector(6 downto 0);
              anodes  : inout std_logic_vector(3 downto 0));
end LCD_driver;

architecture Behavioral of LCD_driver is
    type display is array (0 to 3) of std_logic_vector(6 downto 0);
    signal numbers : display;
    signal counter : unsigned(clk_div-1 downto 0);
    
    --signal last_state : std_logic := '0';
begin

process (clk) 
    variable temp : std_logic_vector(bits-1 downto 0); 
    variable bcd : unsigned(19 downto 0) := (others => '0');
begin
    if rising_edge(clk) then
        --if (latch = '1' and last_state = '0') then
            bcd := (others => '0');

            -- read input into temp variable
            temp := freq;

            for i in 0 to bits-1 loop
                for j in 0 to 4 loop
                    if bcd(4*j+3 downto 4*j) > 4 then 
                    bcd(4*j+3 downto 4*j) := bcd(4*j+3 downto 4*j) + 3;
                    end if;
                end loop;
                
                bcd := bcd(18 downto 0) & temp(bits-1);
                temp := temp(bits-2 downto 0) & '0';
            end loop;

            for i in 1 to 4 loop
                case bcd(4*i+3 downto 4*i) is 
                    when "0000" => numbers(i-1) <="1000000";
                    when "0001" => numbers(i-1) <="1111001";
                    when "0010" => numbers(i-1) <="0100100";
                    when "0011" => numbers(i-1) <="0110000"; 
                    when "0100" => numbers(i-1) <="0011001"; 
                    when "0101" => numbers(i-1) <="0010010"; 
                    when "0110" => numbers(i-1) <="0000010";  
                    when "0111" => numbers(i-1) <="1111000";  
                    when "1000" => numbers(i-1) <="0000000";  
                    when "1001" => numbers(i-1) <="0010000";  
                    when others=> numbers(i-1) <="1111111";
                end case;
            end loop;
        --end if;
        --last_state <= latch;
    end if;
end process;

process (clk)
begin
    if rising_edge(clk) then
        if (counter = (others => '0')) then
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


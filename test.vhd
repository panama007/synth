----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:30:11 01/26/2016 
-- Design Name: 
-- Module Name:    test - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity test is
    Port ( CLKIN : in std_logic;
           AN3 : out std_logic;
           AN2 : out std_logic;
           AN1 : out std_logic;
           AN0 : out std_logic;
           LED : out std_logic_vector(6 downto 0));
end test;

architecture Behavioral of test is
constant n : integer := 10;
signal CTR : STD_LOGIC_VECTOR(n-1 downto 0);
begin			
  Process (CLKIN)
  begin
    if CLKIN'event and CLKIN = '1' then
      if (CTR=(n-1 downto 0 => '0')) then
        if (AN0='0') then 
          AN0 <= '1';	 
          LED <= "0101011";             -- the letter n
          AN1 <= '0';
        elsif (AN1='0') then 
          AN1 <= '1';	 	 
          LED <= "0101011";             -- the letter n
          AN2 <= '0';
        elsif (AN2='0') then 
          AN2 <= '1';	 
          LED <= "0001000";             -- the letter A
          AN3 <= '0';
        elsif (AN3='0') then 
          AN3 <= '1';
          LED <= "0000110";             -- the letter E
          AN0 <= '0';
        end if;
      end if;
      CTR<=CTR+((n-2 downto 0 => '0') & '1');
      if (CTR > '1' & (n-2 downto 0 => '0')) then   -- counter reaches 2^8
        CTR<=(n-1 downto 0 => '0');
      end if;
    end if; -- CLK'event and CLK = '1' 
  End Process;
End Behavioral;
--
--	Package File Template
--
--	Purpose: This package defines supplemental types, subtypes, 
--		 constants, and functions 
--
--   To use any of the example code shown below, uncomment the lines and modify as necessary
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.MATH_REAL.all;

package my_constants is
    constant bits   : integer := 16;
    constant oscs   : integer := 2;
    constant bits_voice_out : integer := bits + integer(ceil(log2(real(oscs))));
    constant voices : integer := 12; 
    constant n      : integer := 20;

    type freqs_array        is array(0 to oscs-1) of std_logic_vector(bits-1 downto 0);
    type freqs_array2       is array(0 to oscs-1) of std_logic_vector(bits+2 downto 0);
    type waveforms_array    is array(0 to oscs-1) of std_logic_vector(bits-1 downto 0);
    type rotaries_array     is array(natural range <>) of std_logic_vector(1 downto 0);
    type waves_array        is array(0 to oscs-1) of std_logic_vector(1 downto 0);
    type angles_array       is array(0 to oscs-1) of std_logic_vector(n-1 downto 0);
    
end package my_constants;

package body my_constants is

---- Example 1
--  function <function_name>  (signal <signal_name> : in <type_declaration>  ) return <type_declaration> is
--    variable <variable_name>     : <type_declaration>;
--  begin
--    <variable_name> := <signal_name> xor <signal_name>;
--    return <variable_name>; 
--  end <function_name>;

---- Example 2
--  function <function_name>  (signal <signal_name> : in <type_declaration>;
--                         signal <signal_name>   : in <type_declaration>  ) return <type_declaration> is
--  begin
--    if (<signal_name> = '1') then
--      return <signal_name>;
--    else
--      return 'Z';
--    end if;
--  end <function_name>;

---- Procedure Example
--  procedure <procedure_name>  (<type_declaration> <constant_name>  : in <type_declaration>) is
--    
--  begin
--    
--  end <procedure_name>;
 
end my_constants;


library IEEE;
use ieee.math_real.all;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;


entity CORDIC is
    generic ( bits : integer := 16;
              iters: integer := 15);
    port    ( K_clk   : in  std_logic;
              data_in : in  std_logic_vector(bits-1 downto 0);
              test : out std_logic_vector(bits-1 downto 0);
              data_out: out std_logic);
end CORDIC;

architecture Behavioral of CORDIC is
    type ar is array (0 to iters-1) of real;
    
    
    function gen_K(iters : integer)
        return real is
            variable run_prod : real := 1.0;
    begin
        for i in 0 to iters-1 loop
            run_prod := run_prod * (1.0 / sqrt(1.0 + 2.0 ** (-2 * i)));
        end loop;
        return run_prod;
    end gen_K; 
    
    function gen_angles(iters : integer)
        return ar is
            variable angles_array : ar;
    begin
        for i in 0 to iters-1 loop
            angles_array(i) := arctan(2.0 ** (-i));
        end loop;
        return angles_array;
    end gen_angles; 

    constant K : real := gen_K(iters);
    constant angles : ar := gen_angles(iters);
begin
    test <= std_logic_vector(to_unsigned(integer(K * real(2**bits)), bits));

end Behavioral;



library IEEE;
use ieee.math_real.all;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;


entity CORDIC is
    generic ( bits : integer := 16;
              iters: integer := 1);
    port    ( K_clk   : in  std_logic;
              data_in : in  std_logic_vector(bits-1 downto 0);
              test : out std_logic_vector(bits-1 downto 0);
              data_out: out std_logic);
end CORDIC;

architecture Behavioral of CORDIC is
    
    function gen_const(iters : integer)
        return real is
            variable run_prod : real := 1.0;
    begin
        for i in 0 to iters-1 loop
            run_prod := run_prod * (1.0 / sqrt(1.0 + 2.0 ** (-2 * i)));
        end loop;
        return run_prod;
    end gen_const; 

    constant K : real := gen_const(iters);
begin
    test <= std_logic_vector(to_unsigned(integer(K * real(2**bits)), bits));

end Behavioral;


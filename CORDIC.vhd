
library IEEE;
use ieee.math_real.all;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;


entity CORDIC is
    generic ( bits : integer := 16;
              iters: integer := 16);
    port    ( clk   : in  std_logic;
              angle : in  std_logic_vector(bits-1 downto 0);
              cos: out std_logic_vector(bits-1 downto 0));
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
    
    signal x_i : signed(iters-1 downto 0);
    signal y_i : signed(iters-1 downto 0);
    signal angle_i : signed(iters-1 downto 0);
    
    signal cos_int : signed(iters-1 downto 0);
begin
    cos <= std_logic_vector(cos_int(iters-1 downto iters-bits));
    
process (clk)
    variable iter : integer := 0;
begin
    if rising_edge(clk) then
        if iter = iters then
            cos_int <= x_i;
            iter := 0;
        end if;
    
        if iter = 0 then
            angle_i <= (others => '0');
            --x_i <= "00" & (iters-3 downto 0 => '1');
            x_i <= to_signed(integer(K * real(2**(iters-2))), iters);
            y_i <= (others => '0');
        else
            if angle_i < signed(angle) then
                angle_i <= angle_i + to_signed(integer(angles(iter-1) * real(2**(iters-2))), iters);
                x_i <= x_i - shift_right(y_i, iter-1);
                y_i <= y_i + shift_right(x_i, iter-1);
            else
                angle_i <= angle_i - to_signed(integer(angles(iter-1) * real(2**(iters-2))), iters);
                x_i <= x_i + shift_right(y_i, iter-1);
                y_i <= y_i - shift_right(x_i, iter-1);
            end if;
        end if;
        
        iter := iter + 1;
    end if;
end process;

end Behavioral;



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
            angles_array(i) := arctan(2.0 ** (-i)) / math_pi; --multiply by 2/pi?
        end loop;
        return angles_array;
    end gen_angles; 

    constant K : real := gen_K(iters);
    constant angles : ar := gen_angles(iters);
    
    signal x_i : signed(iters+1 downto 0);
    signal y_i : signed(iters+1 downto 0);
    signal angle_i : signed(iters-1 downto 0);
    
    signal cos_int : signed(iters-1 downto 0);
    signal angle_int : signed(bits-1 downto 0);
    signal quadrant : std_logic_vector(1 downto 0);
begin
    cos <= std_logic_vector(cos_int(iters-1 downto iters-bits));
    
process (clk)
    variable iter : integer range 0 to iters := 0;
begin
    if rising_edge(clk) then
        if iter = iters then
            if x_i(iters-1) = '1' then
                case quadrant is
                    when "00" => cos_int <= (others => '1');
                    when "01" => cos_int <= '0' & (bits-2 downto 0 => '1');
                    when "10" => cos_int <= (others => '0');
                    when others => cos_int <= '0' & (bits-2 downto 0 => '1');
                end case;
                --x_i <= "000" & (iters-2 downto 0 => '1');
            else
                case quadrant is
                    when "00" => cos_int <= '1' & x_i(bits-2 downto 0);
                    when "01" => cos_int <= '0' & (-(x_i(bits-2 downto 0)));
                    when "10" => cos_int <= '0' & (-(x_i(bits-2 downto 0)));
                    when others => cos_int <= '1' & x_i(bits-2 downto 0);
                end case;
            end if;
            
            
            --cos_int <= x_i;
            iter := 0;
        end if;
    
        if iter = 0 then
            angle_i <= (others => '0');
            --x_i <= "00" & (iters-3 downto 0 => '1');
            x_i <= to_signed(integer(K * real(2**(iters-1))), iters+2);
            y_i <= (others => '0');
            
            quadrant <= angle(bits-1 downto bits-2);
            case quadrant is
                when "00" => angle_int <= signed("00" & angle(bits-3 downto 0));
                when "01" => angle_int <= signed('0' & angle(bits-2 downto 0)) - ('0' & (bits-2 downto 0 => '1'));
                when "10" => angle_int <= signed("00" & angle(bits-3 downto 0));
                when others => angle_int <= signed('0' & angle(bits-2 downto 0)) - ('0' & (bits-2 downto 0 => '1'));
            end case;
        else
            if angle_i < signed(angle_int) then
                angle_i <= angle_i + to_signed(integer(angles(iter-1) * real(2**(iters-1))), iters);
                x_i <= x_i - shift_right(y_i, iter-1);
                y_i <= y_i + shift_right(x_i, iter-1);
            else
                angle_i <= angle_i - to_signed(integer(angles(iter-1) * real(2**(iters-1))), iters);
                x_i <= x_i + shift_right(y_i, iter-1);
                y_i <= y_i - shift_right(x_i, iter-1);
            end if;
        end if;
        
        iter := iter + 1;
    end if;
end process;

end Behavioral;


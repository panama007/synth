-------------------------------------------------------------------
--
-- CORDIC-
--      This entity takes a "bits"-long angle, with 0 being 0 rads
--      and full being 2pi rads, and returns the cosine of that.
--
-------------------------------------------------------------------

library IEEE;
use ieee.math_real.all;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;


-------------------------------------------------------------------
--
-- generics:
--      bits-
--          Number of bits the input has.
--      iters-
--          Number of iterations of this iterative algorithm we will
--          run. I *believe* we get 1 more bit of actual resolution per
--          iteration, and having iters = bits seems to work well.
-- ports:
--      angle-
--          input signal, angle whose cosine we are to calculate,
--          in rads. 0000 = 0 rads, FFFF = 2*pi rads
--      cos-
--          output signal, cos(angle).
-------------------------------------------------------------------


entity CORDIC is
    generic ( bits : integer := 16;
              iters: integer := 16);
    port    ( clk   : in  std_logic;
              angle : in  std_logic_vector(bits-1 downto 0);
              cos: out std_logic_vector(bits-1 downto 0));
end CORDIC;

architecture Behavioral of CORDIC is
    -- array of arctans of 2**-i
    type ar is array (0 to iters-1) of real;
    
    -- function to generate K, the fudge factor to make the output of
    --      CORDIC fall between -1 and 1
    function gen_K(iters : integer)
        return real is
            variable run_prod : real := 1.0;
    begin
        for i in 0 to iters-1 loop
            run_prod := run_prod * (1.0 / sqrt(1.0 + 2.0 ** (-2 * i)));
        end loop;
        return run_prod;
    end gen_K; 
    
    -- function to generate the angles we'll be using at each iteration
    --      scaled so that full range is 0 to 2 pi.
    function gen_angles(iters : integer)
        return ar is
            variable angles_array : ar;
    begin
        for i in 0 to iters-1 loop
            angles_array(i) := arctan(2.0 ** (-i)) / math_pi; --multiply by 2/pi?
        end loop;
        return angles_array;
    end gen_angles; 

    -- actually calculate and store these constants.
    constant K : real := gen_K(iters);
    constant angles : ar := gen_angles(iters);
    
    -- estimate for sin/cos we're updating ever iteration, along with the
    --      angle. I.E. x_i = cos(angle_i)
    signal x_i : signed(iters+1 downto 0);
    signal y_i : signed(iters+1 downto 0);
    signal angle_i : signed(iters-1 downto 0);
    
    -- internal output, just to register it, and use signed.
    signal cos_int : signed(iters-1 downto 0);
    -- latched angle input, so we don't change what we're calculating in the
    --      middle of a calculation.
    signal angle_int : signed(bits-1 downto 0);
    -- quadrant signal to correct CORDIC, since it only works in (-pi/2,pi/2).
    signal quadrant : std_logic_vector(1 downto 0);
begin
    -- take top "bits" bits of cos_int and convert to slv.
    cos <= std_logic_vector(cos_int(iters-1 downto iters-bits));
    
process (clk)
    -- iteration counter, we need to index into precalculated array of
    --      angles, do some initialization, and latch the output when it's
    --      done.
    variable iter : integer range 0 to iters := 0;
begin
    if rising_edge(clk) then
        -- done with iterations, time to output the result.
        if iter = iters then
            -- a correction I tried to fix some overflow I noticed. It
            --      doesn't work 100% correctly. There are occasional
            --      overflows I've noticed, but haven't gotten around to fixing
            --      yet.
            if x_i(iters-1) = '1' then
                case quadrant is
                    when "00" => cos_int <= (others => '1');
                    when "01" => cos_int <= '0' & (bits-2 downto 0 => '1');
                    when "10" => cos_int <= (others => '0');
                    when others => cos_int <= '0' & (bits-2 downto 0 => '1');
                end case;
            else
                case quadrant is
                    when "00" => cos_int <= '1' & x_i(bits-2 downto 0);
                    when "01" => cos_int <= '0' & (-(x_i(bits-2 downto 0)));
                    when "10" => cos_int <= '0' & (-(x_i(bits-2 downto 0)));
                    when others => cos_int <= '1' & x_i(bits-2 downto 0);
                end case;
            end if;
            
            iter := 0; -- start calculating the next one.
        end if;
    
        -- initialization
        if iter = 0 then
            angle_i <= (others => '0');
            -- instead of multiplying by K at the end, we can just start off
            --      with K instead of 1.
            x_i <= to_signed(integer(K * real(2**(iters-1))), iters+2);
            y_i <= (others => '0');
            
            quadrant <= angle(bits-1 downto bits-2); -- divide provided angle into 4 quadrants
            case quadrant is
                -- shift angle down to (-pi/2, pi/2)
                when "00" => angle_int <= signed("00" & angle(bits-3 downto 0));
                when "01" => angle_int <= signed('0' & angle(bits-2 downto 0)) - ('0' & (bits-2 downto 0 => '1'));
                when "10" => angle_int <= signed("00" & angle(bits-3 downto 0));
                when others => angle_int <= signed('0' & angle(bits-2 downto 0)) - ('0' & (bits-2 downto 0 => '1'));
            end case;
        else
            -- if we are below the requested angle, add the next angle in our precalculated array, and
            --      adjust x and y accordingly.
            if angle_i < signed(angle_int) then
                angle_i <= angle_i + to_signed(integer(angles(iter-1) * real(2**(iters-1))), iters);
                x_i <= x_i - shift_right(y_i, iter-1);
                y_i <= y_i + shift_right(x_i, iter-1);
            -- if we are above the requested angle, subtract the next angle in our precalculated array, and
            --      adjust x and y accordingly.
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


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
--          in rads. 0000 = 0 rads, FFFF = 2*pi * (2**16-1)/2**16 rads
--      cos-
--          output signal, cos(angle).
-------------------------------------------------------------------


entity CORDIC is
    generic ( bits_in : integer := 16;
              bits_out: integer := 16;
              iters   : integer := 16);
    port    ( clk   : in  std_logic;
              start : in  std_logic;
              angle : in  signed(bits_in-1 downto 0);
              cos   : out signed(bits_out-1 downto 0));
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
    
    type cordic_record is record
        x_i : signed(bits_out-1 downto 0);
        y_i : signed(bits_out-1 downto 0);
        angle_i : signed(bits_in-1 downto 0);
        angle_int : signed(bits_in-1 downto 0);
        cos_int : signed(bits_out-1 downto 0);
        iter : integer range 0 to iters;
        start : std_logic;
        quadrant : std_logic_vector(1 downto 0);
    end record;
    
    signal rin : cordic_record;
    signal r : cordic_record  := (x_i => (others => '0'),
                                       y_i => (others => '0'),
                                       angle_i => (others => '0'),
                                       angle_int => (others => '0'),
                                       cos_int => (others => '0'),
                                       quadrant => (others => '0'),
                                       iter => 0,
                                       start => '0');
begin

process (r, angle, start)
    -- iteration counter, we need to index into precalculated array of
    --      angles, do some initialization, and latch the output when it's
    --      done.
    variable v : cordic_record;
begin
    v := r; v.iter := r.iter + 1; v.start := start;

    -- done with iterations, time to output the result.
    if r.iter = iters then
        if r.quadrant = "00" or r.quadrant = "11" then
            v.cos_int := r.x_i;
        else
            v.cos_int := -r.x_i;
        end if;   
        if start = '1' and r.start = '0' then
            v.iter := 0; -- start calculating the next one.
        else
            v.iter := r.iter;
        end if;
        
        
    elsif r.iter = 0 then
        v.angle_i := (others => '0');
        -- instead of multiplying by K at the end, we can just start off
        --      with K instead of 1.
        v.x_i := to_signed(integer(K * real(2**(bits_out-1)-10)), bits_out);
        v.y_i := (others => '0');
        
        v.quadrant := std_logic_vector(angle(bits_in-1 downto bits_in-2));
         -- divide provided angle into 4 quadrants
        case angle(bits_in-1 downto bits_in-2) is       -- quadrant
            -- shift angle down to (-pi/2, pi/2)
            when "00"   => v.angle_int := angle;
            when "01"   => v.angle_int := (not angle(bits_in-1)) & angle(bits_in-2 downto 0);
            when "10"   => v.angle_int := (not angle(bits_in-1)) & angle(bits_in-2 downto 0);
            when others => v.angle_int := angle;
        end case;
    else
        -- if we are below the requested angle, add the next angle in our precalculated array, and
        --      adjust x and y accordingly.
        if r.angle_i < r.angle_int then
            v.angle_i := r.angle_i + to_signed(integer(angles(r.iter-1) * real(2**(bits_in-1)-1)), bits_in);
            v.x_i := r.x_i - shift_right(r.y_i, r.iter-1);
            v.y_i := r.y_i + shift_right(r.x_i, r.iter-1);
        -- if we are above the requested angle, subtract the next angle in our precalculated array, and
        --      adjust x and y accordingly.
        else
            v.angle_i := r.angle_i - to_signed(integer(angles(r.iter-1) * real(2**(bits_in-1)-1)), bits_in);
            v.x_i := r.x_i + shift_right(r.y_i, r.iter-1);
            v.y_i := r.y_i - shift_right(r.x_i, r.iter-1);
        end if;
    end if;
    
    rin <= v;
    cos <= r.cos_int;    
 
end process;

process (clk)
begin
    if rising_edge(clk) then
        r <= rin;
    end if;
end process;
end Behavioral;


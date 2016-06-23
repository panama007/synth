----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

--use work.my_constants.all;

entity Karplus is
    generic ( bits  : integer := 17;
              p     : integer := 70);
    port    ( start : in  std_logic;
              clk, div_clk   : in  std_logic;
              --test : out std_logic_vector(bits-1 downto 0);
              --test2 : out unsigned(bits-1 downto 0);
              output: out unsigned(bits-1 downto 0));
end Karplus;

architecture Behavioral of Karplus is
    type delay_line is array (0 to p-1) of std_logic_vector(bits-1 downto 0);
    type state_type is (off, resetting, running);
    
    type KS_record is record
        ctr : integer range 0 to p;
        state : state_type;
        ptr : integer range 0 to p-1;
        start : std_logic;
    end record;
    
    signal delay : delay_line;
    
    signal rin : KS_record;
    signal r : KS_record := ( state => off,
                              ptr => 0,
                              ctr => 0,
                              start => '0');
    --signal dampen_out : unsigned(bits-1 downto 0);
    signal rand_out : std_logic_vector(bits-1 downto 0);
    signal prev1 : unsigned(bits-1 downto 0);
    --signal prev2 : unsigned(bits-1 downto 0);
    signal dampen_out : unsigned(bits-1 downto 0);
    signal output_int : std_logic_vector(bits-1 downto 0);
    signal prev_div_clk : std_logic;
begin
    --test <= std_logic_vector(rand_out);
    --test2 <= r.delay(0);

    NG : entity work.LFSR
        generic map(bits => bits)
        port map( clk => clk, rand => rand_out); 

    dampen_out <= resize(shift_right(resize(unsigned(delay(r.ptr)), bits+1) + resize(unsigned(delay(r.ptr+1 mod p)), bits+1), 1), bits);
    output <= unsigned(output_int);

process (start, r)
    variable v : KS_record;
    --variable dampen_out : unsigned(bits-1 downto 0);
begin
    v := r; v.start := start; 
    if r.ptr < p-1 then 
        v.ptr := r.ptr+1;
    else
        v.ptr := 0;
    end if;
    
    if start = '1' and r.start = '0' then
        v.state := resetting;
        v.ctr := 0;
    end if;
    
    if r.state = resetting then
        v.ctr := r.ctr + 1;
        
        if r.ctr > p-1 then
            v.state := running;
        end if;  
    end if;
    
    rin <= v;
end process;


process (div_clk)
begin
    if rising_edge(div_clk) then
        --if r.state = resetting or (div_clk = '1' and prev_div_clk = '0') then
        r <= rin;
        --end if;
        --prev_div_clk <= div_clk;
    end if;
end process;


process (div_clk)
    variable i : integer;
    variable input : std_logic_vector(bits-1 downto 0);
begin
    if rising_edge(div_clk) then
        prev1 <= unsigned(output_int);
        
        if r.state = running then
            input := std_logic_vector(dampen_out);
        else
            input := rand_out;
        end if;
        
        delay(r.ptr) <= input;
    
        case r.state is
            when off =>
                output_int <= (others => '0');
            when resetting =>     
                output_int <= (others => '0');
            when running =>
                if r.ptr = 0 then
                    i := p-1;
                else
                    i := r.ptr-1;
                end if;
                output_int <= delay(i);
        end case;
    end if;
end process;
end Behavioral;



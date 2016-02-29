----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;


entity Karplus is
    generic ( bits  : integer := 17;
              p     : integer := 160);
    port    ( start : in  std_logic;
              clk, div_clk   : in  std_logic;
              test : out std_logic_vector(bits-1 downto 0);
              output: out unsigned(bits-1 downto 0));
end Karplus;

architecture Behavioral of Karplus is
    type delay_line is array (0 to p-1) of unsigned(bits-1 downto 0);
    type state_type is (off, resetting, running);
    
    type KS_record is record
        delay : delay_line;
        ctr : integer range 0 to p-1;
        state : state_type;
        start : std_logic;
        output : unsigned(bits-1 downto 0);
    end record;
    
    signal rin : KS_record;
    signal r : KS_record := ( delay => (others => (others => '0')),
                              state => off,
                              ctr => 0,
                              start => '0',
                              output => (others => '0'));
    signal dampen_out : unsigned(bits-1 downto 0);
    signal rand_out : std_logic_vector(bits-1 downto 0);
    signal prev_div_clk : std_logic;
begin
    test <= std_logic_vector(rand_out);
    
--    NG : entity work.noise_gen
--        generic map(W => bits, u_type => 0)
--        port map( clk => div_clk, n_reset => '1', enable => '1', u_noise_out => rand_out); 

    NG : entity work.LFSR
        generic map(bits => bits)
        port map( clk => clk, rand => rand_out); 


process (start, r, rand_out, dampen_out)
    variable v : KS_record;
begin
    v := r; v.start := start;
    
    dampen_out <= resize(shift_right(resize(r.delay(p-1), bits+1) + resize(r.delay(p-2), bits+1), 1), bits);
    
    if start = '1' and r.start = '0' then
        v.state := resetting;
        v.ctr := 0;
    end if;
    
    case r.state is
        when off =>
            v.output := (others => '0');
        when resetting =>
            v.output := (others => '0');
            v.ctr := r.ctr + 1;
            
            if r.ctr > p-1 then
                v.state := running;
            else 
                v.delay := unsigned(rand_out) & r.delay(0 to p-2);--to_unsigned(2**bits-1, bits) & r.delay(0 to p-2);
            end if;  
        when running =>
            v.output := r.delay(0);
            v.delay := dampen_out & r.delay(0 to p-2);
    end case;
    
    rin <= v;
    
    output <= r.output;
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
end Behavioral;



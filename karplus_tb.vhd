
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--library work;
--use work.my_constants.all;

entity Karplus_tb is
end Karplus_tb;

architecture TB_ARCHITECTURE of Karplus_tb is
    signal  clk, div_clk, start :   std_logic;

    signal  output :   std_logic_vector(16 downto 0);

    --Signal used to stop clock signal generators
    signal  END_SIM     :  BOOLEAN := FALSE;
    

    constant  clk_period:  time    := 10 ns;
    constant  div_clk_period:  time    := 2.56 us;

    --signal  line : std_logic_vector(16 downto 0);
begin
    

    -- Unit Under Test generic/port map
    UUT : entity work.Karplus
        --generic map(bits => 17, p => 888)
        port map(clk => clk, div_clk => div_clk, start => start, output => output);


    -- now generate the stimulus and test the design
    process

    begin  -- of stimulus process
        start <= '0';
        wait for div_clk_period;
        start <= '1';
        wait;

        END_SIM <= TRUE;        -- end of stimulus events
        wait;                   -- wait for simulation to end

    end process; -- end of stimulus process


    CLOCK_CLK : process

    begin

        -- this process generates a clk_period ns period, 50% duty cycle clock

        -- only generate clock if still simulating

        if END_SIM = FALSE then
            CLK <= '0';
            wait for clk_period/2;
        else
            wait;
        end if;

        if END_SIM = FALSE then
            CLK <= '1';
            wait for clk_period/2;
        else
            wait;
        end if;

    end process;

    CLOCK_CLK2 : process

    begin

        -- this process generates a clk_period ns period, 50% duty cycle clock

        -- only generate clock if still simulating

        if END_SIM = FALSE then
            div_clk <= '0';
            wait for div_clk_period/2;
        else
            wait;
        end if;

        if END_SIM = FALSE then
            div_clk <= '1';
            wait for div_clk_period/2;
        else
            wait;
        end if;

    end process;

end TB_ARCHITECTURE;

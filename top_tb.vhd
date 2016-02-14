
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity MIDI_tb is
end MIDI_tb;

architecture TB_ARCHITECTURE of MIDI_tb is
    type test_signals is array (0 to 2) of std_logic_vector(0 to 29);
    --type intertest_times is array (0 to 2) of integer;
    
    
    -- Stimulus signals - signals mapped to the input and inout ports of tested entity
    signal  MIDI_en :   std_logic;
    signal  MIDI_in :   std_logic;
      
    signal  clk     :   std_logic;

    -- Observed signals - signals mapped to the output ports of tested entity
    signal  status  :   std_logic_vector(6 downto 0);
    signal  data1   :   std_logic_vector(6 downto 0);
    signal  data_rdy:   std_logic;

    --Signal used to stop clock signal generators
    signal  END_SIM     :  BOOLEAN := FALSE;
    
    -- test values
    --signal    TestA     :  test_signals;
    --signal    TestB     :  test_signals;
    --signal    TestC     :  test_signals;

    constant  clk_period:  time    := 20 ns;
    
    constant tests : test_signals := ('0'& X"90" & '1' & '0'& X"3C" & '1' & '0'& X"60" & '1',
                                      '0'& X"80" & '1' & '0'& X"45" & '1' & '0'& X"80" & '1',
                                      '0'& X"A0" & '1' & '0'& X"54" & '1' & '0'& X"10" & '1');
    
begin

    -- Unit Under Test generic/port map
    UUT : entity work.MIDI
        port map(clk => clk, MIDI_in => MIDI_in, enable => MIDI_en,
                 data_rdy => data_rdy, status => status, data1 => data1);


    -- now generate the stimulus and test the design
    process

        -- some useful variables
        variable  i  :  integer;        -- general loop index
        variable  j  :  integer;        -- general loop index

    begin  -- of stimulus process
        -- run the process that generates the random inputs/outputs 
        for j in tests'range loop
            
            for  i  in  0 to 29  loop
                -- drive the inputs
                MIDI_en <= '1';
                MIDI_in <= tests(j)(i);
                
                wait for clk_period;
            end loop;
            MIDI_en <= '0';
            
            assert(data_rdy = '1')
                report "Data Not Ready Error"
                severity ERROR;
                
            assert(status = tests(j)(2 to 8))
                report "Status Error"
                severity ERROR;
                
            assert(data1 = tests(j)(12 to 18))
                report "Data1 Error"
                severity ERROR;
            
            wait for j*clk_period;

        end loop;

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


end TB_ARCHITECTURE;

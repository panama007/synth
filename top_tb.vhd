
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity MIDI_tb is
end MIDI_tb;

architecture TB_ARCHITECTURE of MIDI_tb is
    --type test_signals is array (integer range <>) of std_logic_vector(integer range <>);
    type test_signals3 is array (0 to 2) of std_logic_vector(0 to 29);
    type test_signals2 is array (0 to 2) of std_logic_vector(0 to 19);
    --type intertest_times is array (0 to 2) of integer;
    
    
    -- Stimulus signals - signals mapped to the input and inout ports of tested entity
    signal  MIDI_en :   std_logic;
    signal  MIDI_in :   std_logic;
      
    signal  clk     :   std_logic;

    -- Observed signals - signals mapped to the output ports of tested entity
    signal  status  :   std_logic_vector(7 downto 0);
    signal  data1   :   std_logic_vector(7 downto 0);
    signal  data_rdy:   std_logic;

    --Signal used to stop clock signal generators
    signal  END_SIM     :  BOOLEAN := FALSE;
    
    -- test values
    --signal    TestA     :  test_signals;
    --signal    TestB     :  test_signals;
    --signal    TestC     :  test_signals;

    constant  clk_period:  time    := 10 ns;
    constant  MIDI_period: time    := 32 us;
    
    constant tests1 : test_signals3 := ('0'& X"09" & '1' & '0'& X"3C" & '1' & '0'& X"06" & '1',
                                        '0'& X"01" & '1' & '0'& X"A2" & '1' & '0'& X"01" & '1',
                                        '0'& X"05" & '1' & '0'& X"2A" & '1' & '0'& X"08" & '1');
                                                        
    constant tests2 : test_signals2 := ('0'& X"3C" & '1' & '0'& X"60" & '1',
                                        '0'& X"45" & '1' & '0'& X"80" & '1',
                                        '0'& X"54" & '1' & '0'& X"10" & '1');
    
begin

    -- Unit Under Test generic/port map
    UUT : entity work.MIDI_decoder
        port map(clk => clk, MIDI_in => MIDI_in, enable => MIDI_en,
                 command_rdy => data_rdy, status => status, data1 => data1);


    -- now generate the stimulus and test the design
    process

        -- some useful variables
        variable  i  :  integer;        -- general loop index
        variable  j  :  integer;        -- general loop index

    begin  -- of stimulus process
        -- run the process that generates the random inputs/outputs 
        MIDI_in <= '1';
        wait for MIDI_period;
        
        for j in tests1'range loop
            
            for  i  in  tests1(1)'range  loop
                -- drive the inputs
                MIDI_en <= '1';
                MIDI_in <= tests1(j)(i);
                
                wait for MIDI_period;
            end loop;
            MIDI_en <= '0';
            
            assert(data_rdy = '1')
                report "Data Not Ready Error"
                severity ERROR;
                
            assert(status = tests1(j)(1 to 8))
                report "Status Error"
                severity ERROR;
                
            assert(data1 = tests1(j)(11 to 18))
                report "Data1 Error"
                severity ERROR;
            
            wait for j*MIDI_period;

        end loop;
        
        for j in tests2'range loop
            
            for  i  in  tests2(1)'range  loop
                -- drive the inputs
                MIDI_en <= '1';
                MIDI_in <= tests2(j)(i);
                
                wait for MIDI_period;
            end loop;
            MIDI_en <= '0';
            
            assert(data_rdy = '1')
                report "Data Not Ready Error"
                severity ERROR;
                
            assert(status = tests1(tests1'right)(1 to 8))
                report "Status Error"
                severity ERROR;
                
            assert(data1 = tests2(j)(1 to 8))
                report "Data1 Error"
                severity ERROR;
            
            wait for j*MIDI_period;

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

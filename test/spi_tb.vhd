library ieee;
use ieee.std_logic_1164.all;

entity spi_tb is
end entity;

architecture beh of spi_tb is
    constant period : time := 100 ns;
    constant clk_speed_hz :integer := 10000000;
    constant sclk_speed_hz:integer := 100000;
    constant data_width : integer := 8;

    signal  clk : std_logic := '0';
    signal done : boolean := false;

    signal en   : std_logic := '0';
    signal rst  : std_logic := '0';
    signal send : std_logic := '0';
    signal lsb_finished, msb_finished: std_logic := '0';
    signal miso : std_logic := '1';
    signal lsb_mosi, msb_mosi : std_logic := '0';
    signal msb_data_in, lsb_data_in: std_logic_vector(data_width-1 downto 0) := (others => '0');
    signal data_out : std_logic_vector(data_width-1 downto 0) := (others => '0');
    signal msb_sclk_enable, lsb_sclk_enable : std_logic := '0';
begin

    lsb_uut : entity work.spi
    generic map(
        data_width => data_width, 
        clk_speed_hz => clk_speed_hz,
        sclk_speed_hz => sclk_speed_hz,
        msb_first => false
    )
    port map(
        clk => clk,
        en => en,
        rst => rst,
        mosi => lsb_mosi, 
        sclk_enable => lsb_sclk_enable,
        miso => miso, 
        send => send, 
        done => lsb_finished, 
        data_out => data_out, 
        data_in => lsb_data_in
    );

    msb_uut : entity work.spi
    generic map(
        data_width => data_width, 
        clk_speed_hz => clk_speed_hz,
        sclk_speed_hz => sclk_speed_hz,
        msb_first => true
    )
    port map(
        clk => clk,
        en => en,
        rst => rst,
        mosi => msb_mosi, 
        sclk_enable => msb_sclk_enable,
        miso => miso, 
        send => send, 
        done => msb_finished, 
        data_out => data_out, 
        data_in => msb_data_in
    );

    tick: process
    begin
        while not done loop
            clk <= not clk;
            wait for period/2;
        end loop;
        wait;
    end process;
    
    stim: process
        procedure check_mosi(mosi: in std_logic; sclk_enable: in std_logic; finished : in std_logic; expected_mosi : in std_logic; expected_sclk_enable : in std_logic; expected_finished : in std_logic) is
        begin
            assert sclk_enable = expected_sclk_enable report "sclk isn't " & std_logic'image(expected_sclk_enable) severity failure;
            assert mosi = expected_mosi report "MOSI didn't didn't match " & std_logic'image(expected_mosi) severity failure;
            assert finished = expected_finished report "Finished isn't " & std_logic'image(expected_finished)  severity failure;
        end check_mosi;
    begin
        data_out <= X"AA";
        wait for period / 2; -- ensure assertions are after a rising edge
        en <= '0';
        rst <= '0';
        miso <= '1';

        wait for period;
        
        send <= '1';
        en <= '1';
        wait for period *2; -- one tick to load and one to set up the mosi 

        check_mosi(lsb_mosi, lsb_sclk_enable, lsb_finished, '0', '1', '0');
        check_mosi(msb_mosi, msb_sclk_enable, msb_finished, '1', '1', '0');
        wait for period;
        assert msb_sclk_enable = '0' report "sclk isn't low again" severity failure; 

        wait for period * 99; -- 100 clock ticks for a bit
        check_mosi(msb_mosi, msb_sclk_enable, msb_finished, '0', '1', '0');
        check_mosi(lsb_mosi, lsb_sclk_enable, lsb_finished, '1', '1', '0');
        wait for period * 100;
        check_mosi(msb_mosi, msb_sclk_enable, msb_finished, '1', '1', '0');
        check_mosi(lsb_mosi, lsb_sclk_enable, lsb_finished, '0', '1', '0');
        wait for period * 100;
        check_mosi(msb_mosi, msb_sclk_enable, msb_finished, '0', '1', '0');
        check_mosi(lsb_mosi, lsb_sclk_enable, lsb_finished, '1', '1', '0');
        wait for period * 100;
        check_mosi(msb_mosi, msb_sclk_enable, msb_finished, '1', '1', '0');
        check_mosi(lsb_mosi, lsb_sclk_enable, lsb_finished, '0', '1', '0');
        wait for period * 100;
        check_mosi(msb_mosi, msb_sclk_enable, msb_finished, '0', '1', '0');
        check_mosi(lsb_mosi, lsb_sclk_enable, lsb_finished, '1', '1', '0');
        wait for period * 100;
        check_mosi(msb_mosi, msb_sclk_enable, msb_finished, '1', '1', '0');
        check_mosi(lsb_mosi, lsb_sclk_enable, lsb_finished, '0', '1', '0');
        wait for period * 100;
        check_mosi(msb_mosi, msb_sclk_enable, msb_finished, '0', '1', '0');
        check_mosi(lsb_mosi, lsb_sclk_enable, lsb_finished, '1', '1', '0');
        wait for period * 100;
        
        assert msb_finished = '1' report "Finished didn't assert" severity failure;
        assert msb_data_in = X"FF" report "Data out doesn't match miso feed" severity failure; 
        assert lsb_finished = '1' report "Finished didn't assert" severity failure;
        assert lsb_data_in = X"FF" report "Data out doesn't match miso feed" severity failure; 

        done <= true;
        report "Done";
        wait;

    end process;
end architecture;

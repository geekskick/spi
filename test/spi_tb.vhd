library ieee;
use ieee.std_logic_1164.all;
use work.spi_package.all;

entity spi_tb is
end entity;

architecture beh of spi_tb is
    constant period : time := 100 ns;
    constant clk_speed_hz :integer := 10000000;
    constant sclk_speed_hz:integer := 100000;
    constant clk_idle   : std_logic := '1';

    signal clk  : std_logic := '0';
    signal en   : std_logic := '0';
    signal rst  : std_logic := '0';

    signal done : boolean := false;

    signal uut_in : spi_master_in_t;
    signal uut_out:spi_master_out_t;
    signal uut_pins:spi_master_pins_t;

    alias valid : std_logic is uut_out.valid;
    alias sent : std_logic is uut_out.sent;
    alias send : std_logic is uut_in.send;
    alias mosi : std_logic is uut_pins.mosi;
    alias sclk : std_logic is uut_pins.clk;
    alias miso : std_logic is uut_pins.miso;

begin

    msb_uut : entity work.spi_master
    generic map(
        clk_speed_hz => clk_speed_hz,
        sclk_speed_hz => sclk_speed_hz,
        msb_first => true,
        clk_idle => clk_idle
    )
    port map(
        clk => clk,
        en => en,
        rst => rst,
        d => uut_in,
        q => uut_out,
        pins => uut_pins
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
    begin
        uut_in.data <= X"AA";
        en <= '0';
        uut_in.send <= '0';
        rst <= '0';

        wait for period / 4; -- ensure assertions are after a rising edge

        wait for period * 9;
        assert sclk = clk_idle report "Clock in wrong idle state" severity failure;

        send <= '1';
        en <= '1';
        rst <= '0';

        -- Load the data and start sending
        wait for period;
        assert sclk = not clk_idle report "Clock didn't change from idle after a tick" severity failure;
        assert mosi = '1' report "Data wasn't high" severity failure;

        uut_in.send <= '0';

        wait for period * 50;
        assert sclk = clk_idle report "Clock didn't tick back" severity failure;

        wait for period * 50;
        assert sclk = not clk_idle report "Clock didn't change from idle after a tick" severity failure;
        assert uut_pins.mosi = '0' report "Data wasn't low" severity failure;

        -- Send the rest of the data bits
        wait for period * (data_width-1) * 100;

        assert sent = '1' report "Sent didn't assert" severity failure;
        assert sclk = clk_idle report "Clock not in idle state" severity failure;

        wait for period;
        assert sent = '0' report "Sent didn't clear" severity failure;
        assert sclk = clk_idle report "Clock not in idle state" severity failure;

        done <= true;
        wait;

    end process;
end architecture;

library ieee;
use ieee.std_logic_1164.all;
use work.spi_package.all;

entity spi_tb is
end entity;

architecture beh of spi_tb is
    constant period : time := 100 ns;
    constant clk_speed_hz :integer := 10000000;
    constant sclk_speed_hz:integer := 100000;

    signal  clk : std_logic := '0';
    signal en   : std_logic := '0';
    signal rst  : std_logic := '0';

    signal done : boolean := false;

    signal uut_in : spi_master_in_t;
    signal uut_out:spi_master_out_t;
    signal uut_pins:spi_master_pins_t;

begin

    msb_uut : entity work.spi_master
    generic map(
        clk_speed_hz => clk_speed_hz,
        sclk_speed_hz => sclk_speed_hz,
        msb_first => true
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
        uut_in.send <= '1';

        wait for period / 2; -- ensure assertions are after a rising edge
        en <= '1';
        rst <= '0';

        wait for period * data_width * 100;
        

        done <= true;
        report "Done";
        wait;

    end process;
end architecture;

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
    signal finished: std_logic := '0';
    signal miso : std_logic := '0';
    signal mosi : std_logic := '0';
    signal data_in: std_logic_vector(data_width-1 downto 0) := (others => '0');
    signal data_out : std_logic_vector(data_width-1 downto 0) := (others => '0');
    signal sclk_enable : std_logic := '0';
begin

    uut : entity work.spi
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
        mosi => mosi, 
        sclk_enable => sclk_enable,
        miso => miso, 
        send => send, 
        done => finished, 
        data_out => data_out, 
        data_in => data_in
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
        data_out <= X"AA";
        wait for period / 2; -- ensure assertions are after a rising edge
        en <= '0';
        rst <= '0';
        miso <= '0';

        wait for period;
--        assert mosi = '0' report "mosi changed when not enabled" severity failure;
        
        send <= '1';
        en <= '1';
        wait for period*900;

        done <= true;
        report "Done";
        wait;

    end process;
end architecture;

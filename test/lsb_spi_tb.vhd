library ieee;
use ieee.std_logic_1164.all;
use work.spi_package.all;

entity lsb_spi_tb is
end entity;

architecture beh of lsb_spi_tb is
    constant period         : time      := 100 ns;
    constant clk_speed_hz   : integer   := 10000000;
    constant sclk_speed_hz  : integer   := 100000;
    constant ticks_per_sclk : integer   := clk_speed_hz/sclk_speed_hz;
    constant clk_idle       : std_logic := '1';
    constant msb_first      : boolean   := false;
    constant half_period    : time      := period * (ticks_per_sclk/2);
    constant data_width     : integer   := 8;

    signal to_send : std_logic_vector(data_width-1 downto 0) := X"AA";

    type tb_ctrl is record
        clk  : std_logic;
        en   : std_logic;
        rst  : std_logic;
        done : boolean;
    end record;
    signal ctl     : tb_ctrl := ('0', '0', '0', false);
    signal uut_in  : spi_master_in_t(data(data_width-1 downto 0));
    signal uut_out : spi_master_out_t(data(data_width-1 downto 0));
    signal uut_pins: spi_master_pins_t;

    signal valid: std_logic := uut_out.valid;
    signal sent : std_logic := uut_out.sent;
    signal mosi : std_logic := uut_pins.mosi;
    signal sclk : std_logic := uut_pins.clk;

    signal expected_sclk : std_logic := not clk_idle;
    signal bit_to_check  : integer range -1 to data_width-1 := data_width-1;

    procedure check_sclk(signal expected_state: in std_logic;
                         signal actual_state:   in std_logic) is
    begin
         assert actual_state = expected_state report "check_sclk " & std_logic'image(actual_state) & " doesn't match " & std_logic'image(expected_state) severity failure;

    end procedure;

    procedure check_mosi(signal expected_data: in std_logic_vector(data_width-1 downto 0);
                         signal data_bit:      in std_logic;
                         signal bit_num:       in integer range 0 to data_width-1) is
        variable adjusted_bit_num : integer range 0 to data_width-1 := 0;
    begin
        if msb_first then
            adjusted_bit_num := bit_num;
        else
            adjusted_bit_num := data_width-1 - bit_num;
        end if;

        assert data_bit = expected_data(adjusted_bit_num) report "check_mosi : " & std_logic'image(data_bit) & " doesn't match bit " & integer'image(adjusted_bit_num) & " which is " & std_logic'image(expected_data(adjusted_bit_num)) severity failure;

    end procedure;

    procedure check_mosi_and_sclk(signal expected_data:  in std_logic_vector(data_width-1 downto 0);
                                  signal data_bit:       in std_logic;
                                  signal bit_num:        in integer range 0 to data_width-1;
                                  signal expected_state: in std_logic;
                                  signal actual_state:   in std_logic) is
    begin
        check_sclk( expected_state  => expected_state, 
                    actual_state    => actual_state);

        check_mosi( expected_data   => expected_data, 
                    data_bit        => data_bit, 
                    bit_num         => bit_num);
    end procedure;
begin
    valid <= uut_out.valid;
    sent  <= uut_out.sent;
    mosi  <= uut_pins.mosi;
    sclk  <= uut_pins.clk;

    lsb_uut : entity work.spi_master
    generic map(
        clk_speed_hz    => clk_speed_hz,
        sclk_speed_hz   => sclk_speed_hz,
        msb_first       => msb_first,
        clk_idle        => clk_idle,
        data_width      => data_width
    )
    port map(
        clk     => ctl.clk,
        en      => ctl.en,
        rst     => ctl.rst,
        d       => uut_in,
        q       => uut_out,
        pins    => uut_pins
    );

    tick: process
    begin
        while not ctl.done loop
            ctl.clk <= not ctl.clk;
            wait for period/2;
        end loop;
        wait;
    end process;
    
    stim: process
    begin
        uut_in.data   <= to_send;
        uut_pins.miso <= '1';
        ctl.en        <= '0';
        uut_in.send   <= '0';
        ctl.rst       <= '0';

        wait for period / 4; -- ensure assertions are after a rising edge

        wait for period * 9;
        assert sclk = clk_idle report "Clock in wrong idle state" severity failure;

        uut_in.send   <= '1';
        ctl.en        <= '1';
        ctl.rst       <= '0';
        expected_sclk <= not clk_idle;

        wait for period;
        uut_in.send <= '0';

        for i in 0 to data_width-1 loop

            check_mosi_and_sclk(to_send, mosi, bit_to_check, expected_sclk, sclk);
            expected_sclk <= not expected_sclk;

            wait for half_period;
            check_mosi_and_sclk(to_send, mosi, bit_to_check, expected_sclk, sclk);

            expected_sclk <= not expected_sclk;
            bit_to_check  <= bit_to_check - 1;

            wait for half_period;

        end loop;

        assert valid = '1' report "Receive didn't assert valid" severity failure;
        assert X"FF" = uut_out.data report "Data on miso didn't match ff" severity failure;
        assert sent  = '1' report "Sent didn't assert" severity failure;
        assert sclk  = clk_idle report "Clock not in idle state" severity failure;

        wait for period;
        assert sent = '0' report "Sent didn't clear" severity failure;
        assert sclk = clk_idle report "Clock not in idle state" severity failure;

        ctl.done <= true;
        wait;

    end process;
end architecture;

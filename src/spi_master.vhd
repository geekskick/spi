library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.spi_package.all;

entity spi_master is
    generic(
        clk_speed_hz    : integer range 1_000_000 to 100_000_000;
        sclk_speed_hz   : integer range 9_600 to 100_000;
        msb_first       : boolean;
        clk_idle        : std_logic;
        data_width      : integer range 7 to 9
    );
    port(
        clk : in std_logic;
        rst : in std_logic;
        en  : in std_logic;
        d   : in spi_master_in_t(data(data_width-1 downto 0));
        q   : out spi_master_out_t(data(data_width-1 downto 0));
        pins: inout spi_master_pins_t
    );
end entity;

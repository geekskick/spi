library ieee;
use ieee.std_logic_1164.all;

package spi_package is
    constant data_width : integer := 8;

    type spi_master_in_t is record
        data : std_logic_vector;
        send : std_logic;
    end record;
    
    type spi_master_out_t is record
        data    : std_logic_vector;
        valid   : std_logic;
        sent    : std_logic;
    end record;

    type spi_master_pins_t is record
        mosi : std_logic;
        miso : std_logic;
        clk  : std_logic;
    end record;

    component spi_master is
        generic(
            clk_speed_hz    : integer range 1_000_000 to 100_000_000;
            sclk_speed_hz   : integer range 9_600 to 100_000;
            msb_first       : boolean;
            cpol            : std_logic;
            data_width      : integer range 7 to 9
        );
        port(
            clk : in std_logic;
            rst : in std_logic;
            en  : in std_logic;
            d   : in spi_master_in_t(data(data_width-1 downto 0));
            q   : out spi_master_out_t(data(data_width-1 downto 0));
            pins: out spi_master_pins_t
        );
    end component;

end package;

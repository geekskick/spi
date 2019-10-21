library ieee;
use ieee.std_logic_1164.all;
use work.spi_package.all;

entity spi_master is
    generic(
        clk_speed_hz    : integer range 1_000_000 to 100_000_000;
        sclk_speed_hz   : integer range 9_600 to 100_000;
        msb_first       : boolean
    );
    port(
        clk : in std_logic;
        rst : in std_logic;
        en  : in std_logic;
        d   : in spi_master_in_t;
        q   : out spi_master_out_t;
        pins: out spi_master_pins_t
    );
end entity;

architecture rtl of spi_master is

    constant clk_period : integer   := clk_speed_hz/sclk_speed_hz;
    type spi_private_state_t is (idle, sending, done);

    type spi_private_register_t is record
        state  : spi_private_state_t;
        next_bit: integer range 0 to data_width;
        bit_timer: integer range 0 to clk_period;
        mosi_sr : std_logic_vector(data_width-1 downto 0);
        miso_sr : std_logic_vector(data_width-1 downto 0);
        spi_clk : std_logic;
    end record;

    signal reg      : spi_private_register_t;
    signal reg_in   : spi_private_register_t;

begin

    comb: process(d, reg)
        variable v : spi_private_register_t;
    begin
        v := reg;
        
        if d.send = '1' then 
            v.mosi_sr   := d.data; 
            v.state    := sending;
            v.bit_timer := 0;
            v.next_bit  := 0;
            v.miso_sr   := (others=>'0');
            v.spi_clk   := '1';
        end if;


        if reg.state = sending then

            
            if reg.bit_timer = clk_period then 
                v.next_bit := reg.next_bit + 1; 
                v.spi_clk := '1';
                v.mosi_sr := '0' & reg.mosi_sr(data_width-2 downto 0);
            elsif reg.bit_timer = clk_period/2 then
                v.bit_timer := reg.bit_timer + 1;
                v.spi_clk := '0';
            else
                v.bit_timer := reg.bit_timer + 1;
            end if;
            if reg.next_bit = data_width then v.state := done; end if;

        end if;

        -- Put the variable into the register for the clock tick
        reg_in <= v;
        
        -- Assign outputs from the register output
        if msb_first then
            pins.mosi <= reg.mosi_sr(data_width-1);
        else
            pins.mosi <= reg.mosi_sr(0);
        end if;

        pins.clk <= reg.spi_clk;

        if reg.state = done then q.valid <= '1'; else q.valid <= '0'; end if;
        
    end process;
    
    clked: process(clk)
    begin
        if rising_edge(clk) then
           reg <= reg_in; 
        end if;
    end process;

end architecture;

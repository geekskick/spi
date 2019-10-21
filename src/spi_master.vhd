library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.spi_package.all;

entity spi_master is
    generic(
        clk_speed_hz    : integer range 1_000_000 to 100_000_000;
        sclk_speed_hz   : integer range 9_600 to 100_000;
        msb_first       : boolean;
        clk_idle        : std_logic
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

    signal reg      : spi_private_register_t := (idle, 0, 0, (others=> '0'), (others=>'0'), clk_idle);
    signal reg_in   : spi_private_register_t := (idle, 0, 0, (others=> '0'), (others=>'0'), clk_idle);

begin

    comb: process(d, reg, en, rst)
        variable v : spi_private_register_t;
    begin
        v := reg;

        -- Load the output shift reg and then move to the sending state after
        -- setting everything up
        if reg.state /= sending then
            
            if d.send = '1' then 
                v.mosi_sr   := d.data; 
                v.state     := sending;
                v.bit_timer := 0;
                v.next_bit  := 0;
                v.miso_sr   := (others=>'0');
                v.spi_clk   := not clk_idle; -- First bit needs a change of state in clock
            end if;

        end if;

        if reg.state = sending then
            
            -- At the end of the bit go to the next
            if reg.bit_timer = clk_period -1 then 
                v.next_bit  := reg.next_bit + 1; 
                v.bit_timer := 0;
                v.spi_clk   := not reg.spi_clk;

                if msb_first then
                    v.mosi_sr := reg.mosi_sr(data_width-2 downto 0) & '0';
                else
                    v.mosi_sr := '0' & reg.mosi_sr(data_width-1 downto 1);
                end if;

            -- Half way through the clock change it's state
            elsif v.bit_timer = (clk_period/2) -1 then
                v.bit_timer := reg.bit_timer + 1;
                v.spi_clk   := not reg.spi_clk;
            else
                v.bit_timer := reg.bit_timer + 1;
            end if;

            if v.next_bit = data_width then 
                v.state := done; 
                v.spi_clk := clk_idle;
            end if;

        end if;

        -- Assign outputs from the register output
        if msb_first then
            pins.mosi <= reg.mosi_sr(data_width-1);
        else
            pins.mosi <= reg.mosi_sr(0);
        end if;

        pins.clk <= reg.spi_clk;

        -- If sending straight away
        if reg.state = done then 
            if d.send = '1' then
                v.mosi_sr   := d.data; 
                v.state     := sending;
                v.bit_timer := 0;
                v.next_bit  := 0;
                v.miso_sr   := (others=>'0');
                v.spi_clk   := not clk_idle; -- First bit needs a change of state in clock
            else
                q.valid <= '1'; 
                v.state := idle;
                q.sent <= '1';
            end if;
        else 
            q.valid <= '0'; 
            q.sent <= '0';
        end if;
        
        -- Put the variable into the register for the clock tick
        reg_in <= v;
        
    end process;
    
    clked: process(clk)
    begin
        if rising_edge(clk) then
           reg <= reg_in; 
        end if;
    end process;

end architecture;

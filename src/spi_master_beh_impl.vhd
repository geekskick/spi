library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.spi_package.all;

architecture behavioural of spi_master is

    -- https://groups.google.com/forum/#!msg/comp.lang.vhdl/eBZQXrw2Ngk/4H7oL8hdHMcJ
    function reverse_any_vector (a: in std_logic_vector)
    return std_logic_vector is
        variable result: std_logic_vector(a'RANGE);
        alias aa: std_logic_vector(a'REVERSE_RANGE) is a;
    begin
        for i in aa'RANGE loop
            result(i) := aa(i);
        end loop;
        return result;
    end; -- function reverse_any_vector

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
                if msb_first then
                    v.mosi_sr   := d.data; 
                else
                    v.mosi_sr := reverse_any_vector(d.data);
                end if;
                v.state     := sending;
                v.bit_timer := 0;
                v.next_bit  := 0;
                v.miso_sr   := (0 => pins.miso, others=>'0');
                v.spi_clk   := not clk_idle; -- First bit needs a change of state in clock
            end if;

        end if;

        if reg.state = sending then
            
            -- At the end of the bit go to the next
            if reg.bit_timer = clk_period -1 then 
                v.next_bit  := reg.next_bit + 1; 
                v.bit_timer := 0;
                v.spi_clk   := not reg.spi_clk;
                v.miso_sr := reg.miso_sr(data_width-2 downto 0) & pins.miso;
                v.mosi_sr := reg.mosi_sr(data_width-2 downto 0) & '0';

            -- Half way through the clock change it's state
            elsif v.bit_timer = (clk_period/2) -1 then
                v.bit_timer := reg.bit_timer + 1;
                v.spi_clk   := not reg.spi_clk;
            else
                v.bit_timer := reg.bit_timer + 1;
            end if;

            if v.next_bit = data_width then 
                v.state   := done;
                v.spi_clk := clk_idle;
            end if;

        end if;

        -- Assign outputs from the register output
        pins.mosi <= reg.mosi_sr(data_width-1);
        pins.clk  <= reg.spi_clk;
        q.data    <= reg.miso_sr;

        -- If sending done
        if reg.state = done then 

            q.valid <= '1';
            v.state := idle;
            q.sent  <= '1';

            -- And sending again straight away
            if d.send = '1' then
                v.mosi_sr   := d.data; 
                v.state     := sending;
                v.bit_timer := 0;
                v.next_bit  := 0;
                v.miso_sr   := (0 => pins.mosi, others=>'0');
                v.spi_clk   := not clk_idle; -- First bit needs a change of state in clock
            end if;
        else 
            q.valid <= '0';
            q.sent  <= '0';
        end if;
        
        -- Put the variable into the register for the clock tick
        reg_in <= v;
        
    end process;

    -- Clock the reg_in into the register    
    clked: process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                reg <= (idle, 0, 0, (others=> '0'), (others=>'0'), clk_idle);
            elsif en = '1' then
                reg <= reg_in; 
            end if;
        end if;
    end process;

end architecture;

library ieee;
use ieee.std_logic_1164.all;

entity spi is
    generic(
        data_width      : integer range 7 to 9;
        clk_speed_hz    : integer range 1_000_000 to 100_000_000;
        sclk_speed_hz   : integer range 9_600 to 100_000;
        msb_first       : boolean
    );
    port(
        clk             : in std_logic;
        en              : in std_logic;
        rst             : in std_logic;
        mosi            : out std_logic;
        sclk_enable     : out std_logic;
        miso            : in std_logic;
        send            : in std_logic;
        done            : out std_logic;
        data_out        : in std_logic_vector(data_width-1 downto 0);
        data_in         : out std_logic_vector(data_width-1 downto 0)
    );
end entity;

architecture rtl of spi is
    constant clk_period : integer   := clk_speed_hz/sclk_speed_hz;
    signal bit_timer    : integer range 0 to clk_period  := 0;
    signal i_sclk_enable: std_logic := '0';
    signal i_data_in    : std_logic_vector(data_width-1 downto 0) := (others => '0');
    signal i_data_out   : std_logic_vector(data_width-1 downto 0) := (others => '0');
    signal shift_out    : integer range 0 to data_width := 0;
    
    type states is (idle, busy, finished);
    signal current_state    : states := idle;
    signal next_state       : states := idle;
   
    signal i_done       : std_logic := '0';
    signal i_mosi       : std_logic := '0';
    signal i_miso       : std_logic := '0';

begin

    -- The actual shifting
    process(clk)
    begin
    if rising_edge(clk) and en = '1' then
        i_sclk_enable <= '0';
        case current_state is
            when idle =>

                next_state <= idle;
                if send = '1' then
                    i_data_out <= data_out;
                    shift_out <= 0;
                    next_state <= busy;
                    bit_timer <= 0;
                end if;

            when busy =>

                next_state <= busy;
                i_done <= '0';

                if bit_timer = 0 then
                    bit_timer <= bit_timer + 1;
                    if shift_out = data_width then
                        i_done <= '1';
                        next_state <= idle;
                    else
                        i_sclk_enable <= '1';
                        
                        if msb_first then
                            i_data_in <= i_miso & i_data_in(data_width-1 downto 1);
                            i_mosi <= i_data_out(data_width-1);
                            i_data_out <= i_data_out(data_width-2 downto 0) & '0';
                        else
                            i_data_in <= i_data_in(data_width-2 downto 0) & i_miso;
                            i_mosi <= i_data_out(0);
                            i_data_out <= '0' & i_data_out(data_width-1 downto 1);
                        end if;
                        
                        shift_out <= shift_out + 1;
                    end if;
                elsif bit_timer = clk_period then
                    bit_timer <= 0;
                else 
                    bit_timer <= bit_timer + 1;
                end if;
                
            when others => next_state <= idle;
        end case;
    end if;
    end process;

    -- State advancement is clocked
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                current_state <= idle;
            elsif en = '1' then
                current_state <= next_state;
            end if; 
        end if;
    end process;
    
    i_miso <= miso;
    mosi <= i_mosi;
    done <= i_done;
    data_in <= i_data_in; 
    sclk_enable <= i_sclk_enable;
end architecture;

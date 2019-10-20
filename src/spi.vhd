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
    signal bit_timer    : integer range 0 to clk_period-1  := 0;
    signal i_sclk_enable: std_logic := '0';
    signal i_data_in    : std_logic_vector(data_width-1 downto 0) := (others => '0');
    signal i_data_out   : std_logic_vector(data_width-1 downto 0) := (others => '0');
    signal next_bit     : integer range 0 to data_width := 0;
     
    signal i_done       : std_logic := '0';
    signal i_mosi       : std_logic := '0';
    signal i_miso       : std_logic := '0';

    procedure shift_out(
        signal p_data_in    : inout std_logic_vector(data_width-1 downto 0);
        signal p_data_out   : inout std_logic_vector(data_width-1 downto 0);
        signal p_mosi       : out std_logic;
        signal p_miso       : in std_logic
                       ) is
    begin
         if msb_first then
            p_data_in <= p_miso & p_data_in(data_width-1 downto 1);
            p_mosi <= p_data_out(data_width-1);
            p_data_out <= p_data_out(data_width-2 downto 0) & '0';
        else
            p_data_in <= p_data_in(data_width-2 downto 0) & p_miso;
            p_mosi <= p_data_out(0);
            p_data_out <= '0' & p_data_out(data_width-1 downto 1);
        end if;

    end procedure;
begin

    -- The actual shifting
    process(clk)
        type states is (idle, busy, finished);
        variable current_state    : states := idle;
        variable next_state       : states := idle;

    begin
    if rising_edge(clk)  then
        
        i_sclk_enable <= '0';
        if rst = '1' then
            current_state := idle;
            next_state := idle;
            i_done <= '0';
            i_mosi <= '0';
            i_data_in <= (others => '0');
            i_data_out <= (others => '0');
            next_bit <= 0;
            bit_timer <= 0;
        elsif en = '1' then
            current_state := next_state;
            case current_state is
                when idle =>

                    i_done <= '0';
                    next_state := idle;

                    if send = '1' then
                        i_data_out <= data_out;
                        next_bit <= 0;
                        next_state := busy;
                        bit_timer <= 0;
                    end if;

                when busy =>

                    next_state := busy;
                    i_done <= '0';

                    if bit_timer = 0 then
                        bit_timer <= bit_timer + 1;
                        if next_bit = data_width then
                            i_done <= '1';
                            next_state := idle;
                        else
                            i_sclk_enable <= '1';
                            shift_out(i_data_in, i_data_out, i_mosi, i_miso);                         
                            next_bit <= next_bit + 1;
                        end if;
                    elsif bit_timer = clk_period-1 then
                        bit_timer <= 0;
                    else 
                        bit_timer <= bit_timer + 1;
                    end if;
                    
                when others => next_state := idle;
            end case;
        end if;
    end if;
    end process;
    
    i_miso <= miso;
    mosi <= i_mosi;
    done <= i_done;
    data_in <= i_data_in; 
    sclk_enable <= i_sclk_enable;
end architecture;

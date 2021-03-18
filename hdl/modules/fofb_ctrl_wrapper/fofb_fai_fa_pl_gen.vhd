library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.fofb_cc_pkg.all;

entity fofb_fai_fa_pl_gen is
    generic (
        g_BPMS                  : natural := 1;
        g_XY_OFFSET             : natural := 1000
    );
    port (
        -- Fast acquisition data interface
        adcclk_i                : in  std_logic;
        adcreset_i              : in  std_logic;
        -- Fast acquisition data interface
        fai_fa_data_valid_o     : out std_logic;
        fai_fa_d_x_o            : out std_logic_2d_32(g_BPMS-1 downto 0);
        fai_fa_d_y_o            : out std_logic_2d_32(g_BPMS-1 downto 0);
        -- Flags
        fai_enable_i            : in  std_logic;
        fai_trigger_i           : in  std_logic;
        -- keep signal to '1' to keep generating internal 10 kHz trigger
        fai_trigger_internal_i  : in  std_logic := '0';
        fai_armed_o             : out std_logic
);
end fofb_fai_fa_pl_gen;

architecture rtl of fofb_fai_fa_pl_gen is

signal counter_10kHz            : integer;
signal puls_10kHz               : std_logic;
signal counter_fai_x_dw         : unsigned(31 downto 0);
signal counter_fai_y_dw         : unsigned(31 downto 0);
signal counter_valid            : std_logic;
signal fai_trigger              : std_logic;
signal fai_trigger_rise         : std_logic;
signal fai_armed                : std_logic;
signal fai_done_cycle           : std_logic;

begin

fai_armed_o <= fai_armed;

--
-- Generate 10kHz clock for Synthetic BPM data generation
--
process(adcclk_i)
begin
    if rising_edge(adcclk_i) then
        if (adcreset_i = '1') then
            counter_10kHz <= 0;
            puls_10kHz <= '0';
            fai_done_cycle <= '0';
        else
            if (fai_armed = '1') then
                if (counter_10kHz = 12500) then
                    counter_10kHz <= 0;
                    puls_10kHz <= '1';
                    fai_done_cycle <= '1';
                else
                    counter_10kHz <= counter_10kHz + 1;
                    puls_10kHz <= '0';
                    fai_done_cycle <= '0';
                end if;
            else
                counter_10kHz <= 0;
                puls_10kHz <= '0';
                fai_done_cycle <= '0';
            end if;
        end if;
    end if;
end process;


process(adcclk_i)
begin
    if rising_edge(adcclk_i) then
        if (adcreset_i = '1') then
            fai_trigger <= '0';
            fai_trigger_rise <= '0';
            fai_armed <= '0';
            counter_fai_x_dw <= to_unsigned(0, counter_fai_x_dw'length);
            counter_fai_y_dw <= to_unsigned(0, counter_fai_y_dw'length);
            counter_valid <= '0';
        else
            -- External trigger to be used for synchronus trigger
            fai_trigger <= fai_trigger_i;
            fai_trigger_rise <= fai_trigger_i and not fai_trigger;

            if (fai_trigger_rise = '1' or fai_trigger_internal_i = '1') then
                fai_armed <= '1';
            elsif (fai_enable_i = '0' or fai_done_cycle = '1') then
                fai_armed <= '0';
            end if;

            -- Strech 10kHz FA clock to 16 clock cycles
            if (puls_10kHz = '1') then
                counter_valid <= '1';
            else
                counter_valid <= '0';
            end if;

            if (puls_10kHz = '1') then
                counter_fai_x_dw <= counter_fai_x_dw + 1;
                counter_fai_y_dw <= counter_fai_y_dw + 1 + g_XY_OFFSET;
            end if;
        end if;
    end if;
end process;

fai_fa_data_valid_o <= counter_valid;

GEN_OUTPUT : for i in 0 to g_BPMS-1 generate
  fai_fa_d_x_o(i) <= std_logic_vector(counter_fai_x_dw);
  fai_fa_d_y_o(i) <= std_logic_vector(counter_fai_y_dw);
end generate;

end rtl;

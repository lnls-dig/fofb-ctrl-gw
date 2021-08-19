-------------------------------------------------------------------------------
-- Title      :  Matrix multiplication module
-------------------------------------------------------------------------------
-- Author     :  Melissa Aguiar
-- Company    :  CNPEM LNLS-DIG
-- Platform   :  FPGA-generic
-------------------------------------------------------------------------------
-- Description:  Matrix multiplication module for the Fast Orbit Feedback
-------------------------------------------------------------------------------
-- Copyright (c) 2020 CNPEM
-- Licensed under GNU Lesser General Public License (LGPL) v3.0
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                Description
-- 2021-30-07  1.0      melissa.aguiar        Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

library work;
-- Matmul package
use work.mult_pkg.all;

entity mac_fofb is
  generic(
    -- Width for input a[k]
    g_a_width                           : natural := 32;
    -- Width for input b[k]
    g_b_width                           : natural := 32;
    -- Width for output c
    g_c_width                           : natural := 32;
    -- Number of products
    g_mac_size                          : natural := 160
  );
  port (
    -- Core clock
    clk_i                               : in std_logic;
    -- Reset
    rst_n_i                             : in std_logic;
    -- Data valid input
    valid_i                             : in std_logic;
    -- Input a[k]
    coeff_a_dat_i                       : in signed(g_a_width-1 downto 0);
    -- Input b[k]
    coeff_b_dat_i                       : in signed(g_b_width-1 downto 0);
    -- Result output
    result_o                            : out signed(g_c_width-1 downto 0);
    -- Data valid output for debugging
    result_valid_debug_o                : out std_logic;
    -- Validate the end of fofb cycle
    result_valid_end_o                  : out std_logic
  );
end mac_fofb;

architecture behave of mac_fofb is

  signal valid_i_s, valid_o_s, clear_s  : std_logic                    := '0';
  signal a_s                            : signed(g_a_width-1 downto 0) := (others => '0');
  signal cnt                            : integer                      := 0;

begin

  matmul_INST : matmul
    port map (
      clk_i                    => clk_i,
      rst_n_i                  => rst_n_i,
      clear_acc_i              => clear_s,
      valid_i                  => valid_i_s,
      a_i                      => a_s,
      b_i                      => coeff_b_dat_i,
      c_o                      => result_o,
      c_valid_o                => valid_o_s
    );

  MAC_TOP : process(clk_i)
  begin
    if (rising_edge(clk_i)) then
      if rst_n_i = '0' then
        a_s                    <= (others => '0');
        cnt                    <=  0;
        result_valid_end_o     <= '0';
        result_valid_debug_o   <= '0';

      else

        a_s                    <= coeff_a_dat_i;
        valid_i_s              <= valid_i;
        result_valid_debug_o   <= valid_o_s;

        if valid_o_s = '1' then
          if (cnt < g_mac_size-1) then
            result_valid_end_o <= '0';
            cnt                <= cnt + 1;
            clear_s            <= '0';

          else
            result_valid_end_o <= '1';
            cnt                <= 0;
            clear_s            <= '1';
          end if;
        else
        clear_s                <= '0';
        result_valid_end_o     <= '0';
        end if;
      end if; -- Reset
    end if; -- Clock
  end process MAC_TOP;
end architecture behave;

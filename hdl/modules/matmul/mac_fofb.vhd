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
    c_o                                 : out signed(g_c_width-1 downto 0);
    -- Data valid output for debugging
    valid_debug_o                       : out std_logic;
    -- Validate the end of fofb cycle
    valid_end_o                         : out std_logic
  );
end mac_fofb;

architecture behave of mac_fofb is

  component matmul
    port (
      -- Core clock
      clk_i                             : in std_logic;
      -- Reset all pipeline stages
      rst_n_i                           : in std_logic;
      -- Clear the accumulator
      clear_acc_i                       : in std_logic;
      -- Data valid input
      valid_i                           : in std_logic;
      -- Input a[k]
      a_i                               : in signed(g_a_width-1 downto 0);
      -- Input b[k]
      b_i                               : in signed(g_b_width-1 downto 0);
      -- Result output
      c_o                               : out signed(g_c_width-1 downto 0);
      -- Data valid output
      valid_o                           : out std_logic
    );
  end component;

  signal clr_s, v_i_s, v_o_s            : std_logic                              := '0';
  signal a_s                            : signed(g_a_width-1 downto 0)           := (others => '0');
  signal coeff_b_dat_s                  : signed(g_b_width-1 downto 0)           := (others => '0');
  signal coeff_y_dat_s                  : signed(g_b_width-1 downto 0)           := (others => '0');
  signal cnt                            : integer                                := 0;

begin

  matmul_INST : matmul
    port map (
      clk_i           => clk_i,
      rst_n_i         => rst_n_i,
      clear_acc_i     => clr_s,
      valid_i         => v_i_s,
      a_i             => a_s,
      b_i             => coeff_b_dat_s,
      c_o             => c_o,
      valid_o         => v_o_s
    );

  MAC_TOP : process(clk_i)
  begin
    if (rising_edge(clk_i)) then
      if rst_n_i = '0' then
        a_s           <= (others => '0');
        coeff_b_dat_s <= (others => '0');
        clr_s         <= '0';
        cnt           <=  0;
        valid_end_o   <= '0';
        valid_debug_o <= '0';

      else
        coeff_b_dat_s <= coeff_b_dat_i;
        a_s           <= coeff_a_dat_i;
        v_i_s         <= valid_i;
        valid_debug_o <= v_o_s;

        if v_o_s = '1' then
          if (cnt < g_mac_size-1) then
            valid_end_o <= '0';
            cnt <= cnt + 1;

          else
            valid_end_o <= '1';
            cnt <= 0;
          end if;
        end if;
      end if; -- Reset
    end if; -- Clock
  end process MAC_TOP;
end architecture behave;

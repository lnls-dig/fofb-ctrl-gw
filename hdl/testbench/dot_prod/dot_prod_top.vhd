-------------------------------------------------------------------------------
-- Title      : Dot Product synth test
-------------------------------------------------------------------------------
-- Author     : Augusto Fraga Giachero
-- Company    : CNPEM LNLS-GCA
-- Platform   : Simulation
-------------------------------------------------------------------------------
-- Description: Dot Product synth test
-------------------------------------------------------------------------------
-- Copyright (c) 2022 CNPEM
-- Licensed under GNU Lesser General Public License (LGPL) v3.0
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                Description
-- 2022-08-23  1.0      augusto.fraga         Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.fixed_pkg.all;

library work;
use work.dot_prod_pkg.all;

entity dot_prod_top is
  generic (
    g_A_INT_WIDTH : natural := 0;
    g_A_FRAC_WIDTH : natural := 31;
    g_B_INT_WIDTH : natural := 31;
    g_B_FRAC_WIDTH : natural := 0;
    g_ACC_EXTRA_WIDTH : natural := 4
    );
  port (
    clk : in std_logic := '0';
    rst_n : in std_logic := '0';
    clear_acc : in std_logic := '0';
    valid : in std_logic := '0';
    idle : out std_logic;
    a : in sfixed(g_A_INT_WIDTH downto -g_A_FRAC_WIDTH);
    b : in sfixed(g_B_INT_WIDTH downto -g_B_FRAC_WIDTH);
    res : out sfixed(g_ACC_EXTRA_WIDTH + g_A_INT_WIDTH + g_B_INT_WIDTH + 1
                     downto
                     -(g_A_FRAC_WIDTH + g_B_FRAC_WIDTH))
    );
end dot_prod_top;

architecture rtl of dot_prod_top is
begin
  cmp_dot_prod: dot_prod
    generic map (
      g_A_INT_WIDTH => g_A_INT_WIDTH,
      g_A_FRAC_WIDTH => g_A_FRAC_WIDTH,
      g_B_INT_WIDTH => g_B_INT_WIDTH,
      g_B_FRAC_WIDTH => g_B_FRAC_WIDTH,
      g_ACC_EXTRA_WIDTH => 4,
      g_MULT_PIPELINE_STAGES => 2,
      g_ACC_PIPELINE_STAGES => 2,
      g_REG_INPUTS => true
      )
    port map (
      clk_i => clk,
      rst_n_i => rst_n,
      clear_acc_i => clear_acc,
      valid_i => valid,
      a_i => a,
      b_i => b,
      idle_o => idle,
      result_o => res
      );
end architecture rtl;

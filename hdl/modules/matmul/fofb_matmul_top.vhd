-------------------------------------------------------------------------------
-- Title      :  Matrix multiplication interface
-------------------------------------------------------------------------------
-- Author     :  Melissa Aguiar
-- Company    : CNPEM LNLS-DIG
-- Platform   : FPGA-generic
-------------------------------------------------------------------------------
-- Description:  Matrix multiplication top level for the Fast Orbit Feedback
-------------------------------------------------------------------------------
-- Copyright (c) 2020 CNPEM
-- Licensed under GNU Lesser General Public License (LGPL) v3.0
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                Description
-- 2021-22-07  1.0      melissa.aguiar        Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

library work;
use work.mult_pkg.all;

entity fofb_matmul_top is
  generic(
    -- Width for input a[k]
    g_a_width                           : natural := 32;
    -- Width for index k (coeff_x_addr)
    g_k_width                           : natural := 9;
    -- Width for input b[k] (coeff_x_dat)
    g_b_width                           : natural := 32;
    -- Width for output c
    g_c_width                           : natural := 32;
    -- Number of products
    g_mac_size                          : natural := 160;
    -- Matrix multiplication g_mac_size
    g_mat_size                          : natural := 1
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
    -- Input k
    coeff_k_addr_i                      : in std_logic_vector(g_k_width-1 downto 0);
    -- Result output
    c_o                                 : out signed(g_c_width-1 downto 0);
    -- Data valid output for debugging
    valid_debug_o                       : out std_logic;
    -- Validate the end of fofb cycle
    valid_end_o                         : out std_logic
  );
end fofb_matmul_top;

architecture behave of fofb_matmul_top is

--   signal clk_s           : std_logic_vector(g_mat_size-1 downto 0) := (others => '0');
--   signal rst_s        : std_logic   := '0';
--   signal v_i_s        : std_logic   := '0';
--   signal v_o_s        : std_logic   := '0';
--   signal valid_tr     : std_logic   := '0';
--
--   signal a_s          : signed(g_a_width-1 downto 0)               := (others => '0');
--   signal k_s          : std_logic_vector(g_k_width-1 downto 0)     := (others => '0');
--   signal b_s          : signed(g_b_width-1 downto 0)               := (others => '0');
--   signal c_s          : signed(g_c_width-1 downto 0)               := (others => '0');

begin
  gen_matrix_multiplication : for i in 0 to g_mat_size-1 generate
    matrix_multiplication_INST : mac_fofb
      port map (
        clk_i         => clk_i,
        rst_n_i       => rst_n_i,
        valid_i       => valid_i,
        coeff_a_dat_i => coeff_a_dat_i,
        coeff_b_dat_i => coeff_b_dat_i,
        coeff_k_addr_i=> coeff_k_addr_i,
        c_o           => c_o,
        valid_debug_o => valid_debug_o,
        valid_end_o   => valid_end_o
        );
  end generate;
end architecture behave;

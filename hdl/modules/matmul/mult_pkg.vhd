-------------------------------------------------------------------------------
-- Title      :  Matrix multiplication package
-------------------------------------------------------------------------------
-- Author     :  Melissa Aguiar
-- Company    : CNPEM LNLS-DIG
-- Platform   : FPGA-generic
-------------------------------------------------------------------------------
-- Description:  Package for the matrix multiplication core
-------------------------------------------------------------------------------
-- Copyright (c) 2020 CNPEM
-- Licensed under GNU Lesser General Public License (LGPL) v3.0
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                Description
-- 2021-04-07  1.0      melissa.aguiar        Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.math_real.all;


package mult_pkg is

  constant c_mat_size   : natural := 8;
  constant c_out_width  : natural := 32;
  type t_array is array (0 to c_mat_size-1) of signed(c_out_width-1 downto 0);

  component matmul is
    generic(
      -- Width for input a[k]
      g_a_width                       : natural := 32;
      -- Width for input b[k]
      g_b_width                       : natural := 32;
      -- Width for output c
      g_c_width                       : natural := 32
      );
    port(
      -- Core clock
      clk_i                           : in std_logic;
      -- Reset
      rst_n_i                         : in std_logic;
      -- Clear
      clear_acc_i                     : in std_logic;
      -- Data valid input
      valid_i                         : in std_logic;
      -- Input a[k]
      a_i                             : in signed(g_a_width-1 downto 0);
      -- Input b[k]
      b_i                             : in signed(g_b_width-1 downto 0);
      -- Result output
      c_o                             : out signed(g_c_width-1 downto 0);
      -- Data valid output
      valid_o                         : out std_logic
      );
  end component matmul;

  component mac_fofb is
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
      -- Input k
      coeff_k_addr_i                      : in std_logic_vector(g_k_width-1 downto 0);
      -- Output k
      coeff_k_addr_o                      : out std_logic_vector(g_k_width-1 downto 0);
      -- Result output
      c_o                                 : out signed(g_c_width-1 downto 0);
      -- Data valid output for debugging
      valid_debug_o                       : out std_logic;
      -- Validate the end of fofb cycle
      valid_end_o                         : out std_logic
      );
  end component mac_fofb;

  component fofb_matmul_top is
    generic(
      -- Width for input a[k]
      g_a_width                           : natural := 32;
      -- Width for index k (coeff_x_addr)
      g_k_width                           : natural := 9;
      -- Width for input b[k] (coeff_x_dat)
      g_b_width                           : natural := 32;
      -- Width for output c
      g_c_width                           : natural := 32;
      -- Matrix multiplication size
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
  end component fofb_matmul_top;

  component generic_dpram
    generic (
      g_data_width               : natural := 32;
      g_size                     : natural := 32;
      g_with_byte_enable         : boolean := false;
      g_addr_conflict_resolution : string  := "dont_care";
      g_init_file                : string  := "b_hex.txt";
      g_fail_if_file_not_found   : boolean := true;
      g_dual_clock               : boolean := true);
    port (
      rst_n_i : in  std_logic := '1';
      clka_i  : in  std_logic;
      bwea_i  : in  std_logic_vector((g_data_width+7)/8-1 downto 0);
      wea_i   : in  std_logic := '0';
      aa_i    : in  std_logic_vector(integer(ceil(log2(real(g_size))))-1 downto 0);
      da_i    : in  std_logic_vector(g_data_width-1 downto 0);
      qa_o    : out std_logic_vector(g_data_width-1 downto 0);
      clkb_i  : in  std_logic;
      bweb_i  : in  std_logic_vector((g_data_width+7)/8-1 downto 0);
      web_i   : in  std_logic := '0';
      ab_i    : in  std_logic_vector(integer(ceil(log2(real(g_size))))-1 downto 0);
      db_i    : in  std_logic_vector(g_data_width-1 downto 0);
      qb_o    : out std_logic_vector(g_data_width-1 downto 0));
  end component;

end package mult_pkg;

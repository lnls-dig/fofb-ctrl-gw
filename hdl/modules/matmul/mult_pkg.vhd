-------------------------------------------------------------------------------
-- Title      :  Matrix multiplication package
-------------------------------------------------------------------------------
-- Author     :  Melissa Aguiar
-- Company    :  CNPEM LNLS-DIG
-- Platform   :  FPGA-generic
-------------------------------------------------------------------------------
-- Description:  Package for the matrix multiplication core
-------------------------------------------------------------------------------
-- Copyright (c) 2020 CNPEM
-- Licensed under GNU Lesser General Public License (LGPL) v3.0
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                Description
-- 2021-30-07  1.0      melissa.aguiar        Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.math_real.all;


package mult_pkg is

  constant c_out_width  : natural := 32;

  type t_array_signed   is array (natural range <>) of signed(c_out_width-1 downto 0);
  type t_array_logic    is array (natural range <>) of std_logic_vector(c_out_width-1 downto 0);

  component matmul is
    generic(
      -- Width for input a[k]
      g_a_width                           : natural := 32;
      -- Width for input b[k]
      g_b_width                           : natural := 32;
      -- Width for output c
      g_c_width                           : natural := 32
    );
    port(
      -- Core clock
      clk_i                               : in std_logic;
      -- Reset
      rst_n_i                             : in std_logic;
      -- Clear
      clear_acc_i                         : in std_logic;
      -- Data valid input
      valid_i                             : in std_logic;
      -- Input a[k]
      a_i                                 : in signed(g_a_width-1 downto 0);
      -- Input b[k]
      b_i                                 : in signed(g_b_width-1 downto 0);
      -- Result output
      c_o                                 : out signed(g_c_width-1 downto 0);
      -- Data valid output
      valid_o                             : out std_logic
    );
  end component matmul;

  component mac_fofb is
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
  end component mac_fofb;

  component fofb_matmul_top is
    generic(
      -- Standard parameters of generic_dpram
      g_data_width                        : natural := 32;
      g_size                              : natural := 2048; -- 2**g_k_width
      g_with_byte_enable                  : boolean := false;
      g_addr_conflict_resolution          : string  := "read_first";
      g_init_file                         : string  := ""; --"../../testbench/matmul/coeff_bin.ram";
      g_dual_clock                        : boolean := true;
      g_fail_if_file_not_found            : boolean := true;

      -- Width for inputs x and y
      g_a_width                           : natural := 32;
      -- Width for ram data
      g_b_width                           : natural := 32;
      -- Width for ram addr
      g_k_width                           : natural := 11;
      -- Width for output c
      g_c_width                           : natural := 32;
      -- Matrix multiplication size
      g_mat_size                          : natural := 4
    );
    port (
      -- Core clock
      clk_i                               : in std_logic;

      -- Reset
      rst_n_i                             : in std_logic;

      -- DCC interface
      dcc_valid_i                         : in std_logic;
      dcc_coeff_x_i                       : in signed(g_a_width-1 downto 0);
      dcc_coeff_y_i                       : in signed(g_a_width-1 downto 0);
      dcc_addr_i                          : in std_logic_vector(g_k_width-1 downto 0);

      -- RAM interface
      ram_coeff_dat_i                     : in std_logic_vector(g_b_width-1 downto 0);
      ram_addr_i                          : in std_logic_vector(g_k_width-1 downto 0);
      ram_write_enable_i                  : in std_logic;

      -- Result output array
      c_x_o                               : out t_array_signed(g_mat_size-1 downto 0);
      c_y_o                               : out t_array_signed(g_mat_size-1 downto 0);

      -- Valid output for debugging
      valid_debug_x_o                     : out std_logic_vector(g_mat_size-1 downto 0);
      valid_debug_y_o                     : out std_logic_vector(g_mat_size-1 downto 0);

      -- Valid end of fofb cycle
      valid_end_x_o                       : out std_logic_vector(g_mat_size-1 downto 0);
      valid_end_y_o                       : out std_logic_vector(g_mat_size-1 downto 0)
    );
  end component fofb_matmul_top;

  component matmul_wb is
    port (
      rst_n_i              : in    std_logic;
      clk_i                : in    std_logic;
      wb_cyc_i             : in    std_logic;
      wb_stb_i             : in    std_logic;
      wb_adr_i             : in    std_logic_vector(3 downto 2);
      wb_sel_i             : in    std_logic_vector(3 downto 0);
      wb_we_i              : in    std_logic;
      wb_dat_i             : in    std_logic_vector(31 downto 0);
      wb_ack_o             : out   std_logic;
      wb_err_o             : out   std_logic;
      wb_rty_o             : out   std_logic;
      wb_stall_o           : out   std_logic;
      wb_dat_o             : out   std_logic_vector(31 downto 0);

      -- REG ram_coeff_dat
      ram_coeff_dat_o      : out   std_logic_vector(31 downto 0);

      -- REG ram_coeff_addr
      ram_coeff_addr_o     : out   std_logic_vector(31 downto 0);

      -- REG ram
      ram_write_enable_o   : out   std_logic;
      ram_wr_o             : out   std_logic
    );
  end component matmul_wb;

end package mult_pkg;

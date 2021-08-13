-------------------------------------------------------------------------------
-- Title      :  Testing the matrix multiplication interface
-------------------------------------------------------------------------------
-- Author     :  Melissa Aguiar
-- Company    :  CNPEM LNLS-DIG
-- Platform   :  FPGA-generic
-------------------------------------------------------------------------------
-- Description:  Testing the matrix multiplication interface
-------------------------------------------------------------------------------
-- Copyright (c) 2020 CNPEM
-- Licensed under GNU Lesser General Public License (LGPL) v3.0
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                Description
-- 2021-08-10  1.0      melissa.aguiar        Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

library std;
use std.textio.all;

library work;
use work.mult_pkg.all;
use work.genram_pkg.all;
use work.memory_loader_pkg.all;

entity test_matmul is
  generic(
    -- Width for signals x and y
    g_a_width                    : natural := 32;
    -- Width for ram data
    g_b_width                    : natural := 32;
    -- Width for ram addr
    g_k_width                    : natural := 11;
    -- Width for output c
    g_c_width                    : natural := 32;
    -- Matrix multiplication size
    g_mat_size                   : natural := 4
  );
  port (
    -- Core clock
    clk_core                     : in std_logic;

    -- Reset
    rst_n_i                      : in std_logic;

    -- DCC interface
    dcc_valid_i                  : in std_logic;
    dcc_coeff_x_i                : in signed(g_a_width-1 downto 0);
    dcc_coeff_y_i                : in signed(g_a_width-1 downto 0);
    dcc_addr_i                   : in std_logic_vector(g_k_width-1 downto 0);

    -- RAM interface
    ram_coeff_dat_i              : in std_logic_vector(g_b_width-1 downto 0);
    ram_addr_i                   : in std_logic_vector(g_k_width-1 downto 0);
    ram_write_enable_i           : in std_logic;

    -- Result output array
    c_x_o                        : out t_array_signed(g_mat_size-1 downto 0);
    c_y_o                        : out t_array_signed(g_mat_size-1 downto 0);

    -- Valid output for debugging
    valid_debug_x_o              : out std_logic_vector(g_mat_size-1 downto 0);
    valid_debug_y_o              : out std_logic_vector(g_mat_size-1 downto 0);

    -- Valid end of fofb cycle
    valid_end_x_o                : out std_logic_vector(g_mat_size-1 downto 0);
    valid_end_y_o                : out std_logic_vector(g_mat_size-1 downto 0)
  );
end test_matmul;

architecture behave of test_matmul is

begin

  fofb_matmul_top_INST : fofb_matmul_top
    port map (
    -- Core clock
    clk_i                         => clk_core,

    -- Reset
    rst_n_i                       => rst_n_i,

    -- DCC interface
    dcc_valid_i                   => dcc_valid_i,
    dcc_coeff_x_i                 => dcc_coeff_x_i,
    dcc_coeff_y_i                 => dcc_coeff_y_i,
    dcc_addr_i                    => dcc_addr_i,

    -- RAM interface
    ram_coeff_dat_i               => ram_coeff_dat_i,
    ram_addr_i                    => ram_addr_i,
    ram_write_enable_i            => ram_write_enable_i,

    -- Result output array
    c_x_o                         => c_x_o,
    c_y_o                         => c_y_o,

    -- Valid output for debugging
    valid_debug_x_o               => valid_debug_x_o,
    valid_debug_y_o               => valid_debug_y_o,

    -- Valid end of fofb cycle
    valid_end_x_o                 => valid_end_x_o,
    valid_end_y_o                 => valid_end_y_o
  );

end architecture behave;

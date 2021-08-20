-------------------------------------------------------------------------------
-- Title      :  Wishbone matmul wrapper with structs
-------------------------------------------------------------------------------
-- Author     :  Melissa Aguiar
-- Company    :  CNPEM LNLS-DIG
-- Platform   :  FPGA-generic
-------------------------------------------------------------------------------
-- Description:  Wishbone matmul wrapper for the Fast Orbit Feedback
-------------------------------------------------------------------------------
-- Copyright (c) 2020 CNPEM
-- Licensed under GNU Lesser General Public License (LGPL) v3.0
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                Description
-- 2021-08-19  1.0      melissa.aguiar        Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

library work;
-- Matmul package
use work.mult_pkg.all;
-- RAM package
use work.genram_pkg.all;
-- Main Wishbone Definitions
use work.wishbone_pkg.all;
-- General common cores
use work.gencores_pkg.all;
-- FOFB CTRL package
use work.fofb_ctrl_pkg.all;

entity xwb_matmul_wrapper is
  generic(
    -- Standard parameters of generic_dpram
    g_data_width                 : natural := 32;
    g_size                       : natural := c_size_dpram;
    g_with_byte_enable           : boolean := false;
    g_addr_conflict_resolution   : string  := "read_first";
    g_init_file                  : string  := "";
    g_dual_clock                 : boolean := true;
    g_fail_if_file_not_found     : boolean := true;

    -- Width for inputs x and y
    g_a_width                    : natural := 32;
    -- Width for ram data
    g_b_width                    : natural := 32;
    -- Width for ram addr
    g_k_width                    : natural := 11;
    -- Width for output c
    g_c_width                    : natural := 32;
    -- Matrix multiplication size
    g_mat_size                   : natural := 4;

    -- Wishbone parameters
    g_INTERFACE_MODE             : t_wishbone_interface_mode      := CLASSIC;
    g_ADDRESS_GRANULARITY        : t_wishbone_address_granularity := WORD;
    g_WITH_EXTRA_WB_REG          : boolean := false
  );
  port (
    ---------------------------------------------------------------------------
    -- Clock and reset interface
    ---------------------------------------------------------------------------
    clk_i                        : in std_logic;
    rst_n_i                      : in std_logic;
    clk_sys_i                    : in std_logic;
    rst_sys_n_i                  : in std_logic;

    ---------------------------------------------------------------------------
    -- Matmul Top Level Interface Signals
    ---------------------------------------------------------------------------
    -- DCC interface
    dcc_valid_i                  : in std_logic;
    dcc_coeff_x_i                : in signed(g_a_width-1 downto 0);
    dcc_coeff_y_i                : in signed(g_a_width-1 downto 0);
    dcc_addr_i                   : in std_logic_vector(g_k_width-1 downto 0);

    -- Result output array
    spx_o                        : out t_matmul_array_signed(g_mat_size-1 downto 0);
    spy_o                        : out t_matmul_array_signed(g_mat_size-1 downto 0);

    -- Valid output for debugging
    spx_valid_debug_o            : out std_logic_vector(g_mat_size-1 downto 0);
    spy_valid_debug_o            : out std_logic_vector(g_mat_size-1 downto 0);

    -- Valid end of fofb cycle
    spx_valid_end_o              : out std_logic_vector(g_mat_size-1 downto 0);
    spy_valid_end_o              : out std_logic_vector(g_mat_size-1 downto 0);

    ---------------------------------------------------------------------------
    -- Wishbone Control Interface signals
    ---------------------------------------------------------------------------
    wb_slv_i                     : in t_wishbone_slave_in;
    wb_slv_o                     : out t_wishbone_slave_out
  );
  end xwb_matmul_wrapper;

architecture rtl of xwb_matmul_wrapper is

begin

  cmp_wb_matmul_wrapper : wb_matmul_wrapper
  generic map(
    -- Standard parameters of generic_dpram
    g_data_width                 => g_data_width,
    g_size                       => g_size,
    g_with_byte_enable           => g_with_byte_enable,
    g_addr_conflict_resolution   => g_addr_conflict_resolution,
    g_init_file                  => g_init_file,
    g_dual_clock                 => g_dual_clock,
    g_fail_if_file_not_found     => g_fail_if_file_not_found,

    -- Width for inputs x and y
    g_a_width                    => g_a_width,
    -- Width for ram data
    g_b_width                    => g_b_width,
    -- Width for ram addr
    g_k_width                    => g_k_width,
    -- Width for output c
    g_c_width                    => g_c_width,
    -- Matrix multiplication size
    g_mat_size                   => g_mat_size,

    -- Wishbone parameters
    g_INTERFACE_MODE             => g_INTERFACE_MODE,
    g_ADDRESS_GRANULARITY        => g_ADDRESS_GRANULARITY,
    g_WITH_EXTRA_WB_REG          => g_WITH_EXTRA_WB_REG
  )
  port map(
    ---------------------------------------------------------------------------
    -- Clock and reset interface
    ---------------------------------------------------------------------------
    clk_i                        => clk_i,
    rst_n_i                      => rst_n_i,
    clk_sys_i                    => clk_sys_i,
    rst_sys_n_i                  => rst_sys_n_i,

    ---------------------------------------------------------------------------
    -- Matmul Top Level Interface Signals
    ---------------------------------------------------------------------------
    -- DCC interface
    dcc_valid_i                  => dcc_valid_i,
    dcc_coeff_x_i                => dcc_coeff_x_i,
    dcc_coeff_y_i                => dcc_coeff_y_i,
    dcc_addr_i                   => dcc_addr_i,

    -- Result output array
    spx_o                        => spx_o,
    spy_o                        => spy_o,

    -- Valid output for debugging
    spx_valid_debug_o            => spx_valid_debug_o,
    spy_valid_debug_o            => spy_valid_debug_o,

    -- Valid end of fofb cycle
    spx_valid_end_o              => spx_valid_end_o,
    spy_valid_end_o              => spy_valid_end_o,

    ---------------------------------------------------------------------------
    -- Wishbone Control Interface signals
    ---------------------------------------------------------------------------
    wb_adr_i                     => wb_slv_i.adr,
    wb_dat_i                     => wb_slv_i.dat,
    wb_dat_o                     => wb_slv_o.dat,
    wb_sel_i                     => wb_slv_i.sel,
    wb_we_i                      => wb_slv_i.we,
    wb_cyc_i                     => wb_slv_i.cyc,
    wb_stb_i                     => wb_slv_i.stb,
    wb_ack_o                     => wb_slv_o.ack,
    wb_err_o                     => wb_slv_o.err,
    wb_rty_o                     => wb_slv_o.rty,
    wb_stall_o                   => wb_slv_o.stall
  );

end architecture rtl;

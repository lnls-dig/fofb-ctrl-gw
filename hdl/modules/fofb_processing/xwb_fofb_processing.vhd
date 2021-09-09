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
-- Dot product package
use work.dot_prod_pkg.all;
-- RAM package
use work.genram_pkg.all;
-- Main Wishbone Definitions
use work.wishbone_pkg.all;
-- General common cores
use work.gencores_pkg.all;
-- FOFB CTRL package
use work.fofb_ctrl_pkg.all;

entity xwb_fofb_processing is
  generic(
    -- Standard parameters of generic_dpram
    g_DATA_WIDTH                 : natural := c_DATA_WIDTH;
    g_SIZE                       : natural := c_SIZE;
    g_WITH_BYTE_ENABLE           : boolean := c_WITH_BYTE_ENABLE;
    g_ADDR_CONFLICT_RESOLUTION   : string  := c_ADDR_CONFLICT_RESOLUTION;
    g_INIT_FILE                  : string  := c_INIT_FILE;
    g_DUAL_CLOCK                 : boolean := c_DUAL_CLOCK;
    g_FAIL_IF_FILE_NOT_FOUND     : boolean := c_FAIL_IF_FILE_NOT_FOUND;

    -- Width for DCC input
    g_A_WIDTH                    : natural := c_A_WIDTH;

    -- Width for RAM coeff
    g_B_WIDTH                    : natural := c_B_WIDTH;

    -- Width for RAM addr
    g_K_WIDTH                    : natural := c_K_WIDTH;

    -- Width for output
    g_C_WIDTH                    : natural := c_C_WIDTH;

    -- Number of channels
    g_CHANNELS                   : natural := c_CHANNELS;

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
    -- FOFB Processing Interface signals
    ---------------------------------------------------------------------------
    -- DCC interface
    dcc_fod_i                    : in t_dot_prod_array_record_fod(g_CHANNELS-1 downto 0);
    dcc_time_frame_start_i       : in std_logic;
    dcc_time_frame_end_i         : in std_logic;

    -- Result output array
    sp_o                         : out t_dot_prod_array_signed(g_CHANNELS-1 downto 0);
    sp_debug_o                   : out t_dot_prod_array_signed(g_CHANNELS-1 downto 0);

    -- Valid output
    sp_valid_o                   : out std_logic_vector(g_CHANNELS-1 downto 0);
    sp_valid_debug_o             : out std_logic_vector(g_CHANNELS-1 downto 0);

    ---------------------------------------------------------------------------
    -- Wishbone Control Interface signals
    ---------------------------------------------------------------------------
    wb_slv_i                     : in t_wishbone_slave_in;
    wb_slv_o                     : out t_wishbone_slave_out
  );
  end xwb_fofb_processing;

architecture rtl of xwb_fofb_processing is

begin

  cmp_wb_fofb_processing : wb_fofb_processing
  generic map(
    -- Standard parameters of generic_dpram
    g_DATA_WIDTH                 => g_DATA_WIDTH,
    g_SIZE                       => g_SIZE,
    g_WITH_BYTE_ENABLE           => g_WITH_BYTE_ENABLE,
    g_ADDR_CONFLICT_RESOLUTION   => g_ADDR_CONFLICT_RESOLUTION,
    g_INIT_FILE                  => g_INIT_FILE,
    g_DUAL_CLOCK                 => g_DUAL_CLOCK,
    g_FAIL_IF_FILE_NOT_FOUND     => g_FAIL_IF_FILE_NOT_FOUND,

    -- Width for inputs x and y
    g_A_WIDTH                    => g_A_WIDTH,
    -- Width for ram data
    g_B_WIDTH                    => g_B_WIDTH,
    -- Width for ram addr
    g_K_WIDTH                    => g_K_WIDTH,
    -- Width for output c
    g_C_WIDTH                    => g_C_WIDTH,

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
    dcc_fod_i                    => dcc_fod_i,
    dcc_time_frame_start_i       => dcc_time_frame_start_i,
    dcc_time_frame_end_i         => dcc_time_frame_end_i,

    -- Result output array
    sp_o                         => sp_o,
    sp_debug_o                   => sp_debug_o,

    -- Valid output for debugging
    sp_valid_o                   => sp_valid_o,
    sp_valid_debug_o             => sp_valid_debug_o,

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

-------------------------------------------------------------------------------
-- Title      :  FOFB processing channel
-------------------------------------------------------------------------------
-- Author     :  Melissa Aguiar
-- Company    :  CNPEM LNLS-DIG
-- Platform   :  FPGA-generic
-------------------------------------------------------------------------------
-- Description:  Processing channel for the Fast Orbit Feedback
-------------------------------------------------------------------------------
-- Copyright (c) 2020 CNPEM
-- Licensed under GNU Lesser General Public License (LGPL) v3.0
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                Description
-- 2021-08-26  1.0      melissa.aguiar        Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

library work;
-- Dot product package
use work.dot_prod_pkg.all;

entity fofb_processing_channel is
  generic(
    -- Standard parameters of generic_dpram
    g_DATA_WIDTH                   : natural := c_DATA_WIDTH;
    g_SIZE                         : natural := c_SIZE;
    g_WITH_BYTE_ENABLE             : boolean := c_WITH_BYTE_ENABLE;
    g_ADDR_CONFLICT_RESOLUTION     : string  := c_ADDR_CONFLICT_RESOLUTION;
    g_INIT_FILE                    : string  := c_INIT_FILE;
    g_DUAL_CLOCK                   : boolean := c_DUAL_CLOCK;
    g_FAIL_IF_FILE_NOT_FOUND       : boolean := c_FAIL_IF_FILE_NOT_FOUND;

    -- Width for DCC input
    g_A_WIDTH                      : natural := c_A_WIDTH;

    -- Width for RAM coeff
    g_B_WIDTH                      : natural := c_B_WIDTH;

    -- Width for RAM addr
    g_K_WIDTH                      : natural := c_K_WIDTH;

    -- Width for DCC addr
    g_ID_WIDTH                     : natural := c_K_WIDTH;

    -- Width for output
    g_C_WIDTH                      : natural := c_C_WIDTH
  );
  port (
    ---------------------------------------------------------------------------
    -- Clock and reset interface
    ---------------------------------------------------------------------------
    clk_i                          : in std_logic;
    rst_n_i                        : in std_logic;

    ---------------------------------------------------------------------------
    -- Dot product interface signals
    ---------------------------------------------------------------------------
    -- DCC interface
    dcc_valid_i                    : in std_logic;
    dcc_data_i                     : in signed(g_A_WIDTH-1 downto 0);
    dcc_addr_i                     : in std_logic_vector(g_ID_WIDTH-1 downto 0);
    dcc_time_frame_start_i         : in std_logic;
    dcc_time_frame_end_i           : in std_logic;

    -- RAM interface
    ram_coeff_dat_i                : in std_logic_vector(g_B_WIDTH-1 downto 0);
    ram_addr_i                     : in std_logic_vector(g_K_WIDTH-1 downto 0);
    ram_write_enable_i             : in std_logic;

    -- Result output array
    sp_o                           : out signed(g_C_WIDTH-1 downto 0);
    sp_debug_o                     : out signed(g_C_WIDTH-1 downto 0);

    -- Valid output
    sp_valid_o                     : out std_logic;
    sp_valid_debug_o               : out std_logic
  );
  end fofb_processing_channel;

architecture behave of fofb_processing_channel is

begin

  dot_prod_coeff_vec_interface : dot_prod_coeff_vec
    port map (
      clk_i                        => clk_i,
      rst_n_i                      => rst_n_i,
      dcc_valid_i                  => dcc_valid_i,
      dcc_data_i                   => dcc_data_i,
      dcc_addr_i                   => dcc_addr_i,
      dcc_time_frame_start_i       => dcc_time_frame_start_i,
      dcc_time_frame_end_i         => dcc_time_frame_end_i,
      ram_coeff_dat_i              => ram_coeff_dat_i,
      ram_addr_i                   => ram_addr_i,
      ram_write_enable_i           => ram_write_enable_i,
      sp_o                         => sp_o,
      sp_debug_o                   => sp_debug_o,
      sp_valid_o                   => sp_valid_o,
      sp_valid_debug_o             => sp_valid_debug_o
    );

end architecture behave;

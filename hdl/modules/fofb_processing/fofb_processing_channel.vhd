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
    g_data_width                   : natural := 32;
    g_size                         : natural := c_size_dpram;
    g_with_byte_enable             : boolean := false;
    g_addr_conflict_resolution     : string  := "read_first";
    g_init_file                    : string  := "";
    g_dual_clock                   : boolean := true;
    g_fail_if_file_not_found       : boolean := true;

    -- Width for DCC input
    g_a_width                      : natural := 32;

    -- Width for RAM data
    g_b_width                      : natural := 32;

    -- Width for RAM addr
    g_k_width                      : natural := 11;

    -- Width for output
    g_c_width                      : natural := 32
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
    dcc_coeff_i                    : in signed(g_a_width-1 downto 0);
    dcc_addr_i                     : in std_logic_vector(g_k_width-1 downto 0);
    dcc_time_frame_start_i				 : in std_logic;
    dcc_time_frame_end_i					 : in std_logic;

    -- RAM interface
    ram_coeff_dat_i                : in std_logic_vector(g_b_width-1 downto 0);
    ram_addr_i                     : in std_logic_vector(g_k_width-1 downto 0);
    ram_write_enable_i             : in std_logic;

    -- Result output array
		sp_o                           : out signed(g_c_width-1 downto 0);
    sp_debug_o                     : out signed(g_c_width-1 downto 0);

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
      dcc_coeff_i                  => dcc_coeff_i,
      dcc_addr_i                   => dcc_addr_i,
      dcc_time_frame_start_i			 => dcc_time_frame_start_i,
    	dcc_time_frame_end_i				 => dcc_time_frame_end_i,
      ram_coeff_dat_i              => ram_coeff_dat_i,
      ram_addr_i                   => ram_addr_i,
      ram_write_enable_i           => ram_write_enable_i,
      sp_o                         => sp_o,
      sp_debug_o									 => sp_debug_o,
      sp_valid_o                   => sp_valid_o,
      sp_valid_debug_o             => sp_valid_debug_o
    );

end architecture behave;

-------------------------------------------------------------------------------
-- Title      :  FOFB processing module
-------------------------------------------------------------------------------
-- Author     :  Melissa Aguiar
-- Company    :  CNPEM LNLS-DIG
-- Platform   :  FPGA-generic
-------------------------------------------------------------------------------
-- Description:  Processing module for the Fast Orbit Feedback
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

entity fofb_processing is
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
    -- FOFB processing channel interface
    ---------------------------------------------------------------------------
    -- Clock core
    clk_i                          : in std_logic;

    -- Reset
    rst_n_i                        : in std_logic;

    -- Clear
    clear_i                        : in std_logic;

    -- DCC interface
    dcc_valid_i                    : in std_logic;
    dcc_coeff_i                    : in signed(g_a_width-1 downto 0);
    dcc_addr_i                     : in std_logic_vector(g_k_width-1 downto 0);

    -- RAM interface
    ram_coeff_dat_i                : in std_logic_vector(g_b_width-1 downto 0);
    ram_addr_i                     : in std_logic_vector(g_k_width-1 downto 0);
    ram_write_enable_i             : in std_logic;

    -- Result output array
    sp_o                           : out signed(g_c_width-1 downto 0);

    -- Valid output
    sp_valid_o                     : out std_logic
  );
  end fofb_processing;

architecture behave of fofb_processing is

begin

  fofb_processing_channel_interface : fofb_processing_channel
    port map (
      clk_i                        => clk_i,
      rst_n_i                      => rst_n_i,
      clear_i                      => clear_i,
      dcc_valid_i                  => dcc_valid_i,
      dcc_coeff_i                  => dcc_coeff_i,
      dcc_addr_i                   => dcc_addr_i,
      ram_coeff_dat_i              => ram_coeff_dat_i,
      ram_addr_i                   => ram_addr_i,
      ram_write_enable_i           => ram_write_enable_i,
      sp_o                         => sp_o,
      sp_valid_o                   => sp_valid_o
    );

end architecture behave;

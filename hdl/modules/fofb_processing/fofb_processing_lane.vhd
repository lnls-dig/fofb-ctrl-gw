-------------------------------------------------------------------------------
-- Title      :  FOFB processing lane
-------------------------------------------------------------------------------
-- Author     :  Melissa Aguiar
-- Company    :  CNPEM LNLS-DIG
-- Platform   :  FPGA-generic
-------------------------------------------------------------------------------
-- Description:  Processing lane for the Fast Orbit Feedback
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

entity fofb_processing_lane is
  generic(
    -- Width for DCC input
    g_a_width                      : natural := 32;

    -- Width for RAM data
    g_b_width                      : natural := 32;

    -- Width for RAM addr
    g_k_width                      : natural := 11;

    -- Width for output c
    g_c_width                      : natural := 32
  );
  port (
    ---------------------------------------------------------------------------
    -- Clock, reset and clear interface
    ---------------------------------------------------------------------------
    clk_i                          : in std_logic;
    rst_n_i                        : in std_logic;
    clear_i                        : in std_logic;

    ---------------------------------------------------------------------------
    -- Dot product Interface Signals
    ---------------------------------------------------------------------------
    -- DCC interface
    dcc_valid_i                    : in std_logic;
    dcc_coeff_i                    : in signed(g_a_width-1 downto 0);
    dcc_addr_i                     : in std_logic_vector(g_k_width-1 downto 0);

    -- RAM interface
    ram_coeff_dat_i                : in std_logic_vector(g_b_width-1 downto 0);
    ram_addr_i                     : in std_logic_vector(g_k_width-1 downto 0);
    ram_write_enable_i             : in std_logic;

    -- Result output array
    sp_o                           : out signed(g_a_width-1 downto 0);

    -- Valid output
    sp_valid_o                     : out std_logic
  );
  end fofb_processing_lane;

architecture behave of fofb_processing_lane is

begin

  dot_prod_coeff_interface : dot_prod_coeff
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

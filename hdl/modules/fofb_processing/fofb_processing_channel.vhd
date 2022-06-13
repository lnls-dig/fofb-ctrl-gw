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
    g_SIZE                         : natural := 512;
    g_WITH_BYTE_ENABLE             : boolean := false;
    g_ADDR_CONFLICT_RESOLUTION     : string  := "read_first";
    g_INIT_FILE                    : string  := "";
    g_DUAL_CLOCK                   : boolean := true;
    g_FAIL_IF_FILE_NOT_FOUND       : boolean := true;

    -- Width for DCC input
    g_A_WIDTH                      : natural := 32;

    -- Width for RAM coeff
    g_B_WIDTH                      : natural := 32;

    -- Width for DCC addr
    g_ID_WIDTH                     : natural := 9;

    -- Fixed point representation for output
    g_OUT_FIXED                    : natural := 26;

    -- Extra bits for accumulator
    g_EXTRA_WIDTH                  : natural := 4;

    -- Width for output
    g_C_WIDTH                      : natural := 16;

    g_ANTI_WINDUP_UPPER_LIMIT      : integer; -- anti-windup upper limit
    g_ANTI_WINDUP_LOWER_LIMIT      : integer  -- anti-windup lower limit
  );
  port(
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
    ram_addr_i                     : in std_logic_vector(g_ID_WIDTH-1 downto 0);
    ram_write_enable_i             : in std_logic;
    ram_coeff_dat_o                : out std_logic_vector(g_B_WIDTH-1 downto 0);

    -- Setpoint
    sp_o                           : out signed(g_C_WIDTH-1 downto 0);
    sp_valid_o                     : out std_logic
  );
  end fofb_processing_channel;

architecture behave of fofb_processing_channel is
  signal sp_s                      : signed(g_C_WIDTH-1 downto 0);
  signal sp_valid_s                : std_logic;

begin

  dot_prod_coeff_vec_interface : dot_prod_coeff_vec
    generic map
      (
      -- Standard parameters of generic_dpram
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
      -- Width for dcc addr
      g_ID_WIDTH                   => g_ID_WIDTH,
      -- Width for output
      g_C_WIDTH                    => g_C_WIDTH,
      -- Fixed point representation for output
      g_OUT_FIXED                  => g_OUT_FIXED,
      -- Extra bits for accumulator
      g_EXTRA_WIDTH                => g_EXTRA_WIDTH
    )
    port map
    (
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
      ram_coeff_dat_o              => ram_coeff_dat_o,
      sp_o                         => sp_s,
      sp_debug_o                   => open,
      sp_valid_o                   => sp_valid_s,
      sp_valid_debug_o             => open
    );

  cmp_anti_windup_accumulator : entity work.anti_windup_accumulator
    generic map
    (
      g_A_WIDTH                    => g_C_WIDTH,                  -- input width
      g_Q_WIDTH                    => g_C_WIDTH,                  -- output width
      g_ANTI_WINDUP_UPPER_LIMIT    => g_ANTI_WINDUP_UPPER_LIMIT,  -- anti-windup upper limit
      g_ANTI_WINDUP_LOWER_LIMIT    => g_ANTI_WINDUP_LOWER_LIMIT   -- anti-windup lower limit
    )
    port map
    (
      clk_i                        => clk_i,                      -- clock
      rst_n_i                      => rst_n_i,                    -- reset

      a_i                          => sp_s,                       -- input a
      clear_i                      => '0',                        -- clear
      sum_i                        => sp_valid_s,                 -- sum
      q_o                          => sp_o,                       -- output q
      valid_o                      => sp_valid_o                  -- valid
    );

end architecture behave;

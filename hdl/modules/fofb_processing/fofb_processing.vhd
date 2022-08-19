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
-- 2022-07-27  1.1      guilherme.ricioli     Changed coeffs RAMs' wb interface
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

library work;
-- Dot product package
use work.dot_prod_pkg.all;

entity fofb_processing is
  generic(
    -- Width for DCC input
    g_A_WIDTH                      : natural := 32;

    -- Width for DCC addr
    g_ID_WIDTH                     : natural := 9;

    -- Width for RAM coeff
    g_B_WIDTH                      : natural;

    -- Width for RAM addr
    g_K_WIDTH                      : natural;

    -- Width for output
    g_C_WIDTH                      : natural := 16;

    -- Fixed point representation for output
    g_OUT_FIXED                    : natural := 26;

    -- Extra bits for accumulator
    g_EXTRA_WIDTH                  : natural := 4;

    -- Number of channels
    g_CHANNELS                     : natural;

    g_ANTI_WINDUP_UPPER_LIMIT      : integer; -- anti-windup upper limit
    g_ANTI_WINDUP_LOWER_LIMIT      : integer  -- anti-windup lower limit
  );
  port(
    ---------------------------------------------------------------------------
    -- FOFB processing interface
    ---------------------------------------------------------------------------
    -- Clock core
    clk_i                          : in std_logic;

    -- Reset
    rst_n_i                        : in std_logic;

    -- DCC interface
    dcc_fod_i                      : in t_dot_prod_array_record_fod(g_CHANNELS-1 downto 0);
    dcc_time_frame_start_i         : in std_logic;
    dcc_time_frame_end_i           : in std_logic;

    -- RAM interface
    coeff_ram_addr_arr_o           : out t_arr_coeff_ram_addr;
    coeff_ram_data_arr_i           : in t_arr_coeff_ram_data;

    -- Setpoints
    sp_arr_o                       : out t_fofb_processing_setpoints(g_CHANNELS-1 downto 0);
    sp_valid_arr_o                 : out std_logic_vector(g_CHANNELS-1 downto 0)
  );
  end fofb_processing;

architecture behave of fofb_processing is

  -----------------------------------------------------------------------------
  -- VIO/ILA signals
  -----------------------------------------------------------------------------

--   signal reset_s                             : std_logic;
--   signal data                                : std_logic_vector(255 downto 0);
--   signal trig0                               : std_logic_vector(7 downto 0);

begin

  gen_channels : for i in 0 to g_CHANNELS-1 generate
    fofb_processing_channel_interface : fofb_processing_channel
      generic map
      (
        -- Width for inputs x and y
        g_A_WIDTH                  => g_A_WIDTH,
        -- Width for dcc addr
        g_ID_WIDTH                 => g_ID_WIDTH,
        -- Width for ram data
        g_B_WIDTH                  => g_B_WIDTH,
        -- Width for ram addr
        g_K_WIDTH                  => g_K_WIDTH,
        -- Width for output
        g_C_WIDTH                  => g_C_WIDTH,
        -- Fixed point representation for output
        g_OUT_FIXED                => g_OUT_FIXED,
        -- Extra bits for accumulator
        g_EXTRA_WIDTH              => g_EXTRA_WIDTH,

        g_ANTI_WINDUP_UPPER_LIMIT  => g_ANTI_WINDUP_UPPER_LIMIT, -- anti-windup upper limit
        g_ANTI_WINDUP_LOWER_LIMIT  => g_ANTI_WINDUP_LOWER_LIMIT  -- anti-windup lower limit
      )
      port map
      (
        clk_i                      => clk_i,
        rst_n_i                    => rst_n_i,
        dcc_valid_i                => dcc_fod_i(i).valid,
        dcc_data_i                 => signed(dcc_fod_i(i).data),
        dcc_addr_i                 => dcc_fod_i(i).addr,
        dcc_time_frame_start_i     => dcc_time_frame_start_i,
        dcc_time_frame_end_i       => dcc_time_frame_end_i,
        coeff_ram_addr_o           => coeff_ram_addr_arr_o(i),
        coeff_ram_data_i           => coeff_ram_data_arr_i(i),
        sp_o                       => sp_arr_o(i),
        sp_valid_o                 => sp_valid_arr_o(i)
      );
    end generate;

--     ila_core_inst : entity work.ila_t8_d256_s8192_cap
--     port map (
--       clk               => clk_i,
--       probe0            => data,
--       probe1            => trig0
--     );
--
--     reset_s             <= not rst_n_i;
--
--     trig0(0)            <= reset_s;
--     trig0(1)            <= rst_n_i;
--     trig0(2)            <= '0';
--     trig0(3)            <= '0';
--     trig0(4)            <= '0';
--     trig0(5)            <= '0';
--     trig0(6)            <= '0';
--     trig0(7)            <= '0';
--
--     data(0)             <= reset_s;
--     data(1)             <= rst_n_i;
--     data(9 downto 2)    <= coeff_ram_addr_arr_o(i);
--     data(41 downto 10)  <= coeff_ram_data_arr_i(i);
--     data(255 downto 42) <= (others => '0');

end architecture behave;

------------------------------------------------------------------------------
-- Title      : FOFB Controller Wrapper
------------------------------------------------------------------------------
-- Author     : Lucas Maziero Russo
-- Company    : CNPEM LNLS-DIG
-- Created    : 2020-10-28
-- Platform   : FPGA-generic
-------------------------------------------------------------------------------
-- Description: FOFB Controller Wrapper for DLS DCC
-------------------------------------------------------------------------------
-- Copyright (c) 2020 CNPEM
-- Licensed under GNU Lesser General Public License (LGPL) v3.0
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author          Description
-- 2020-10-28  1.0      lucas.russo        Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
-- DLS FOFB package
use work.fofb_cc_pkg.all;
-- Main Wishbone Definitions
use work.wishbone_pkg.all;
-- General common cores
use work.gencores_pkg.all;

entity fofb_ctrl_wrapper is
generic
(
  -- Default node ID 0-255
  g_ID                                      : integer := 200;
  -- FPGA Device
  g_DEVICE                                  : device_t := BPM;
  g_USE_DCM                                 : boolean := true;
  g_SIM_GTPRESET_SPEEDUP                    : integer := 0;
  g_INTERLEAVED                             : boolean := true;
  -- Extended FAI interface for FOFB
  g_EXTENDED_CONF_BUF                       : boolean := false;
  -- Absolute or Difference position data
  g_TX_BPM_POS_ABS                          : boolean := true;
  -- MGT Interface Parameters
  g_LANE_COUNT                              : integer := 4;
  g_TX_IDLE_NUM                             : integer := 16;
  g_RX_IDLE_NUM                             : integer := 8;
  g_SEND_ID_NUM                             : integer := 14;
  -- BPM Data Interface Parameters
  g_BPMS                                    : integer := 1;
  g_FAI_DW                                  : integer := 16;
  g_DMUX                                    : integer := 2;
  -- BPM synthetic data
  g_SIM_BPM_DATA                            : boolean := false;
  g_SIM_BLOCK_START_PERIOD                  : integer := 10000; -- in ADC clock cycles
  g_SIM_BLOCK_VALID_LENGTH                  : integer range 16 to 16*32 := 32     -- in ADC clock cycles.
);
port
(
  ---------------------------------------------------------------------------
  -- differential MGT/GTP clock inputs
  ---------------------------------------------------------------------------
  refclk_p_i                                 : in std_logic;
  refclk_n_i                                 : in std_logic;

  ---------------------------------------------------------------------------
  -- clock and reset interface
  ---------------------------------------------------------------------------
  adcclk_i                                   : in std_logic;
  adcreset_i                                 : in std_logic;
  sysclk_i                                   : in std_logic;
  sysreset_n_i                               : in std_logic;

  ---------------------------------------------------------------------------
  -- fast acquisition data interface
  -- Only used when g_SIM_BPM_DATA = false
  ---------------------------------------------------------------------------
  fai_fa_block_start_i                       : in std_logic := '0';
  fai_fa_data_valid_i                        : in std_logic := '0';
  fai_fa_d_i                                 : in std_logic_vector(g_FAI_DW-1 downto 0) := (others => '0');

  ---------------------------------------------------------------------------
  -- Synthetic data fast acquisition data interface.
  -- Only used when g_SIM_BPM_DATA = true
  ---------------------------------------------------------------------------

  fai_sim_data_sel_i                         : in  std_logic_vector(3 downto 0) := (others => '0');
  fai_sim_enable_i                           : in  std_logic := '0';
  fai_sim_trigger_i                          : in  std_logic := '0';
  fai_sim_armed_o                            : out std_logic;

  ---------------------------------------------------------------------------
  -- FOFB communication controller configuration interface
  ---------------------------------------------------------------------------
  fai_cfg_a_o                                : out std_logic_vector(10 downto 0);
  fai_cfg_d_o                                : out std_logic_vector(31 downto 0);
  fai_cfg_d_i                                : in  std_logic_vector(31 downto 0) := (others => '0');
  fai_cfg_we_o                               : out std_logic;
  fai_cfg_clk_o                              : out std_logic;
  fai_cfg_val_i                              : in  std_logic_vector(31 downto 0);
  toa_rstb_i                                 : in  std_logic := '0';
  toa_rden_i                                 : in  std_logic := '0';
  toa_dat_o                                  : out std_logic_vector(31 downto 0);
  rcb_rstb_i                                 : in  std_logic := '0';
  rcb_rden_i                                 : in  std_logic := '0';
  rcb_dat_o                                  : out std_logic_vector(31 downto 0);
  fai_rxfifo_clear_i                         : in  std_logic := '0';
  fai_txfifo_clear_i                         : in  std_logic := '0';

  ---------------------------------------------------------------------------
  -- serial I/Os for eight RocketIOs on the Libera
  ---------------------------------------------------------------------------
  fai_rio_rdp_i                              : in  std_logic_vector(g_LANE_COUNT-1 downto 0);
  fai_rio_rdn_i                              : in  std_logic_vector(g_LANE_COUNT-1 downto 0);
  fai_rio_tdp_o                              : out std_logic_vector(g_LANE_COUNT-1 downto 0);
  fai_rio_tdn_o                              : out std_logic_vector(g_LANE_COUNT-1 downto 0);
  fai_rio_tdis_o                             : out std_logic_vector(g_LANE_COUNT-1 downto 0);

  ---------------------------------------------------------------------------
  -- inverse response matrix coefficient buffer i/o
  ---------------------------------------------------------------------------
  coeff_x_addr_i                             : in  std_logic_vector(7 downto 0) := (others => '0');
  coeff_x_dat_o                              : out std_logic_vector(31 downto 0);
  coeff_y_addr_i                             : in  std_logic_vector(7 downto 0) := (others => '0');
  coeff_y_dat_o                              : out std_logic_vector(31 downto 0);

  ---------------------------------------------------------------------------
  -- Higher-level integration interface (PMC, SNIFFER_V5)
  ---------------------------------------------------------------------------
  xy_buf_addr_i                              : in  std_logic_vector(NodeW downto 0);
  xy_buf_dat_o                               : out std_logic_vector(63 downto 0);
  xy_buf_rstb_i                              : in  std_logic;
  timeframe_start_o                          : out std_logic;
  timeframe_end_o                            : out std_logic;
  fofb_watchdog_i                            : in  std_logic_vector(31 downto 0) := (others => '0');
  fofb_event_i                               : in  std_logic_vector(31 downto 0) := (others => '0');
  fofb_process_time_o                        : out std_logic_vector(15 downto 0);
  fofb_bpm_count_o                           : out std_logic_vector(7 downto 0);
  fofb_dma_ok_i                              : in  std_logic := '1';
  fofb_node_mask_o                           : out std_logic_vector(NodeNum-1 downto 0);
  fofb_timestamp_val_o                       : out std_logic_vector(31 downto 0);
  fofb_link_status_o                         : out std_logic_vector(31 downto 0)
);
end fofb_ctrl_wrapper;

architecture rtl of fofb_ctrl_wrapper is

  signal fai_fa_block_start                  : std_logic;
  signal fai_fa_data_valid                   : std_logic;
  signal fai_fa_d                            : std_logic_vector(g_FAI_DW-1 downto 0);

begin

  gen_with_sim_data : if g_SIM_BPM_DATA generate

    cmp_fofb_cc_fai_fa_gen : entity work.fofb_cc_fai_fa_gen
    generic map (
      FAI_DW                                 => g_FAI_DW
    )
    port map (
      adcclk_i                               => adcclk_i,
      adcreset_i                             => adcreset_i,
      data_sel_i                             => fai_sim_data_sel_i,
      fai_fa_block_start_o                   => fai_fa_block_start,
      fai_fa_data_valid_o                    => fai_fa_data_valid,
      fai_fa_d_o                             => fai_fa_d,
      fai_enable_i                           => fai_sim_enable_i,
      fai_trigger_i                          => fai_sim_trigger_i,
      fai_armed_o                            => fai_sim_armed_o
    );

  end generate;

  gen_without_sim_data : if not g_SIM_BPM_DATA generate

    fai_fa_block_start <= fai_fa_block_start_i;
    fai_fa_data_valid  <= fai_fa_data_valid_i;
    fai_fa_d           <= fai_fa_d_i;

    fai_sim_armed_o <= '0';

  end generate;

  cmp_fofb_cc_top : entity work.fofb_cc_top
    generic map (
      ID                                     => g_ID,
      DEVICE                                 => g_DEVICE,
      USE_DCM                                => g_USE_DCM,
      SIM_GTPRESET_SPEEDUP                   => g_SIM_GTPRESET_SPEEDUP,
      INTERLEAVED                            => g_INTERLEAVED,
      EXTENDED_CONF_BUF                      => g_EXTENDED_CONF_BUF,
      TX_BPM_POS_ABS                         => g_TX_BPM_POS_ABS,
      LANE_COUNT                             => g_LANE_COUNT,
      TX_IDLE_NUM                            => g_TX_IDLE_NUM,
      RX_IDLE_NUM                            => g_RX_IDLE_NUM,
      SEND_ID_NUM                            => g_SEND_ID_NUM,
      BPMS                                   => g_BPMS,
      FAI_DW                                 => g_FAI_DW,
      DMUX                                   => g_DMUX
    )
    port map (
      -- differential MGT/GTP clock inputs
      refclk_p_i                             => refclk_p_i,
      refclk_n_i                             => refclk_n_i,
      -- clock and reset interface
      adcclk_i                               => adcclk_i,
      adcreset_i                             => adcreset_i,
      sysclk_i                               => sysclk_i,
      sysreset_n_i                           => sysreset_n_i,
      -- fast acquisition data interface
      fai_fa_block_start_i                   => fai_fa_block_start,
      fai_fa_data_valid_i                    => fai_fa_data_valid,
      fai_fa_d_i                             => fai_fa_d,
      -- FOFB communication controller configuration interface
      fai_cfg_a_o                            => fai_cfg_a_o,
      fai_cfg_d_o                            => fai_cfg_d_o,
      fai_cfg_d_i                            => fai_cfg_d_i,
      fai_cfg_we_o                           => fai_cfg_we_o,
      fai_cfg_clk_o                          => fai_cfg_clk_o,
      fai_cfg_val_i                          => fai_cfg_val_i,
      toa_rstb_i                             => toa_rstb_i,
      toa_rden_i                             => toa_rden_i,
      toa_dat_o                              => toa_dat_o,
      rcb_rstb_i                             => rcb_rstb_i,
      rcb_rden_i                             => rcb_rden_i,
      rcb_dat_o                              => rcb_dat_o,
      fai_rxfifo_clear                       => fai_rxfifo_clear_i,
      fai_txfifo_clear                       => fai_txfifo_clear_i,
      -- serial I/Os for eight RocketIOs on the Libera
      fai_rio_rdp_i                          => fai_rio_rdp_i,
      fai_rio_rdn_i                          => fai_rio_rdn_i,
      fai_rio_tdp_o                          => fai_rio_tdp_o,
      fai_rio_tdn_o                          => fai_rio_tdn_o,
      fai_rio_tdis_o                         => fai_rio_tdis_o,
      -- inverse response matrix coefficient buffer i/o
      coeff_x_addr_i                         => coeff_x_addr_i,
      coeff_x_dat_o                          => coeff_x_dat_o,
      coeff_y_addr_i                         => coeff_y_addr_i,
      coeff_y_dat_o                          => coeff_y_dat_o,
      -- Higher-level integration interface (PMC, SNIFFER_V5)
      xy_buf_addr_i                          => xy_buf_addr_i,
      xy_buf_dat_o                           => xy_buf_dat_o,
      xy_buf_rstb_i                          => xy_buf_rstb_i,
      timeframe_start_o                      => timeframe_start_o,
      timeframe_end_o                        => timeframe_end_o,
      fofb_watchdog_i                        => fofb_watchdog_i,
      fofb_event_i                           => fofb_event_i,
      fofb_process_time_o                    => fofb_process_time_o,
      fofb_bpm_count_o                       => fofb_bpm_count_o,
      fofb_dma_ok_i                          => fofb_dma_ok_i,
      fofb_node_mask_o                       => fofb_node_mask_o,
      fofb_timestamp_val_o                   => fofb_timestamp_val_o,
      fofb_link_status_o                     => fofb_link_status_o
    );

end rtl;

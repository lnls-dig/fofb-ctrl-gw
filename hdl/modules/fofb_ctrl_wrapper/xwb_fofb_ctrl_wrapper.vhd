------------------------------------------------------------------------------
-- Title      : Wishbone FOFB Controller Wrapper with structs
------------------------------------------------------------------------------
-- Author     : Lucas Maziero Russo
-- Company    : CNPEM LNLS-DIG
-- Created    : 2020-11-06
-- Platform   : FPGA-generic
-------------------------------------------------------------------------------
-- Description: Wishbone FOFB Controller Wrapper for DLS DCC with structs
-------------------------------------------------------------------------------
-- Copyright (c) 2020 CNPEM
-- Licensed under GNU Lesser General Public License (LGPL) v3.0
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author          Description
-- 2020-11-28  1.0      lucas.russo        Created
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
-- FOFB CTRL package
use work.fofb_ctrl_pkg.all;

entity xwb_fofb_ctrl_wrapper is
generic
(
  g_INTERFACE_MODE                          : t_wishbone_interface_mode      := CLASSIC;
  g_ADDRESS_GRANULARITY                     : t_wishbone_address_granularity := WORD;
  g_WITH_EXTRA_WB_REG                       : boolean := false;
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
  -- Set to true to instantiate a chipscope with transceiver signals
  g_USE_CHIPSCOPE                           : boolean := false;
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
  -- Wishbone Control Interface signals
  ---------------------------------------------------------------------------
  wb_slv_i                                  : in t_wishbone_slave_in;
  wb_slv_o                                  : out t_wishbone_slave_out;

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
  fai_sim_trigger_internal_i                 : in  std_logic := '0';
  fai_sim_armed_o                            : out std_logic;

  ---------------------------------------------------------------------------
  -- FOFB communication controller configuration interface
  ---------------------------------------------------------------------------
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
  fofb_link_status_o                         : out std_logic_vector(31 downto 0);
  fofb_fod_dat_o                             : out std_logic_vector((32*PacketSize-1) downto 0);
  fofb_fod_dat_val_o                         : out std_logic_vector(g_LANE_COUNT-1 downto 0)
);
end xwb_fofb_ctrl_wrapper;

architecture rtl of xwb_fofb_ctrl_wrapper is

begin

  cmp_wb_fofb_ctrl_wrapper : wb_fofb_ctrl_wrapper
  generic map
  (
    g_INTERFACE_MODE                          => g_INTERFACE_MODE,
    g_ADDRESS_GRANULARITY                     => g_ADDRESS_GRANULARITY,
    g_WITH_EXTRA_WB_REG                       => g_WITH_EXTRA_WB_REG,
    -- Default node ID 0-255
    g_ID                                      => g_ID,
    -- FPGA Device
    g_DEVICE                                  => g_DEVICE,
    g_USE_DCM                                 => g_USE_DCM,
    g_SIM_GTPRESET_SPEEDUP                    => g_SIM_GTPRESET_SPEEDUP,
    g_INTERLEAVED                             => g_INTERLEAVED,
    -- Extended FAI interface for FOFB
    g_EXTENDED_CONF_BUF                       => g_EXTENDED_CONF_BUF,
    -- Absolute or Difference position data
    g_TX_BPM_POS_ABS                          => g_TX_BPM_POS_ABS,
    -- MGT Interface Parameters
    g_LANE_COUNT                              => g_LANE_COUNT,
    g_TX_IDLE_NUM                             => g_TX_IDLE_NUM,
    g_RX_IDLE_NUM                             => g_RX_IDLE_NUM,
    g_SEND_ID_NUM                             => g_SEND_ID_NUM,
    -- BPM Data Interface Parameters
    g_BPMS                                    => g_BPMS,
    g_FAI_DW                                  => g_FAI_DW,
    g_DMUX                                    => g_DMUX,
    -- Set to true to instantiate a chipscope with transceiver signals
    g_USE_CHIPSCOPE                           => g_USE_CHIPSCOPE,
    -- BPM synthetic data
    g_SIM_BPM_DATA                            => g_SIM_BPM_DATA,
    g_SIM_BLOCK_START_PERIOD                  => g_SIM_BLOCK_START_PERIOD,
    g_SIM_BLOCK_VALID_LENGTH                  => g_SIM_BLOCK_VALID_LENGTH
  )
  port map
  (
    ---------------------------------------------------------------------------
    -- differential MGT/GTP clock inputs
    ---------------------------------------------------------------------------
    refclk_p_i                                 => refclk_p_i,
    refclk_n_i                                 => refclk_n_i,

    ---------------------------------------------------------------------------
    -- clock and reset interface
    ---------------------------------------------------------------------------
    adcclk_i                                   => adcclk_i,
    adcreset_i                                 => adcreset_i,
    sysclk_i                                   => sysclk_i,
    sysreset_n_i                               => sysreset_n_i,

    ---------------------------------------------------------------------------
    -- Wishbone Control Interface signals
    ---------------------------------------------------------------------------
    wb_adr_i                                  => wb_slv_i.adr,
    wb_dat_i                                  => wb_slv_i.dat,
    wb_dat_o                                  => wb_slv_o.dat,
    wb_sel_i                                  => wb_slv_i.sel,
    wb_we_i                                   => wb_slv_i.we,
    wb_cyc_i                                  => wb_slv_i.cyc,
    wb_stb_i                                  => wb_slv_i.stb,
    wb_ack_o                                  => wb_slv_o.ack,
    wb_err_o                                  => wb_slv_o.err,
    wb_rty_o                                  => wb_slv_o.rty,
    wb_stall_o                                => wb_slv_o.stall,

    ---------------------------------------------------------------------------
    -- fast acquisition data interface
    -- Only used when g_SIM_BPM_DATA = false
    ---------------------------------------------------------------------------
    fai_fa_block_start_i                       => fai_fa_block_start_i,
    fai_fa_data_valid_i                        => fai_fa_data_valid_i,
    fai_fa_d_i                                 => fai_fa_d_i,

    ---------------------------------------------------------------------------
    -- Synthetic data fast acquisition data interface.
    -- Only used when g_SIM_BPM_DATA = true
    ---------------------------------------------------------------------------
    fai_sim_data_sel_i                         => fai_sim_data_sel_i,
    fai_sim_enable_i                           => fai_sim_enable_i,
    fai_sim_trigger_i                          => fai_sim_trigger_i,
    fai_sim_trigger_internal_i                 => fai_sim_trigger_internal_i,
    fai_sim_armed_o                            => fai_sim_armed_o,

    ---------------------------------------------------------------------------
    -- FOFB communication controller configuration interface
    ---------------------------------------------------------------------------
    toa_rstb_i                                 => toa_rstb_i,
    toa_rden_i                                 => toa_rden_i,
    toa_dat_o                                  => toa_dat_o,
    rcb_rstb_i                                 => rcb_rstb_i,
    rcb_rden_i                                 => rcb_rden_i,
    rcb_dat_o                                  => rcb_dat_o,
    fai_rxfifo_clear_i                         => fai_rxfifo_clear_i,
    fai_txfifo_clear_i                         => fai_txfifo_clear_i,

    ---------------------------------------------------------------------------
    -- serial I/Os for eight RocketIOs on the Libera
    ---------------------------------------------------------------------------
    fai_rio_rdp_i                              => fai_rio_rdp_i,
    fai_rio_rdn_i                              => fai_rio_rdn_i,
    fai_rio_tdp_o                              => fai_rio_tdp_o,
    fai_rio_tdn_o                              => fai_rio_tdn_o,
    fai_rio_tdis_o                             => fai_rio_tdis_o,

    ---------------------------------------------------------------------------
    -- inverse response matrix coefficient buffer i/o
    ---------------------------------------------------------------------------
    coeff_x_addr_i                             => coeff_x_addr_i,
    coeff_x_dat_o                              => coeff_x_dat_o,
    coeff_y_addr_i                             => coeff_y_addr_i,
    coeff_y_dat_o                              => coeff_y_dat_o,

    ---------------------------------------------------------------------------
    -- Higher-level integration interface (PMC, SNIFFER_V5)
    ---------------------------------------------------------------------------
    xy_buf_addr_i                              => xy_buf_addr_i,
    xy_buf_dat_o                               => xy_buf_dat_o,
    xy_buf_rstb_i                              => xy_buf_rstb_i,
    timeframe_start_o                          => timeframe_start_o,
    timeframe_end_o                            => timeframe_end_o,
    fofb_watchdog_i                            => fofb_watchdog_i,
    fofb_event_i                               => fofb_event_i,
    fofb_process_time_o                        => fofb_process_time_o,
    fofb_bpm_count_o                           => fofb_bpm_count_o,
    fofb_dma_ok_i                              => fofb_dma_ok_i,
    fofb_node_mask_o                           => fofb_node_mask_o,
    fofb_timestamp_val_o                       => fofb_timestamp_val_o,
    fofb_link_status_o                         => fofb_link_status_o,
    fofb_fod_dat_o                             => fofb_fod_dat_o,
    fofb_fod_dat_val_o                         => fofb_fod_dat_val_o
  );

end rtl;

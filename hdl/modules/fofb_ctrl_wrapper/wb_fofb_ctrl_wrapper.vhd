------------------------------------------------------------------------------
-- Title      : Wishbone FOFB Controller Wrapper
------------------------------------------------------------------------------
-- Author     : Lucas Maziero Russo
-- Company    : CNPEM LNLS-DIG
-- Created    : 2020-11-06
-- Platform   : FPGA-generic
-------------------------------------------------------------------------------
-- Description: Wishbone FOFB Controller Wrapper for DLS DCC
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

entity wb_fofb_ctrl_wrapper is
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
  g_BLK_SIZE                                : integer := 16;
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
  wb_adr_i                                   : in  std_logic_vector(c_WISHBONE_ADDRESS_WIDTH-1 downto 0) := (others => '0');
  wb_dat_i                                   : in  std_logic_vector(c_WISHBONE_DATA_WIDTH-1 downto 0) := (others => '0');
  wb_dat_o                                   : out std_logic_vector(c_WISHBONE_DATA_WIDTH-1 downto 0);
  wb_sel_i                                   : in  std_logic_vector(c_WISHBONE_DATA_WIDTH/8-1 downto 0) := (others => '0');
  wb_we_i                                    : in  std_logic := '0';
  wb_cyc_i                                   : in  std_logic := '0';
  wb_stb_i                                   : in  std_logic := '0';
  wb_ack_o                                   : out std_logic;
  wb_err_o                                   : out std_logic;
  wb_rty_o                                   : out std_logic;
  wb_stall_o                                 : out std_logic;

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
  fofb_userclk_o                             : out std_logic;
  fofb_userrst_o                             : out std_logic;
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
end wb_fofb_ctrl_wrapper;

architecture rtl of wb_fofb_ctrl_wrapper is

  -----------------------------
  -- General Contants
  -----------------------------
  -- Number of bits in Wishbone register interface. Plus 2 to account for BYTE addressing
  constant c_periph_addr_size               : natural := 12+2;

  -----------------------------
  -- FOFB CC signals/structures
  -----------------------------
  signal fai_fa_block_start                  : std_logic;
  signal fai_fa_data_valid                   : std_logic;
  signal fai_fa_d                            : std_logic_vector(g_FAI_DW-1 downto 0);

  signal fai_cfg_a_out                       : std_logic_vector(10 downto 0);
  signal fai_cfg_d_out                       : std_logic_vector(31 downto 0);
  signal fai_cfg_d_in                        : std_logic_vector(31 downto 0);
  signal fai_cfg_we_out                      : std_logic;
  signal fai_cfg_clk_out                     : std_logic;
  signal fai_cfg_val_in                      : std_logic_vector(31 downto 0);
  signal fai_cfg_val_act_part                : std_logic;
  signal fai_cfg_val_err_clr                 : std_logic;
  signal fai_cfg_val_cc_enable               : std_logic;
  signal fai_cfg_val_tfs_override            : std_logic;
  signal fai_cfg_to_wbram_we                 : std_logic;
  signal fai_cfg_to_wbram_re                 : std_logic;

  -----------------------------
  -- Wishbone slave adapter signals/structures
  -----------------------------
  signal wb_slv_adp_out                      : t_wishbone_master_out;
  signal wb_slv_adp_in                       : t_wishbone_master_in;
  signal resized_addr                        : std_logic_vector(c_wishbone_address_width-1 downto 0);

  -- Extra Wishbone registering stage
  signal wb_slave_in                         : t_wishbone_slave_in_array (0 downto 0);
  signal wb_slave_out                        : t_wishbone_slave_out_array(0 downto 0);
  signal wb_slave_in_reg0                    : t_wishbone_slave_in_array (0 downto 0);
  signal wb_slave_out_reg0                   : t_wishbone_slave_out_array(0 downto 0);

begin

  -----------------------------
  -- Insert extra Wishbone registering stage for ease timing.
  -- It effectively cuts the bandwidth in half!
  -----------------------------
  gen_with_extra_wb_reg : if g_WITH_EXTRA_WB_REG generate

    cmp_register_link : xwb_register_link -- puts a register of delay between crossbars
    port map (
      clk_sys_i                             => sysclk_i,
      rst_n_i                               => sysreset_n_i,
      slave_i                               => wb_slave_in_reg0(0),
      slave_o                               => wb_slave_out_reg0(0),
      master_i                              => wb_slave_out(0),
      master_o                              => wb_slave_in(0)
    );

    wb_slave_in_reg0(0).adr                 <= wb_adr_i;
    wb_slave_in_reg0(0).dat                 <= wb_dat_i;
    wb_slave_in_reg0(0).sel                 <= wb_sel_i;
    wb_slave_in_reg0(0).we                  <= wb_we_i;
    wb_slave_in_reg0(0).cyc                 <= wb_cyc_i;
    wb_slave_in_reg0(0).stb                 <= wb_stb_i;

    wb_dat_o                                <= wb_slave_out_reg0(0).dat;
    wb_ack_o                                <= wb_slave_out_reg0(0).ack;
    wb_err_o                                <= wb_slave_out_reg0(0).err;
    wb_rty_o                                <= wb_slave_out_reg0(0).rty;
    wb_stall_o                              <= wb_slave_out_reg0(0).stall;

  end generate;

  gen_without_extra_wb_reg : if not g_WITH_EXTRA_WB_REG generate

    -- External master connection
    wb_slave_in(0).adr                      <= wb_adr_i;
    wb_slave_in(0).dat                      <= wb_dat_i;
    wb_slave_in(0).sel                      <= wb_sel_i;
    wb_slave_in(0).we                       <= wb_we_i;
    wb_slave_in(0).cyc                      <= wb_cyc_i;
    wb_slave_in(0).stb                      <= wb_stb_i;

    wb_dat_o                                <= wb_slave_out(0).dat;
    wb_ack_o                                <= wb_slave_out(0).ack;
    wb_err_o                                <= wb_slave_out(0).err;
    wb_rty_o                                <= wb_slave_out(0).rty;
    wb_stall_o                              <= wb_slave_out(0).stall;

  end generate;

  -----------------------------
  -- Slave adapter for Wishbone Register Interface
  -----------------------------
  cmp_slave_adapter : wb_slave_adapter
  generic map (
    g_master_use_struct                      => true,
    g_master_mode                            => PIPELINED,
    g_master_granularity                     => WORD,
    g_slave_use_struct                       => false,
    g_slave_mode                             => g_INTERFACE_MODE,
    g_slave_granularity                      => g_ADDRESS_GRANULARITY
  )
  port map (
    clk_sys_i                                => sysclk_i,
    rst_n_i                                  => sysreset_n_i,
    master_i                                 => wb_slv_adp_in,
    master_o                                 => wb_slv_adp_out,
    sl_adr_i                                 => resized_addr,
    sl_dat_i                                 => wb_slave_in(0).dat,
    sl_sel_i                                 => wb_slave_in(0).sel,
    sl_cyc_i                                 => wb_slave_in(0).cyc,
    sl_stb_i                                 => wb_slave_in(0).stb,
    sl_we_i                                  => wb_slave_in(0).we,
    sl_dat_o                                 => wb_slave_out(0).dat,
    sl_ack_o                                 => wb_slave_out(0).ack,
    sl_rty_o                                 => wb_slave_out(0).rty,
    sl_err_o                                 => wb_slave_out(0).err,
    sl_stall_o                               => wb_slave_out(0).stall
  );

  -- By doing this zeroing we avoid the issue related to BYTE -> WORD  conversion
  -- slave addressing (possibly performed by the slave adapter component)
  -- in which a bit in the MSB of the peripheral addressing part (31 - 5 in our case)
  -- is shifted to the internal register adressing part (4 - 0 in our case).
  -- Therefore, possibly changing the these bits!
  resized_addr(c_PERIPH_ADDR_SIZE-1 downto 0)
                                             <= wb_slave_in(0).adr(c_PERIPH_ADDR_SIZE-1 downto 0);
  resized_addr(c_WISHBONE_ADDRESS_WIDTH-1 downto c_PERIPH_ADDR_SIZE)
                                             <= (others => '0');

  -----------------------------
  -- FOFB CC register map
  -----------------------------
  cmp_fofb_cc_regs : entity work.wb_fofb_cc_regs
    port map (
      rst_n_i                                => sysreset_n_i,
      clk_sys_i                              => sysclk_i,
      wb_adr_i                               => wb_slv_adp_out.adr(11 downto 0),
      wb_dat_i                               => wb_slv_adp_out.dat,
      wb_dat_o                               => wb_slv_adp_in.dat,
      wb_cyc_i                               => wb_slv_adp_out.cyc,
      wb_sel_i                               => wb_slv_adp_out.sel,
      wb_stb_i                               => wb_slv_adp_out.stb,
      wb_we_i                                => wb_slv_adp_out.we,
      wb_ack_o                               => wb_slv_adp_in.ack,
      wb_stall_o                             => wb_slv_adp_in.stall,
      fofb_cc_clk_ram_reg_i                  => fai_cfg_clk_out,
      fofb_cc_regs_cfg_val_act_part_o        => fai_cfg_val_act_part,
      fofb_cc_regs_cfg_val_err_clr_o         => fai_cfg_val_err_clr,
      fofb_cc_regs_cfg_val_cc_enable_o       => fai_cfg_val_cc_enable,
      fofb_cc_regs_cfg_val_tfs_override_o    => fai_cfg_val_tfs_override,
      fofb_cc_regs_ram_reg_addr_i            => fai_cfg_a_out,
      fofb_cc_regs_ram_reg_data_o            => fai_cfg_d_in,
      fofb_cc_regs_ram_reg_rd_i              => fai_cfg_to_wbram_re,
      fofb_cc_regs_ram_reg_data_i            => fai_cfg_d_out,
      fofb_cc_regs_ram_reg_wr_i              => fai_cfg_to_wbram_we
    );

  fai_cfg_to_wbram_we <= fai_cfg_we_out;
  fai_cfg_to_wbram_re <= not fai_cfg_we_out;

  fai_cfg_val_in(31 downto 5) <= (others => '0');
  -- TFS BPM override
  fai_cfg_val_in(4) <= fai_cfg_val_tfs_override;
  -- CC enable
  fai_cfg_val_in(3) <= fai_cfg_val_cc_enable;
  -- Error clear
  fai_cfg_val_in(2) <= fai_cfg_val_err_clr;
  -- Unused
  fai_cfg_val_in(1) <= '0';
  -- 1-CC pulse indicating a new write operation was issued.
  fai_cfg_val_in(0) <= fai_cfg_val_act_part;

  cmp_fofb_ctrl_wrapper : fofb_ctrl_wrapper
    generic map (
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
      g_BLK_SIZE                                => g_BLK_SIZE,
      g_DMUX                                    => g_DMUX,
      -- Set to true to instantiate a chipscope with transceiver signals
      g_USE_CHIPSCOPE                           => g_USE_CHIPSCOPE,
      -- BPM synthetic data
      g_SIM_BPM_DATA                            => g_SIM_BPM_DATA,
      g_SIM_BLOCK_START_PERIOD                  => g_SIM_BLOCK_START_PERIOD,
      g_SIM_BLOCK_VALID_LENGTH                  => g_SIM_BLOCK_VALID_LENGTH
    )
    port map (
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
      fai_cfg_a_o                                => fai_cfg_a_out,
      fai_cfg_d_o                                => fai_cfg_d_out,
      fai_cfg_d_i                                => fai_cfg_d_in,
      fai_cfg_we_o                               => fai_cfg_we_out,
      fai_cfg_clk_o                              => fai_cfg_clk_out,
      fai_cfg_val_i                              => fai_cfg_val_in,
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
      fofb_userclk_o                             => fofb_userclk_o,
      fofb_userrst_o                             => fofb_userrst_o,
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

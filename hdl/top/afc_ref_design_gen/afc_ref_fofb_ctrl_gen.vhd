------------------------------------------------------------------------------
-- Title      : Generic AFC design for FOFB Controller
------------------------------------------------------------------------------
-- Author     : Lucas Maziero Russo
-- Company    : CNPEM LNLS-DIG
-- Created    : 2021-06-02
-- Platform   : FPGA-generic
-------------------------------------------------------------------------------
-- Description: AFC design for FOFB Controller + 1 FMC SFP
-------------------------------------------------------------------------------
-- Copyright (c) 2020 CNPEM
-- Licensed under GNU Lesser General Public License (LGPL) v3.0
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author          Description
-- 2021-06-02  1.0      lucas.russo        Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
-- Main Wishbone Definitions
use work.wishbone_pkg.all;
-- Custom Wishbone Modules
use work.ifc_wishbone_pkg.all;
-- Custom common cores
use work.ifc_common_pkg.all;
-- Custom generic cores
use work.ifc_generic_pkg.all;
-- Trigger definitions
use work.trigger_common_pkg.all;
-- Trigger Modules
use work.trigger_pkg.all;
-- AFC base definitions
use work.afc_base_pkg.all;
-- AFC base wrappers definitions
use work.afc_base_wrappers_pkg.all;
-- General-cores Common
use work.gencores_pkg.all;
-- IP cores constants
use work.ipcores_pkg.all;
-- Meta Package
use work.synthesis_descriptor_pkg.all;
-- Data Acquisition core
use work.acq_core_pkg.all;
-- AXI cores
use work.pcie_cntr_axi_pkg.all;
-- FOFC CC wrapper
use work.fofb_ctrl_pkg.all;
-- FOFC CC
use work.fofb_cc_pkg.all;
-- RTM LAMP definitions
use work.rtm_lamp_pkg.all;

entity afc_ref_fofb_ctrl_gen is
generic (
  g_BOARD                                    : string  := "AFCv4";
  -- Number of P2P GTs
  g_NUM_P2P_GTS                              : integer := 4;
  -- Starting index of used P2P GTs
  g_P2P_GT_START_ID                          : integer := 0;
  -- Number of RTM LAMP ADC channels
  g_ADC_CHANNELS                             : natural := 12;
  -- Number of RTM LAMP DAC channels
  g_DAC_CHANNELS                             : natural := 12
);
port (
  ---------------------------------------------------------------------------
  -- Clocking pins
  ---------------------------------------------------------------------------
  sys_clk_p_i                                : in std_logic;
  sys_clk_n_i                                : in std_logic;

  aux_clk_p_i                                : in std_logic;
  aux_clk_n_i                                : in std_logic;

  afc_fp2_clk1_p_i                           : in std_logic;
  afc_fp2_clk1_n_i                           : in std_logic;

  ---------------------------------------------------------------------------
  -- Reset Button
  ---------------------------------------------------------------------------
  sys_rst_button_n_i                         : in std_logic := '1';

  ---------------------------------------------------------------------------
  -- UART pins
  ---------------------------------------------------------------------------

  uart_rxd_i                                 : in  std_logic := '1';
  uart_txd_o                                 : out std_logic;

  ---------------------------------------------------------------------------
  -- Trigger pins
  ---------------------------------------------------------------------------
  trig_dir_o                                 : out   std_logic_vector(c_NUM_TRIG-1 downto 0);
  -- AFCv4
  trig_i                                     : in    std_logic_vector(c_NUM_TRIG-1 downto 0) := (others => '0');
  trig_o                                     : out   std_logic_vector(c_NUM_TRIG-1 downto 0);
  -- AFCv3
  trig_b                                     : inout std_logic_vector(c_NUM_TRIG-1 downto 0);

  ---------------------------------------------------------------------------
  -- AFC Diagnostics
  ---------------------------------------------------------------------------

  diag_spi_cs_i                              : in std_logic := '0';
  diag_spi_si_i                              : in std_logic := '0';
  diag_spi_so_o                              : out std_logic;
  diag_spi_clk_i                             : in std_logic := '0';

  ---------------------------------------------------------------------------
  -- ADN4604ASVZ. AFCv3
  ---------------------------------------------------------------------------
  adn4604_vadj2_clk_updt_n_o                 : out std_logic;

  ---------------------------------------------------------------------------
  -- AFC I2C.
  ---------------------------------------------------------------------------
  -- Si57x oscillator
  afc_si57x_scl_b                            : inout std_logic;
  afc_si57x_sda_b                            : inout std_logic;

  -- Si57x oscillator output enable
  afc_si57x_oe_o                             : out   std_logic;

  ---------------------------------------------------------------------------
  -- PCIe pins
  ---------------------------------------------------------------------------

  -- DDR3 memory pins
  ddr3_dq_b                                  : inout std_logic_vector(c_DDR_DQ_WIDTH-1 downto 0);
  ddr3_dqs_p_b                               : inout std_logic_vector(c_DDR_DQS_WIDTH-1 downto 0);
  ddr3_dqs_n_b                               : inout std_logic_vector(c_DDR_DQS_WIDTH-1 downto 0);
  ddr3_addr_o                                : out   std_logic_vector(c_DDR_ROW_WIDTH-1 downto 0);
  ddr3_ba_o                                  : out   std_logic_vector(c_DDR_BANK_WIDTH-1 downto 0);
  ddr3_cs_n_o                                : out   std_logic_vector(0 downto 0);
  ddr3_ras_n_o                               : out   std_logic;
  ddr3_cas_n_o                               : out   std_logic;
  ddr3_we_n_o                                : out   std_logic;
  ddr3_reset_n_o                             : out   std_logic;
  ddr3_ck_p_o                                : out   std_logic_vector(c_DDR_CK_WIDTH-1 downto 0);
  ddr3_ck_n_o                                : out   std_logic_vector(c_DDR_CK_WIDTH-1 downto 0);
  ddr3_cke_o                                 : out   std_logic_vector(c_DDR_CKE_WIDTH-1 downto 0);
  ddr3_dm_o                                  : out   std_logic_vector(c_DDR_DM_WIDTH-1 downto 0);
  ddr3_odt_o                                 : out   std_logic_vector(c_DDR_ODT_WIDTH-1 downto 0);

  -- PCIe transceivers
  pci_exp_rxp_i                              : in  std_logic_vector(c_PCIELANES - 1 downto 0);
  pci_exp_rxn_i                              : in  std_logic_vector(c_PCIELANES - 1 downto 0);
  pci_exp_txp_o                              : out std_logic_vector(c_PCIELANES - 1 downto 0);
  pci_exp_txn_o                              : out std_logic_vector(c_PCIELANES - 1 downto 0);

  -- PCI clock and reset signals
  pcie_clk_p_i                               : in std_logic;
  pcie_clk_n_i                               : in std_logic;

  ---------------------------------------------------------------------------
  -- User LEDs
  ---------------------------------------------------------------------------
  leds_o                                     : out std_logic_vector(2 downto 0);

  ---------------------------------------------------------------------------
  -- FMC interface
  ---------------------------------------------------------------------------

  board_i2c_scl_b                            : inout std_logic;
  board_i2c_sda_b                            : inout std_logic;

  ---------------------------------------------------------------------------
  -- Flash memory SPI interface
  ---------------------------------------------------------------------------
  --
  -- spi_sclk_o                              : out std_logic;
  -- spi_cs_n_o                              : out std_logic;
  -- spi_mosi_o                              : out std_logic;
  -- spi_miso_i                              : in  std_logic := '0';

  ---------------------------------------------------------------------------
  -- P2P GT pins
  ---------------------------------------------------------------------------
  -- P2P
  p2p_gt_rx_p_i                              : in    std_logic_vector(g_NUM_P2P_GTS+g_P2P_GT_START_ID-1 downto g_P2P_GT_START_ID);
  p2p_gt_rx_n_i                              : in    std_logic_vector(g_NUM_P2P_GTS+g_P2P_GT_START_ID-1 downto g_P2P_GT_START_ID);
  p2p_gt_tx_p_o                              : out   std_logic_vector(g_NUM_P2P_GTS+g_P2P_GT_START_ID-1 downto g_P2P_GT_START_ID);
  p2p_gt_tx_n_o                              : out   std_logic_vector(g_NUM_P2P_GTS+g_P2P_GT_START_ID-1 downto g_P2P_GT_START_ID);

  ---------------------------------------------------------------------------
  -- FMC slot 0 - CAEN 4 SFP+
  ---------------------------------------------------------------------------

  fmc0_sfp_rx_p_i                            : in    std_logic_vector(3 downto 0);
  fmc0_sfp_rx_n_i                            : in    std_logic_vector(3 downto 0);
  fmc0_sfp_tx_p_o                            : out   std_logic_vector(3 downto 0);
  fmc0_sfp_tx_n_o                            : out   std_logic_vector(3 downto 0);

  fmc0_sfp_scl_b                             : inout std_logic_vector(3 downto 0);
  fmc0_sfp_sda_b                             : inout std_logic_vector(3 downto 0);
  fmc0_sfp_mod_abs_i                         : in    std_logic_vector(3 downto 0);
  fmc0_sfp_rx_los_i                          : in    std_logic_vector(3 downto 0);
  fmc0_sfp_tx_disable_o                      : out   std_logic_vector(3 downto 0);
  fmc0_sfp_tx_fault_i                        : in    std_logic_vector(3 downto 0);
  fmc0_sfp_rs0_o                             : out   std_logic_vector(3 downto 0);
  fmc0_sfp_rs1_o                             : out   std_logic_vector(3 downto 0);

  fmc0_si570_clk_p_i                         : in    std_logic;
  fmc0_si570_clk_n_i                         : in    std_logic;
  fmc0_si570_scl_b                           : inout std_logic;
  fmc0_si570_sda_b                           : inout std_logic;

  ---------------------------------------------------------------------------
  -- FMC slot 0 management
  ---------------------------------------------------------------------------
  fmc0_prsnt_m2c_n_i                         : in    std_logic;       -- Mezzanine present (active low)
  -- fmc0_scl_b         : inout std_logic;       -- Mezzanine system I2C clock (EEPROM)
  -- fmc0_sda_b         : inout std_logic        -- Mezzanine system I2C data (EEPROM)

  ---------------------------------------------------------------------------
  -- FMC slot 1 management
  ---------------------------------------------------------------------------
  fmc1_prsnt_m2c_n_i                         : in    std_logic;       -- Mezzanine present (active low)
  -- fmc1_scl_b         : inout std_logic;       -- Mezzanine system I2C clock (EEPROM)
  -- fmc1_sda_b         : inout std_logic        -- Mezzanine system I2C data (EEPROM)

  ---------------------------------------------------------------------------
  -- RTM LAMP board pins
  ---------------------------------------------------------------------------

  ---------------------------------------------------------------------------
  -- RTM ADC interface
  ---------------------------------------------------------------------------
  rtmlamp_adc_cnv_o                          : out   std_logic;

  rtmlamp_adc_octo_sck_p_o                   : out   std_logic;
  rtmlamp_adc_octo_sck_n_o                   : out   std_logic;
  rtmlamp_adc_octo_sck_ret_p_i               : in    std_logic;
  rtmlamp_adc_octo_sck_ret_n_i               : in    std_logic;
  rtmlamp_adc_octo_sdoa_p_i                  : in    std_logic;
  rtmlamp_adc_octo_sdoa_n_i                  : in    std_logic;
  rtmlamp_adc_octo_sdob_p_i                  : in    std_logic;
  rtmlamp_adc_octo_sdob_n_i                  : in    std_logic;
  rtmlamp_adc_octo_sdoc_p_i                  : in    std_logic;
  rtmlamp_adc_octo_sdoc_n_i                  : in    std_logic;
  rtmlamp_adc_octo_sdod_p_i                  : in    std_logic;
  rtmlamp_adc_octo_sdod_n_i                  : in    std_logic;

  -- AFCv4. Only used when g_ADC_CHANNELS > 8
  rtmlamp_adc_quad_sck_p_o                   : out   std_logic;
  rtmlamp_adc_quad_sck_n_o                   : out   std_logic;
  rtmlamp_adc_quad_sck_ret_p_i               : in    std_logic := '0';
  rtmlamp_adc_quad_sck_ret_n_i               : in    std_logic := '0';
  rtmlamp_adc_quad_sdoa_p_i                  : in    std_logic := '0';
  rtmlamp_adc_quad_sdoa_n_i                  : in    std_logic := '0';
  rtmlamp_adc_quad_sdoc_p_i                  : in    std_logic := '0';
  rtmlamp_adc_quad_sdoc_n_i                  : in    std_logic := '0';

  ---------------------------------------------------------------------------
  -- RTM DAC interface
  ---------------------------------------------------------------------------
  rtmlamp_dac_ldac_n_o                       : out  std_logic;
  rtmlamp_dac_cs_n_o                         : out  std_logic;
  rtmlamp_dac_sck_o                          : out  std_logic;
  rtmlamp_dac_sdi_o                          : out  std_logic_vector(g_DAC_CHANNELS-1 downto 0);

  ---------------------------------------------------------------------------
  -- RTM Serial registers interface
  ---------------------------------------------------------------------------
  rtmlamp_amp_shift_clk_o                    : out   std_logic;
  -- AFCv4
  rtmlamp_amp_shift_dout_i                   : in    std_logic := '0';
  rtmlamp_amp_shift_pl_o                     : out   std_logic;

  -- AFCv4
  rtmlamp_amp_shift_oe_n_o                   : out   std_logic;

  rtmlamp_amp_shift_din_o                    : out   std_logic;
  rtmlamp_amp_shift_str_o                    : out   std_logic
);
end entity afc_ref_fofb_ctrl_gen;

architecture top of afc_ref_fofb_ctrl_gen is

  -----------------------------------------------------------------------------
  -- General constants
  -----------------------------------------------------------------------------
  constant c_SYS_CLOCK_FREQ                  : natural := 100000000;
  constant c_REF_CLOCK_FREQ                  : natural := 69306000; -- RF*5/36
  constant c_FAST_SPI_FREQ                   : natural := 400000000;
  constant c_ADC_SCLK_FREQ                   : natural := 100000000;
  constant c_DAC_SCLK_FREQ                   : natural := 25000000;
  constant c_USE_REF_CLOCK                   : boolean := true;
  constant c_ADC_CHANNELS                    : natural := g_ADC_CHANNELS;
  constant c_DAC_CHANNELS                    : natural := g_DAC_CHANNELS;

  constant c_NUM_USER_IRQ                    : natural := 1;

  -- RTM LAMP IDs
  constant c_RTM_LAMP_NUM_CORES              : natural := 1;


  -- FMC 4SFP IDs
  constant c_NUM_SFPS_FOFB                   : integer := 4; -- maximum of 4 supported
  constant c_FMC_4SFP_NUM_CORES              : natural := 1;

  -- P2P GT IDs
  constant c_NUM_P2P_GTS_FOFB                : integer := 4; -- maximum of 4 supported

  -- FOFB CC
  constant c_NUM_FOFC_CC_CORES               : natural := 2;

  constant c_BPMS                            : integer := 1;
  constant c_FAI_DW                          : integer := 16;
  constant c_DMUX                            : integer := 2;
  constant c_LANE_COUNT                      : integer := c_NUM_SFPS_FOFB;
  constant c_USE_CHIPSCOPE                   : boolean := true;

  constant c_AFC_SI57x_I2C_FREQ              : integer := 400000;
  constant c_AFC_SI57x_INIT_OSC              : boolean := true;
  constant c_AFC_SI57x_INIT_RFREQ_VALUE      : std_logic_vector(37 downto 0) := "00" & x"2bc0af3b8";
  constant c_AFC_SI57x_INIT_N1_VALUE         : std_logic_vector(6 downto 0) := "0000111";
  constant c_AFC_SI57x_INIT_HS_VALUE         : std_logic_vector(2 downto 0) := "000";

  -----------------------------------------------------------------------------
  -- RTM signals
  -----------------------------------------------------------------------------

  signal clk_rtm_ref                         : std_logic;
  signal clk_rtm_ref_rstn                    : std_logic;

  signal rtmlamp_adc_start                   : std_logic := '1';
  signal rtmlamp_adc_data                    : t_16b_word_array(c_ADC_CHANNELS-1 downto 0);
  signal rtmlamp_adc_valid                   : std_logic_vector(c_ADC_CHANNELS-1 downto 0);

  signal rtmlamp_dac_start                   : std_logic := '1';
  signal rtmlamp_dac_data                    : t_16b_word_array(c_DAC_CHANNELS-1 downto 0);
  signal rtmlamp_dac_ready                   : std_logic;
  signal rtmlamp_dac_done_pp                 : std_logic;

  -----------------------------------------------------------------------------
  -- AFC Si57x signals
  -----------------------------------------------------------------------------

  signal afc_si57x_sta_reconfig_done         : std_logic;
  signal afc_si57x_sta_reconfig_done_pp      : std_logic;
  signal afc_si57x_reconfig_rst              : std_logic;
  signal afc_si57x_reconfig_rst_n            : std_logic;

  signal afc_si57x_ext_wr                    : std_logic;
  signal afc_si57x_ext_rfreq_value           : std_logic_vector(37 downto 0);
  signal afc_si57x_ext_n1_value              : std_logic_vector(6 downto 0);
  signal afc_si57x_ext_hs_value              : std_logic_vector(2 downto 0);

  -----------------------------------------------------------------------------
  -- FOFB CC signals
  -----------------------------------------------------------------------------

  type t_fofb_cc_logic_array is array (natural range <>) of std_logic;
  type t_fofb_cc_data_fai_array is array (natural range <>) of std_logic_vector(c_FAI_DW-1 downto 0);
  type t_fofb_cc_buf_addr_array is array (natural range <>) of std_logic_vector(NodeW downto 0);
  type t_fofb_cc_buf_data_array is array (natural range <>) of std_logic_vector(63 downto 0);
  type t_fofb_cc_node_mask_array is array (natural range <>) of std_logic_vector(NodeNum-1 downto 0);
  type t_fofb_cc_std32_array is array (natural range <>) of std_logic_vector(31 downto 0);
  type t_fofb_cc_std4_array is array (natural range <>) of std_logic_vector(3 downto 0);
  type t_fofb_cc_fod_data_array is array (natural range <>) of std_logic_vector((32*PacketSize-1) downto 0);
  type t_fofb_cc_fod_val_array is array (natural range <>) of std_logic_vector(c_LANE_COUNT-1 downto 0);
  type t_fofb_cc_rio_array is array (natural range <>) of std_logic_vector(c_LANE_COUNT-1 downto 0);

  signal fai_fa_block_start                  : t_fofb_cc_logic_array(c_NUM_FOFC_CC_CORES-1 downto 0) :=
                                                    (others => '0');
  signal fai_fa_data_valid                   : t_fofb_cc_logic_array(c_NUM_FOFC_CC_CORES-1 downto 0) :=
                                                    (others => '0');
  signal fai_fa_d                            : t_fofb_cc_data_fai_array(c_NUM_FOFC_CC_CORES-1 downto 0) :=
                                                    (others => (others => '0'));

  signal fai_sim_data_sel                    : t_fofb_cc_std4_array(c_NUM_FOFC_CC_CORES-1 downto 0) :=
                                                    (others => (others => '0'));
  signal fai_sim_enable                      : t_fofb_cc_logic_array(c_NUM_FOFC_CC_CORES-1 downto 0) :=
                                                    (others => '1');
  signal fai_sim_trigger                     : t_fofb_cc_logic_array(c_NUM_FOFC_CC_CORES-1 downto 0) :=
                                                    (others => '0');
  signal fai_sim_trigger_internal            : t_fofb_cc_logic_array(c_NUM_FOFC_CC_CORES-1 downto 0) :=
                                                    (others => '0');
  signal fai_sim_armed                       : t_fofb_cc_logic_array(c_NUM_FOFC_CC_CORES-1 downto 0);

   signal fai_cfg_clk                        : t_fofb_cc_logic_array(c_NUM_FOFC_CC_CORES-1 downto 0) :=
                                                    (others => '0');
   signal fai_cfg_val                        : t_fofb_cc_std32_array(c_NUM_FOFC_CC_CORES-1 downto 0) :=
                                                    (others => (others => '0'));


  signal fofb_userclk                        : t_fofb_cc_logic_array(c_NUM_FOFC_CC_CORES-1 downto 0) :=
                                                    (others => '0');
  signal fofb_userrst                        : t_fofb_cc_logic_array(c_NUM_FOFC_CC_CORES-1 downto 0) :=
                                                    (others => '0');
  signal fofb_userrst_n                      : t_fofb_cc_logic_array(c_NUM_FOFC_CC_CORES-1 downto 0) :=
                                                    (others => '0');
  signal timeframe_start                     : t_fofb_cc_logic_array(c_NUM_FOFC_CC_CORES-1 downto 0) :=
                                                    (others => '0');
  signal timeframe_end                       : t_fofb_cc_logic_array(c_NUM_FOFC_CC_CORES-1 downto 0) :=
                                                    (others => '0');
  signal fofb_dma_ok                         : t_fofb_cc_logic_array(c_NUM_FOFC_CC_CORES-1 downto 0) :=
                                                    (others => '0');
  signal fofb_node_mask                      : t_fofb_cc_node_mask_array(c_NUM_FOFC_CC_CORES-1 downto 0) :=
                                                    (others => (others => '0'));
  signal fofb_timestamp_val                  : t_fofb_cc_std32_array(c_NUM_FOFC_CC_CORES-1 downto 0) :=
                                                    (others => (others => '0'));
  signal fofb_link_status                    : t_fofb_cc_std32_array(c_NUM_FOFC_CC_CORES-1 downto 0) :=
                                                    (others => (others => '0'));

  signal fofb_fod_dat                        : t_fofb_cc_fod_data_array(c_NUM_FOFC_CC_CORES-1 downto 0);
  signal fofb_fod_dat_val                    : t_fofb_cc_fod_val_array(c_NUM_FOFC_CC_CORES-1 downto 0);
  signal fofb_rio_rx_p                       : t_fofb_cc_rio_array(c_NUM_FOFC_CC_CORES-1 downto 0);
  signal fofb_rio_rx_n                       : t_fofb_cc_rio_array(c_NUM_FOFC_CC_CORES-1 downto 0);
  signal fofb_rio_tx_p                       : t_fofb_cc_rio_array(c_NUM_FOFC_CC_CORES-1 downto 0);
  signal fofb_rio_tx_n                       : t_fofb_cc_rio_array(c_NUM_FOFC_CC_CORES-1 downto 0);
  signal fofb_rio_tx_disable                 : t_fofb_cc_rio_array(c_NUM_FOFC_CC_CORES-1 downto 0);

  signal fofb_ref_clk_p                      : t_fofb_cc_logic_array(c_NUM_FOFC_CC_CORES-1 downto 0);
  signal fofb_ref_clk_n                      : t_fofb_cc_logic_array(c_NUM_FOFC_CC_CORES-1 downto 0);

  -----------------------------------------------------------------------------
  -- FMC 0 4SFP CAEN signals
  -----------------------------------------------------------------------------

  -- Wishbone bus from user afc_base_acq to FMC mezzanine
  signal wb_fmc_master_out                   : t_wishbone_master_out_array(c_FMC_4SFP_NUM_CORES-1 downto 0);
  signal wb_fmc_master_in                    : t_wishbone_master_in_array(c_FMC_4SFP_NUM_CORES-1 downto 0);

  signal fmc0_fpga_sfp_rx_p                  :  std_logic_vector(3 downto 0);
  signal fmc0_fpga_sfp_rx_n                  :  std_logic_vector(3 downto 0);
  signal fmc0_fpga_sfp_tx_p                  :  std_logic_vector(3 downto 0);
  signal fmc0_fpga_sfp_tx_n                  :  std_logic_vector(3 downto 0);

  signal fmc0_fpga_sfp_mod_abs               :  std_logic_vector(3 downto 0);
  signal fmc0_fpga_sfp_rx_los                :  std_logic_vector(3 downto 0);
  signal fmc0_fpga_sfp_tx_disable            :  std_logic_vector(3 downto 0);
  signal fmc0_fpga_sfp_tx_fault              :  std_logic_vector(3 downto 0);
  signal fmc0_fpga_sfp_rs0                   :  std_logic_vector(3 downto 0);
  signal fmc0_fpga_sfp_rs1                   :  std_logic_vector(3 downto 0);

  signal fmc0_fpga_si570_clk_p               :  std_logic;
  signal fmc0_fpga_si570_clk_n               :  std_logic;

  -----------------------------------------------------------------------------
  -- FMC 0 CAEN Si57x signals
  -----------------------------------------------------------------------------

  signal fmc0_si57x_sta_reconfig_done        : std_logic;
  signal fmc0_si57x_sta_reconfig_done_pp     : std_logic;
  signal fmc0_si57x_reconfig_rst             : std_logic := '0';
  signal fmc0_si57x_reconfig_rst_n           : std_logic := '1';

  signal fmc0_si57x_ext_wr                   : std_logic;
  signal fmc0_si57x_ext_rfreq_value          : std_logic_vector(37 downto 0);
  signal fmc0_si57x_ext_n1_value             : std_logic_vector(6 downto 0);
  signal fmc0_si57x_ext_hs_value             : std_logic_vector(2 downto 0);

  -----------------------------------------------------------------------------
  -- Acquisition signals
  -----------------------------------------------------------------------------

  constant c_ACQ_FIFO_SIZE                   : natural := 256;

  -- Number of acquisition cores. Same as the number of DCC
  constant c_ACQ_NUM_CORES                   : natural := c_NUM_FOFC_CC_CORES + c_RTM_LAMP_NUM_CORES;
  -- Acquisition core IDs
  constant c_ACQ_CORE_0_ID                   : natural := 0;
  constant c_ACQ_CORE_1_ID                   : natural := 1;
  constant c_ACQ_CORE_2_ID                   : natural := 2;

  -- Type of DDR3 core interface
  constant c_DDR_INTERFACE_TYPE              : string := "AXIS";

  constant c_ACQ_ADDR_WIDTH                  : natural := c_DDR_ADDR_WIDTH;
  -- Post-Mortem Acq Cores dont need Multishot. So, set them to 0
  constant c_ACQ_MULTISHOT_RAM_SIZE          : t_property_value_array(c_ACQ_NUM_CORES-1 downto 0) := (others => 512);
  constant c_ACQ_DDR_ADDR_RES_WIDTH          : natural := 32;
  constant c_ACQ_DDR_ADDR_DIFF               : natural := c_ACQ_DDR_ADDR_RES_WIDTH-c_ddr_addr_width;

  -- Acquisition channels IDs
  constant c_ACQ_DCC_ID                      : natural := 0;
  constant c_ACQ_RTM_LAMP_ID                 : natural := 1;
  -- Number of channels per acquisition core
  constant c_ACQ_NUM_CHANNELS                : natural := 2;

  constant c_FACQ_PARAMS_DCC                 : t_facq_chan_param := (
    width                                    => to_unsigned(128, c_ACQ_CHAN_CMPLT_WIDTH_LOG2),
    num_atoms                                => to_unsigned(4, c_ACQ_NUM_ATOMS_WIDTH_LOG2),
    atom_width                               => to_unsigned(32, c_ACQ_ATOM_WIDTH_LOG2) -- 2^5 = 16-bit
  );

  constant c_FACQ_PARAMS_RTM_LAMP            : t_facq_chan_param := (
    width                                    => to_unsigned(256, c_ACQ_CHAN_CMPLT_WIDTH_LOG2),
    num_atoms                                => to_unsigned(16, c_ACQ_NUM_ATOMS_WIDTH_LOG2),
    atom_width                               => to_unsigned(16, c_ACQ_ATOM_WIDTH_LOG2)
  );

  constant c_FACQ_CHANNELS                   : t_facq_chan_param_array(c_ACQ_NUM_CHANNELS-1 downto 0) :=
  (
    c_ACQ_DCC_ID            => c_FACQ_PARAMS_DCC,
    c_ACQ_RTM_LAMP_ID       => c_FACQ_PARAMS_RTM_LAMP
  );

  signal acq_chan_array                      : t_facq_chan_array2d(c_ACQ_NUM_CORES-1 downto 0, c_ACQ_NUM_CHANNELS-1 downto 0);

  -- Acquisition clocks
  signal fs_clk_array                        : std_logic_vector(c_ACQ_NUM_CORES-1 downto 0);
  signal fs_rst_n_array                      : std_logic_vector(c_ACQ_NUM_CORES-1 downto 0);
  signal fs_rst_array                        : std_logic_vector(c_ACQ_NUM_CORES-1 downto 0);
  signal fs_ce_array                         : std_logic_vector(c_ACQ_NUM_CORES-1 downto 0);

  -----------------------------------------------------------------------------
  -- RTM Data signals
  -----------------------------------------------------------------------------

  type t_acq_logic_array is array (natural range <>) of std_logic;
  type t_acq_rtmlamp_data_array is array (natural range <>) of std_logic_vector(to_integer(c_FACQ_PARAMS_RTM_LAMP.width)-1 downto 0);

  signal acq_rtmlamp_data                    : t_acq_rtmlamp_data_array(c_ACQ_NUM_CORES-1 downto 0);
  signal acq_rtmlamp_data_valid              : t_acq_logic_array(c_ACQ_NUM_CORES-1 downto 0);

  -----------------------------------------------------------------------------
  -- Trigger signals
  -----------------------------------------------------------------------------

  -- Trigger core IDs
  constant c_TRIG_MUX_0_ID                   : natural  := 0;
  constant c_TRIG_MUX_1_ID                   : natural  := 1;
  constant c_TRIG_MUX_2_ID                   : natural  := 2;

  constant c_TRIG_MUX_NUM_CORES              : natural  := 3;

  constant c_TRIG_MUX_SYNC_EDGE              : string   := "positive";

  constant c_TRIG_MUX_ID_START               : natural  := c_ACQ_NUM_CHANNELS;
  constant c_TRIG_MUX_FOFB_SYNC_ID           : natural  := c_TRIG_MUX_ID_START;

  constant c_TRIG_MUX_NUM_CHANNELS           : natural  := 10; -- Arbitrary for now

  constant c_TRIG_MUX_INTERN_NUM             : positive := c_TRIG_MUX_NUM_CHANNELS + c_ACQ_NUM_CHANNELS;
  constant c_TRIG_MUX_RCV_INTERN_NUM         : positive := 2; -- Arbitrary
  constant c_TRIG_MUX_MUX_NUM_CORES          : natural  := c_ACQ_NUM_CORES;
  constant c_TRIG_MUX_OUT_RESOLVER           : string   := "fanout";
  constant c_TRIG_MUX_IN_RESOLVER            : string   := "or";
  constant c_TRIG_MUX_WITH_INPUT_SYNC        : boolean  := true;
  constant c_TRIG_MUX_WITH_OUTPUT_SYNC       : boolean  := true;

  -- Trigger RCV intern IDs
  constant c_TRIG_RCV_INTERN_CHAN_0_ID       : natural := 0; -- Internal Channel 1
  constant c_TRIG_RCV_INTERN_CHAN_1_ID       : natural := 1; -- Internal Channel 2

  signal trig_ref_clk                        : std_logic;
  signal trig_ref_rst_n                      : std_logic;

  signal trig_rcv_intern                     : t_trig_channel_array2d(c_TRIG_MUX_NUM_CORES-1 downto 0, c_TRIG_MUX_RCV_INTERN_NUM-1 downto 0);
  signal trig_pulse_transm                   : t_trig_channel_array2d(c_TRIG_MUX_NUM_CORES-1 downto 0, c_TRIG_MUX_INTERN_NUM-1 downto 0);
  signal trig_pulse_rcv                      : t_trig_channel_array2d(c_TRIG_MUX_NUM_CORES-1 downto 0, c_TRIG_MUX_INTERN_NUM-1 downto 0);

  signal trig_acq_channel                    : t_trig_channel_array2d(c_TRIG_MUX_NUM_CORES-1 downto 0, c_TRIG_MUX_RCV_INTERN_NUM-1 downto 0);

  -----------------------------------------------------------------------------
  -- User Signals
  -----------------------------------------------------------------------------

  constant c_FOFB_CC_FMC_ID                  : natural := 0;
  constant c_FOFB_CC_P2P_ID                  : natural := 1;
  constant c_RTM_LAMP_ID                     : natural := 2;
  constant c_USER_NUM_CORES                  : natural := c_NUM_FOFC_CC_CORES + c_RTM_LAMP_NUM_CORES;

  constant c_USER_SDB_RECORD_ARRAY           : t_sdb_record_array(c_USER_NUM_CORES-1 downto 0) :=
  (
    c_FOFB_CC_FMC_ID           => f_sdb_auto_device(c_xwb_fofb_cc_regs_sdb,        true),
    c_FOFB_CC_P2P_ID           => f_sdb_auto_device(c_xwb_fofb_cc_regs_sdb,        true),
    c_RTM_LAMP_ID              => f_sdb_auto_device(c_xwb_rtm_lamp_regs_sdb,       true)
  );

  -----------------------------------------------------------------------------
  -- Signals
  -----------------------------------------------------------------------------

  signal clk_sys                             : std_logic;
  signal clk_sys_rstn                        : std_logic;
  signal clk_sys_rst                         : std_logic;
  signal clk_aux                             : std_logic;
  signal clk_aux_rstn                        : std_logic;
  signal clk_aux_rst                         : std_logic;
  signal clk_aux_raw                         : std_logic;
  signal clk_aux_raw_rstn                    : std_logic;
  signal clk_aux_raw_rst                     : std_logic;
  signal clk_fp2_clk1_p                      : std_logic;
  signal clk_fp2_clk1_n                      : std_logic;
  signal clk_200mhz                          : std_logic;
  signal clk_200mhz_rstn                     : std_logic;
  signal clk_fast_spi                        : std_logic;
  signal clk_fast_spi_rstn                   : std_logic;
  signal clk_pcie                            : std_logic;
  signal clk_pcie_rstn                       : std_logic;
  signal clk_user2                           : std_logic;
  signal clk_user2_rstn                      : std_logic;
  signal clk_trig_ref                        : std_logic;
  signal clk_trig_ref_rstn                   : std_logic;

  signal pcb_rev_id                          : std_logic_vector(3 downto 0);

  signal irq_user                            : std_logic_vector(c_NUM_USER_IRQ + 5 downto 6) := (others => '0');

  signal trig_out                            : t_trig_channel_array(c_NUM_TRIG-1 downto 0);
  signal trig_in                             : t_trig_channel_array(c_NUM_TRIG-1 downto 0) := (others => c_TRIG_CHANNEL_DUMMY);

  signal trig_dbg                            : std_logic_vector(c_NUM_TRIG-1 downto 0);
  signal trig_dbg_data_sync                  : std_logic_vector(c_NUM_TRIG-1 downto 0);
  signal trig_dbg_data_degliteched           : std_logic_vector(c_NUM_TRIG-1 downto 0);

  signal user_wb_out                         : t_wishbone_master_out_array(c_USER_NUM_CORES-1 downto 0);
  signal user_wb_in                          : t_wishbone_master_in_array(c_USER_NUM_CORES-1 downto 0) := (others => c_DUMMY_WB_MASTER_IN);

  signal fpga_si570_oe                       : std_logic;
  signal fofb_sysreset_n                     : std_logic_vector(c_NUM_FOFC_CC_CORES-1 downto 0);
  signal fofb_reset_n                        : std_logic := '1';
  signal fofb_reset                          : std_logic := '0';

  -------------------------------------------------------------------------------
  ---- VIO/ILA signals
  -------------------------------------------------------------------------------

  --signal probe_in0                           : std_logic_vector(63 downto 0);
  --signal probe_in1                           : std_logic_vector(63 downto 0);

  --signal probe_out0                          : std_logic_vector(63 downto 0);
  --signal probe_out1                          : std_logic_vector(63 downto 0);

  --signal data                                : std_logic_vector(255 downto 0);
  --signal trig0                               : std_logic_vector(7 downto 0);

begin

  assert (g_BOARD = "AFCv4" or g_BOARD = "AFCv3")
    report "[afc_ref_fofb_ctrl_gen] g_BOARD value(" & g_BOARD &
    ") unsuppoted. Must be one of AFCv4 or AFCv3"
    severity failure;

  gen_afcv4_base : if g_BOARD = "AFCv4" generate
    cmp_afc_base_acq : afcv4_base_acq
      generic map (
        g_DIVCLK_DIVIDE                          => 5,
        g_CLKBOUT_MULT_F                         => 48,
        g_CLK0_DIVIDE_F                          => 12,   -- 100 MHz
        g_CLK1_DIVIDE                            => 6,    -- Must be 200 MHz
        g_CLK2_DIVIDE                            => 3,    -- 400 MHz
        g_SYS_CLOCK_FREQ                         => c_SYS_CLOCK_FREQ,
        -- AFC Si57x parameters
        g_AFC_SI57x_I2C_FREQ                     => c_AFC_SI57x_I2C_FREQ,
        -- Whether or not to initialize oscilator with the specified values
        g_AFC_SI57x_INIT_OSC                     => c_AFC_SI57x_INIT_OSC,
        -- Init Oscillator values
        g_AFC_SI57x_INIT_RFREQ_VALUE             => c_AFC_SI57x_INIT_RFREQ_VALUE,
        g_AFC_SI57x_INIT_N1_VALUE                => c_AFC_SI57x_INIT_N1_VALUE,
        g_AFC_SI57x_INIT_HS_VALUE                => c_AFC_SI57x_INIT_HS_VALUE,
        --  If true, instantiate a VIC/UART/DIAG/SPI.
        g_WITH_VIC                               => true,
        g_WITH_UART_MASTER                       => true,
        g_WITH_DIAG                              => true,
        g_WITH_TRIGGER                           => true,
        g_WITH_SPI                               => false,
        g_WITH_AFC_SI57x                         => true,
        g_WITH_BOARD_I2C                         => true,
        g_ACQ_NUM_CORES                          => c_ACQ_NUM_CORES,
        g_TRIG_MUX_NUM_CORES                     => c_TRIG_MUX_NUM_CORES,
        g_USER_NUM_CORES                         => c_USER_NUM_CORES,
        -- Acquisition module generics
        g_ACQ_NUM_CHANNELS                       => c_ACQ_NUM_CHANNELS,
        g_ACQ_MULTISHOT_RAM_SIZE                 => c_ACQ_MULTISHOT_RAM_SIZE,
        g_ACQ_FIFO_FC_SIZE                       => c_ACQ_FIFO_SIZE,
        g_FACQ_CHANNELS                          => c_FACQ_CHANNELS,
        -- Trigger Mux generic
        g_TRIG_MUX_SYNC_EDGE                     => c_TRIG_MUX_SYNC_EDGE,
        g_TRIG_MUX_INTERN_NUM                    => c_TRIG_MUX_INTERN_NUM,
        g_TRIG_MUX_RCV_INTERN_NUM                => c_TRIG_MUX_RCV_INTERN_NUM,
        g_TRIG_MUX_OUT_RESOLVER                  => c_TRIG_MUX_OUT_RESOLVER,
        g_TRIG_MUX_IN_RESOLVER                   => c_TRIG_MUX_IN_RESOLVER,
        g_TRIG_MUX_WITH_INPUT_SYNC               => c_TRIG_MUX_WITH_INPUT_SYNC,
        g_TRIG_MUX_WITH_OUTPUT_SYNC              => c_TRIG_MUX_WITH_OUTPUT_SYNC,
        -- User generic. Must be g_USER_NUM_CORES length
        g_USER_SDB_RECORD_ARRAY                  => c_USER_SDB_RECORD_ARRAY,
        -- Auxiliary clock used to sync incoming triggers in the trigger module.
        -- If false, trigger will be synch'ed with clk_sys
        g_WITH_AUX_CLK                           => true,
        -- Number of user interrupts
        g_NUM_USER_IRQ                           => c_NUM_USER_IRQ
      )
      port map (
        ---------------------------------------------------------------------------
        -- Clocking pins
        ---------------------------------------------------------------------------
        sys_clk_p_i                              => sys_clk_p_i,
        sys_clk_n_i                              => sys_clk_n_i,

        aux_clk_p_i                              => aux_clk_p_i,
        aux_clk_n_i                              => aux_clk_n_i,

        afc_fp2_clk1_p_i                         => afc_fp2_clk1_p_i,
        afc_fp2_clk1_n_i                         => afc_fp2_clk1_n_i,

        ---------------------------------------------------------------------------
        -- Reset Button
        ---------------------------------------------------------------------------
        sys_rst_button_n_i                       => sys_rst_button_n_i,

        ---------------------------------------------------------------------------
        -- UART pins
        ---------------------------------------------------------------------------

        uart_rxd_i                               => uart_rxd_i,
        uart_txd_o                               => uart_txd_o,

        ---------------------------------------------------------------------------
        -- Trigger pins
        ---------------------------------------------------------------------------
        trig_dir_o                               => trig_dir_o,
        trig_i                                   => trig_i,
        trig_o                                   => trig_o,

        ---------------------------------------------------------------------------
        -- AFC Diagnostics
        ---------------------------------------------------------------------------

        diag_spi_cs_i                            => diag_spi_cs_i,
        diag_spi_si_i                            => diag_spi_si_i,
        diag_spi_so_o                            => diag_spi_so_o,
        diag_spi_clk_i                           => diag_spi_clk_i,

        ---------------------------------------------------------------------------
        -- AFC I2C.
        ---------------------------------------------------------------------------
        -- Si57x oscillator
        afc_si57x_scl_b                          => afc_si57x_scl_b,
        afc_si57x_sda_b                          => afc_si57x_sda_b,

        -- Si57x oscillator output enable
        afc_si57x_oe_o                           => afc_si57x_oe_o,

        ---------------------------------------------------------------------------
        -- PCIe pins
        ---------------------------------------------------------------------------

        -- DDR3 memory pins
        ddr3_dq_b                                => ddr3_dq_b,
        ddr3_dqs_p_b                             => ddr3_dqs_p_b,
        ddr3_dqs_n_b                             => ddr3_dqs_n_b,
        ddr3_addr_o                              => ddr3_addr_o,
        ddr3_ba_o                                => ddr3_ba_o,
        ddr3_cs_n_o                              => ddr3_cs_n_o,
        ddr3_ras_n_o                             => ddr3_ras_n_o,
        ddr3_cas_n_o                             => ddr3_cas_n_o,
        ddr3_we_n_o                              => ddr3_we_n_o,
        ddr3_reset_n_o                           => ddr3_reset_n_o,
        ddr3_ck_p_o                              => ddr3_ck_p_o,
        ddr3_ck_n_o                              => ddr3_ck_n_o,
        ddr3_cke_o                               => ddr3_cke_o,
        ddr3_dm_o                                => ddr3_dm_o,
        ddr3_odt_o                               => ddr3_odt_o,

        -- PCIe transceivers
        pci_exp_rxp_i                            => pci_exp_rxp_i,
        pci_exp_rxn_i                            => pci_exp_rxn_i,
        pci_exp_txp_o                            => pci_exp_txp_o,
        pci_exp_txn_o                            => pci_exp_txn_o,

        -- PCI clock and reset signals
        pcie_clk_p_i                             => pcie_clk_p_i,
        pcie_clk_n_i                             => pcie_clk_n_i,

        ---------------------------------------------------------------------------
        -- User LEDs
        ---------------------------------------------------------------------------
        leds_o                                   => leds_o,

        ---------------------------------------------------------------------------
        -- FMC interface
        ---------------------------------------------------------------------------

        board_i2c_scl_b                          => board_i2c_scl_b,
        board_i2c_sda_b                          => board_i2c_sda_b,

        ---------------------------------------------------------------------------
        -- Flash memory SPI interface
        ---------------------------------------------------------------------------
       --
       -- spi_sclk_o                               => spi_sclk_o,
       -- spi_cs_n_o                               => spi_cs_n_o,
       -- spi_mosi_o                               => spi_mosi_o,
       -- spi_miso_i                               => spi_miso_i,
       --
        ---------------------------------------------------------------------------
        -- Miscellanous AFC pins
        ---------------------------------------------------------------------------

        -- PCB version
        pcb_rev_id_i                             => pcb_rev_id,

        ---------------------------------------------------------------------------
        --  User part
        ---------------------------------------------------------------------------

        --  Clocks and reset.
        clk_sys_o                                => clk_sys,
        rst_sys_n_o                              => clk_sys_rstn,

        clk_aux_o                                => clk_aux,
        rst_aux_n_o                              => clk_aux_rstn,

        clk_aux_raw_o                            => clk_aux_raw,
        rst_aux_raw_n_o                          => clk_aux_raw_rstn,

        clk_200mhz_o                             => clk_200mhz,
        rst_200mhz_n_o                           => clk_200mhz_rstn,

        clk_pcie_o                               => clk_pcie,
        rst_pcie_n_o                             => clk_pcie_rstn,

        clk_user2_o                              => clk_user2,
        rst_user2_n_o                            => clk_user2_rstn,

        clk_trig_ref_o                           => clk_trig_ref,
        rst_trig_ref_n_o                         => clk_trig_ref_rstn,

        clk_fp2_clk1_p_o                         => clk_fp2_clk1_p,
        clk_fp2_clk1_n_o                         => clk_fp2_clk1_n,

        --  Interrupts
        irq_user_i                               => irq_user,

        -- Acquisition
        fs_clk_array_i                           => fs_clk_array,
        fs_ce_array_i                            => fs_ce_array,
        fs_rst_n_array_i                         => fs_rst_n_array,

        acq_chan_array_i                         => acq_chan_array,

        -- Triggers                                 -- Triggers
        trig_rcv_intern_i                        => trig_rcv_intern,
        trig_pulse_transm_i                      => trig_pulse_transm,
        trig_pulse_rcv_o                         => trig_pulse_rcv,

        trig_dbg_o                               => trig_dbg,
        trig_dbg_data_sync_o                     => trig_dbg_data_sync,
        trig_dbg_data_degliteched_o              => trig_dbg_data_degliteched,

        -- AFC Si57x
        afc_si57x_ext_wr_i                       => afc_si57x_ext_wr,
        afc_si57x_ext_rfreq_value_i              => afc_si57x_ext_rfreq_value,
        afc_si57x_ext_n1_value_i                 => afc_si57x_ext_n1_value,
        afc_si57x_ext_hs_value_i                 => afc_si57x_ext_hs_value,
        afc_si57x_sta_reconfig_done_o            => afc_si57x_sta_reconfig_done,

        afc_si57x_oe_i                           => '1',
        afc_si57x_addr_i                         => "10101010",

        --  The wishbone bus from the pcie/host to the application
        --  LSB addresses are not available (used by the carrier).
        --  For the exact used addresses see SDB Description.
        --  This is a pipelined wishbone with byte granularity.
        user_wb_o                                 => user_wb_out,
        user_wb_i                                 => user_wb_in
      );
  end generate;

  gen_afcv3_base : if g_BOARD = "AFCv3" generate
    cmp_afc_base_acq : afcv3_base_acq
      generic map (
        g_DIVCLK_DIVIDE                          => 5,
        g_CLKBOUT_MULT_F                         => 48,
        g_CLK0_DIVIDE_F                          => 12,   -- 100 MHz
        g_CLK1_DIVIDE                            => 6,    -- Must be 200 MHz
        g_CLK2_DIVIDE                            => 3,    -- 400 MHz
        g_SYS_CLOCK_FREQ                         => c_SYS_CLOCK_FREQ,
        -- AFC Si57x parameters
        g_AFC_SI57x_I2C_FREQ                     => c_AFC_SI57x_I2C_FREQ,
        -- Whether or not to initialize oscilator with the specified values
        g_AFC_SI57x_INIT_OSC                     => c_AFC_SI57x_INIT_OSC,
        -- Init Oscillator values
        g_AFC_SI57x_INIT_RFREQ_VALUE             => c_AFC_SI57x_INIT_RFREQ_VALUE,
        g_AFC_SI57x_INIT_N1_VALUE                => c_AFC_SI57x_INIT_N1_VALUE,
        g_AFC_SI57x_INIT_HS_VALUE                => c_AFC_SI57x_INIT_HS_VALUE,
        --  If true, instantiate a VIC/UART/DIAG/SPI.
        g_WITH_VIC                               => true,
        g_WITH_UART_MASTER                       => true,
        g_WITH_DIAG                              => true,
        g_WITH_TRIGGER                           => true,
        g_WITH_SPI                               => false,
        g_WITH_AFC_SI57x                         => true,
        g_WITH_BOARD_I2C                         => true,
        g_ACQ_NUM_CORES                          => c_ACQ_NUM_CORES,
        g_TRIG_MUX_NUM_CORES                     => c_TRIG_MUX_NUM_CORES,
        g_USER_NUM_CORES                         => c_USER_NUM_CORES,
        -- Acquisition module generics
        g_ACQ_NUM_CHANNELS                       => c_ACQ_NUM_CHANNELS,
        g_ACQ_MULTISHOT_RAM_SIZE                 => c_ACQ_MULTISHOT_RAM_SIZE,
        g_ACQ_FIFO_FC_SIZE                       => c_ACQ_FIFO_SIZE,
        g_FACQ_CHANNELS                          => c_FACQ_CHANNELS,
        -- Trigger Mux generic
        g_TRIG_MUX_SYNC_EDGE                     => c_TRIG_MUX_SYNC_EDGE,
        g_TRIG_MUX_INTERN_NUM                    => c_TRIG_MUX_INTERN_NUM,
        g_TRIG_MUX_RCV_INTERN_NUM                => c_TRIG_MUX_RCV_INTERN_NUM,
        g_TRIG_MUX_OUT_RESOLVER                  => c_TRIG_MUX_OUT_RESOLVER,
        g_TRIG_MUX_IN_RESOLVER                   => c_TRIG_MUX_IN_RESOLVER,
        g_TRIG_MUX_WITH_INPUT_SYNC               => c_TRIG_MUX_WITH_INPUT_SYNC,
        g_TRIG_MUX_WITH_OUTPUT_SYNC              => c_TRIG_MUX_WITH_OUTPUT_SYNC,
        -- User generic. Must be g_USER_NUM_CORES length
        g_USER_SDB_RECORD_ARRAY                  => c_USER_SDB_RECORD_ARRAY,
        -- Auxiliary clock used to sync incoming triggers in the trigger module.
        -- If false, trigger will be synch'ed with clk_sys
        g_WITH_AUX_CLK                           => true,
        -- Number of user interrupts
        g_NUM_USER_IRQ                           => c_NUM_USER_IRQ
      )
      port map (
        ---------------------------------------------------------------------------
        -- Clocking pins
        ---------------------------------------------------------------------------
        sys_clk_p_i                              => sys_clk_p_i,
        sys_clk_n_i                              => sys_clk_n_i,

        aux_clk_p_i                              => aux_clk_p_i,
        aux_clk_n_i                              => aux_clk_n_i,

        afc_fp2_clk1_p_i                         => afc_fp2_clk1_p_i,
        afc_fp2_clk1_n_i                         => afc_fp2_clk1_n_i,

        ---------------------------------------------------------------------------
        -- Reset Button
        ---------------------------------------------------------------------------
        sys_rst_button_n_i                       => sys_rst_button_n_i,

        ---------------------------------------------------------------------------
        -- UART pins
        ---------------------------------------------------------------------------

        uart_rxd_i                               => uart_rxd_i,
        uart_txd_o                               => uart_txd_o,

        ---------------------------------------------------------------------------
        -- Trigger pins
        ---------------------------------------------------------------------------
        trig_dir_o                               => trig_dir_o,
        trig_b                                   => trig_b,

        ---------------------------------------------------------------------------
        -- AFC Diagnostics
        ---------------------------------------------------------------------------

        diag_spi_cs_i                            => diag_spi_cs_i,
        diag_spi_si_i                            => diag_spi_si_i,
        diag_spi_so_o                            => diag_spi_so_o,
        diag_spi_clk_i                           => diag_spi_clk_i,

        ---------------------------------------------------------------------------
        -- AFC I2C.
        ---------------------------------------------------------------------------
        -- Si57x oscillator
        afc_si57x_scl_b                          => afc_si57x_scl_b,
        afc_si57x_sda_b                          => afc_si57x_sda_b,

        -- Si57x oscillator output enable
        afc_si57x_oe_o                           => afc_si57x_oe_o,

        ---------------------------------------------------------------------------
        -- PCIe pins
        ---------------------------------------------------------------------------

        -- DDR3 memory pins
        ddr3_dq_b                                => ddr3_dq_b,
        ddr3_dqs_p_b                             => ddr3_dqs_p_b,
        ddr3_dqs_n_b                             => ddr3_dqs_n_b,
        ddr3_addr_o                              => ddr3_addr_o,
        ddr3_ba_o                                => ddr3_ba_o,
        ddr3_cs_n_o                              => ddr3_cs_n_o,
        ddr3_ras_n_o                             => ddr3_ras_n_o,
        ddr3_cas_n_o                             => ddr3_cas_n_o,
        ddr3_we_n_o                              => ddr3_we_n_o,
        ddr3_reset_n_o                           => ddr3_reset_n_o,
        ddr3_ck_p_o                              => ddr3_ck_p_o,
        ddr3_ck_n_o                              => ddr3_ck_n_o,
        ddr3_cke_o                               => ddr3_cke_o,
        ddr3_dm_o                                => ddr3_dm_o,
        ddr3_odt_o                               => ddr3_odt_o,

        -- PCIe transceivers
        pci_exp_rxp_i                            => pci_exp_rxp_i,
        pci_exp_rxn_i                            => pci_exp_rxn_i,
        pci_exp_txp_o                            => pci_exp_txp_o,
        pci_exp_txn_o                            => pci_exp_txn_o,

        -- PCI clock and reset signals
        pcie_clk_p_i                             => pcie_clk_p_i,
        pcie_clk_n_i                             => pcie_clk_n_i,

        ---------------------------------------------------------------------------
        -- User LEDs
        ---------------------------------------------------------------------------
        leds_o                                   => leds_o,

        ---------------------------------------------------------------------------
        -- FMC interface
        ---------------------------------------------------------------------------

        board_i2c_scl_b                          => board_i2c_scl_b,
        board_i2c_sda_b                          => board_i2c_sda_b,

        ---------------------------------------------------------------------------
        -- Flash memory SPI interface
        ---------------------------------------------------------------------------
       --
       -- spi_sclk_o                               => spi_sclk_o,
       -- spi_cs_n_o                               => spi_cs_n_o,
       -- spi_mosi_o                               => spi_mosi_o,
       -- spi_miso_i                               => spi_miso_i,
       --
        ---------------------------------------------------------------------------
        -- Miscellanous AFC pins
        ---------------------------------------------------------------------------

        -- PCB version
        pcb_rev_id_i                             => pcb_rev_id,

        ---------------------------------------------------------------------------
        --  User part
        ---------------------------------------------------------------------------

        --  Clocks and reset.
        clk_sys_o                                => clk_sys,
        rst_sys_n_o                              => clk_sys_rstn,

        clk_aux_o                                => clk_aux,
        rst_aux_n_o                              => clk_aux_rstn,

        clk_aux_raw_o                            => clk_aux_raw,
        rst_aux_raw_n_o                          => clk_aux_raw_rstn,

        clk_200mhz_o                             => clk_200mhz,
        rst_200mhz_n_o                           => clk_200mhz_rstn,

        clk_pcie_o                               => clk_pcie,
        rst_pcie_n_o                             => clk_pcie_rstn,

        clk_user2_o                              => clk_user2,
        rst_user2_n_o                            => clk_user2_rstn,

        clk_trig_ref_o                           => clk_trig_ref,
        rst_trig_ref_n_o                         => clk_trig_ref_rstn,

        clk_fp2_clk1_p_o                         => clk_fp2_clk1_p,
        clk_fp2_clk1_n_o                         => clk_fp2_clk1_n,

        --  Interrupts
        irq_user_i                               => irq_user,

        -- Acquisition
        fs_clk_array_i                           => fs_clk_array,
        fs_ce_array_i                            => fs_ce_array,
        fs_rst_n_array_i                         => fs_rst_n_array,

        acq_chan_array_i                         => acq_chan_array,

        -- Triggers                                 -- Triggers
        trig_rcv_intern_i                        => trig_rcv_intern,
        trig_pulse_transm_i                      => trig_pulse_transm,
        trig_pulse_rcv_o                         => trig_pulse_rcv,

        trig_dbg_o                               => trig_dbg,
        trig_dbg_data_sync_o                     => trig_dbg_data_sync,
        trig_dbg_data_degliteched_o              => trig_dbg_data_degliteched,

        -- AFC Si57x
        afc_si57x_ext_wr_i                       => afc_si57x_ext_wr,
        afc_si57x_ext_rfreq_value_i              => afc_si57x_ext_rfreq_value,
        afc_si57x_ext_n1_value_i                 => afc_si57x_ext_n1_value,
        afc_si57x_ext_hs_value_i                 => afc_si57x_ext_hs_value,
        afc_si57x_sta_reconfig_done_o            => afc_si57x_sta_reconfig_done,

        afc_si57x_oe_i                           => '1',
        afc_si57x_addr_i                         => "10101010",

        --  The wishbone bus from the pcie/host to the application
        --  LSB addresses are not available (used by the carrier).
        --  For the exact used addresses see SDB Description.
        --  This is a pipelined wishbone with byte granularity.
        user_wb_o                                 => user_wb_out,
        user_wb_i                                 => user_wb_in
      );
  end generate;

  pcb_rev_id <= (others => '0');
  clk_aux_rst <= not clk_aux_rstn;
  clk_aux_raw_rst <= not clk_aux_raw_rstn;

  ----------------------------------------------------------------------
  --                     IDELAYCTRL for IDELAYs                       --
  ----------------------------------------------------------------------

  cmp_idelayctrl : idelayctrl
  port map(
    rst                                     => clk_sys_rst,
    refclk                                  => clk_200mhz,
    rdy                                     => open
  );

  clk_sys_rst <= not clk_sys_rstn;

  ----------------------------------------------------------------------
  --                          FMC 0 4SFP                              --
  ----------------------------------------------------------------------
  cmp_fmc4sfp_caen_0 : fmc4sfp_caen
  port map (
    ---------------------------------------------------------------------------
    -- FMC board pins
    ---------------------------------------------------------------------------
    sfp_rx_p_i                                 => fmc0_sfp_rx_p_i,
    sfp_rx_n_i                                 => fmc0_sfp_rx_n_i,
    sfp_tx_p_o                                 => fmc0_sfp_tx_p_o,
    sfp_tx_n_o                                 => fmc0_sfp_tx_n_o,
    sfp_scl_b                                  => fmc0_sfp_scl_b,
    sfp_sda_b                                  => fmc0_sfp_sda_b,
    sfp_mod_abs_i                              => fmc0_sfp_mod_abs_i,
    sfp_rx_los_i                               => fmc0_sfp_rx_los_i,
    sfp_tx_disable_o                           => fmc0_sfp_tx_disable_o,
    sfp_tx_fault_i                             => fmc0_sfp_tx_fault_i,
    sfp_rs0_o                                  => fmc0_sfp_rs0_o,
    sfp_rs1_o                                  => fmc0_sfp_rs1_o,

    si570_clk_p_i                              => fmc0_si570_clk_p_i,
    si570_clk_n_i                              => fmc0_si570_clk_n_i,
    si570_scl_b                                => fmc0_si570_scl_b,
    si570_sda_b                                => fmc0_si570_sda_b,

    fpga_sfp_rx_p_o                            => fmc0_fpga_sfp_rx_p,
    fpga_sfp_rx_n_o                            => fmc0_fpga_sfp_rx_n,
    fpga_sfp_tx_p_i                            => fmc0_fpga_sfp_tx_p,
    fpga_sfp_tx_n_i                            => fmc0_fpga_sfp_tx_n,
    fpga_sfp_mod_abs_o                         => fmc0_fpga_sfp_mod_abs,
    fpga_sfp_rx_los_o                          => fmc0_fpga_sfp_rx_los,
    fpga_sfp_tx_disable_i                      => fmc0_fpga_sfp_tx_disable,
    fpga_sfp_tx_fault_o                        => fmc0_fpga_sfp_tx_fault,
    fpga_sfp_rs0_i                             => fmc0_fpga_sfp_rs0,
    fpga_sfp_rs1_i                             => fmc0_fpga_sfp_rs1,

    fpga_si570_clk_p_o                         => fmc0_fpga_si570_clk_p,
    fpga_si570_clk_n_o                         => fmc0_fpga_si570_clk_n
  );

  gen_fmc0_sfp_channels : for i in 0 to 3 generate

    -- SFP dependant. Using lowest TX/RX signalling rate
    fmc0_fpga_sfp_rs0(i) <= '0';
    fmc0_fpga_sfp_rs1(i) <= '0';

  end generate;

  ----------------------------------------------------------------------
  --                          FOFB DCC 0                              --
  ----------------------------------------------------------------------

  -- RX lines
  fofb_rio_rx_p(c_FOFB_CC_FMC_ID)(0) <= fmc0_fpga_sfp_rx_p(0);
  fofb_rio_rx_n(c_FOFB_CC_FMC_ID)(0) <= fmc0_fpga_sfp_rx_n(0);
  fofb_rio_rx_p(c_FOFB_CC_FMC_ID)(1) <= fmc0_fpga_sfp_rx_p(1);
  fofb_rio_rx_n(c_FOFB_CC_FMC_ID)(1) <= fmc0_fpga_sfp_rx_n(1);
  fofb_rio_rx_p(c_FOFB_CC_FMC_ID)(2) <= fmc0_fpga_sfp_rx_p(2);
  fofb_rio_rx_n(c_FOFB_CC_FMC_ID)(2) <= fmc0_fpga_sfp_rx_n(2);
  fofb_rio_rx_p(c_FOFB_CC_FMC_ID)(3) <= fmc0_fpga_sfp_rx_p(3);
  fofb_rio_rx_n(c_FOFB_CC_FMC_ID)(3) <= fmc0_fpga_sfp_rx_n(3);

  -- TX lines
  fmc0_fpga_sfp_tx_p(0) <= fofb_rio_tx_p(c_FOFB_CC_FMC_ID)(0);
  fmc0_fpga_sfp_tx_n(0) <= fofb_rio_tx_n(c_FOFB_CC_FMC_ID)(0);
  fmc0_fpga_sfp_tx_disable(0) <= fofb_rio_tx_disable(c_FOFB_CC_FMC_ID)(0);

  fmc0_fpga_sfp_tx_p(1) <= fofb_rio_tx_p(c_FOFB_CC_FMC_ID)(1);
  fmc0_fpga_sfp_tx_n(1) <= fofb_rio_tx_n(c_FOFB_CC_FMC_ID)(1);
  fmc0_fpga_sfp_tx_disable(1) <= fofb_rio_tx_disable(c_FOFB_CC_FMC_ID)(1);

  fmc0_fpga_sfp_tx_p(2) <= fofb_rio_tx_p(c_FOFB_CC_FMC_ID)(2);
  fmc0_fpga_sfp_tx_n(2) <= fofb_rio_tx_n(c_FOFB_CC_FMC_ID)(2);
  fmc0_fpga_sfp_tx_disable(2) <= fofb_rio_tx_disable(c_FOFB_CC_FMC_ID)(2);

  fmc0_fpga_sfp_tx_p(3) <= fofb_rio_tx_p(c_FOFB_CC_FMC_ID)(3);
  fmc0_fpga_sfp_tx_n(3) <= fofb_rio_tx_n(c_FOFB_CC_FMC_ID)(3);
  fmc0_fpga_sfp_tx_disable(3) <= fofb_rio_tx_disable(c_FOFB_CC_FMC_ID)(3);

  -- Clocks
  fofb_ref_clk_p(c_FOFB_CC_FMC_ID) <= fmc0_fpga_si570_clk_p;
  fofb_ref_clk_n(c_FOFB_CC_FMC_ID) <= fmc0_fpga_si570_clk_n;

  -- Trigger signal for DCC timeframe_start.
  -- Trigger pulses are synch'ed with the respective fs_clk
  fai_sim_trigger(c_FOFB_CC_FMC_ID) <= trig_pulse_rcv(c_TRIG_MUX_0_ID, c_TRIG_MUX_FOFB_SYNC_ID).pulse;

  cmp_fofb_ctrl_wrapper_0 : xwb_fofb_ctrl_wrapper
  generic map
  (
    g_INTERFACE_MODE                          => PIPELINED,
    g_ADDRESS_GRANULARITY                     => BYTE,
    g_ID                                      => 0,
    g_DEVICE                                  => BPM,
    g_PHYSICAL_INTERFACE                      => "SFP",
    g_REFCLK_INPUT                            => "REFCLK0",
    g_LANE_COUNT                              => c_LANE_COUNT,
    g_USE_CHIPSCOPE                           => c_USE_CHIPSCOPE,
    -- BPM synthetic data
    g_SIM_BPM_DATA                            => true,
    g_SIM_BLOCK_START_PERIOD                  => 10000,
    g_SIM_BLOCK_VALID_LENGTH                  => 32
  )
  port map
  (
    ---------------------------------------------------------------------------
    -- differential MGT/GTP clock inputs
    ---------------------------------------------------------------------------
    refclk_p_i                                 => fofb_ref_clk_p(c_FOFB_CC_FMC_ID),
    refclk_n_i                                 => fofb_ref_clk_n(c_FOFB_CC_FMC_ID),

    ---------------------------------------------------------------------------
    -- clock and reset interface
    ---------------------------------------------------------------------------
    adcclk_i                                   => fs_clk_array(c_FOFB_CC_FMC_ID),
    adcreset_i                                 => fs_rst_array(c_FOFB_CC_FMC_ID),
    sysclk_i                                   => clk_sys,
    sysreset_n_i                               => fofb_sysreset_n(c_FOFB_CC_FMC_ID),

    ---------------------------------------------------------------------------
    -- Wishbone Control Interface signals
    ---------------------------------------------------------------------------
    wb_slv_i                                  => user_wb_out(c_FOFB_CC_FMC_ID),
    wb_slv_o                                  => user_wb_in(c_FOFB_CC_FMC_ID),

    ---------------------------------------------------------------------------
    -- fast acquisition data interface
    -- Only used when g_SIM_BPM_DATA = false
    ---------------------------------------------------------------------------
    fai_fa_block_start_i                       => fai_fa_block_start(c_FOFB_CC_FMC_ID),
    fai_fa_data_valid_i                        => fai_fa_data_valid(c_FOFB_CC_FMC_ID),
    fai_fa_d_i                                 => fai_fa_d(c_FOFB_CC_FMC_ID),

    ---------------------------------------------------------------------------
    -- Synthetic data fast acquisition data interface.
    -- Only used when g_SIM_BPM_DATA = true
    ---------------------------------------------------------------------------
    fai_sim_data_sel_i                         => fai_sim_data_sel(c_FOFB_CC_FMC_ID),
    fai_sim_enable_i                           => fai_sim_enable(c_FOFB_CC_FMC_ID),
    fai_sim_trigger_i                          => fai_sim_trigger(c_FOFB_CC_FMC_ID),
    fai_sim_trigger_internal_i                 => fai_sim_trigger_internal(c_FOFB_CC_FMC_ID),
    fai_sim_armed_o                            => fai_sim_armed(c_FOFB_CC_FMC_ID),

    ---------------------------------------------------------------------------
    -- serial I/Os for eight RocketIOs on the Libera
    ---------------------------------------------------------------------------
    fai_rio_rdp_i                              => fofb_rio_rx_p(c_FOFB_CC_FMC_ID),
    fai_rio_rdn_i                              => fofb_rio_rx_n(c_FOFB_CC_FMC_ID),
    fai_rio_tdp_o                              => fofb_rio_tx_p(c_FOFB_CC_FMC_ID),
    fai_rio_tdn_o                              => fofb_rio_tx_n(c_FOFB_CC_FMC_ID),
    fai_rio_tdis_o                             => fofb_rio_tx_disable(c_FOFB_CC_FMC_ID),

    ---------------------------------------------------------------------------
    -- Higher-level integration interface (PMC, SNIFFER_V5)
    ---------------------------------------------------------------------------
    fofb_userclk_o                             => fofb_userclk(c_FOFB_CC_FMC_ID),
    fofb_userrst_o                             => fofb_userrst(c_FOFB_CC_FMC_ID),
    timeframe_start_o                          => timeframe_start(c_FOFB_CC_FMC_ID),
    timeframe_end_o                            => timeframe_end(c_FOFB_CC_FMC_ID),
    fofb_dma_ok_i                              => fofb_dma_ok(c_FOFB_CC_FMC_ID),
    fofb_node_mask_o                           => fofb_node_mask(c_FOFB_CC_FMC_ID),
    fofb_timestamp_val_o                       => fofb_timestamp_val(c_FOFB_CC_FMC_ID),
    fofb_link_status_o                         => fofb_link_status(c_FOFB_CC_FMC_ID),
    fofb_fod_dat_o                             => fofb_fod_dat(c_FOFB_CC_FMC_ID),
    fofb_fod_dat_val_o                         => fofb_fod_dat_val(c_FOFB_CC_FMC_ID)
  );

  fofb_sysreset_n(c_FOFB_CC_FMC_ID) <= clk_sys_rstn and fmc0_si57x_reconfig_rst_n and fofb_reset_n;

  fofb_userrst_n(c_FOFB_CC_FMC_ID) <= not fofb_userrst(c_FOFB_CC_FMC_ID);

  ----------------------------------------------------------------------
  --                          AFC Si57x                               --
  ----------------------------------------------------------------------

  -- Generate large pulse for reset
  cmp_afc_si57x_gc_posedge : gc_posedge
  port map (
    clk_i                                      => clk_sys,
    rst_n_i                                    => clk_sys_rstn,
    data_i                                     => afc_si57x_sta_reconfig_done,
    pulse_o                                    => afc_si57x_sta_reconfig_done_pp
  );

  cmp_afc_si57x_gc_extend_pulse : gc_extend_pulse
  generic map (
    g_width                                    => 50000
  )
  port map (
    clk_i                                      => clk_sys,
    rst_n_i                                    => clk_sys_rstn,
    pulse_i                                    => afc_si57x_sta_reconfig_done_pp,
    extended_o                                 => afc_si57x_reconfig_rst
  );

  afc_si57x_reconfig_rst_n <= not afc_si57x_reconfig_rst;

  ----------------------------------------------------------------------
  --                          FOFB DCC P2P                            --
  ----------------------------------------------------------------------

  gen_fofb_p2p_gts: for i in 0 to c_NUM_P2P_GTS_FOFB-1 generate

    -- RX lines
    fofb_rio_rx_p(c_FOFB_CC_P2P_ID)(i) <= p2p_gt_rx_p_i(g_P2P_GT_START_ID+i);
    fofb_rio_rx_n(c_FOFB_CC_P2P_ID)(i) <= p2p_gt_rx_n_i(g_P2P_GT_START_ID+i);

    -- TX lines
    p2p_gt_tx_p_o(g_P2P_GT_START_ID+i) <= fofb_rio_tx_p(c_FOFB_CC_P2P_ID)(i);
    p2p_gt_tx_n_o(g_P2P_GT_START_ID+i) <= fofb_rio_tx_n(c_FOFB_CC_P2P_ID)(i);

  end generate;

  gen_unused_fofb_p2p_gts: for i in c_NUM_P2P_GTS_FOFB to g_NUM_P2P_GTS-1 generate

    -- TX lines
    p2p_gt_tx_p_o(i) <= '0';
    p2p_gt_tx_n_o(i) <= '1';

  end generate;

  fofb_ref_clk_p(c_FOFB_CC_P2P_ID) <= clk_fp2_clk1_p;
  fofb_ref_clk_n(c_FOFB_CC_P2P_ID) <= clk_fp2_clk1_n;

  -- Trigger signal for DCC timeframe_start.
  -- Trigger pulses are synch'ed with the respective fs_clk
  fai_sim_trigger(c_FOFB_CC_P2P_ID) <= trig_pulse_rcv(c_TRIG_MUX_1_ID, c_TRIG_MUX_FOFB_SYNC_ID).pulse;

  cmp_fofb_ctrl_wrapper_1 : xwb_fofb_ctrl_wrapper
  generic map
  (
    g_INTERFACE_MODE                          => PIPELINED,
    g_ADDRESS_GRANULARITY                     => BYTE,
    g_ID                                      => 0,
    g_DEVICE                                  => BPM,
    g_PHYSICAL_INTERFACE                      => "BACKPLANE",
    g_REFCLK_INPUT                            => "REFCLK1",
    g_LANE_COUNT                              => c_LANE_COUNT,
    g_USE_CHIPSCOPE                           => c_USE_CHIPSCOPE,
    -- BPM synthetic data
    g_SIM_BPM_DATA                            => true,
    g_SIM_BLOCK_START_PERIOD                  => 10000,
    g_SIM_BLOCK_VALID_LENGTH                  => 32
  )
  port map
  (
    ---------------------------------------------------------------------------
    -- differential MGT/GTP clock inputs
    ---------------------------------------------------------------------------
    refclk_p_i                                 => fofb_ref_clk_p(c_FOFB_CC_P2P_ID),
    refclk_n_i                                 => fofb_ref_clk_n(c_FOFB_CC_P2P_ID),

    ---------------------------------------------------------------------------
    -- clock and reset interface
    ---------------------------------------------------------------------------
    adcclk_i                                   => fs_clk_array(c_FOFB_CC_P2P_ID),
    adcreset_i                                 => fs_rst_array(c_FOFB_CC_P2P_ID),
    sysclk_i                                   => clk_sys,
    sysreset_n_i                               => fofb_sysreset_n(c_FOFB_CC_P2P_ID),

    ---------------------------------------------------------------------------
    -- Wishbone Control Interface signals
    ---------------------------------------------------------------------------
    wb_slv_i                                  => user_wb_out(c_FOFB_CC_P2P_ID),
    wb_slv_o                                  => user_wb_in(c_FOFB_CC_P2P_ID),

    ---------------------------------------------------------------------------
    -- fast acquisition data interface
    -- Only used when g_SIM_BPM_DATA = false
    ---------------------------------------------------------------------------
    fai_fa_block_start_i                       => fai_fa_block_start(c_FOFB_CC_P2P_ID),
    fai_fa_data_valid_i                        => fai_fa_data_valid(c_FOFB_CC_P2P_ID),
    fai_fa_d_i                                 => fai_fa_d(c_FOFB_CC_P2P_ID),

    ---------------------------------------------------------------------------
    -- Synthetic data fast acquisition data interface.
    -- Only used when g_SIM_BPM_DATA = true
    ---------------------------------------------------------------------------
    fai_sim_data_sel_i                         => fai_sim_data_sel(c_FOFB_CC_P2P_ID),
    fai_sim_enable_i                           => fai_sim_enable(c_FOFB_CC_P2P_ID),
    fai_sim_trigger_i                          => fai_sim_trigger(c_FOFB_CC_P2P_ID),
    fai_sim_trigger_internal_i                 => fai_sim_trigger_internal(c_FOFB_CC_P2P_ID),
    fai_sim_armed_o                            => fai_sim_armed(c_FOFB_CC_P2P_ID),

    ---------------------------------------------------------------------------
    -- serial I/Os for eight RocketIOs on the Libera
    ---------------------------------------------------------------------------
    fai_rio_rdp_i                              => fofb_rio_rx_p(c_FOFB_CC_P2P_ID),
    fai_rio_rdn_i                              => fofb_rio_rx_n(c_FOFB_CC_P2P_ID),
    fai_rio_tdp_o                              => fofb_rio_tx_p(c_FOFB_CC_P2P_ID),
    fai_rio_tdn_o                              => fofb_rio_tx_n(c_FOFB_CC_P2P_ID),
    fai_rio_tdis_o                             => fofb_rio_tx_disable(c_FOFB_CC_P2P_ID),

    ---------------------------------------------------------------------------
    -- Higher-level integration interface (PMC, SNIFFER_V5)
    ---------------------------------------------------------------------------
    fofb_userclk_o                             => fofb_userclk(c_FOFB_CC_P2P_ID),
    fofb_userrst_o                             => fofb_userrst(c_FOFB_CC_P2P_ID),
    timeframe_start_o                          => timeframe_start(c_FOFB_CC_P2P_ID),
    timeframe_end_o                            => timeframe_end(c_FOFB_CC_P2P_ID),
    fofb_dma_ok_i                              => fofb_dma_ok(c_FOFB_CC_P2P_ID),
    fofb_node_mask_o                           => fofb_node_mask(c_FOFB_CC_P2P_ID),
    fofb_timestamp_val_o                       => fofb_timestamp_val(c_FOFB_CC_P2P_ID),
    fofb_link_status_o                         => fofb_link_status(c_FOFB_CC_P2P_ID),
    fofb_fod_dat_o                             => fofb_fod_dat(c_FOFB_CC_P2P_ID),
    fofb_fod_dat_val_o                         => fofb_fod_dat_val(c_FOFB_CC_P2P_ID)
  );

  fofb_sysreset_n(c_FOFB_CC_P2P_ID) <= clk_sys_rstn and afc_si57x_reconfig_rst_n and fofb_reset_n;

  fofb_userrst_n(c_FOFB_CC_P2P_ID) <= not fofb_userrst(c_FOFB_CC_P2P_ID);

  ----------------------------------------------------------------------
  --                          RTM LAMP OHWR                           --
  ----------------------------------------------------------------------

  -- Keep it so it's easier to apply constraints on all nets that use this clock
  -- name
  clk_fast_spi <= clk_user2;
  clk_fast_spi_rstn <= clk_user2_rstn;

  clk_rtm_ref <= clk_aux_raw;
  clk_rtm_ref_rstn <= clk_aux_raw_rstn;

  cmp_rtmlamp_ohwr : xwb_rtmlamp_ohwr
  generic map (
    g_INTERFACE_MODE                           => PIPELINED,
    g_ADDRESS_GRANULARITY                      => BYTE,
    g_WITH_EXTRA_WB_REG                        => false,
    -- System clock frequency [Hz]
    g_SYS_CLOCK_FREQ                           => c_SYS_CLOCK_FREQ,
    -- Reference clock frequency [Hz], used only when g_USE_REF_CNV is
    -- set to true
    g_REF_CLK_FREQ                             => c_REF_CLOCK_FREQ,
    -- Wether or not to use a reference clk to drive CNV/LDAC.
    -- If true uses clk_ref_i to drive CNV/LDAC
    -- If false uses clk_i to drive CNV/LDAC
    g_USE_REF_CLK                              => c_USE_REF_CLOCK,
    -- ADC clock frequency [Hz]. Must be a multiple of g_ADC_SCLK_FREQ
    g_CLK_FAST_SPI_FREQ                        => c_FAST_SPI_FREQ,
    -- ADC clock frequency [Hz]
    g_ADC_SCLK_FREQ                            => c_ADC_SCLK_FREQ,
    -- Number of ADC channels
    g_ADC_CHANNELS                             => c_ADC_CHANNELS,
    -- If the ADC inputs are inverted on RTM-LAMP or not
    g_ADC_FIX_INV_INPUTS                       => true,
    -- DAC clock frequency [Hz]
    g_DAC_SCLK_FREQ                            => c_DAC_SCLK_FREQ,
    -- Number of DAC channels
    g_DAC_CHANNELS                             => c_DAC_CHANNELS
  )
  port map (
    ---------------------------------------------------------------------------
    -- clock and reset interface
    ---------------------------------------------------------------------------
    clk_i                                      => clk_sys,
    rst_n_i                                    => clk_sys_rstn,

    clk_ref_i                                  => clk_rtm_ref,
    rst_ref_n_i                                => clk_rtm_ref_rstn,

    clk_fast_spi_i                             => clk_fast_spi,
    rst_fast_spi_n_i                           => clk_fast_spi_rstn,

    ---------------------------------------------------------------------------
    -- Wishbone Control Interface signals
    ---------------------------------------------------------------------------
    wb_slv_i                                   => user_wb_out(c_RTM_LAMP_ID),
    wb_slv_o                                   => user_wb_in(c_RTM_LAMP_ID),

    ---------------------------------------------------------------------------
    -- RTM ADC interface
    ---------------------------------------------------------------------------
    -- use octo conversion signal to drive all ADCs
    adc_octo_cnv_o                             => rtmlamp_adc_cnv_o,
    adc_octo_sck_p_o                           => rtmlamp_adc_octo_sck_p_o,
    adc_octo_sck_n_o                           => rtmlamp_adc_octo_sck_n_o,
    adc_octo_sck_ret_p_i                       => rtmlamp_adc_octo_sck_ret_p_i,
    adc_octo_sck_ret_n_i                       => rtmlamp_adc_octo_sck_ret_n_i,
    adc_octo_sdoa_p_i                          => rtmlamp_adc_octo_sdoa_p_i,
    adc_octo_sdoa_n_i                          => rtmlamp_adc_octo_sdoa_n_i,
    adc_octo_sdob_p_i                          => rtmlamp_adc_octo_sdob_p_i,
    adc_octo_sdob_n_i                          => rtmlamp_adc_octo_sdob_n_i,
    adc_octo_sdoc_p_i                          => rtmlamp_adc_octo_sdoc_p_i,
    adc_octo_sdoc_n_i                          => rtmlamp_adc_octo_sdoc_n_i,
    adc_octo_sdod_p_i                          => rtmlamp_adc_octo_sdod_p_i,
    adc_octo_sdod_n_i                          => rtmlamp_adc_octo_sdod_n_i,

    -- Only used when g_ADC_CHANNELS > 8
    adc_quad_sck_p_o                           => rtmlamp_adc_quad_sck_p_o,
    adc_quad_sck_n_o                           => rtmlamp_adc_quad_sck_n_o,
    adc_quad_sck_ret_p_i                       => rtmlamp_adc_quad_sck_ret_p_i,
    adc_quad_sck_ret_n_i                       => rtmlamp_adc_quad_sck_ret_n_i,
    adc_quad_sdoa_p_i                          => rtmlamp_adc_quad_sdoa_p_i,
    adc_quad_sdoa_n_i                          => rtmlamp_adc_quad_sdoa_n_i,
    adc_quad_sdoc_p_i                          => rtmlamp_adc_quad_sdoc_p_i,
    adc_quad_sdoc_n_i                          => rtmlamp_adc_quad_sdoc_n_i,

    ---------------------------------------------------------------------------
    -- RTM DAC interface
    ---------------------------------------------------------------------------
    dac_cs_n_o                                 => rtmlamp_dac_cs_n_o,
    dac_ldac_n_o                               => rtmlamp_dac_ldac_n_o,
    dac_sck_o                                  => rtmlamp_dac_sck_o,
    dac_sdi_o                                  => rtmlamp_dac_sdi_o,

    ---------------------------------------------------------------------------
    -- RTM Serial registers interface
    ---------------------------------------------------------------------------
    amp_shift_clk_o                            => rtmlamp_amp_shift_clk_o,
    amp_shift_dout_i                           => rtmlamp_amp_shift_dout_i,
    amp_shift_pl_o                             => rtmlamp_amp_shift_pl_o,

    amp_shift_oe_n_o                           => rtmlamp_amp_shift_oe_n_o,
    amp_shift_din_o                            => rtmlamp_amp_shift_din_o,
    amp_shift_str_o                            => rtmlamp_amp_shift_str_o,

    ---------------------------------------------------------------------------
    -- FPGA interface
    ---------------------------------------------------------------------------

    ---------------------------------------------------------------------------
    -- ADC parallel interface
    ---------------------------------------------------------------------------
    adc_start_i                                => rtmlamp_adc_start,
    adc_data_o                                 => rtmlamp_adc_data,
    adc_valid_o                                => rtmlamp_adc_valid,

    ---------------------------------------------------------------------------
    -- DAC parallel interface
    ---------------------------------------------------------------------------
    dac_start_i                                => rtmlamp_dac_start,
    dac_data_i                                 => rtmlamp_dac_data,
    dac_ready_o                                => rtmlamp_dac_ready,
    dac_done_pp_o                              => rtmlamp_dac_done_pp
  );

  ----------------------------------------------------------------------
  --                          Acquisition                             --
  ----------------------------------------------------------------------

  fs_clk_array(c_ACQ_CORE_0_ID)   <= fofb_userclk(c_FOFB_CC_FMC_ID);
  fs_rst_n_array(c_ACQ_CORE_0_ID) <= fofb_userrst_n(c_FOFB_CC_FMC_ID);

  fs_clk_array(c_ACQ_CORE_1_ID)   <= fofb_userclk(c_FOFB_CC_P2P_ID);
  fs_rst_n_array(c_ACQ_CORE_1_ID) <= fofb_userrst_n(c_FOFB_CC_P2P_ID);

  fs_clk_array(c_ACQ_CORE_2_ID)   <= clk_sys;
  fs_rst_n_array(c_ACQ_CORE_2_ID) <= clk_sys_rstn;

  gen_acq_clks : for i in 0 to c_ACQ_NUM_CORES-1 generate

    fs_ce_array(i)    <= '1';
    fs_rst_array(i)   <= not fs_rst_n_array(i);

  end generate;

  -- RTM_LAMP data
  gen_rtm_acq_num_cores : for i in 0 to c_ACQ_NUM_CORES-1 generate
    gen_rtm_acq_channels : for j in 0 to c_ADC_CHANNELS-1 generate

      acq_rtmlamp_data(i)(
        (j+1)*to_integer(c_FACQ_CHANNELS(c_ACQ_RTM_LAMP_ID).atom_width)-1
        downto
        j*to_integer(c_FACQ_CHANNELS(c_ACQ_RTM_LAMP_ID).atom_width))
      <= rtmlamp_adc_data(j);

    end generate;

    acq_rtmlamp_data_valid(i) <= rtmlamp_adc_valid(0);
  end generate;

  gen_rtm_acq_acq_num_cores_unused : for i in 0 to c_ACQ_NUM_CORES-1 generate
    gen_rtm_acq_channels_unused : for j in c_ADC_CHANNELS to
        to_integer(c_FACQ_CHANNELS(c_ACQ_RTM_LAMP_ID).num_atoms)-1 generate

      acq_rtmlamp_data(i)(
        (j+1)*to_integer(c_FACQ_CHANNELS(c_ACQ_RTM_LAMP_ID).atom_width)-1
        downto
        j*to_integer(c_FACQ_CHANNELS(c_ACQ_RTM_LAMP_ID).atom_width))
      <= (others => '0');

    end generate;
  end generate;

  --------------------
  -- ACQ Core 0
  --------------------

  -- DCC
  acq_chan_array(c_ACQ_CORE_0_ID, c_ACQ_DCC_ID).val(to_integer(c_FACQ_CHANNELS(c_ACQ_DCC_ID).width)-1 downto 0) <=
                                                                 fofb_fod_dat(c_FOFB_CC_FMC_ID);
  acq_chan_array(c_ACQ_CORE_0_ID, c_ACQ_DCC_ID).dvalid        <= fofb_fod_dat_val(c_FOFB_CC_FMC_ID)(0);
  acq_chan_array(c_ACQ_CORE_0_ID, c_ACQ_DCC_ID).trig          <= trig_pulse_rcv(c_TRIG_MUX_0_ID, c_ACQ_DCC_ID).pulse;

  --------------------
  -- ACQ Core 1
  --------------------
  -- DCC
  acq_chan_array(c_ACQ_CORE_1_ID, c_ACQ_DCC_ID).val(to_integer(c_FACQ_CHANNELS(c_ACQ_DCC_ID).width)-1 downto 0) <=
                                                                 fofb_fod_dat(c_FOFB_CC_P2P_ID);
  acq_chan_array(c_ACQ_CORE_1_ID, c_ACQ_DCC_ID).dvalid        <= fofb_fod_dat_val(c_FOFB_CC_P2P_ID)(0);
  acq_chan_array(c_ACQ_CORE_1_ID, c_ACQ_DCC_ID).trig          <= trig_pulse_rcv(c_TRIG_MUX_1_ID, c_ACQ_DCC_ID).pulse;

  --------------------
  -- ACQ Core 2
  --------------------

  -- RTM LAMP
  acq_chan_array(c_ACQ_CORE_2_ID, c_ACQ_RTM_LAMP_ID).val(to_integer(c_FACQ_CHANNELS(c_ACQ_RTM_LAMP_ID).width)-1 downto 0) <=
                                                                 acq_rtmlamp_data(c_ACQ_CORE_2_ID);
  acq_chan_array(c_ACQ_CORE_2_ID, c_ACQ_RTM_LAMP_ID).dvalid        <= acq_rtmlamp_data_valid(c_ACQ_CORE_2_ID);
  acq_chan_array(c_ACQ_CORE_2_ID, c_ACQ_RTM_LAMP_ID).trig          <= trig_pulse_rcv(c_TRIG_MUX_2_ID, c_ACQ_RTM_LAMP_ID).pulse;

  ----------------------------------------------------------------------
  --                          Trigger                                 --
  ----------------------------------------------------------------------

  trig_ref_clk <= clk_trig_ref;
  trig_ref_rst_n <= clk_trig_ref_rstn;

  -- Assign trigger pulses to trigger channel interfaces
  trig_acq_channel(c_TRIG_MUX_0_ID, c_TRIG_RCV_INTERN_CHAN_0_ID).pulse <=
    timeframe_start(c_FOFB_CC_FMC_ID);
  trig_acq_channel(c_TRIG_MUX_0_ID, c_TRIG_RCV_INTERN_CHAN_1_ID).pulse <=
    timeframe_end(c_FOFB_CC_FMC_ID);

  trig_acq_channel(c_TRIG_MUX_1_ID, c_TRIG_RCV_INTERN_CHAN_0_ID).pulse <=
    timeframe_start(c_FOFB_CC_P2P_ID);
  trig_acq_channel(c_TRIG_MUX_1_ID, c_TRIG_RCV_INTERN_CHAN_1_ID).pulse <=
    timeframe_end(c_FOFB_CC_P2P_ID);

  trig_acq_channel(c_TRIG_MUX_2_ID, c_TRIG_RCV_INTERN_CHAN_0_ID).pulse <=
    rtmlamp_adc_start;
  trig_acq_channel(c_TRIG_MUX_2_ID, c_TRIG_RCV_INTERN_CHAN_1_ID).pulse <=
    rtmlamp_dac_start;

  -- Assign intern triggers to trigger module
  trig_rcv_intern(c_TRIG_MUX_0_ID, c_TRIG_RCV_INTERN_CHAN_0_ID) <=
    trig_acq_channel(c_TRIG_MUX_0_ID, c_TRIG_RCV_INTERN_CHAN_0_ID);
  trig_rcv_intern(c_TRIG_MUX_0_ID, c_TRIG_RCV_INTERN_CHAN_1_ID) <=
    trig_acq_channel(c_TRIG_MUX_0_ID, c_TRIG_RCV_INTERN_CHAN_1_ID);

  trig_rcv_intern(c_TRIG_MUX_1_ID, c_TRIG_RCV_INTERN_CHAN_0_ID) <=
    trig_acq_channel(c_TRIG_MUX_1_ID, c_TRIG_RCV_INTERN_CHAN_0_ID);
  trig_rcv_intern(c_TRIG_MUX_1_ID, c_TRIG_RCV_INTERN_CHAN_1_ID) <=
    trig_acq_channel(c_TRIG_MUX_1_ID, c_TRIG_RCV_INTERN_CHAN_1_ID);

  trig_rcv_intern(c_TRIG_MUX_2_ID, c_TRIG_RCV_INTERN_CHAN_0_ID) <=
    trig_acq_channel(c_TRIG_MUX_2_ID, c_TRIG_RCV_INTERN_CHAN_0_ID);
  trig_rcv_intern(c_TRIG_MUX_2_ID, c_TRIG_RCV_INTERN_CHAN_1_ID) <=
    trig_acq_channel(c_TRIG_MUX_2_ID, c_TRIG_RCV_INTERN_CHAN_1_ID);

  ----------------------------------------------------------------------
  --                          VIO                                     --
  ----------------------------------------------------------------------
--  cmp_vio_din2_w64_dout2_w64 : entity work.vio_din2_w64_dout2_w64
--  port map (
--    clk                                      => clk_sys,
--    probe_in0                                => probe_in0,
--    probe_in1                                => probe_in1,
--    probe_out0                               => probe_out0,
--    probe_out1                               => probe_out1
--  );
--
--  probe_in0(63 downto 0) <= (others => '0')
--  probe_in1(63 downto 0) <= (others => '0');
--
--  afc_si57x_ext_rfreq_value <= probe_out0(37 downto 0);
--  afc_si57x_ext_wr          <= probe_out1(0);
--  afc_si57x_ext_n1_value    <= probe_out1(7 downto 1);
--  afc_si57x_ext_hs_value    <= probe_out1(10 downto 8);
--  fofb_reset          <= probe_out1(11);
--
--  fofb_reset_n        <= not fofb_reset;
--
--  ila_core_inst : entity work.ila_t8_d256_s16384
--  port map (
--    clk             => clk_sys,
--    probe0          => data,
--    probe1          => trig0
--  );
--
--  trig0(0)          <= fofb_reset;
--  trig0(1)          <= fofb_reset_n;
--  trig0(2)          <= afc_si57x_sta_reconfig_done;
--  trig0(3)          <= afc_si57x_sta_reconfig_done_pp;
--  trig0(4)          <= afc_si57x_reconfig_rst;
--  trig0(5)          <= afc_si57x_reconfig_rst_n;
--  trig0(6)          <= '0';
--  trig0(7)          <= '0';
--
--  data(0)          <= fofb_reset;
--  data(1)          <= fofb_reset_n;
--  data(2)          <= afc_si57x_sta_reconfig_done;
--  data(3)          <= afc_si57x_sta_reconfig_done_pp;
--  data(4)          <= afc_si57x_reconfig_rst;
--  data(5)          <= afc_si57x_reconfig_rst_n;
--
--  data(255 downto 6) <= (others => '0');

end architecture top;
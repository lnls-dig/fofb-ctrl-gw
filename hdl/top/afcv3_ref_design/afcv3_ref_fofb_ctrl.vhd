------------------------------------------------------------------------------
-- Title      : AFC design for FOFB Controller + 1 FMC SFPs
------------------------------------------------------------------------------
-- Author     : Lucas Maziero Russo
-- Company    : CNPEM LNLS-DIG
-- Created    : 2020-10-26
-- Platform   : FPGA-generic
-------------------------------------------------------------------------------
-- Description: AFC design for FOFB Controller + 1 FMC SFPs
-------------------------------------------------------------------------------
-- Copyright (c) 2020 CNPEM
-- Licensed under GNU Lesser General Public License (LGPL) v3.0
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author          Description
-- 2020-10-26  1.0      lucas.russo        Created
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

entity afcv3_ref_fofb_ctrl is
generic (
  -- Number of P2P GTs
  g_NUM_P2P_GTS                              : integer := 8;
  -- Starting index of used P2P GTs
  g_P2P_GT_START_ID                          : integer := 0;
  -- Number of RTM LAMP ADC channels
  g_ADC_CHANNELS                             : natural := 8;
  -- Number of RTM LAMP DAC channels
  g_DAC_CHANNELS                             : natural := 8
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
  trig_b                                     : inout std_logic_vector(c_NUM_TRIG-1 downto 0);

  ---------------------------------------------------------------------------
  -- AFC Diagnostics
  ---------------------------------------------------------------------------

  diag_spi_cs_i                              : in std_logic := '0';
  diag_spi_si_i                              : in std_logic := '0';
  diag_spi_so_o                              : out std_logic;
  diag_spi_clk_i                             : in std_logic := '0';

  ---------------------------------------------------------------------------
  -- ADN4604ASVZ
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

  -- Only for AFCv4
  -- rtmlamp_adc_quad_sck_p_o                   : out   std_logic;
  -- rtmlamp_adc_quad_sck_n_o                   : out   std_logic;
  -- rtmlamp_adc_quad_sck_ret_p_i               : in    std_logic := '0';
  -- rtmlamp_adc_quad_sck_ret_n_i               : in    std_logic := '0';
  -- rtmlamp_adc_quad_sdoa_p_i                  : in    std_logic := '0';
  -- rtmlamp_adc_quad_sdoa_n_i                  : in    std_logic := '0';
  -- rtmlamp_adc_quad_sdoc_p_i                  : in    std_logic := '0';
  -- rtmlamp_adc_quad_sdoc_n_i                  : in    std_logic := '0';

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
  -- Only for AFCv4
  -- rtmlamp_amp_shift_dout_i                   : in    std_logic;
  -- rtmlamp_amp_shift_pl_o                     : out   std_logic;

  -- rtmlamp_amp_shift_oe_n_o                   : out   std_logic;
  rtmlamp_amp_shift_din_o                    : out   std_logic;
  rtmlamp_amp_shift_str_o                    : out   std_logic
);
end entity afcv3_ref_fofb_ctrl;

architecture top of afcv3_ref_fofb_ctrl is

begin

  cmp_afc_ref_fofb_ctrl_gen : entity work.afc_ref_fofb_ctrl_gen
  generic map (
    g_BOARD                                    => "AFCv3",
    -- Number of P2P GTs
    g_NUM_P2P_GTS                              => g_NUM_P2P_GTS,
    -- Starting index of used P2P GTs
    g_P2P_GT_START_ID                          => g_P2P_GT_START_ID,
    -- Number of RTM LAMP ADC channels
    g_ADC_CHANNELS                             => g_ADC_CHANNELS,
    -- Number of RTM LAMP DAC channels
    g_DAC_CHANNELS                             => g_DAC_CHANNELS
  )
  port map (
    ---------------------------------------------------------------------------
    -- Clocking pins
    ---------------------------------------------------------------------------
    sys_clk_p_i                                => sys_clk_p_i,
    sys_clk_n_i                                => sys_clk_n_i,

    aux_clk_p_i                                => aux_clk_p_i,
    aux_clk_n_i                                => aux_clk_n_i,

    afc_fp2_clk1_p_i                           => afc_fp2_clk1_p_i,
    afc_fp2_clk1_n_i                           => afc_fp2_clk1_n_i,

    ---------------------------------------------------------------------------
    -- Reset Button
    ---------------------------------------------------------------------------
    sys_rst_button_n_i                         => sys_rst_button_n_i,

    ---------------------------------------------------------------------------
    -- UART pins
    ---------------------------------------------------------------------------

    uart_rxd_i                                 => uart_rxd_i,
    uart_txd_o                                 => uart_txd_o,

    ---------------------------------------------------------------------------
    -- Trigger pins
    ---------------------------------------------------------------------------
    trig_dir_o                                 => trig_dir_o,
    -- AFCv3
    trig_b                                     => trig_b,

    ---------------------------------------------------------------------------
    -- AFC Diagnostics
    ---------------------------------------------------------------------------

    diag_spi_cs_i                              => diag_spi_cs_i,
    diag_spi_si_i                              => diag_spi_si_i,
    diag_spi_so_o                              => diag_spi_so_o,
    diag_spi_clk_i                             => diag_spi_clk_i,

    ---------------------------------------------------------------------------
    -- ADN4604ASVZ. AFCv3
    ---------------------------------------------------------------------------
    adn4604_vadj2_clk_updt_n_o                 => adn4604_vadj2_clk_updt_n_o,

    ---------------------------------------------------------------------------
    -- AFC I2C.
    ---------------------------------------------------------------------------
    -- Si57x oscillator
    afc_si57x_scl_b                            => afc_si57x_scl_b,
    afc_si57x_sda_b                            => afc_si57x_sda_b,

    -- Si57x oscillator output enable
    afc_si57x_oe_o                             => afc_si57x_oe_o,

    ---------------------------------------------------------------------------
    -- PCIe pins
    ---------------------------------------------------------------------------

    -- DDR3 memory pins
    ddr3_dq_b                                  => ddr3_dq_b,
    ddr3_dqs_p_b                               => ddr3_dqs_p_b,
    ddr3_dqs_n_b                               => ddr3_dqs_n_b,
    ddr3_addr_o                                => ddr3_addr_o,
    ddr3_ba_o                                  => ddr3_ba_o,
    ddr3_cs_n_o                                => ddr3_cs_n_o,
    ddr3_ras_n_o                               => ddr3_ras_n_o,
    ddr3_cas_n_o                               => ddr3_cas_n_o,
    ddr3_we_n_o                                => ddr3_we_n_o,
    ddr3_reset_n_o                             => ddr3_reset_n_o,
    ddr3_ck_p_o                                => ddr3_ck_p_o,
    ddr3_ck_n_o                                => ddr3_ck_n_o,
    ddr3_cke_o                                 => ddr3_cke_o,
    ddr3_dm_o                                  => ddr3_dm_o,
    ddr3_odt_o                                 => ddr3_odt_o,

    -- PCIe transceivers
    pci_exp_rxp_i                              => pci_exp_rxp_i,
    pci_exp_rxn_i                              => pci_exp_rxn_i,
    pci_exp_txp_o                              => pci_exp_txp_o,
    pci_exp_txn_o                              => pci_exp_txn_o,

    -- PCI clock and reset signals
    pcie_clk_p_i                               => pcie_clk_p_i,
    pcie_clk_n_i                               => pcie_clk_n_i,

    ---------------------------------------------------------------------------
    -- User LEDs
    ---------------------------------------------------------------------------
    leds_o                                     => leds_o,

    ---------------------------------------------------------------------------
    -- FMC interface
    ---------------------------------------------------------------------------

    board_i2c_scl_b                            => board_i2c_scl_b,
    board_i2c_sda_b                            => board_i2c_sda_b,

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
    p2p_gt_rx_p_i                              => p2p_gt_rx_p_i,
    p2p_gt_rx_n_i                              => p2p_gt_rx_n_i,
    p2p_gt_tx_p_o                              => p2p_gt_tx_p_o,
    p2p_gt_tx_n_o                              => p2p_gt_tx_n_o,

    ---------------------------------------------------------------------------
    -- FMC slot 0 - CAEN 4 SFP+
    ---------------------------------------------------------------------------

    fmc0_sfp_rx_p_i                            => fmc0_sfp_rx_p_i,
    fmc0_sfp_rx_n_i                            => fmc0_sfp_rx_n_i,
    fmc0_sfp_tx_p_o                            => fmc0_sfp_tx_p_o,
    fmc0_sfp_tx_n_o                            => fmc0_sfp_tx_n_o,

    fmc0_sfp_scl_b                             => fmc0_sfp_scl_b,
    fmc0_sfp_sda_b                             => fmc0_sfp_sda_b,
    fmc0_sfp_mod_abs_i                         => fmc0_sfp_mod_abs_i,
    fmc0_sfp_rx_los_i                          => fmc0_sfp_rx_los_i,
    fmc0_sfp_tx_disable_o                      => fmc0_sfp_tx_disable_o,
    fmc0_sfp_tx_fault_i                        => fmc0_sfp_tx_fault_i,
    fmc0_sfp_rs0_o                             => fmc0_sfp_rs0_o,
    fmc0_sfp_rs1_o                             => fmc0_sfp_rs1_o,

    fmc0_si570_clk_p_i                         => fmc0_si570_clk_p_i,
    fmc0_si570_clk_n_i                         => fmc0_si570_clk_n_i,
    fmc0_si570_scl_b                           => fmc0_si570_scl_b,
    fmc0_si570_sda_b                           => fmc0_si570_sda_b,

    ---------------------------------------------------------------------------
    -- FMC slot 0 management
    ---------------------------------------------------------------------------
    fmc0_prsnt_m2c_n_i                         => fmc0_prsnt_m2c_n_i,
    -- fmc0_scl_b         : inout std_logic;       -- Mezzanine system I2C clock (EEPROM)
    -- fmc0_sda_b         : inout std_logic        -- Mezzanine system I2C data (EEPROM)

    ---------------------------------------------------------------------------
    -- FMC slot 1 management
    ---------------------------------------------------------------------------
    fmc1_prsnt_m2c_n_i                         => fmc1_prsnt_m2c_n_i,
    -- fmc1_scl_b         : inout std_logic;       -- Mezzanine system I2C clock (EEPROM)
    -- fmc1_sda_b         : inout std_logic        -- Mezzanine system I2C data (EEPROM)

    ---------------------------------------------------------------------------
    -- RTM LAMP board pins
    ---------------------------------------------------------------------------

    ---------------------------------------------------------------------------
    -- RTM ADC interface
    ---------------------------------------------------------------------------
    rtmlamp_adc_cnv_o                          => rtmlamp_adc_cnv_o,

    rtmlamp_adc_octo_sck_p_o                   => rtmlamp_adc_octo_sck_p_o,
    rtmlamp_adc_octo_sck_n_o                   => rtmlamp_adc_octo_sck_n_o,
    rtmlamp_adc_octo_sck_ret_p_i               => rtmlamp_adc_octo_sck_ret_p_i,
    rtmlamp_adc_octo_sck_ret_n_i               => rtmlamp_adc_octo_sck_ret_n_i,
    rtmlamp_adc_octo_sdoa_p_i                  => rtmlamp_adc_octo_sdoa_p_i,
    rtmlamp_adc_octo_sdoa_n_i                  => rtmlamp_adc_octo_sdoa_n_i,
    rtmlamp_adc_octo_sdob_p_i                  => rtmlamp_adc_octo_sdob_p_i,
    rtmlamp_adc_octo_sdob_n_i                  => rtmlamp_adc_octo_sdob_n_i,
    rtmlamp_adc_octo_sdoc_p_i                  => rtmlamp_adc_octo_sdoc_p_i,
    rtmlamp_adc_octo_sdoc_n_i                  => rtmlamp_adc_octo_sdoc_n_i,
    rtmlamp_adc_octo_sdod_p_i                  => rtmlamp_adc_octo_sdod_p_i,
    rtmlamp_adc_octo_sdod_n_i                  => rtmlamp_adc_octo_sdod_n_i,

    ---------------------------------------------------------------------------
    -- RTM DAC interface
    ---------------------------------------------------------------------------
    rtmlamp_dac_ldac_n_o                       => rtmlamp_dac_ldac_n_o,
    rtmlamp_dac_cs_n_o                         => rtmlamp_dac_cs_n_o,
    rtmlamp_dac_sck_o                          => rtmlamp_dac_sck_o,
    rtmlamp_dac_sdi_o                          => rtmlamp_dac_sdi_o,

    ---------------------------------------------------------------------------
    -- RTM Serial registers interface
    ---------------------------------------------------------------------------
    rtmlamp_amp_shift_clk_o                    => rtmlamp_amp_shift_clk_o,

    rtmlamp_amp_shift_din_o                    => rtmlamp_amp_shift_din_o,
    rtmlamp_amp_shift_str_o                    => rtmlamp_amp_shift_str_o
  );

end architecture top;

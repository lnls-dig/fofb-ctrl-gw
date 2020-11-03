library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fofb_cc_pkg.all;

package fofb_ctrl_pkg is

  --------------------------------------------------------------------
  -- Components
  --------------------------------------------------------------------

  component fofb_ctrl_wrapper
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
    fai_sim_trigger_internal_i                 : in  std_logic := '0';
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
    fofb_link_status_o                         : out std_logic_vector(31 downto 0);
    fofb_fod_dat_o                             : out std_logic_vector((32*PacketSize-1) downto 0);
    fofb_fod_dat_val_o                         : out std_logic
  );
  end component;

end fofb_ctrl_pkg;

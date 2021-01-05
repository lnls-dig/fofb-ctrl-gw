library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fofb_cc_pkg.all;
use work.wishbone_pkg.all;

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
    fofb_fod_dat_val_o                         : out std_logic_vector(g_LANE_COUNT-1 downto 0)
  );
  end component;

  component wb_fofb_ctrl_wrapper
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
  end component;

  component xwb_fofb_ctrl_wrapper
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
  end component;

  component fmc4sfp_caen
  port (
    ---------------------------------------------------------------------------
    -- FMC board pins
    ---------------------------------------------------------------------------
    sfp_rx_p_i                                 : in    std_logic_vector(3 downto 0);
    sfp_rx_n_i                                 : in    std_logic_vector(3 downto 0);
    sfp_tx_p_o                                 : out   std_logic_vector(3 downto 0);
    sfp_tx_n_o                                 : out   std_logic_vector(3 downto 0);
    sfp_scl_b                                  : inout std_logic_vector(3 downto 0);
    sfp_sda_b                                  : inout std_logic_vector(3 downto 0);
    sfp_mod_abs_i                              : in    std_logic_vector(3 downto 0);
    sfp_rx_los_i                               : in    std_logic_vector(3 downto 0);
    sfp_tx_disable_o                           : out   std_logic_vector(3 downto 0);
    sfp_tx_fault_i                             : in    std_logic_vector(3 downto 0);
    sfp_rs0_o                                  : out   std_logic_vector(3 downto 0);
    sfp_rs1_o                                  : out   std_logic_vector(3 downto 0);

    si570_clk_p_i                              : in    std_logic;
    si570_clk_n_i                              : in    std_logic;
    si570_scl_b                                : inout std_logic;
    si570_sda_b                                : inout std_logic;

    ---------------------------------------------------------------------------
    -- FPGA side. Just a bypass for now
    ---------------------------------------------------------------------------
    fpga_sfp_rx_p_o                            : out    std_logic_vector(3 downto 0);
    fpga_sfp_rx_n_o                            : out    std_logic_vector(3 downto 0);
    fpga_sfp_tx_p_i                            : in     std_logic_vector(3 downto 0);
    fpga_sfp_tx_n_i                            : in     std_logic_vector(3 downto 0);
    fpga_sfp_mod_abs_o                         : out    std_logic_vector(3 downto 0);
    fpga_sfp_rx_los_o                          : out    std_logic_vector(3 downto 0);
    fpga_sfp_tx_disable_i                      : in     std_logic_vector(3 downto 0);
    fpga_sfp_tx_fault_o                        : out    std_logic_vector(3 downto 0);
    fpga_sfp_rs0_i                             : in     std_logic_vector(3 downto 0);
    fpga_sfp_rs1_i                             : in     std_logic_vector(3 downto 0);

    fpga_si570_clk_p_o                         : out    std_logic;
    fpga_si570_clk_n_o                         : out    std_logic
  );
  end component;

  component si57x_interface
  generic (
    g_SYS_CLOCK_FREQ                           : integer := 100000000;
    g_I2C_FREQ                                 : integer := 100000;
    -- Whether or not to initialize oscilator with the specified values
    g_INIT_OSC                                 : boolean := true;
    -- Init Oscillator values
    g_INIT_RFREQ_VALUE                         : std_logic_vector(37 downto 0) := "00" & x"3017a66ad";
    g_INIT_N1_VALUE                            : std_logic_vector(6 downto 0) := "0000011";
    g_INIT_HS_VALUE                            : std_logic_vector(2 downto 0) := "111"
  );
  port (
    ---------------------------------------------------------------------------
    -- clock and reset interface
    ---------------------------------------------------------------------------
    clk_sys_i                                  : in std_logic;
    rst_n_i                                    : in std_logic;

    ---------------------------------------------------------------------------
    -- Optional external RFFREQ interface
    ---------------------------------------------------------------------------
    ext_wr_i                                   : in std_logic := '0';
    ext_rfreq_value_i                          : in std_logic_vector(37 downto 0) := (others => '0');
    ext_n1_value_i                             : in std_logic_vector(6 downto 0) := (others => '0');
    ext_hs_value_i                             : in std_logic_vector(2 downto 0) := (others => '0');

    ---------------------------------------------------------------------------
    -- I2C bus: output enable (active low)
    ---------------------------------------------------------------------------
    scl_pad_oen_o                              : out std_logic;
    sda_pad_oen_o                              : out std_logic;

    ---------------------------------------------------------------------------
    -- SI57x pins
    ---------------------------------------------------------------------------
    -- Optional OE control
    si57x_oe_i                                 : in std_logic := '1';
    -- Si57x slave address. Default is (slave address & '0')
    si57x_addr_i                               : in std_logic_vector(7 downto 0) := "10101010";
    si57x_oe_o                                 : out std_logic

  );
  end component;

  component rtm8sfp_ohwr
  generic (
    g_NUM_SFPS                                 : integer := 8;
    g_SYS_CLOCK_FREQ                           : integer := 100000000;
    g_SI57x_I2C_FREQ                           : integer := 400000;
    -- Whether or not to initialize oscilator with the specified values
    g_SI57x_INIT_OSC                           : boolean := true;
    -- Init Oscillator values
    g_SI57x_INIT_RFREQ_VALUE                   : std_logic_vector(37 downto 0) := "00" & x"3017a66ad";
    g_SI57x_INIT_N1_VALUE                      : std_logic_vector(6 downto 0) := "0000011";
    g_SI57x_INIT_HS_VALUE                      : std_logic_vector(2 downto 0) := "111"
  );
  port (
    ---------------------------------------------------------------------------
    -- clock and reset interface
    ---------------------------------------------------------------------------
    clk_sys_i                                  : in std_logic;
    rst_n_i                                    : in std_logic;

    ---------------------------------------------------------------------------
    -- RTM board pins
    ---------------------------------------------------------------------------
    -- SFP
    sfp_rx_p_i                                 : in    std_logic_vector(g_NUM_SFPS-1 downto 0);
    sfp_rx_n_i                                 : in    std_logic_vector(g_NUM_SFPS-1 downto 0);
    sfp_tx_p_o                                 : out   std_logic_vector(g_NUM_SFPS-1 downto 0);
    sfp_tx_n_o                                 : out   std_logic_vector(g_NUM_SFPS-1 downto 0);

    -- RTM I2C.
    -- SFP configuration pins, behind a I2C MAX7356. I2C addr = 1110_100 & '0' = 0xE8
    -- Si570 oscillator. Input 0 of CDCLVD1212. I2C addr = 1010101 & '0' = 0x55
    rtm_scl_b                                  : inout std_logic;
    rtm_sda_b                                  : inout std_logic;

    -- Si570 oscillator output enable
    si570_oe_o                                 : out   std_logic;

    -- Clock to RTM connector. Input 1 of CDCLVD1212
    rtm_sync_clk_p_o                           : out   std_logic;
    rtm_sync_clk_n_o                           : out   std_logic;

    -- Select between input 0 or 1 or CDCLVD1212. 0 is Si570, 1 is RTM sync clock
    clk_in_sel_o                               : out   std_logic;

    -- FPGA clocks from CDCLVD1212
    fpga_clk1_p_i                              : in    std_logic;
    fpga_clk1_n_i                              : in    std_logic;
    fpga_clk2_p_i                              : in    std_logic;
    fpga_clk2_n_i                              : in    std_logic;

    -- SFP status bits. Behind 4 74HC165, 8-parallel-in/serial-out. 4 x 8 bits.
    -- The PISO chips are organized like this:
    --
    -- D0: SFP1_DETECT
    -- D1: SFP1_TXFAULT
    -- D2: SFP1_LOS
    -- D3: SFP1_LED1
    -- D4: SFP2_DETECT
    -- D5: SFP2_TXFAULT
    -- D6: SFP2_LOS
    -- D7: SFP2_LED1
    --
    -- ...
    --
    -- D0: SFP7_DETECT
    -- D1: SFP7_TXFAULT
    -- D2: SFP7_LOS
    -- D3: SFP7_LED1
    -- D4: SFP8_DETECT
    -- D5: SFP8_TXFAULT
    -- D6: SFP8_LOS
    -- D7: SFP8_LED1
    --
    -- So, after parallel load, each clock will shift the chain in the reverse
    -- order: SFP8_LED1, SFP8_LOS, SFP8_TXFAULT, SFP7_DETECT, ...
    --
    -- Parallel load
    sfp_status_reg_pl_o                        : out   std_logic;
    -- Clock N
    sfp_status_reg_clk_n_o                     : out   std_logic;
    -- Serial output
    sfp_status_reg_out_i                       : in    std_logic;

    -- SFP control bits. Behind 4 74HC4094D, serial-in/8-parallel-out. 5 x 8 bits.
    -- The SIPO chips are organized like this:
    --
    -- D0: SFP1_TXDISABLE
    -- D1: SFP1_RS0
    -- D2: SFP1_RS1
    -- D3: SFP1_LED1
    -- D4: SFP2_TXDISABLE
    -- D5: SFP2_RS0
    -- D6: SFP2_RS1
    -- D7: SFP2_LED1
    --
    -- ...
    --
    -- D0: SFP7_TXDISABLE
    -- D1: SFP7_RS0
    -- D2: SFP7_RS1
    -- D3: SFP7_LED1
    -- D4: SFP8_TXDISABLE
    -- D5: SFP8_RS0
    -- D6: SFP8_RS1
    -- D7: SFP8_LED1o
    --
    -- D0: SFP1_LED2
    -- D1: SFP2_LED2
    -- D2: SFP3_LED2
    -- D3: SFP4_LED2
    -- D4: SFP5_LED2
    -- D5: SFP6_LED2
    -- D6: SFP7_LED2
    -- D7: SFP8_LED2
    --
    --
    -- So, we must shift data in reverse order: SFP8_LED2, ..., SFP1_LED2,
    -- SFP8_LED1, SFP8_RS1LOS, SFP8_TXFAULT, SFP7_DETECT, ...
    --
    -- Strobe
    sfp_ctl_str_n_o                            : out   std_logic;
    -- Data input
    sfp_ctl_din_n_o                            : out   std_logic;
    -- Parallel output enable
    sfp_ctl_oe_n_o                             : out   std_logic;

    -- External clock from RTM to FPGA
    ext_clk_p_i                                : in    std_logic;
    ext_clk_n_i                                : in    std_logic;

    ---------------------------------------------------------------------------
    -- FPGA side. Just a bypass for now
    ---------------------------------------------------------------------------
    fpga_sfp_rx_p_o                            : out    std_logic_vector(g_NUM_SFPS-1 downto 0);
    fpga_sfp_rx_n_o                            : out    std_logic_vector(g_NUM_SFPS-1 downto 0);
    fpga_sfp_tx_p_i                            : in     std_logic_vector(g_NUM_SFPS-1 downto 0);
    fpga_sfp_tx_n_i                            : in     std_logic_vector(g_NUM_SFPS-1 downto 0);

    fpga_rtm_sync_clk_p_i                      : in     std_logic := '0';
    fpga_rtm_sync_clk_n_i                      : in     std_logic := '1';

    fpga_si570_oe_i                            : in     std_logic := '1';
    fpga_si57x_addr_i                          : in     std_logic_vector(7 downto 0) := "10101010";

    fpga_clk_in_sel_i                          : in     std_logic;

    fpga_clk1_p_o                              : out    std_logic;
    fpga_clk1_n_o                              : out    std_logic;
    fpga_clk2_p_o                              : out    std_logic;
    fpga_clk2_n_o                              : out    std_logic;

    fpga_ext_clk_p_o                           : out    std_logic;
    fpga_ext_clk_n_o                           : out    std_logic
  );
  end component;

  --------------------------------------------------------------------
  -- SDB Devices Structures
  --------------------------------------------------------------------

  -- FOFB CC
  constant c_xwb_fofb_cc_regs_sdb : t_sdb_device := (
    abi_class     => x"0000",                   -- undocumented device
    abi_ver_major => x"01",
    abi_ver_minor => x"00",
    wbd_endian    => c_sdb_endian_big,
    wbd_width     => x"4",                      -- 32-bit port granularity (0100)
    sdb_component => (
    addr_first    => x"0000000000000000",
    addr_last     => x"0000000000000FFF",
    product => (
    vendor_id     => x"1000000000001215",       -- LNLS
    device_id     => x"4a1df147",
    version       => x"00000001",
    date          => x"20201109",
    name          => "DLS_DCC_REGS       ")));

end fofb_ctrl_pkg;

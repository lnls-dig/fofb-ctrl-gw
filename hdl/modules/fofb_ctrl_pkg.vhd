library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fofb_cc_pkg.all;
use work.wishbone_pkg.all;
use work.mult_pkg.all;

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
    g_PHYSICAL_INTERFACE                      : string  := "SFP";
    g_REFCLK_INPUT                            : string  := "REFCLK0";
    g_CLK_BUFFERS                             : boolean := true;
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
    refclk_p_i                                 : in std_logic := '0';
    refclk_n_i                                 : in std_logic := '1';

    ---------------------------------------------------------------------------
    -- external clocks/resets input from adjacent DCC
    ---------------------------------------------------------------------------
    -- Only used when CLK_BUFFERS := false
    ext_initclk_i                              : in std_logic := '0';
    ext_refclk_i                               : in std_logic := '0';

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
    fofb_userclk_2x_o                          : out std_logic;
    fofb_userrst_o                             : out std_logic;
    fofb_initclk_o                             : out std_logic;
    fofb_refclk_o                              : out std_logic;
    fofb_mgtreset_o                            : out std_logic;
    fofb_gtreset_o                             : out std_logic;
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
    g_PHYSICAL_INTERFACE                      : string  := "SFP";
    g_REFCLK_INPUT                            : string  := "REFCLK0";
    g_CLK_BUFFERS                             : boolean := true;
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
    refclk_p_i                                 : in std_logic := '0';
    refclk_n_i                                 : in std_logic := '1';

    ---------------------------------------------------------------------------
    -- external clocks/resets input from adjacent DCC
    ---------------------------------------------------------------------------
    -- Only used when CLK_BUFFERS := false
    ext_initclk_i                              : in std_logic := '0';
    ext_refclk_i                               : in std_logic := '0';

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
    fofb_userclk_2x_o                          : out std_logic;
    fofb_userrst_o                             : out std_logic;
    fofb_initclk_o                             : out std_logic;
    fofb_refclk_o                              : out std_logic;
    fofb_mgtreset_o                            : out std_logic;
    fofb_gtreset_o                             : out std_logic;
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
    g_PHYSICAL_INTERFACE                      : string  := "SFP";
    g_REFCLK_INPUT                            : string  := "REFCLK0";
    g_CLK_BUFFERS                             : boolean := true;
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
    refclk_p_i                                 : in std_logic := '0';
    refclk_n_i                                 : in std_logic := '1';

    ---------------------------------------------------------------------------
    -- external clocks/resets input from adjacent DCC
    ---------------------------------------------------------------------------
    -- Only used when CLK_BUFFERS := false
    ext_initclk_i                              : in std_logic := '0';
    ext_refclk_i                               : in std_logic := '0';

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
    fofb_userclk_2x_o                          : out std_logic;
    fofb_userrst_o                             : out std_logic;
    fofb_initclk_o                             : out std_logic;
    fofb_refclk_o                              : out std_logic;
    fofb_mgtreset_o                            : out std_logic;
    fofb_gtreset_o                             : out std_logic;
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

  component wb_matmul_wrapper
  generic
  (
    -- Standard parameters of generic_dpram
    g_data_width                               : natural := 32;
    g_size                                     : natural := c_size_dpram;
    g_with_byte_enable                         : boolean := false;
    g_addr_conflict_resolution                 : string  := "read_first";
    g_init_file                                : string  := "";
    g_dual_clock                               : boolean := true;
    g_fail_if_file_not_found                   : boolean := true;
    -- Width for inputs x and y
    g_a_width                                  : natural := 32;
    -- Width for ram data
    g_b_width                                  : natural := 32;
    -- Width for ram addr
    g_k_width                                  : natural := 11;
    -- Width for output c
    g_c_width                                  : natural := 32;
    -- Matrix multiplication size
    g_mat_size                                 : natural := 4;
    -- Wishbone parameters
    g_INTERFACE_MODE                           : t_wishbone_interface_mode      := CLASSIC;
    g_ADDRESS_GRANULARITY                      : t_wishbone_address_granularity := WORD;
    g_WITH_EXTRA_WB_REG                        : boolean := false
  );
  port
  (
    ---------------------------------------------------------------------------
    -- Clock and reset interface
    ---------------------------------------------------------------------------
    clk_i                                      : in std_logic;
    rst_n_i                                    : in std_logic;
    clk_sys_i                                  : in std_logic;
    rst_sys_n_i                                : in std_logic;

    ---------------------------------------------------------------------------
    -- Matmul Top Level Interface Signals
    ---------------------------------------------------------------------------
    -- DCC interface
    dcc_valid_i                                : in std_logic;
    dcc_coeff_x_i                              : in signed(g_a_width-1 downto 0);
    dcc_coeff_y_i                              : in signed(g_a_width-1 downto 0);
    dcc_addr_i                                 : in std_logic_vector(g_k_width-1 downto 0);

    -- Result output array
    spx_o                                      : out t_matmul_array_signed(g_mat_size-1 downto 0);
    spy_o                                      : out t_matmul_array_signed(g_mat_size-1 downto 0);

    -- Valid output for debugging
    spx_valid_debug_o                          : out std_logic_vector(g_mat_size-1 downto 0);
    spy_valid_debug_o                          : out std_logic_vector(g_mat_size-1 downto 0);

    -- Valid end of fofb cycle
    spx_valid_end_o                            : out std_logic_vector(g_mat_size-1 downto 0);
    spy_valid_end_o                            : out std_logic_vector(g_mat_size-1 downto 0);

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
    wb_stall_o                                 : out std_logic
  );
  end component;

  component xwb_matmul_wrapper
  generic
  (
    -- Standard parameters of generic_dpram
    g_data_width                               : natural := 32;
    g_size                                     : natural := c_size_dpram;
    g_with_byte_enable                         : boolean := false;
    g_addr_conflict_resolution                 : string  := "read_first";
    g_init_file                                : string  := "";
    g_dual_clock                               : boolean := true;
    g_fail_if_file_not_found                   : boolean := true;
    -- Width for inputs x and y
    g_a_width                                  : natural := 32;
    -- Width for ram data
    g_b_width                                  : natural := 32;
    -- Width for ram addr
    g_k_width                                  : natural := 11;
    -- Width for output c
    g_c_width                                  : natural := 32;
    -- Matrix multiplication size
    g_mat_size                                 : natural := 4;
    -- Wishbone parameters
    g_INTERFACE_MODE                           : t_wishbone_interface_mode      := CLASSIC;
    g_ADDRESS_GRANULARITY                      : t_wishbone_address_granularity := WORD;
    g_WITH_EXTRA_WB_REG                        : boolean := false
  );
  port
  (
    ---------------------------------------------------------------------------
    -- Clock and reset interface
    ---------------------------------------------------------------------------
    clk_i                                      : in std_logic;
    rst_n_i                                    : in std_logic;
    clk_sys_i                                  : in std_logic;
    rst_sys_n_i                                : in std_logic;

    ---------------------------------------------------------------------------
    -- Matmul Top Level Interface Signals
    ---------------------------------------------------------------------------
    -- DCC interface
    dcc_valid_i                                : in std_logic;
    dcc_coeff_x_i                              : in signed(g_a_width-1 downto 0);
    dcc_coeff_y_i                              : in signed(g_a_width-1 downto 0);
    dcc_addr_i                                 : in std_logic_vector(g_k_width-1 downto 0);

    -- Result output array
    spx_o                                      : out t_matmul_array_signed(g_mat_size-1 downto 0);
    spy_o                                      : out t_matmul_array_signed(g_mat_size-1 downto 0);

    -- Valid output for debugging
    spx_valid_debug_o                          : out std_logic_vector(g_mat_size-1 downto 0);
    spy_valid_debug_o                          : out std_logic_vector(g_mat_size-1 downto 0);

    -- Valid end of fofb cycle
    spx_valid_end_o                            : out std_logic_vector(g_mat_size-1 downto 0);
    spy_valid_end_o                            : out std_logic_vector(g_mat_size-1 downto 0);

    ---------------------------------------------------------------------------
    -- Wishbone Control Interface signals
    ---------------------------------------------------------------------------
    wb_slv_i                                   : in t_wishbone_slave_in;
    wb_slv_o                                   : out t_wishbone_slave_out
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
    addr_last     => x"000000000000FFFF",
    product => (
    vendor_id     => x"1000000000000d15",       -- DLS
    device_id     => x"4a1df147",
    version       => x"00000001",
    date          => x"20201109",
    name          => "DLS_DCC_REGS       ")));

  -- Matmul
  constant c_xwb_matmul_regs_sdb : t_sdb_device := (
    abi_class     => x"0000",                   -- undocumented device
    abi_ver_major => x"01",
    abi_ver_minor => x"00",
    wbd_endian    => c_sdb_endian_big,
    wbd_width     => x"4",                      -- 32-bit port granularity (0100)
    sdb_component => (
    addr_first    => x"0000000000000000",
    addr_last     => x"00000000000000FF",
    product => (
    vendor_id     => x"1000000000000d15",       -- DLS
    device_id     => x"49681ca6",
    version       => x"00000001",
    date          => x"20210819",
    name          => "MATMUL_REGS       ")));

end fofb_ctrl_pkg;

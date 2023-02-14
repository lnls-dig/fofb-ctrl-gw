-------------------------------------------------------------------------------
-- Title      :  Wishbone fofb processing wrapper
-------------------------------------------------------------------------------
-- Author     :  Melissa Aguiar
-- Company    :  CNPEM LNLS-DIG
-- Platform   :  FPGA-generic
-------------------------------------------------------------------------------
-- Description:  Wishbone fofb processing wrapper
-------------------------------------------------------------------------------
-- Copyright (c) 2020-2022 CNPEM
-- Licensed under GNU Lesser General Public License (LGPL) v3.0
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                Description
-- 2021-08-19  1.0      melissa.aguiar        Created
-- 2022-07-27  1.1      guilherme.ricioli     Changed coeffs RAMs' wb interface
-- 2022-09-05  2.0      augusto.fraga         Update to match the new
--                                            fofb_processing API
-- 2022-01-11  2.1      guilherme.ricioli     Expose loop interlock regs
-- 2023-02-10  3.0      guilherme.ricioli     Update to match the new
--                                            wb_fofb_processing_regs api
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

library work;
-- Dot product package
use work.dot_prod_pkg.all;
-- Main Wishbone Definitions
use work.wishbone_pkg.all;
-- General common cores
use work.gencores_pkg.all;
-- FOFB CTRL package
use work.fofb_ctrl_pkg.all;

entity xwb_fofb_processing is
  generic (
    -- Integer width for the inverse response matrix coefficient input
    g_COEFF_INT_WIDTH              : natural := 0;

    -- Fractionary width for the inverse response matrix coefficient input
    g_COEFF_FRAC_WIDTH             : natural := 17;

    -- Integer width for the BPM position error input
    g_BPM_POS_INT_WIDTH            : natural := 20;

    -- Fractionary width for the BPM position error input
    g_BPM_POS_FRAC_WIDTH           : natural := 0;

    -- Extra bits for the dot product accumulator
    g_DOT_PROD_ACC_EXTRA_WIDTH     : natural := 4;

    -- Dot product multiply pipeline stages
    g_DOT_PROD_MUL_PIPELINE_STAGES : natural := 1;

    -- Dot product accumulator pipeline stages
    g_DOT_PROD_ACC_PIPELINE_STAGES : natural := 1;

    -- Gain multiplication pipeline stages
    g_ACC_GAIN_MUL_PIPELINE_STAGES : natural := 1;

    -- If true, take the average of the last 2 positions for each BPM
    g_USE_MOVING_AVG               : boolean := false;

    -- Number of channels
    g_CHANNELS                     : natural;

    -- Wishbone parameters
    g_INTERFACE_MODE               : t_wishbone_interface_mode      := CLASSIC;
    g_ADDRESS_GRANULARITY          : t_wishbone_address_granularity := WORD;
    g_WITH_EXTRA_WB_REG            : boolean := false
  );
  port (
    -- Clock
    clk_i                          : in  std_logic;

    -- Reset
    rst_n_i                        : in  std_logic;

    -- If busy_o = '1', core is busy, can't receive new data
    busy_o                         : out std_logic;

    -- BPM position measurement (either horizontal or vertical)
    bpm_pos_i                      : in  signed(c_SP_POS_RAM_DATA_WIDTH-1 downto 0);

    -- BPM index, 0 to 255 for horizontal measurements, 256 to 511 for vertical
    -- measurements
    bpm_pos_index_i                : in  unsigned(c_SP_COEFF_RAM_ADDR_WIDTH-1 downto 0);

    -- BPM position valid
    bpm_pos_valid_i                : in  std_logic;

    -- End of time frame, computes the next set-point
    bpm_time_frame_end_i           : in  std_logic;

    -- Set-points output array (for each channel)
    sp_arr_o                       : out t_fofb_processing_sp_arr(g_CHANNELS-1 downto 0);

    -- Set-point valid array (for each channel)
    sp_valid_arr_o                 : out std_logic_vector(g_CHANNELS-1 downto 0);

    dcc_p2p_en_o                   : out std_logic;

    ---------------------------------------------------------------------------
    -- Wishbone Control Interface signals
    ---------------------------------------------------------------------------
    wb_slv_i                       : in t_wishbone_slave_in;
    wb_slv_o                       : out t_wishbone_slave_out
  );
  end xwb_fofb_processing;

architecture rtl of xwb_fofb_processing is
  -----------------------------
  -- General contants
  -----------------------------

  -- Number of bits in Wishbone register interface. Plus 2 to account for BYTE addressing
  constant c_PERIPH_ADDR_SIZE    : natural := 13+2;

  -- The wishbone interface can't be parameterized via generics, so it contains
  -- the maximum fofb processing channels supported, g_CHANNELS should be less
  -- or equal to c_MAX_CHANNELS
  constant c_MAX_CHANNELS        : natural := 12;

  -- Coefficient fixed point position, used indicate to the upper software
  -- layers how to convert a floating point number to fixed point. In this
  -- particular case, we only take in consideration the most significant bits,
  -- so the fixed point number is aligned to the left
  constant c_COEFF_FIXED_POINT_POS_VAL : std_logic_vector(31 downto 0) :=
      std_logic_vector(to_unsigned(31 - g_COEFF_INT_WIDTH, 32));

  -- Gain fixed point position, used indicate to the upper software
  -- layers how to convert a floating point number to fixed point. In this
  -- particular case, we only take in consideration the most significant bits,
  -- so the fixed point number is aligned to the left
  constant c_GAIN_FIXED_POINT_POS_VAL : std_logic_vector(31 downto 0) :=
      std_logic_vector(to_unsigned(31 - c_FOFB_GAIN_INT_WIDTH, 32));

  -----------------------------
  -- Signals
  -----------------------------

  -- Accumulator clear bit array (for each fofb channel)
  signal acc_ctl_clear_arr  : std_logic_vector(c_MAX_CHANNELS-1 downto 0) := (others => '0');
  -- Accumulator freeze bit array  (for each fofb channel)
  signal acc_ctl_freeze_arr : std_logic_vector(c_MAX_CHANNELS-1 downto 0) := (others => '0');

  -----------------------------
  -- Set-point RAM signals
  -----------------------------
  signal sps_ram_bank_adr       : std_logic_vector(c_SP_COEFF_RAM_ADDR_WIDTH-1 downto 0);
  signal sps_ram_bank_data_dat  : std_logic_vector(c_SP_POS_RAM_DATA_WIDTH-1 downto 0);

  -- Gain array
  signal gain_arr         : t_fofb_processing_gain_arr(g_CHANNELS-1 downto 0);
  signal acc_gain_val_arr : t_fofb_processing_wb_gain_arr(c_MAX_CHANNELS-1 downto 0) := (others => (others => '0'));

  -----------------------------
  -- Coefficients RAM signals
  -----------------------------
  signal coeff_ram_addr_arr : t_arr_coeff_ram_addr(c_MAX_CHANNELS-1 downto 0);
  signal coeff_ram_data_arr : t_arr_coeff_ram_data(c_MAX_CHANNELS-1 downto 0);

  -----------------------------
  -- Output saturation signals
  -----------------------------
  signal sp_max_arr             : t_fofb_processing_sp_arr(g_CHANNELS-1 downto 0);
  signal sp_min_arr             : t_fofb_processing_sp_arr(g_CHANNELS-1 downto 0);
  signal sp_limits_max_val_arr  : t_fofb_processing_wb_sp_arr(c_MAX_CHANNELS-1 downto 0);
  signal sp_limits_min_val_arr  : t_fofb_processing_wb_sp_arr(c_MAX_CHANNELS-1 downto 0);

  -----------------------------
  -- Loop interlock signals
  -----------------------------
  signal loop_intlk_src_en                : std_logic_vector(c_FOFB_LOOP_INTLK_TRIGS_WIDTH-1 downto 0);
  signal loop_intlk_ctl_sta_clr           : std_logic;
  signal loop_intlk_sta                   : std_logic_vector(c_FOFB_LOOP_INTLK_TRIGS_WIDTH-1 downto 0);
  signal loop_intlk_distort_limit         : unsigned(g_BPM_POS_INT_WIDTH-1 downto 0);
  signal loop_intlk_min_num_meas          : unsigned(c_SP_COEFF_RAM_ADDR_WIDTH-1 downto 0);
  signal loop_intlk_orb_distort_limit_val : std_logic_vector(31 downto 0);
  signal loop_intlk_min_num_pkts_val      : std_logic_vector(31 downto 0);

  -----------------------------
  -- Wishbone slave adapter signals/structures
  -----------------------------
  signal wb_slv_adp_out          : t_wishbone_master_out;
  signal wb_slv_adp_in           : t_wishbone_master_in;
  signal resized_addr            : std_logic_vector(c_WISHBONE_ADDRESS_WIDTH-1 downto 0);

  -- Extra Wishbone registering stage
  signal wb_slave_in             : t_wishbone_slave_in_array (0 downto 0);
  signal wb_slave_out            : t_wishbone_slave_out_array(0 downto 0);
  signal wb_slave_in_reg0        : t_wishbone_slave_in_array (0 downto 0);
  signal wb_slave_out_reg0       : t_wishbone_slave_out_array(0 downto 0);

begin

  cmp_fofb_processing: fofb_processing
    generic map (
      g_COEFF_INT_WIDTH               => g_COEFF_INT_WIDTH,
      g_COEFF_FRAC_WIDTH              => g_COEFF_FRAC_WIDTH,
      g_BPM_POS_INT_WIDTH             => g_BPM_POS_INT_WIDTH,
      g_BPM_POS_FRAC_WIDTH            => g_BPM_POS_FRAC_WIDTH,
      g_DOT_PROD_ACC_EXTRA_WIDTH      => g_DOT_PROD_ACC_EXTRA_WIDTH,
      g_DOT_PROD_MUL_PIPELINE_STAGES  => g_DOT_PROD_MUL_PIPELINE_STAGES,
      g_DOT_PROD_ACC_PIPELINE_STAGES  => g_DOT_PROD_ACC_PIPELINE_STAGES,
      g_ACC_GAIN_MUL_PIPELINE_STAGES  => g_ACC_GAIN_MUL_PIPELINE_STAGES,
      g_USE_MOVING_AVG                => g_USE_MOVING_AVG,
      g_CHANNELS                      => g_CHANNELS
    )
    port map (
      clk_i                           => clk_i,
      rst_n_i                         => rst_n_i,
      busy_o                          => busy_o,
      bpm_pos_i                       => bpm_pos_i,
      bpm_pos_index_i                 => bpm_pos_index_i,
      bpm_pos_valid_i                 => bpm_pos_valid_i,
      bpm_time_frame_end_i            => bpm_time_frame_end_i,
      coeff_ram_addr_arr_o            => coeff_ram_addr_arr(g_CHANNELS-1 downto 0),
      coeff_ram_data_arr_i            => coeff_ram_data_arr(g_CHANNELS-1 downto 0),
      sp_pos_ram_addr_o               => sps_ram_bank_adr,
      sp_pos_ram_data_i               => sps_ram_bank_data_dat,
      gain_arr_i                      => gain_arr(g_CHANNELS-1 downto 0),
      clear_acc_arr_i                 => acc_ctl_clear_arr(g_CHANNELS-1 downto 0),
      freeze_acc_arr_i                => acc_ctl_freeze_arr(g_CHANNELS-1 downto 0),
      sp_max_arr_i                    => sp_max_arr,
      sp_min_arr_i                    => sp_min_arr,
      sp_arr_o                        => sp_arr_o,
      sp_valid_arr_o                  => sp_valid_arr_o,
      loop_intlk_src_en_i             => loop_intlk_src_en,
      loop_intlk_state_clr_i          => loop_intlk_ctl_sta_clr,
      loop_intlk_state_o              => loop_intlk_sta,
      loop_intlk_distort_limit_i      => loop_intlk_distort_limit,
      loop_intlk_min_num_meas_i       => loop_intlk_min_num_meas
    );

  -----------------------------
  -- Insert extra Wishbone registering stage for ease timing.
  -- It effectively cuts the bandwidth in half!
  -----------------------------
  gen_with_extra_wb_reg : if g_WITH_EXTRA_WB_REG generate
    cmp_register_link : xwb_register_link -- puts a register of delay between crossbars
      port map (
        clk_sys_i => clk_i,
        rst_n_i   => rst_n_i,
        slave_i   => wb_slave_in_reg0(0),
        slave_o   => wb_slave_out_reg0(0),
        master_i  => wb_slave_out(0),
        master_o  => wb_slave_in(0)
      );

      wb_slave_in_reg0(0) <= wb_slv_i;
      wb_slv_o            <= wb_slave_out_reg0(0);
    end generate;

  gen_without_extra_wb_reg : if not g_WITH_EXTRA_WB_REG generate
    -- External master connection
    wb_slave_in(0)  <= wb_slv_i;
    wb_slv_o        <= wb_slave_out(0);
  end generate;

  -----------------------------
  -- Slave adapter for Wishbone Register Interface
  -----------------------------
  cmp_slave_adapter : wb_slave_adapter
    generic map (
      g_MASTER_USE_STRUCT   => true,
      g_MASTER_MODE         => PIPELINED,
      -- TODO: it seems that using cheby without wbgen compatibility requires
      -- g_MASTER_GRANULARITY to be byte
      g_MASTER_GRANULARITY  => BYTE,
      g_SLAVE_USE_STRUCT    => false,
      g_SLAVE_MODE          => g_INTERFACE_MODE,
      g_SLAVE_GRANULARITY   => g_ADDRESS_GRANULARITY
    )
    port map (
      clk_sys_i             => clk_i,
      rst_n_i               => rst_n_i,
      master_i              => wb_slv_adp_in,
      master_o              => wb_slv_adp_out,
      sl_adr_i              => resized_addr,
      sl_dat_i              => wb_slave_in(0).dat,
      sl_sel_i              => wb_slave_in(0).sel,
      sl_cyc_i              => wb_slave_in(0).cyc,
      sl_stb_i              => wb_slave_in(0).stb,
      sl_we_i               => wb_slave_in(0).we,
      sl_dat_o              => wb_slave_out(0).dat,
      sl_ack_o              => wb_slave_out(0).ack,
      sl_rty_o              => wb_slave_out(0).rty,
      sl_err_o              => wb_slave_out(0).err,
      sl_stall_o            => wb_slave_out(0).stall
    );

    gen_wb_slave_in_addr_conn : if g_ADDRESS_GRANULARITY = WORD generate
      -- By doing this zeroing we avoid the issue related to BYTE -> WORD  conversion
      -- slave addressing (possibly performed by the slave adapter component)
      -- in which a bit in the MSB of the peripheral addressing part (31 downto c_PERIPH_ADDR_SIZE in our case)
      -- is shifted to the internal register adressing part (c_PERIPH_ADDR_SIZE-1 downto 0 in our case).
      -- Therefore, possibly changing the these bits!
      resized_addr(c_PERIPH_ADDR_SIZE-1 downto 0)
                                   <= wb_slave_in(0).adr(c_PERIPH_ADDR_SIZE-1 downto 0);
      resized_addr(c_WISHBONE_ADDRESS_WIDTH-1 downto c_PERIPH_ADDR_SIZE)
                                   <= (others => '0');
    else generate
      resized_addr <= wb_slave_in(0).adr;
    end generate;


  gen_wb_conn: for i in 0 to g_CHANNELS-1
  generate
    -- fixed-point values are aligned to the left
    gain_arr(i) <= signed(acc_gain_val_arr(i)(c_FOFB_WB_GAIN_WIDTH-1 downto c_FOFB_WB_GAIN_WIDTH-c_FOFB_GAIN_WIDTH));

    sp_max_arr(i) <= signed(sp_limits_max_val_arr(i)(c_FOFB_SP_WIDTH-1 downto 0));
    sp_min_arr(i) <= signed(sp_limits_min_val_arr(i)(c_FOFB_SP_WIDTH-1 downto 0));
  end generate gen_wb_conn;

  loop_intlk_distort_limit <= unsigned(loop_intlk_orb_distort_limit_val(loop_intlk_distort_limit'left downto 0));
  -- Each DCC packet has 2 measurements
  loop_intlk_min_num_meas <= shift_left(unsigned(loop_intlk_min_num_pkts_val(loop_intlk_min_num_meas'left downto 0)), 1);

  cmp_wb_fofb_processing_regs: entity work.wb_fofb_processing_regs
    port map (
      rst_n_i                             => rst_n_i,
      clk_i                               => clk_i,
      wb_i                                => wb_slv_adp_out,
      wb_o                                => wb_slv_adp_in,
      fixed_point_pos_coeff_val_i         => c_COEFF_FIXED_POINT_POS_VAL,
      fixed_point_pos_accs_gains_val_i    => c_GAIN_FIXED_POINT_POS_VAL,
      loop_intlk_ctl_sta_clr_o            => loop_intlk_ctl_sta_clr,
      loop_intlk_ctl_src_en_orb_distort_o => loop_intlk_src_en(c_FOFB_LOOP_INTLK_DISTORT_ID),
      loop_intlk_ctl_src_en_packet_loss_o => loop_intlk_src_en(c_FOFB_LOOP_INTLK_PKT_LOSS_ID),
      loop_intlk_sta_orb_distort_i        => loop_intlk_sta(c_FOFB_LOOP_INTLK_DISTORT_ID),
      loop_intlk_sta_packet_loss_i        => loop_intlk_sta(c_FOFB_LOOP_INTLK_PKT_LOSS_ID),
      loop_intlk_orb_distort_limit_val_o  => loop_intlk_orb_distort_limit_val,
      loop_intlk_min_num_pkts_val_o       => loop_intlk_min_num_pkts_val,
      sps_ram_bank_adr_i                  => sps_ram_bank_adr,
      sps_ram_bank_data_rd_i              => '0',
      sps_ram_bank_data_dat_o             => sps_ram_bank_data_dat,
      ch_0_coeff_ram_bank_adr_i           => coeff_ram_addr_arr(0),
      ch_0_coeff_ram_bank_data_rd_i       => '0',
      ch_0_coeff_ram_bank_data_dat_o      => coeff_ram_data_arr(0),
      ch_0_acc_ctl_clear_o                => acc_ctl_clear_arr(0),
      ch_0_acc_ctl_freeze_o               => acc_ctl_freeze_arr(0),
      ch_0_acc_gain_val_o                 => acc_gain_val_arr(0),
      ch_0_sp_limits_max_val_o            => sp_limits_max_val_arr(0),
      ch_0_sp_limits_min_val_o            => sp_limits_min_val_arr(0),
      ch_1_coeff_ram_bank_adr_i           => coeff_ram_addr_arr(1),
      ch_1_coeff_ram_bank_data_rd_i       => '0',
      ch_1_coeff_ram_bank_data_dat_o      => coeff_ram_data_arr(1),
      ch_1_acc_ctl_clear_o                => acc_ctl_clear_arr(1),
      ch_1_acc_ctl_freeze_o               => acc_ctl_freeze_arr(1),
      ch_1_acc_gain_val_o                 => acc_gain_val_arr(1),
      ch_1_sp_limits_max_val_o            => sp_limits_max_val_arr(1),
      ch_1_sp_limits_min_val_o            => sp_limits_min_val_arr(1),
      ch_2_coeff_ram_bank_adr_i           => coeff_ram_addr_arr(2),
      ch_2_coeff_ram_bank_data_rd_i       => '0',
      ch_2_coeff_ram_bank_data_dat_o      => coeff_ram_data_arr(2),
      ch_2_acc_ctl_clear_o                => acc_ctl_clear_arr(2),
      ch_2_acc_ctl_freeze_o               => acc_ctl_freeze_arr(2),
      ch_2_acc_gain_val_o                 => acc_gain_val_arr(2),
      ch_2_sp_limits_max_val_o            => sp_limits_max_val_arr(2),
      ch_2_sp_limits_min_val_o            => sp_limits_min_val_arr(2),
      ch_3_coeff_ram_bank_adr_i           => coeff_ram_addr_arr(3),
      ch_3_coeff_ram_bank_data_rd_i       => '0',
      ch_3_coeff_ram_bank_data_dat_o      => coeff_ram_data_arr(3),
      ch_3_acc_ctl_clear_o                => acc_ctl_clear_arr(3),
      ch_3_acc_ctl_freeze_o               => acc_ctl_freeze_arr(3),
      ch_3_acc_gain_val_o                 => acc_gain_val_arr(3),
      ch_3_sp_limits_max_val_o            => sp_limits_max_val_arr(3),
      ch_3_sp_limits_min_val_o            => sp_limits_min_val_arr(3),
      ch_4_coeff_ram_bank_adr_i           => coeff_ram_addr_arr(4),
      ch_4_coeff_ram_bank_data_rd_i       => '0',
      ch_4_coeff_ram_bank_data_dat_o      => coeff_ram_data_arr(4),
      ch_4_acc_ctl_clear_o                => acc_ctl_clear_arr(4),
      ch_4_acc_ctl_freeze_o               => acc_ctl_freeze_arr(4),
      ch_4_acc_gain_val_o                 => acc_gain_val_arr(4),
      ch_4_sp_limits_max_val_o            => sp_limits_max_val_arr(4),
      ch_4_sp_limits_min_val_o            => sp_limits_min_val_arr(4),
      ch_5_coeff_ram_bank_adr_i           => coeff_ram_addr_arr(5),
      ch_5_coeff_ram_bank_data_rd_i       => '0',
      ch_5_coeff_ram_bank_data_dat_o      => coeff_ram_data_arr(5),
      ch_5_acc_ctl_clear_o                => acc_ctl_clear_arr(5),
      ch_5_acc_ctl_freeze_o               => acc_ctl_freeze_arr(5),
      ch_5_acc_gain_val_o                 => acc_gain_val_arr(5),
      ch_5_sp_limits_max_val_o            => sp_limits_max_val_arr(5),
      ch_5_sp_limits_min_val_o            => sp_limits_min_val_arr(5),
      ch_6_coeff_ram_bank_adr_i           => coeff_ram_addr_arr(6),
      ch_6_coeff_ram_bank_data_rd_i       => '0',
      ch_6_coeff_ram_bank_data_dat_o      => coeff_ram_data_arr(6),
      ch_6_acc_ctl_clear_o                => acc_ctl_clear_arr(6),
      ch_6_acc_ctl_freeze_o               => acc_ctl_freeze_arr(6),
      ch_6_acc_gain_val_o                 => acc_gain_val_arr(6),
      ch_6_sp_limits_max_val_o            => sp_limits_max_val_arr(6),
      ch_6_sp_limits_min_val_o            => sp_limits_min_val_arr(6),
      ch_7_coeff_ram_bank_adr_i           => coeff_ram_addr_arr(7),
      ch_7_coeff_ram_bank_data_rd_i       => '0',
      ch_7_coeff_ram_bank_data_dat_o      => coeff_ram_data_arr(7),
      ch_7_acc_ctl_clear_o                => acc_ctl_clear_arr(7),
      ch_7_acc_ctl_freeze_o               => acc_ctl_freeze_arr(7),
      ch_7_acc_gain_val_o                 => acc_gain_val_arr(7),
      ch_7_sp_limits_max_val_o            => sp_limits_max_val_arr(7),
      ch_7_sp_limits_min_val_o            => sp_limits_min_val_arr(7),
      ch_8_coeff_ram_bank_adr_i           => coeff_ram_addr_arr(8),
      ch_8_coeff_ram_bank_data_rd_i       => '0',
      ch_8_coeff_ram_bank_data_dat_o      => coeff_ram_data_arr(8),
      ch_8_acc_ctl_clear_o                => acc_ctl_clear_arr(8),
      ch_8_acc_ctl_freeze_o               => acc_ctl_freeze_arr(8),
      ch_8_acc_gain_val_o                 => acc_gain_val_arr(8),
      ch_8_sp_limits_max_val_o            => sp_limits_max_val_arr(8),
      ch_8_sp_limits_min_val_o            => sp_limits_min_val_arr(8),
      ch_9_coeff_ram_bank_adr_i           => coeff_ram_addr_arr(9),
      ch_9_coeff_ram_bank_data_rd_i       => '0',
      ch_9_coeff_ram_bank_data_dat_o      => coeff_ram_data_arr(9),
      ch_9_acc_ctl_clear_o                => acc_ctl_clear_arr(9),
      ch_9_acc_ctl_freeze_o               => acc_ctl_freeze_arr(9),
      ch_9_acc_gain_val_o                 => acc_gain_val_arr(9),
      ch_9_sp_limits_max_val_o            => sp_limits_max_val_arr(9),
      ch_9_sp_limits_min_val_o            => sp_limits_min_val_arr(9),
      ch_10_coeff_ram_bank_adr_i          => coeff_ram_addr_arr(10),
      ch_10_coeff_ram_bank_data_rd_i      => '0',
      ch_10_coeff_ram_bank_data_dat_o     => coeff_ram_data_arr(10),
      ch_10_acc_ctl_clear_o               => acc_ctl_clear_arr(10),
      ch_10_acc_ctl_freeze_o              => acc_ctl_freeze_arr(10),
      ch_10_acc_gain_val_o                => acc_gain_val_arr(10),
      ch_10_sp_limits_max_val_o           => sp_limits_max_val_arr(10),
      ch_10_sp_limits_min_val_o           => sp_limits_min_val_arr(10),
      ch_11_coeff_ram_bank_adr_i          => coeff_ram_addr_arr(11),
      ch_11_coeff_ram_bank_data_rd_i      => '0',
      ch_11_coeff_ram_bank_data_dat_o     => coeff_ram_data_arr(11),
      ch_11_acc_ctl_clear_o               => acc_ctl_clear_arr(11),
      ch_11_acc_ctl_freeze_o              => acc_ctl_freeze_arr(11),
      ch_11_acc_gain_val_o                => acc_gain_val_arr(11),
      ch_11_sp_limits_max_val_o           => sp_limits_max_val_arr(11),
      ch_11_sp_limits_min_val_o           => sp_limits_min_val_arr(11)
    );

    dcc_p2p_en_o <= not loop_intlk_sta(c_FOFB_LOOP_INTLK_PKT_LOSS_ID);

end architecture rtl;

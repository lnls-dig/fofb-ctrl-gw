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
-- 2022-01-11  2.3      guilherme.ricioli     Expose loop interlock regs
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
    wb_slv_i                     : in t_wishbone_slave_in;
    wb_slv_o                     : out t_wishbone_slave_out
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
  signal clear_acc_arr        : std_logic_vector(c_MAX_CHANNELS-1 downto 0) := (others => '0');
  -- Accumulator freeze bit array  (for each fofb channel)
  signal freeze_acc_arr       : std_logic_vector(c_MAX_CHANNELS-1 downto 0) := (others => '0');

  -----------------------------
  -- Set-point RAM signals
  -----------------------------
  signal sp_pos_ram_addr      : std_logic_vector(c_SP_COEFF_RAM_ADDR_WIDTH-1 downto 0);
  signal sp_pos_ram_data      : std_logic_vector(c_SP_POS_RAM_DATA_WIDTH-1 downto 0);

  -- Gain array
  signal gain_arr             : t_fofb_processing_gain_arr(g_CHANNELS-1 downto 0);
  signal wb_gain_arr          : t_fofb_processing_wb_gain_arr(c_MAX_CHANNELS-1 downto 0) := (others => (others => '0'));

  -----------------------------
  -- Coefficients RAM signals
  -----------------------------
  signal coeff_ram_addr_arr      : t_arr_coeff_ram_addr(c_MAX_CHANNELS-1 downto 0);
  signal coeff_ram_data_arr      : t_arr_coeff_ram_data(c_MAX_CHANNELS-1 downto 0);

  -----------------------------
  -- Output saturation signals
  -----------------------------
  signal sp_max_arr              : t_fofb_processing_sp_arr(g_CHANNELS-1 downto 0);
  signal sp_min_arr              : t_fofb_processing_sp_arr(g_CHANNELS-1 downto 0);
  signal wb_sp_max_arr           : t_fofb_processing_wb_sp_arr(c_MAX_CHANNELS-1 downto 0);
  signal wb_sp_min_arr           : t_fofb_processing_wb_sp_arr(c_MAX_CHANNELS-1 downto 0);

  -----------------------------
  -- Loop interlock signals
  -----------------------------
  signal loop_intlk_src_en            : std_logic_vector(c_FOFB_LOOP_INTLK_TRIGS_WIDTH-1 downto 0);
  signal loop_intlk_state_clr         : std_logic;
  signal loop_intlk_state             : std_logic_vector(c_FOFB_LOOP_INTLK_TRIGS_WIDTH-1 downto 0);
  signal loop_intlk_distort_limit     : unsigned(g_BPM_POS_INT_WIDTH-1 downto 0);
  signal loop_intlk_min_num_meas      : unsigned(c_SP_COEFF_RAM_ADDR_WIDTH-1 downto 0);
  signal orb_distort_limit_val        : std_logic_vector(31 downto 0);
  signal min_num_pkts_val             : std_logic_vector(31 downto 0);

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

  -----------------------------
  -- Insert extra Wishbone registering stage for ease timing.
  -- It effectively cuts the bandwidth in half!
  -----------------------------
  gen_with_extra_wb_reg : if g_WITH_EXTRA_WB_REG generate
    cmp_register_link : xwb_register_link -- puts a register of delay between crossbars
      port map (
        clk_sys_i                => clk_i,
        rst_n_i                  => rst_n_i,
        slave_i                  => wb_slave_in_reg0(0),
        slave_o                  => wb_slave_out_reg0(0),
        master_i                 => wb_slave_out(0),
        master_o                 => wb_slave_in(0)
      );

      wb_slave_in_reg0(0)        <= wb_slv_i;
      wb_slv_o                   <= wb_slave_out_reg0(0);
    end generate;

  gen_without_extra_wb_reg : if not g_WITH_EXTRA_WB_REG generate
    -- External master connection
    wb_slave_in(0)           <= wb_slv_i;
    wb_slv_o                 <= wb_slave_out(0);
  end generate;

  cmp_fofb_processing: fofb_processing
    generic map (
      g_COEFF_INT_WIDTH              => g_COEFF_INT_WIDTH,
      g_COEFF_FRAC_WIDTH             => g_COEFF_FRAC_WIDTH,
      g_BPM_POS_INT_WIDTH            => g_BPM_POS_INT_WIDTH,
      g_BPM_POS_FRAC_WIDTH           => g_BPM_POS_FRAC_WIDTH,
      g_DOT_PROD_ACC_EXTRA_WIDTH     => g_DOT_PROD_ACC_EXTRA_WIDTH,
      g_DOT_PROD_MUL_PIPELINE_STAGES => g_DOT_PROD_MUL_PIPELINE_STAGES,
      g_DOT_PROD_ACC_PIPELINE_STAGES => g_DOT_PROD_ACC_PIPELINE_STAGES,
      g_ACC_GAIN_MUL_PIPELINE_STAGES => g_ACC_GAIN_MUL_PIPELINE_STAGES,
      g_USE_MOVING_AVG               => g_USE_MOVING_AVG,
      g_CHANNELS                     => g_CHANNELS
    )
    port map (
      clk_i                        => clk_i,
      rst_n_i                      => rst_n_i,

      busy_o                       => busy_o,

      bpm_pos_i                    => bpm_pos_i,
      bpm_pos_index_i              => bpm_pos_index_i,
      bpm_pos_valid_i              => bpm_pos_valid_i,
      bpm_time_frame_end_i         => bpm_time_frame_end_i,

      coeff_ram_addr_arr_o         => coeff_ram_addr_arr(g_CHANNELS-1 downto 0),
      coeff_ram_data_arr_i         => coeff_ram_data_arr(g_CHANNELS-1 downto 0),

      sp_pos_ram_addr_o            => sp_pos_ram_addr,
      sp_pos_ram_data_i            => sp_pos_ram_data,

      gain_arr_i                   => gain_arr(g_CHANNELS-1 downto 0),

      clear_acc_arr_i              => clear_acc_arr(g_CHANNELS-1 downto 0),
      freeze_acc_arr_i             => freeze_acc_arr(g_CHANNELS-1 downto 0),

      sp_max_arr_i                 => sp_max_arr,
      sp_min_arr_i                 => sp_min_arr,

      sp_arr_o                     => sp_arr_o,
      sp_valid_arr_o               => sp_valid_arr_o,

      loop_intlk_src_en_i          => loop_intlk_src_en,
      loop_intlk_state_clr_i       => loop_intlk_state_clr,
      loop_intlk_state_o           => loop_intlk_state,
      loop_intlk_distort_limit_i   => loop_intlk_distort_limit,
      loop_intlk_min_num_meas_i    => loop_intlk_min_num_meas
    );

  -----------------------------
  -- Slave adapter for Wishbone Register Interface
  -----------------------------
  cmp_slave_adapter : wb_slave_adapter
    generic map (
      g_master_use_struct        => true,
      g_master_mode              => PIPELINED,
      g_master_granularity       => WORD,
      g_slave_use_struct         => false,
      g_slave_mode               => g_INTERFACE_MODE,
      g_slave_granularity        => g_ADDRESS_GRANULARITY
    )
    port map (
      clk_sys_i                  => clk_i,
      rst_n_i                    => rst_n_i,
      master_i                   => wb_slv_adp_in,
      master_o                   => wb_slv_adp_out,
      sl_adr_i                   => resized_addr,
      sl_dat_i                   => wb_slave_in(0).dat,
      sl_sel_i                   => wb_slave_in(0).sel,
      sl_cyc_i                   => wb_slave_in(0).cyc,
      sl_stb_i                   => wb_slave_in(0).stb,
      sl_we_i                    => wb_slave_in(0).we,
      sl_dat_o                   => wb_slave_out(0).dat,
      sl_ack_o                   => wb_slave_out(0).ack,
      sl_rty_o                   => wb_slave_out(0).rty,
      sl_err_o                   => wb_slave_out(0).err,
      sl_stall_o                 => wb_slave_out(0).stall
    );
    -- By doing this zeroing we avoid the issue related to BYTE -> WORD  conversion
    -- slave addressing (possibly performed by the slave adapter component)
    -- in which a bit in the MSB of the peripheral addressing part (31 downto c_PERIPH_ADDR_SIZE in our case)
    -- is shifted to the internal register adressing part (c_PERIPH_ADDR_SIZE-1 downto 0 in our case).
    -- Therefore, possibly changing the these bits!
    resized_addr(c_PERIPH_ADDR_SIZE-1 downto 0)
                                 <= wb_slave_in(0).adr(c_PERIPH_ADDR_SIZE-1 downto 0);
    resized_addr(c_WISHBONE_ADDRESS_WIDTH-1 downto c_PERIPH_ADDR_SIZE)
                                 <= (others => '0');

  gen_wb_conn: for i in 0 to g_CHANNELS-1
  generate
    -- fixed-point values are aligned to the left
    gain_arr(i) <= signed(wb_gain_arr(i)(c_FOFB_WB_GAIN_WIDTH-1 downto c_FOFB_WB_GAIN_WIDTH-c_FOFB_GAIN_WIDTH));

    sp_max_arr(i) <= signed(wb_sp_max_arr(i)(c_FOFB_SP_WIDTH-1 downto 0));
    sp_min_arr(i) <= signed(wb_sp_min_arr(i)(c_FOFB_SP_WIDTH-1 downto 0));
  end generate gen_wb_conn;

  loop_intlk_distort_limit <= unsigned(orb_distort_limit_val(loop_intlk_distort_limit'left downto 0));
  -- Each DCC packet has 2 measurements
  loop_intlk_min_num_meas <= shift_left(unsigned(min_num_pkts_val(loop_intlk_min_num_meas'left downto 0)), 1);

  cmp_wb_fofb_processing_regs: entity work.wb_fofb_processing_regs
    port map (
      rst_n_i                                                         => rst_n_i,
      clk_sys_i                                                       => clk_i,
      wb_adr_i                                                        => wb_slv_adp_out.adr(12 downto 0),
      wb_dat_i                                                        => wb_slv_adp_out.dat(31 downto 0),
      wb_dat_o                                                        => wb_slv_adp_in.dat(31 downto 0),
      wb_cyc_i                                                        => wb_slv_adp_out.cyc,
      wb_sel_i                                                        => wb_slv_adp_out.sel(3 downto 0),
      wb_stb_i                                                        => wb_slv_adp_out.stb,
      wb_we_i                                                         => wb_slv_adp_out.we,
      wb_ack_o                                                        => wb_slv_adp_in.ack,
      wb_stall_o                                                      => wb_slv_adp_in.stall,
      wb_fofb_processing_regs_clk_i                                   => clk_i,
      wb_fofb_processing_regs_coeffs_fixed_point_pos_val_i            => c_COEFF_FIXED_POINT_POS_VAL,
      wb_fofb_processing_regs_accs_gains_fixed_point_pos_val_i        => c_GAIN_FIXED_POINT_POS_VAL,
      wb_fofb_processing_regs_acc_gain_0_val_o                        => wb_gain_arr(0),
      wb_fofb_processing_regs_acc_ctl_0_clear_o                       => clear_acc_arr(0),
      wb_fofb_processing_regs_acc_ctl_0_freeze_o                      => freeze_acc_arr(0),
      wb_fofb_processing_regs_acc_gain_1_val_o                        => wb_gain_arr(1),
      wb_fofb_processing_regs_acc_ctl_1_clear_o                       => clear_acc_arr(1),
      wb_fofb_processing_regs_acc_ctl_1_freeze_o                      => freeze_acc_arr(1),
      wb_fofb_processing_regs_acc_gain_2_val_o                        => wb_gain_arr(2),
      wb_fofb_processing_regs_acc_ctl_2_clear_o                       => clear_acc_arr(2),
      wb_fofb_processing_regs_acc_ctl_2_freeze_o                      => freeze_acc_arr(2),
      wb_fofb_processing_regs_acc_gain_3_val_o                        => wb_gain_arr(3),
      wb_fofb_processing_regs_acc_ctl_3_clear_o                       => clear_acc_arr(3),
      wb_fofb_processing_regs_acc_ctl_3_freeze_o                      => freeze_acc_arr(3),
      wb_fofb_processing_regs_acc_gain_4_val_o                        => wb_gain_arr(4),
      wb_fofb_processing_regs_acc_ctl_4_clear_o                       => clear_acc_arr(4),
      wb_fofb_processing_regs_acc_ctl_4_freeze_o                      => freeze_acc_arr(4),
      wb_fofb_processing_regs_acc_gain_5_val_o                        => wb_gain_arr(5),
      wb_fofb_processing_regs_acc_ctl_5_clear_o                       => clear_acc_arr(5),
      wb_fofb_processing_regs_acc_ctl_5_freeze_o                      => freeze_acc_arr(5),
      wb_fofb_processing_regs_acc_gain_6_val_o                        => wb_gain_arr(6),
      wb_fofb_processing_regs_acc_ctl_6_clear_o                       => clear_acc_arr(6),
      wb_fofb_processing_regs_acc_ctl_6_freeze_o                      => freeze_acc_arr(6),
      wb_fofb_processing_regs_acc_gain_7_val_o                        => wb_gain_arr(7),
      wb_fofb_processing_regs_acc_ctl_7_clear_o                       => clear_acc_arr(7),
      wb_fofb_processing_regs_acc_ctl_7_freeze_o                      => freeze_acc_arr(7),
      wb_fofb_processing_regs_acc_gain_8_val_o                        => wb_gain_arr(8),
      wb_fofb_processing_regs_acc_ctl_8_clear_o                       => clear_acc_arr(8),
      wb_fofb_processing_regs_acc_ctl_8_freeze_o                      => freeze_acc_arr(8),
      wb_fofb_processing_regs_acc_gain_9_val_o                        => wb_gain_arr(9),
      wb_fofb_processing_regs_acc_ctl_9_clear_o                       => clear_acc_arr(9),
      wb_fofb_processing_regs_acc_ctl_9_freeze_o                      => freeze_acc_arr(9),
      wb_fofb_processing_regs_acc_gain_10_val_o                       => wb_gain_arr(10),
      wb_fofb_processing_regs_acc_ctl_10_clear_o                      => clear_acc_arr(10),
      wb_fofb_processing_regs_acc_ctl_10_freeze_o                     => freeze_acc_arr(10),
      wb_fofb_processing_regs_acc_gain_11_val_o                       => wb_gain_arr(11),
      wb_fofb_processing_regs_acc_ctl_11_clear_o                      => clear_acc_arr(11),
      wb_fofb_processing_regs_acc_ctl_11_freeze_o                     => freeze_acc_arr(11),
      wb_fofb_processing_regs_sp_max_0_val_o                          => wb_sp_max_arr(0),
      wb_fofb_processing_regs_sp_min_0_val_o                          => wb_sp_min_arr(0),
      wb_fofb_processing_regs_sp_max_1_val_o                          => wb_sp_max_arr(1),
      wb_fofb_processing_regs_sp_min_1_val_o                          => wb_sp_min_arr(1),
      wb_fofb_processing_regs_sp_max_2_val_o                          => wb_sp_max_arr(2),
      wb_fofb_processing_regs_sp_min_2_val_o                          => wb_sp_min_arr(2),
      wb_fofb_processing_regs_sp_max_3_val_o                          => wb_sp_max_arr(3),
      wb_fofb_processing_regs_sp_min_3_val_o                          => wb_sp_min_arr(3),
      wb_fofb_processing_regs_sp_max_4_val_o                          => wb_sp_max_arr(4),
      wb_fofb_processing_regs_sp_min_4_val_o                          => wb_sp_min_arr(4),
      wb_fofb_processing_regs_sp_max_5_val_o                          => wb_sp_max_arr(5),
      wb_fofb_processing_regs_sp_min_5_val_o                          => wb_sp_min_arr(5),
      wb_fofb_processing_regs_sp_max_6_val_o                          => wb_sp_max_arr(6),
      wb_fofb_processing_regs_sp_min_6_val_o                          => wb_sp_min_arr(6),
      wb_fofb_processing_regs_sp_max_7_val_o                          => wb_sp_max_arr(7),
      wb_fofb_processing_regs_sp_min_7_val_o                          => wb_sp_min_arr(7),
      wb_fofb_processing_regs_sp_max_8_val_o                          => wb_sp_max_arr(8),
      wb_fofb_processing_regs_sp_min_8_val_o                          => wb_sp_min_arr(8),
      wb_fofb_processing_regs_sp_max_9_val_o                          => wb_sp_max_arr(9),
      wb_fofb_processing_regs_sp_min_9_val_o                          => wb_sp_min_arr(9),
      wb_fofb_processing_regs_sp_max_10_val_o                         => wb_sp_max_arr(10),
      wb_fofb_processing_regs_sp_min_10_val_o                         => wb_sp_min_arr(10),
      wb_fofb_processing_regs_sp_max_11_val_o                         => wb_sp_max_arr(11),
      wb_fofb_processing_regs_sp_min_11_val_o                         => wb_sp_min_arr(11),
      wb_fofb_processing_regs_coeffs_ram_bank_0_addr_i                => coeff_ram_addr_arr(0),
      wb_fofb_processing_regs_coeffs_ram_bank_0_data_o                => coeff_ram_data_arr(0),
      wb_fofb_processing_regs_coeffs_ram_bank_0_rd_i                  => '0',
      wb_fofb_processing_regs_coeffs_ram_bank_0_data_i                => (others => '0'),
      wb_fofb_processing_regs_coeffs_ram_bank_0_wr_i                  => '0',
      wb_fofb_processing_regs_coeffs_ram_bank_1_addr_i                => coeff_ram_addr_arr(1),
      wb_fofb_processing_regs_coeffs_ram_bank_1_data_o                => coeff_ram_data_arr(1),
      wb_fofb_processing_regs_coeffs_ram_bank_1_rd_i                  => '0',
      wb_fofb_processing_regs_coeffs_ram_bank_1_data_i                => (others => '0'),
      wb_fofb_processing_regs_coeffs_ram_bank_1_wr_i                  => '0',
      wb_fofb_processing_regs_coeffs_ram_bank_2_addr_i                => coeff_ram_addr_arr(2),
      wb_fofb_processing_regs_coeffs_ram_bank_2_data_o                => coeff_ram_data_arr(2),
      wb_fofb_processing_regs_coeffs_ram_bank_2_rd_i                  => '0',
      wb_fofb_processing_regs_coeffs_ram_bank_2_data_i                => (others => '0'),
      wb_fofb_processing_regs_coeffs_ram_bank_2_wr_i                  => '0',
      wb_fofb_processing_regs_coeffs_ram_bank_3_addr_i                => coeff_ram_addr_arr(3),
      wb_fofb_processing_regs_coeffs_ram_bank_3_data_o                => coeff_ram_data_arr(3),
      wb_fofb_processing_regs_coeffs_ram_bank_3_rd_i                  => '0',
      wb_fofb_processing_regs_coeffs_ram_bank_3_data_i                => (others => '0'),
      wb_fofb_processing_regs_coeffs_ram_bank_3_wr_i                  => '0',
      wb_fofb_processing_regs_coeffs_ram_bank_4_addr_i                => coeff_ram_addr_arr(4),
      wb_fofb_processing_regs_coeffs_ram_bank_4_data_o                => coeff_ram_data_arr(4),
      wb_fofb_processing_regs_coeffs_ram_bank_4_rd_i                  => '0',
      wb_fofb_processing_regs_coeffs_ram_bank_4_data_i                => (others => '0'),
      wb_fofb_processing_regs_coeffs_ram_bank_4_wr_i                  => '0',
      wb_fofb_processing_regs_coeffs_ram_bank_5_addr_i                => coeff_ram_addr_arr(5),
      wb_fofb_processing_regs_coeffs_ram_bank_5_data_o                => coeff_ram_data_arr(5),
      wb_fofb_processing_regs_coeffs_ram_bank_5_rd_i                  => '0',
      wb_fofb_processing_regs_coeffs_ram_bank_5_data_i                => (others => '0'),
      wb_fofb_processing_regs_coeffs_ram_bank_5_wr_i                  => '0',
      wb_fofb_processing_regs_coeffs_ram_bank_6_addr_i                => coeff_ram_addr_arr(6),
      wb_fofb_processing_regs_coeffs_ram_bank_6_data_o                => coeff_ram_data_arr(6),
      wb_fofb_processing_regs_coeffs_ram_bank_6_rd_i                  => '0',
      wb_fofb_processing_regs_coeffs_ram_bank_6_data_i                => (others => '0'),
      wb_fofb_processing_regs_coeffs_ram_bank_6_wr_i                  => '0',
      wb_fofb_processing_regs_coeffs_ram_bank_7_addr_i                => coeff_ram_addr_arr(7),
      wb_fofb_processing_regs_coeffs_ram_bank_7_data_o                => coeff_ram_data_arr(7),
      wb_fofb_processing_regs_coeffs_ram_bank_7_rd_i                  => '0',
      wb_fofb_processing_regs_coeffs_ram_bank_7_data_i                => (others => '0'),
      wb_fofb_processing_regs_coeffs_ram_bank_7_wr_i                  => '0',
      wb_fofb_processing_regs_coeffs_ram_bank_8_addr_i                => coeff_ram_addr_arr(8),
      wb_fofb_processing_regs_coeffs_ram_bank_8_data_o                => coeff_ram_data_arr(8),
      wb_fofb_processing_regs_coeffs_ram_bank_8_rd_i                  => '0',
      wb_fofb_processing_regs_coeffs_ram_bank_8_data_i                => (others => '0'),
      wb_fofb_processing_regs_coeffs_ram_bank_8_wr_i                  => '0',
      wb_fofb_processing_regs_coeffs_ram_bank_9_addr_i                => coeff_ram_addr_arr(9),
      wb_fofb_processing_regs_coeffs_ram_bank_9_data_o                => coeff_ram_data_arr(9),
      wb_fofb_processing_regs_coeffs_ram_bank_9_rd_i                  => '0',
      wb_fofb_processing_regs_coeffs_ram_bank_9_data_i                => (others => '0'),
      wb_fofb_processing_regs_coeffs_ram_bank_9_wr_i                  => '0',
      wb_fofb_processing_regs_coeffs_ram_bank_10_addr_i               => coeff_ram_addr_arr(10),
      wb_fofb_processing_regs_coeffs_ram_bank_10_data_o               => coeff_ram_data_arr(10),
      wb_fofb_processing_regs_coeffs_ram_bank_10_rd_i                 => '0',
      wb_fofb_processing_regs_coeffs_ram_bank_10_data_i               => (others => '0'),
      wb_fofb_processing_regs_coeffs_ram_bank_10_wr_i                 => '0',
      wb_fofb_processing_regs_coeffs_ram_bank_11_addr_i               => coeff_ram_addr_arr(11),
      wb_fofb_processing_regs_coeffs_ram_bank_11_data_o               => coeff_ram_data_arr(11),
      wb_fofb_processing_regs_coeffs_ram_bank_11_rd_i                 => '0',
      wb_fofb_processing_regs_coeffs_ram_bank_11_data_i               => (others => '0'),
      wb_fofb_processing_regs_coeffs_ram_bank_11_wr_i                 => '0',
      wb_fofb_processing_regs_setpoints_ram_bank_addr_i               => sp_pos_ram_addr,
      wb_fofb_processing_regs_setpoints_ram_bank_data_o               => sp_pos_ram_data,
      wb_fofb_processing_regs_setpoints_ram_bank_rd_i                 => '0',
      wb_fofb_processing_regs_setpoints_ram_bank_data_i               => (others => '0'),
      wb_fofb_processing_regs_setpoints_ram_bank_wr_i                 => '0',
      wb_fofb_processing_regs_loop_intlk_src_en_ctl_orb_distort_en_o  => loop_intlk_src_en(c_FOFB_LOOP_INTLK_DISTORT_ID),
      wb_fofb_processing_regs_loop_intlk_src_en_ctl_packet_loss_en_o  => loop_intlk_src_en(c_FOFB_LOOP_INTLK_PKT_LOSS_ID),
      wb_fofb_processing_regs_loop_intlk_ctl_clr_o                    => loop_intlk_state_clr,
      wb_fofb_processing_regs_loop_intlk_sta_orb_distort_i            => loop_intlk_state(c_FOFB_LOOP_INTLK_DISTORT_ID),
      wb_fofb_processing_regs_loop_intlk_sta_packet_loss_i            => loop_intlk_state(c_FOFB_LOOP_INTLK_PKT_LOSS_ID),
      wb_fofb_processing_regs_orb_distort_limit_val_o                 => orb_distort_limit_val,
      wb_fofb_processing_regs_min_num_pkts_val_o                      => min_num_pkts_val
    );

    dcc_p2p_en_o <= not loop_intlk_state(c_FOFB_LOOP_INTLK_PKT_LOSS_ID);

end architecture rtl;

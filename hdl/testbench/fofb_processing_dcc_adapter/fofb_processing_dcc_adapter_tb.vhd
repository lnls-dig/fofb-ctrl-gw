-------------------------------------------------------------------------------
-- Title      : FOFB processing DCC adapter testbench
-------------------------------------------------------------------------------
-- Author     : Augusto Fraga Giachero
-- Company    : CNPEM LNLS-GCA
-- Platform   : Simulation
-- Standard   : VHDL 2008
-------------------------------------------------------------------------------
-- Description: FOFB processing DCC adapter testbench
-------------------------------------------------------------------------------
-- Copyright (c) 2022 CNPEM
-- Licensed under GNU Lesser General Public License (LGPL) v3.0
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                Description
-- 2022-09-26  1.0      augusto.fraga         Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.dot_prod_pkg.all;
use work.fofb_ctrl_pkg.all;
use work.fofb_tb_pkg.all;

entity fofb_processing_dcc_adapter_tb is
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
    g_DOT_PROD_MUL_PIPELINE_STAGES : natural := 2;

    -- Dot product accumulator pipeline stages
    g_DOT_PROD_ACC_PIPELINE_STAGES : natural := 2;

    -- Gain multiplication pipeline stages
    g_ACC_GAIN_MUL_PIPELINE_STAGES : natural := 2;

    -- If true, take the average of the last 2 positions for each BPM
    g_USE_MOVING_AVG               : boolean := false;

    -- Number of FOFB processing channels
    g_FOFB_CHANNELS                : natural := 2
  );
end fofb_processing_dcc_adapter_tb;

architecture rtl of fofb_processing_dcc_adapter_tb is
  constant c_SP_DECIM_RATIO       : integer := 4600; -- at Monit rate (but not synced)

  signal clk                      : std_logic := '0';
  signal rst_n                    : std_logic := '0';
  signal clk_dcc                  : std_logic := '0';
  signal rst_dcc_n                : std_logic := '0';
  signal dcc_time_frame_end       : std_logic := '0';
  signal dcc_packet               : t_fofb_cc_packet;
  signal dcc_packet_valid         : std_logic := '0';
  signal fofb_proc_busy           : std_logic := '0';
  signal fofb_proc_bpm_pos        : signed(c_SP_POS_RAM_DATA_WIDTH-1 downto 0);
  signal fofb_proc_bpm_pos_index  : unsigned(c_SP_COEFF_RAM_ADDR_WIDTH-1 downto 0);
  signal fofb_proc_bpm_pos_valid  : std_logic;
  signal fofb_proc_time_frame_end : std_logic;
  signal coeff_ram_addr_arr       : t_arr_coeff_ram_addr(g_FOFB_CHANNELS-1 downto 0);
  signal coeff_ram_data_arr       : t_arr_coeff_ram_data(g_FOFB_CHANNELS-1 downto 0) := (others => x"40000000");
  signal sp_pos_ram_addr          : std_logic_vector(c_SP_COEFF_RAM_ADDR_WIDTH-1 downto 0);
  signal sp_pos_ram_data          : std_logic_vector(c_SP_POS_RAM_DATA_WIDTH-1 downto 0) := x"00000000";
  signal gain_arr                 : t_fofb_processing_gain_arr(g_FOFB_CHANNELS-1 downto 0) := (others => x"1000");
  signal sp_arr                   : t_fofb_processing_sp_arr(g_FOFB_CHANNELS-1 downto 0);
  signal sp_valid_arr             : std_logic_vector(g_FOFB_CHANNELS-1 downto 0);
  signal sp_max                   : signed(c_FOFB_SP_WIDTH-1 downto 0) := to_signed(32767, c_FOFB_SP_WIDTH);
  signal sp_min                   : signed(c_FOFB_SP_WIDTH-1 downto 0) := to_signed(-32768, c_FOFB_SP_WIDTH);

begin

  -- Generate clocks
  f_gen_clk(100_000_000, clk);
  f_gen_clk(156_250_000, clk_dcc);

  process
  begin
    -- Reset all cores
    f_wait_cycles(clk, 5);
    rst_n <= '1';
    f_wait_cycles(clk_dcc, 5);
    rst_dcc_n <= '1';

    -- TODO: improve this testbench to generate a pass/fail result

    dcc_packet.bpm_data_x <= to_signed(56, dcc_packet.bpm_data_x'length);
    dcc_packet.bpm_data_y <= to_signed(77, dcc_packet.bpm_data_y'length);
    dcc_packet.bpm_id <= to_unsigned(13, dcc_packet.bpm_id'length);
    dcc_packet_valid <= '1';
    f_wait_cycles(clk_dcc, 1);
    dcc_packet_valid <= '0';

    dcc_packet.bpm_data_x <= to_signed(51, dcc_packet.bpm_data_x'length);
    dcc_packet.bpm_data_y <= to_signed(24, dcc_packet.bpm_data_y'length);
    dcc_packet.bpm_id <= to_unsigned(14, dcc_packet.bpm_id'length);
    dcc_packet_valid <= '1';
    f_wait_cycles(clk_dcc, 1);
    dcc_packet_valid <= '0';

    dcc_time_frame_end <= '1';
    f_wait_cycles(clk_dcc, 1);
    dcc_time_frame_end <= '0';

    dcc_packet.bpm_data_x <= to_signed(95, dcc_packet.bpm_data_x'length);
    dcc_packet.bpm_data_y <= to_signed(11, dcc_packet.bpm_data_y'length);
    dcc_packet.bpm_id <= to_unsigned(15, dcc_packet.bpm_id'length);
    dcc_packet_valid <= '1';
    f_wait_cycles(clk_dcc, 1);
    dcc_packet_valid <= '0';

    dcc_time_frame_end <= '1';
    f_wait_cycles(clk_dcc, 1);
    dcc_time_frame_end <= '0';

    f_wait_cycles(clk, 40);
    std.env.finish;
  end process;

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
      g_CHANNELS                      => g_FOFB_CHANNELS
    )
    port map (
      clk_i                           => clk,
      rst_n_i                         => rst_n,
      busy_o                          => fofb_proc_busy,
      bpm_pos_i                       => fofb_proc_bpm_pos,
      bpm_pos_index_i                 => fofb_proc_bpm_pos_index,
      bpm_pos_valid_i                 => fofb_proc_bpm_pos_valid,
      bpm_time_frame_end_i            => fofb_proc_time_frame_end,
      coeff_ram_addr_arr_o            => coeff_ram_addr_arr,
      coeff_ram_data_arr_i            => coeff_ram_data_arr,
      freeze_acc_arr_i                => (others => '0'),
      clear_acc_arr_i                 => (others => '0'),
      sp_pos_ram_addr_o               => sp_pos_ram_addr,
      sp_pos_ram_data_i               => sp_pos_ram_data,
      gain_arr_i                      => gain_arr,
      sp_max_arr_i                    => (others => sp_max),
      sp_min_arr_i                    => (others => sp_min),
      sp_arr_o                        => sp_arr,
      sp_valid_arr_o                  => sp_valid_arr,
      sp_decim_ratio_arr_i            => (others => c_SP_DECIM_RATIO),
      sp_decim_arr_o                  => open,
      sp_decim_valid_arr_o            => open,
      loop_intlk_src_en_i             => (others => '0'),
      loop_intlk_state_clr_i          => '0',
      loop_intlk_state_o              => open,
      loop_intlk_distort_limit_i      => (others => '0'),
      loop_intlk_min_num_meas_i       => (others => '0')
    );

  cmp_fofb_dcc_adapter: fofb_processing_dcc_adapter
    port map (
      clk_i                      => clk,
      rst_n_i                    => rst_n,
      clk_dcc_i                  => clk_dcc,
      rst_dcc_n_i                => rst_dcc_n,
      dcc_time_frame_end_i       => dcc_time_frame_end,
      dcc_packet_i               => dcc_packet,
      dcc_packet_valid_i         => dcc_packet_valid,
      fofb_proc_busy_i           => fofb_proc_busy,
      fofb_proc_bpm_pos_o        => fofb_proc_bpm_pos,
      fofb_proc_bpm_pos_index_o  => fofb_proc_bpm_pos_index,
      fofb_proc_bpm_pos_valid_o  => fofb_proc_bpm_pos_valid,
      fofb_proc_time_frame_end_o => fofb_proc_time_frame_end,
      acq_dcc_packet_o           => open,
      acq_dcc_valid_o            => open
    );

end architecture rtl;

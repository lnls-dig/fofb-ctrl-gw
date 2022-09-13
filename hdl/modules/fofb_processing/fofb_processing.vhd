-------------------------------------------------------------------------------
-- Title      : FOFB processing module
-------------------------------------------------------------------------------
-- Author     : Melissa Aguiar
-- Company    : CNPEM LNLS-DIG
-- Platform   : FPGA-generic
-- Standard   : VHDL 2008
-------------------------------------------------------------------------------
-- Description: Processing module for the Fast Orbit Feedback
-------------------------------------------------------------------------------
-- Copyright (c) 2020-2022 CNPEM
-- Licensed under GNU Lesser General Public License (LGPL) v3.0
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                Description
-- 2021-08-26  1.0      melissa.aguiar        Created
-- 2022-07-27  1.1      guilherme.ricioli     Changed coeffs RAMs' wb interface
-- 2022-09-02  2.0      augusto.fraga         Update to match the new
--                                            fofb_processing_channel version,
--                                            add memory interface for set-points
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

library work;
use work.dot_prod_pkg.all;

entity fofb_processing is
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

    -- Number of channels
    g_CHANNELS                     : natural
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

    -- Set-point RAM address
    sp_pos_ram_addr_o              : out std_logic_vector(c_SP_COEFF_RAM_ADDR_WIDTH-1 downto 0);

    -- Set-point RAM data
    sp_pos_ram_data_i              : in  std_logic_vector(c_SP_POS_RAM_DATA_WIDTH-1 downto 0);

    -- Coefficients RAM address array
    coeff_ram_addr_arr_o           : out t_arr_coeff_ram_addr(g_CHANNELS-1 downto 0);

    -- Coefficients RAM data array
    coeff_ram_data_arr_i           : in  t_arr_coeff_ram_data(g_CHANNELS-1 downto 0);

    -- Array of gains (for each channel)
    gain_arr_i                     : in  t_fofb_processing_gain_arr(g_CHANNELS-1 downto 0);

    -- Clear set-point accumulator array (for each channel)
    clear_acc_arr_i                : in  std_logic_vector(g_CHANNELS-1 downto 0);

    -- Freeze set-point accumulator array (for each channel)
    freeze_acc_arr_i               : in  std_logic_vector(g_CHANNELS-1 downto 0);

    -- Set-points output array (for each channel)
    sp_arr_o                       : out t_fofb_processing_sp_arr(g_CHANNELS-1 downto 0);

    -- Set-point valid array (for each channel)
    sp_valid_arr_o                 : out std_logic_vector(g_CHANNELS-1 downto 0)
  );
end fofb_processing;

architecture behave of fofb_processing is
  signal bpm_pos_err            : signed((g_BPM_POS_INT_WIDTH + g_BPM_POS_FRAC_WIDTH) downto 0);
  signal bpm_pos_err_valid      : std_logic;
  signal bpm_pos_tmp            : signed(c_SP_POS_RAM_DATA_WIDTH-1 downto 0);
  signal bpm_index_tmp          : unsigned(c_SP_COEFF_RAM_ADDR_WIDTH-1 downto 0);
  signal bpm_pos_valid_tmp      : std_logic;
  signal bpm_time_frame_end     : std_logic;
  signal bpm_time_frame_end_tmp : std_logic;
  signal busy_arr               : std_logic_vector(g_CHANNELS-1 downto 0);
  signal busy                   : std_logic;
  signal bpm_pos_err_index      : integer range 0 to (2**c_SP_COEFF_RAM_ADDR_WIDTH)-1;
begin

  gen_channels : for i in 0 to g_CHANNELS-1 generate
    fofb_processing_channel_interface : fofb_processing_channel
      generic map (
        g_COEFF_INT_WIDTH              => g_COEFF_INT_WIDTH,
        g_COEFF_FRAC_WIDTH             => g_COEFF_FRAC_WIDTH,
        g_BPM_POS_INT_WIDTH            => g_BPM_POS_INT_WIDTH,
        g_BPM_POS_FRAC_WIDTH           => g_BPM_POS_FRAC_WIDTH,
        g_GAIN_INT_WIDTH               => c_FOFB_GAIN_INT_WIDTH,
        g_GAIN_FRAC_WIDTH              => c_FOFB_GAIN_FRAC_WIDTH,
        g_SP_INT_WIDTH                 => c_FOFB_SP_INT_WIDTH,
        g_SP_FRAC_WIDTH                => c_FOFB_SP_FRAC_WIDTH,
        g_DOT_PROD_ACC_EXTRA_WIDTH     => g_DOT_PROD_ACC_EXTRA_WIDTH,
        g_DOT_PROD_MUL_PIPELINE_STAGES => g_DOT_PROD_MUL_PIPELINE_STAGES,
        g_DOT_PROD_ACC_PIPELINE_STAGES => g_DOT_PROD_ACC_PIPELINE_STAGES,
        g_ACC_GAIN_MUL_PIPELINE_STAGES => g_ACC_GAIN_MUL_PIPELINE_STAGES,
        g_COEFF_RAM_ADDR_WIDTH         => c_SP_COEFF_RAM_ADDR_WIDTH,
        g_COEFF_RAM_DATA_WIDTH         => c_COEFF_RAM_DATA_WIDTH
      )
      port map (
        clk_i                          => clk_i,
        rst_n_i                        => rst_n_i,
        busy_o                         => busy_arr(i),
        bpm_pos_err_i                  => bpm_pos_err,
        bpm_pos_err_valid_i            => bpm_pos_err_valid,
        bpm_pos_err_index_i            => bpm_pos_err_index,
        bpm_time_frame_end_i           => bpm_time_frame_end,
        gain_i                         => gain_arr_i(i),
        coeff_ram_addr_o               => coeff_ram_addr_arr_o(i),
        coeff_ram_data_i               => coeff_ram_data_arr_i(i),
        freeze_acc_i                   => freeze_acc_arr_i(i),
        clear_acc_i                    => clear_acc_arr_i(i),
        sp_o                           => sp_arr_o(i),
        sp_valid_o                     => sp_valid_arr_o(i)
      );
  end generate;

  -- Simply cast the BPM position index to std_logic_vector to interface with
  -- the set-points RAM
  sp_pos_ram_addr_o <= std_logic_vector(bpm_pos_index_i);

  -- We are busy if any of the fofb_processing_channel instances are busy
  busy <= or(busy_arr);
  busy_o <= busy;

  process(clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        bpm_pos_valid_tmp <= '0';
        bpm_index_tmp <= (others => '0');
        bpm_pos_tmp <= (others => '0');
        bpm_time_frame_end_tmp <= '0';
        bpm_pos_err <= (others => '0');
        bpm_pos_err_valid <= '0';
        bpm_time_frame_end <= '0';
        bpm_pos_err_index <= 0;
      elsif busy = '0' then
        -- Delay received data by 1 cycle to wait for the set-point data to be
        -- read from the set-point RAM
        bpm_pos_valid_tmp <= bpm_pos_valid_i;
        bpm_index_tmp <= bpm_pos_index_i;
        bpm_pos_tmp <= bpm_pos_i;
        bpm_time_frame_end_tmp <= bpm_time_frame_end_i;

        -- Add an extra clock cycle to ease timing for the subtraction
        -- operation between the received BPM position data and the orbit
        -- set-point
        bpm_pos_err <= resize(bpm_pos_tmp - signed(sp_pos_ram_data_i), g_BPM_POS_INT_WIDTH + g_BPM_POS_FRAC_WIDTH + 1);
        bpm_pos_err_valid <= bpm_pos_valid_tmp;
        bpm_time_frame_end <= bpm_time_frame_end_tmp;
        bpm_pos_err_index <= to_integer(bpm_index_tmp);
      end if;
    end if;
  end process;

end architecture behave;

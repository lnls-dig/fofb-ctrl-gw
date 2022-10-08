-------------------------------------------------------------------------------
-- Title      : Dot product package
-------------------------------------------------------------------------------
-- Author     : Melissa Aguiar
-- Company    : CNPEM LNLS-DIG
-- Platform   : FPGA-generic
-- Standard   : VHDL 2008
-------------------------------------------------------------------------------
-- Description: Package for the dot product core
-------------------------------------------------------------------------------
-- Copyright (c) 2020-2022 CNPEM
-- Licensed under GNU Lesser General Public License (LGPL) v3.0
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                Description
-- 2021-07-30  1.0      melissa.aguiar        Created
-- 2022-07-27  1.1      guilherme.ricioli     Changed coeffs RAMs' wb interface
-- 2022-08-22  2.0      augusto.fraga         Refactored using VHDL 2008
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.fixed_pkg.all;

package dot_prod_pkg is

  constant c_FOFB_SP_INT_WIDTH           : natural := 15;
  constant c_FOFB_SP_FRAC_WIDTH          : natural := 0;
  constant c_FOFB_SP_WIDTH               : natural := c_FOFB_SP_INT_WIDTH + c_FOFB_SP_FRAC_WIDTH + 1;
  constant c_FOFB_WB_SP_MIN_MAX_WIDTH    : natural := 32;
  type t_fofb_processing_sp_arr is array (natural range <>) of signed(c_FOFB_SP_WIDTH-1 downto 0);
  type t_fofb_processing_wb_sp_arr is array (natural range <>) of std_logic_vector(c_FOFB_WB_SP_MIN_MAX_WIDTH-1 downto 0);

  constant c_FOFB_GAIN_INT_WIDTH         : natural := 3;
  constant c_FOFB_GAIN_FRAC_WIDTH        : natural := 12;
  constant c_FOFB_GAIN_WIDTH             : natural := c_FOFB_GAIN_INT_WIDTH + c_FOFB_GAIN_FRAC_WIDTH + 1;
  constant c_FOFB_WB_GAIN_WIDTH          : natural := 32;
  type t_fofb_processing_gain_arr is array (natural range <>) of signed(c_FOFB_GAIN_WIDTH-1 downto 0);
  type t_fofb_processing_wb_gain_arr is array (natural range <>) of std_logic_vector(c_FOFB_WB_GAIN_WIDTH-1 downto 0);

  -- RAM interface widths
  constant c_SP_COEFF_RAM_ADDR_WIDTH      : natural := 9;
  constant c_COEFF_RAM_DATA_WIDTH         : natural := 32;
  constant c_SP_POS_RAM_DATA_WIDTH        : natural := 32;
  type t_arr_coeff_ram_addr is array (natural range <>) of std_logic_vector(c_SP_COEFF_RAM_ADDR_WIDTH-1 downto 0);
  type t_arr_coeff_ram_data is array (natural range <>) of std_logic_vector(c_COEFF_RAM_DATA_WIDTH-1 downto 0);

  component dot_prod is
    generic(
    -- Integer width for input a[k]
    g_A_INT_WIDTH                  : natural := 7;

    -- Fractionary width for input a[k]
    g_A_FRAC_WIDTH                 : natural := 10;

    -- Integer width for input b[k]
    g_B_INT_WIDTH                  : natural := 7;

    -- Fractionary width for input b[k]
    g_B_FRAC_WIDTH                 : natural := 10;

    -- Extra bits for accumulator
    g_ACC_EXTRA_WIDTH              : natural := 4;

    -- Use registered inputs
    g_REG_INPUTS                   : boolean := false;

    -- Number of multiplier pipeline stages
    g_MULT_PIPELINE_STAGES         : natural := 1;

    -- Number of accumulator pipeline stages
    g_ACC_PIPELINE_STAGES          : natural := 1
  );
  port(
    -- Core clock
    clk_i                          : in std_logic;

    -- Reset all pipeline stages
    rst_n_i                        : in std_logic;

    -- Clear the accumulator
    clear_acc_i                    : in std_logic;

    -- Data valid input
    valid_i                        : in std_logic;

    -- Input a[k]
    a_i                            : in sfixed(g_A_INT_WIDTH downto -g_A_FRAC_WIDTH);

    -- Input b[k]
    b_i                            : in sfixed(g_B_INT_WIDTH downto -g_B_FRAC_WIDTH);

    -- No ongoing operations, all pipeline stages idle
    idle_o                         : out std_logic;

    -- Result output
    result_o                       : out sfixed(g_A_INT_WIDTH + g_B_INT_WIDTH + g_ACC_EXTRA_WIDTH + 1
                                                downto
                                                -(g_A_FRAC_WIDTH + g_B_FRAC_WIDTH))
  );
  end component dot_prod;

  component fofb_processing_channel is
    generic (
      -- Integer width for the inverse response matrix coefficient input
      g_COEFF_INT_WIDTH              : natural := 0;

      -- Fractionary width for the inverse response matrix coefficient input
      g_COEFF_FRAC_WIDTH             : natural := 17;

      -- Integer width for the BPM position error input
      g_BPM_POS_INT_WIDTH            : natural := 20;

      -- Fractionary width for the BPM position error input
      g_BPM_POS_FRAC_WIDTH           : natural := 0;

      -- Integer width for the accumulator gain input
      g_GAIN_INT_WIDTH               : natural := 7;

      -- Fractionary width for the accumulator gain input
      g_GAIN_FRAC_WIDTH              : natural := 8;

      -- Integer width for the set-point output
      g_SP_INT_WIDTH                 : natural := 15;

      -- Fractionary width for the set-point output
      g_SP_FRAC_WIDTH                : natural := 0;

      -- Extra bits for the dot product accumulator
      g_DOT_PROD_ACC_EXTRA_WIDTH     : natural := 4;

      -- Dot product multiply pipeline stages
      g_DOT_PROD_MUL_PIPELINE_STAGES : natural := 1;

      -- Dot product accumulator pipeline stages
      g_DOT_PROD_ACC_PIPELINE_STAGES : natural := 1;

      -- Gain multiplication pipeline stages
      g_ACC_GAIN_MUL_PIPELINE_STAGES : natural := 1;

      -- Width for RAM addr
      g_COEFF_RAM_ADDR_WIDTH         : natural;

      -- Bit width
      g_COEFF_RAM_DATA_WIDTH         : natural
    );
    port (
      -- Core clock
      clk_i                          : in  std_logic;

      -- Core reset
      rst_n_i                        : in  std_logic;

      -- If busy_o = '1', core is busy, can't receive new data
      busy_o                         : out std_logic;

      -- BPM position error data
      bpm_pos_err_i                  : in  signed((g_BPM_POS_INT_WIDTH + g_BPM_POS_FRAC_WIDTH) downto 0);

      -- BPM position error data valid
      bpm_pos_err_valid_i            : in  std_logic;

      -- BPM position index, it should match the coefficient address
      bpm_pos_err_index_i            : in  integer range 0 to (2**g_COEFF_RAM_ADDR_WIDTH)-1;

      -- Indicates that the time frame has ended, so it can compute a new setpoint
      bpm_time_frame_end_i           : in  std_logic;

      -- Coefficients RAM address, it is derived from bpm_pos_err_index
      coeff_ram_addr_o               : out std_logic_vector(g_COEFF_RAM_ADDR_WIDTH-1 downto 0);

      -- Coefficients RAM data, it should be the corresponding data from the address
      -- written in the previous clock cycle
      coeff_ram_data_i               : in  std_logic_vector(g_COEFF_RAM_DATA_WIDTH-1 downto 0);

      -- Pre-accumulator gain
      gain_i                         : in  signed((g_GAIN_INT_WIDTH + g_GAIN_FRAC_WIDTH) downto 0);

      -- Stop accumulating the dot product result
      freeze_acc_i                   : in  std_logic;

      -- Clear the set-point accumulator, also generate a valid pulse
      clear_acc_i                    : in  std_logic;

      -- Set-point maximum value, don't accumulate beyond that
      sp_max_i                       : in  signed((g_SP_INT_WIDTH + g_SP_FRAC_WIDTH) downto 0);

      -- Set-point minimum value, don't accumulate below that
      sp_min_i                       : in  signed((g_SP_INT_WIDTH + g_SP_FRAC_WIDTH) downto 0);

      -- Setpoint output
      sp_o                           : out signed((g_SP_INT_WIDTH + g_SP_FRAC_WIDTH) downto 0);

      -- Setpoint valid, it will generate a positive pulse after bpm_time_frame_end_i
      -- is set to '1' and all arithmetic operations have finished
      sp_valid_o                     : out std_logic
    );
  end component fofb_processing_channel;

  component fofb_processing is
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

      -- Set-points (per channel) maximum value, don't accumulate beyond that
      sp_max_arr_i                   : in  t_fofb_processing_sp_arr(g_CHANNELS-1 downto 0);

      -- Set-points (per channel) minimum value, don't accumulate below that
      sp_min_arr_i                   : in  t_fofb_processing_sp_arr(g_CHANNELS-1 downto 0);

      -- Set-points output array (for each channel)
      sp_arr_o                       : out t_fofb_processing_sp_arr(g_CHANNELS-1 downto 0);

      -- Set-point valid array (for each channel)
      sp_valid_arr_o                 : out std_logic_vector(g_CHANNELS-1 downto 0)
    );
  end component fofb_processing;

end package dot_prod_pkg;

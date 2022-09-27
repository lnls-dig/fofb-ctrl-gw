-------------------------------------------------------------------------------
-- Title      : FOFB processing channel
-------------------------------------------------------------------------------
-- Author     : Melissa Aguiar
-- Company    : CNPEM LNLS-GCA
-- Platform   : FPGA-generic
-- Standard   : VHDL 2008
-------------------------------------------------------------------------------
-- Description: Processing channel for the Fast Orbit Feedback
--
-- Functional overview:
--                                    +-----------+
--                          gain_i -> |   Gain    |    +-------------+
--                     +---------+    | Multplier | -> | Accumulator | -> sp_o
-- coeff_ram_data_i -> |   Dot   | -> |           |    +-------------+
-- bpm_pos_err_i    -> | Product |    +-----------+
--                     +---------+
-------------------------------------------------------------------------------
-- Copyright (c) 2020-2022 CNPEM
-- Licensed under GNU Lesser General Public License (LGPL) v3.0
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                Description
-- 2021-08-26  1.0      melissa.aguiar        Created
-- 2022-07-27  1.1      guilherme.ricioli     Changed coeffs RAMs' wb interface
-- 2022-08-29  2.0      augusto.fraga         Refactored using VHDL 2008, add
--                                            accumulator gain
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;
use ieee.fixed_pkg.all;

library work;
-- Dot product package
use work.dot_prod_pkg.all;

entity fofb_processing_channel is
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
end fofb_processing_channel;

architecture behave of fofb_processing_channel is
  type t_fofb_proc_state is (CALC_DOT_PROD, WAIT_DOT_PROD_FINISH);
  signal fofb_proc_state           : t_fofb_proc_state;
  signal clear_acc_dot_prod        : std_logic;
  signal dot_prod_valid            : std_logic;
  signal dot_prod_idle             : std_logic;
  signal dot_prod_res              : sfixed(g_COEFF_INT_WIDTH
                                            + g_BPM_POS_INT_WIDTH
                                            + g_DOT_PROD_ACC_EXTRA_WIDTH
                                            + 1
                                            downto
                                            -(g_COEFF_FRAC_WIDTH + g_BPM_POS_FRAC_WIDTH));
  type t_res_mult_gain_arr is array (natural range <>) of sfixed(dot_prod_res'left
                                            + g_GAIN_INT_WIDTH
                                            + 1
                                            downto
                                            dot_prod_res'right
                                            - g_GAIN_FRAC_WIDTH);

  signal res_mult_gain_pipe        : t_res_mult_gain_arr(g_ACC_GAIN_MUL_PIPELINE_STAGES-1 downto 0);
  signal res_mult_gain_pipe_valid  : std_logic_vector(g_ACC_GAIN_MUL_PIPELINE_STAGES-1 downto 0);
  signal acc                       : sfixed(g_SP_INT_WIDTH downto -g_SP_FRAC_WIDTH);
  signal gain                      : sfixed(g_GAIN_INT_WIDTH downto -g_GAIN_FRAC_WIDTH);
  signal bpm_pos_err_fp            : sfixed(g_BPM_POS_INT_WIDTH downto -g_BPM_POS_FRAC_WIDTH);
  signal coeff_fp                  : sfixed(g_COEFF_INT_WIDTH downto -g_COEFF_FRAC_WIDTH);
begin

  -- Cast bpm_pos_err_index_i to std_logic_vector (coefficient RAM address)
  coeff_ram_addr_o <= std_logic_vector(to_unsigned(bpm_pos_err_index_i, coeff_ram_addr_o'length));

  -- Get the first most significant bits from the coefficient ram data
  coeff_fp <= sfixed(coeff_ram_data_i(g_COEFF_RAM_DATA_WIDTH - 1
                                      downto
                                      g_COEFF_RAM_DATA_WIDTH
                                      - g_COEFF_INT_WIDTH
                                      - g_COEFF_FRAC_WIDTH
                                      - 1));

  -- Cast gain_i to fixed point, assume the integer and fractionary parts to be
  -- g_GAIN_INT_WIDTH and g_GAIN_FRAC_WIDTH respectively
  gain <= sfixed(gain_i);

  -- Set-point output is the accumulator value casted to signed
  sp_o <= signed(to_slv(acc));

  -- Core is busy when it is not in the calculing the dot product state
  busy_o <= '0' when fofb_proc_state = CALC_DOT_PROD else '1';

  cmp_dot_prod: dot_prod
    generic map (
      g_A_INT_WIDTH          => g_COEFF_INT_WIDTH,
      g_A_FRAC_WIDTH         => g_COEFF_FRAC_WIDTH,
      g_B_INT_WIDTH          => g_BPM_POS_INT_WIDTH,
      g_B_FRAC_WIDTH         => g_BPM_POS_FRAC_WIDTH,
      g_ACC_EXTRA_WIDTH      => g_DOT_PROD_ACC_EXTRA_WIDTH,
      g_REG_INPUTS           => false,
      g_MULT_PIPELINE_STAGES => g_DOT_PROD_MUL_PIPELINE_STAGES,
      g_ACC_PIPELINE_STAGES  => g_DOT_PROD_ACC_PIPELINE_STAGES
      )
    port map (
      clk_i                  => clk_i,
      rst_n_i                => rst_n_i,
      clear_acc_i            => clear_acc_dot_prod,
      valid_i                => dot_prod_valid,
      a_i                    => coeff_fp,
      b_i                    => bpm_pos_err_fp,
      idle_o                 => dot_prod_idle,
      result_o               => dot_prod_res
      );

  process(clk_i)
    variable res_mult_gain_resized_to_acc : acc'subtype;
    variable res_acc_sum                  : acc'subtype;
  begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        clear_acc_dot_prod <= '0';
        dot_prod_valid <= '0';
        bpm_pos_err_fp <= (others => '0');
        acc <= (others => '0');
        sp_valid_o <= '0';
        res_mult_gain_pipe_valid <= (others => '0');
        fofb_proc_state <= CALC_DOT_PROD;
      else
        -- Delay 1 clock cycle to wait for the RAM data
        dot_prod_valid <= bpm_pos_err_valid_i;
        bpm_pos_err_fp <= sfixed(bpm_pos_err_i);

        -- Drive first pipeline stage valid to '0' by default
        res_mult_gain_pipe_valid(0) <= '0';

        case fofb_proc_state is
          when CALC_DOT_PROD =>
            clear_acc_dot_prod <= '0';
            if bpm_time_frame_end_i = '1' then
              -- Time frame ended, wait for the dot product core to end all operations
              fofb_proc_state <= WAIT_DOT_PROD_FINISH;
            end if;

          when WAIT_DOT_PROD_FINISH =>
            if dot_prod_idle = '1' then
              -- Clear the dot product accumulator for the next fofb cycle
              clear_acc_dot_prod <= '1';

              -- Multiply the dot product result with the accumulator gain
              res_mult_gain_pipe(0) <= dot_prod_res * gain;
              -- Set the valid bit to the gain multiplication pipeline
              res_mult_gain_pipe_valid(0) <= '1';

              -- Go back to calculing the dot product state, ready to receive
              -- new data
              fofb_proc_state <= CALC_DOT_PROD;
            end if;
        end case;

        -- Add more intermediate registers to the gain multiplication result
        if g_ACC_GAIN_MUL_PIPELINE_STAGES > 1 then
          for i in 1 to g_ACC_GAIN_MUL_PIPELINE_STAGES-1 loop
            res_mult_gain_pipe_valid(i) <= res_mult_gain_pipe_valid(i - 1);
            res_mult_gain_pipe(i) <= res_mult_gain_pipe(i - 1);
          end loop;
        end if;

        if clear_acc_i = '1' then
          acc <= (others => '0');
          sp_valid_o <= '1';
        elsif res_mult_gain_pipe_valid(res_mult_gain_pipe_valid'high) = '1' then
          -- Only accumulate if freeze_acc_i = '0', but generate a sp_valid_o
          -- pulse anyways
          if freeze_acc_i = '0' then
            -- Resize gain multiplication result to the accumulator size
            res_mult_gain_resized_to_acc := resize(res_mult_gain_pipe(res_mult_gain_pipe'high), acc'left, acc'right);
            res_acc_sum := resize(acc + res_mult_gain_resized_to_acc, acc'left, acc'right);
            -- Check if the resulting set-point is withing limits set by
            -- sp_max_i and sp_min_i
            if signed(to_slv(res_acc_sum)) > sp_max_i then
              -- Saturate to sp_max_i
              acc <= sfixed(sp_max_i);
            elsif signed(to_slv(res_acc_sum)) < sp_min_i then
              -- Saturate to sp_min_i
              acc <= sfixed(sp_min_i);
            else
              -- Accumulate dot product result
              acc <= res_acc_sum;
            end if;
          end if;
          sp_valid_o <= '1';
        else
          sp_valid_o <= '0';
        end if;

      end if;
    end if;
  end process;

end architecture behave;

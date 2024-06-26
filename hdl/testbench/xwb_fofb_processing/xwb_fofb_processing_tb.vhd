------------------------------------------------------------------------------
-- Title      : xwb_fofb_processing_tb testbench
------------------------------------------------------------------------------
-- Author     : Guilherme Ricioli Cruz
-- Company    : CNPEM LNLS-GCA
-- Platform   : Simulation
-- Standard   : VHDL 2008
-------------------------------------------------------------------------------
-- Description:  Testbench for the xwb_fofb_processing_tb module.
-------------------------------------------------------------------------------
-- Copyright (c) 2022 CNPEM
-- Licensed under GNU Lesser General Public License (LGPL) v3.0
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author             Description
-- 2022-07-26  1.0      guilherme.ricioli  Created
-- 2022-09-05  2.0      augusto.fraga      Update testbench to match the new
--                                         xwb_fofb_processing interface
-- 2022-09-13  2.1      guilherme.ricioli  Include reference ram and compute/
--                                         check xwb_fofb_processing expected
--                                         output
-- 2022-09-19  2.2      guilherme.ricioli  Test wishbone interface for
--                                         accumulators regs
-- 2022-01-11  2.3      guilherme.ricioli  Test wishbone interface for
--                                         loop interlock regs
-- 2023-02-15  3.0      guilherme.ricioli  Update to match the new
--                                         wb_fofb_processing_regs api
-- 2023-03-03  3.1      guilherme.ricioli  Test setpoint decimation regs
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library std;
use std.env.finish;
use std.textio.all;

library work;
use work.fofb_ctrl_pkg.all;
use work.dot_prod_pkg.all;
use work.wishbone_pkg.all;
use work.sim_wishbone.all;
use work.wb_fofb_processing_regs_consts_pkg.all;
use work.fofb_tb_pkg.all;

entity xwb_fofb_processing_tb is
  generic (
    -- integer width for the inverse response matrix coefficient input
    g_COEFF_INT_WIDTH              : natural := 0;

    -- fractionary width for the inverse response matrix coefficient input
    g_COEFF_FRAC_WIDTH             : natural := 17;

    -- integer width for the bpm position error input
    g_BPM_POS_INT_WIDTH            : natural := 20;

    -- fractionary width for the bpm position error input
    g_BPM_POS_FRAC_WIDTH           : natural := 0;

    -- extra bits for the dot product accumulator
    g_DOT_PROD_ACC_EXTRA_WIDTH     : natural := 4;

    -- dot product multiply pipeline stages
    g_DOT_PROD_MUL_PIPELINE_STAGES : natural := 2;

    -- dot product accumulator pipeline stages
    g_DOT_PROD_ACC_PIPELINE_STAGES : natural := 2;

    -- gain multiplication pipeline stages
    g_ACC_GAIN_MUL_PIPELINE_STAGES : natural := 2;

    -- number of fofb cycles to simulate
    g_FOFB_NUM_CYC                 : natural := 20;

    -- fofb processing saturation maximum value
    g_SP_MAX                       : integer := 15200;

    -- fofb processing saturation minimum value
    g_SP_MIN                       : integer := -15200;

    -- loop interlock orbit distortion limit
    g_ORB_DISTORT_LIMIT            : natural := 1000;

    -- loop interlock minimum number of measurements per timeframe
    g_MIN_NUM_PKTS                 : natural := 10;

    -- inverse response matrix coefficients file (in binary)
    g_COEFF_RAM_FILE               : string  := "../coeff_norm.dat";

    -- bpm positions data
    g_FOFB_BPM_POS_FILE            : string  := "../fofb_bpm_pos.dat";

    -- bpm reference orbit data (set-point)
    g_FOFB_BPM_REF_FILE            : string  := "../fofb_bpm_ref.dat";

    -- accumulators gains
    g_FOFB_GAINS_FILE              : string  := "../fofb_gains.dat";

    -- number of fofb processing channels
    g_CHANNELS                     : natural := 12
  );
end entity xwb_fofb_processing_tb;

architecture xwb_fofb_processing_tb_arch of xwb_fofb_processing_tb is
  -- constants
  constant c_SYS_CLOCK_FREQ             : natural := 100_000_000;

  constant c_RAM_BANK_SIZE              : natural :=
    (c_WB_FOFB_PROCESSING_REGS_CH_0_ACC_ADDR -
      c_WB_FOFB_PROCESSING_REGS_CH_0_COEFF_RAM_BANK_ADDR);

  constant c_NUM_OF_COEFFS_PER_CHANNEL  : natural :=
    c_RAM_BANK_SIZE / c_WB_FOFB_PROCESSING_REGS_CH_0_COEFF_RAM_BANK_SIZE;

  constant c_NUM_OF_SETPOINTS           : natural :=
    c_NUM_OF_COEFFS_PER_CHANNEL;

  constant c_WB_SP_MAX                  :
    std_logic_vector(c_FOFB_WB_SP_MIN_MAX_WIDTH-1 downto 0) :=
      std_logic_vector(to_signed(g_SP_MAX, c_FOFB_WB_SP_MIN_MAX_WIDTH));

  constant c_WB_SP_MIN                  :
    std_logic_vector(c_FOFB_WB_SP_MIN_MAX_WIDTH-1 downto 0) :=
      std_logic_vector(to_signed(g_SP_MIN, c_FOFB_WB_SP_MIN_MAX_WIDTH));

  constant c_WB_ORB_DISTORT_LIMIT       : std_logic_vector(31 downto 0) :=
    std_logic_vector(to_unsigned(g_ORB_DISTORT_LIMIT, c_FOFB_WB_GAIN_WIDTH));

  constant c_WB_MIN_NUM_PKTS            : std_logic_vector(31 downto 0) :=
    std_logic_vector(to_unsigned(g_MIN_NUM_PKTS, c_FOFB_WB_GAIN_WIDTH));

  -- signals
  signal clk                            : std_logic := '0';
  signal rst_n                          : std_logic := '0';

  signal busy                           : std_logic;
  signal bpm_pos                        :
    signed(c_SP_POS_RAM_DATA_WIDTH-1 downto 0) := (others => '0');
  signal bpm_pos_index                  :
    unsigned(c_SP_COEFF_RAM_ADDR_WIDTH-1 downto 0) := (others => '0');
  signal bpm_pos_valid                  : std_logic := '0';
  signal bpm_time_frame_end             : std_logic := '0';

  signal sp_arr                         :
    t_fofb_processing_sp_arr(g_CHANNELS-1 downto 0);
  signal frozen_sp_arr                  :
    t_fofb_processing_sp_arr(g_CHANNELS-1 downto 0);
  signal sp_valid_arr                   :
    std_logic_vector(g_CHANNELS-1 downto 0):= (others => '0');

  signal sp_decim_arr                   :
    t_fofb_processing_sp_decim_arr(g_CHANNELS-1 downto 0);
  signal sp_decim_valid_arr             :
    std_logic_vector(g_CHANNELS-1 downto 0);
  signal is_there_any_sp_decim_valid    : std_logic := '0';

  signal wb_slave_i                     : t_wishbone_slave_in;
  signal wb_slave_o                     : t_wishbone_slave_out;

  -- TODO: used to solve 'actual signal must be a static name' error
  signal valid_to_check                 : std_logic := '0';

  function f_get_ch_reg_addr(offs: natural; ch: natural) return natural is
    constant c_CH_REGS_BASE_ADDR : natural := c_WB_FOFB_PROCESSING_REGS_CH_ADDR;
    constant c_CH_REGS_SIZE_PER_CH : natural := c_WB_FOFB_PROCESSING_REGS_CH_0_SIZE;
  begin
    assert (offs <= c_CH_REGS_SIZE_PER_CH and ch <= g_CHANNELS-1)
      report "improper params: offs: " & natural'image(offs) & ", ch: " &
        natural'image(ch)
      severity error;

    return c_CH_REGS_BASE_ADDR + ch * c_CH_REGS_SIZE_PER_CH + offs;
  end function;

begin
  f_gen_clk(c_SYS_CLOCK_FREQ, clk);

  is_there_any_sp_decim_valid <= or sp_decim_valid_arr;

  -- main process
  process
    variable addr                         : natural := 0;
    variable offs                         : natural := 0;
    variable data                         : std_logic_vector(31 downto 0) :=
      (others => '0');

    variable bpm_pos_reader               : t_bpm_pos_reader;
    variable bpm_x, bpm_y                 : integer;
    variable bpm_x_err, bpm_y_err         : integer;

    variable accs_gains_reader            : t_accs_gains_reader;
    variable real_gain_arr                :
      real_vector(g_CHANNELS-1 downto 0) := (others => 0.0);
    variable wb_gain                      :
      std_logic_vector(c_FOFB_WB_GAIN_WIDTH-1 downto 0);
    variable wb_ratio                     : std_logic_vector(31 downto 0);

    variable coeff_ram                    : t_coeff_ram_data;
    variable sp_ram                       : t_sp_ram_data;

    variable expec_dot_prod_arr           :
      real_vector(g_CHANNELS-1 downto 0) := (others => 0.0);
    variable expec_fofb_proc_sp_arr       :
      real_vector(g_CHANNELS-1 downto 0) := (others => 0.0);
    variable sp_err                       : real := 0.0;
    variable sp_diff                      : real := 0.0;

    variable expec_fofb_proc_sp_decim_arr :
      real_vector(g_CHANNELS-1 downto 0) := (others => 0.0);
    variable sp_decim_err                 : real := 0.0;

    variable meas_cnt                     : natural := 0;
    variable expec_loop_intlk_state       : boolean := false;

  begin
    -- loading coefficients and set-point from files
    report "loading coefficients and set-point from files"
    severity note;

    coeff_ram.load_coeff_from_file(g_COEFF_RAM_FILE);
    sp_ram.load_sp_from_file(g_FOFB_BPM_REF_FILE);

    -- opening accumulators gains file
    report "opening accumulators gains file"
    severity note;

    accs_gains_reader.open_accs_gains_file(g_FOFB_GAINS_FILE);

    -- resetting cores
    report "resetting cores"
    severity note;

    init(wb_slave_i);
    f_wait_cycles(clk, 10);

    rst_n <= '0';
    f_wait_cycles(clk, 1);
    rst_n <= '1';
    f_wait_cycles(clk, 10);

    -- writing on coefficients rams
    report "writing on coefficients rams"
    severity note;

    read32_pl(clk, wb_slave_i, wb_slave_o,
      c_WB_FOFB_PROCESSING_REGS_FIXED_POINT_POS_COEFF_ADDR, data);
    report "coefficients fixed-point position: " & to_hstring(data)
    severity note;

    offs := c_WB_FOFB_PROCESSING_REGS_CH_0_COEFF_RAM_BANK_ADDR -
      c_WB_FOFB_PROCESSING_REGS_CH_0_ADDR;
    for i in 0 to (g_CHANNELS - 1)
    loop
      for j in 0 to (c_NUM_OF_COEFFS_PER_CHANNEL - 1)
      loop
        addr := f_get_ch_reg_addr(offs +
          j*c_WB_FOFB_PROCESSING_REGS_CH_0_COEFF_RAM_BANK_SIZE, i);

        write32_pl(clk, wb_slave_i, wb_slave_o, addr, coeff_ram.get_coeff(j));
        read32_pl(clk, wb_slave_i, wb_slave_o, addr, data);

        assert (data = coeff_ram.get_coeff(j))
          report "wrong ram coefficient at " & natural'image(addr) & " " & to_hstring(data)
          severity error;
      end loop;
    end loop;

    -- writing on setpoints ram
    report "writing on setpoints ram"
    severity note;

    addr := c_WB_FOFB_PROCESSING_REGS_SPS_RAM_BANK_ADDR;
    for i in 0 to (c_NUM_OF_SETPOINTS - 1)
    loop
      write32_pl(clk, wb_slave_i, wb_slave_o, addr, sp_ram.get_sp(i));
      read32_pl(clk, wb_slave_i, wb_slave_o, addr, data);

      assert (data = sp_ram.get_sp(i))
        report "wrong ram setpoint at " & natural'image(addr)
        severity error;

      -- address should jump c_WB_FOFB_PROCESSING_REGS_SPS_RAM_BANK_SIZE
      -- on each iteration (wishbone bus is using byte-granularity)
      addr := addr + c_WB_FOFB_PROCESSING_REGS_SPS_RAM_BANK_SIZE;
    end loop;

    -- setting gains
    report "setting gains"
    severity note;

    read32_pl(clk, wb_slave_i, wb_slave_o,
      c_WB_FOFB_PROCESSING_REGS_FIXED_POINT_POS_ACCS_GAINS_ADDR, data);
    report "gains fixed-point position: " & to_hstring(data)
    severity note;

    offs := c_WB_FOFB_PROCESSING_REGS_CH_0_ACC_GAIN_ADDR -
      c_WB_FOFB_PROCESSING_REGS_CH_0_ADDR;
    for i in 0 to (g_CHANNELS - 1)
    loop
      accs_gains_reader.read_accs_gain(real_gain_arr(i));
      wb_gain := std_logic_vector(
        shift_left(
          to_signed(integer(real_gain_arr(i) * 2.0**c_FOFB_GAIN_FRAC_WIDTH),
            c_FOFB_WB_GAIN_WIDTH), c_FOFB_WB_GAIN_WIDTH-c_FOFB_GAIN_WIDTH));

      addr := f_get_ch_reg_addr(offs, i);

      write32_pl(clk, wb_slave_i, wb_slave_o, addr, wb_gain);
      read32_pl(clk, wb_slave_i, wb_slave_o, addr, data);

      assert (data = wb_gain)
        report "wrong gain at " & natural'image(addr)
        severity error;

    end loop;

    -- setting saturation limits
    report "setting saturation limits"
    severity note;

    for i in 0 to (g_CHANNELS - 1)
    loop
      offs := c_WB_FOFB_PROCESSING_REGS_CH_0_SP_LIMITS_MAX_ADDR -
        c_WB_FOFB_PROCESSING_REGS_CH_0_ADDR;
      addr := f_get_ch_reg_addr(offs, i);

      -- writing maximum saturation value
      write32_pl(clk, wb_slave_i, wb_slave_o, addr, c_WB_SP_MAX);
      read32_pl(clk, wb_slave_i, wb_slave_o, addr, data);

      assert (data = c_WB_SP_MAX)
        report "wrong saturation limit at " & natural'image(addr)
        severity error;

      offs := c_WB_FOFB_PROCESSING_REGS_CH_0_SP_LIMITS_MIN_ADDR -
        c_WB_FOFB_PROCESSING_REGS_CH_0_ADDR;
      addr := f_get_ch_reg_addr(offs, i);

      -- writing minimum saturation value
      write32_pl(clk, wb_slave_i, wb_slave_o, addr, c_WB_SP_MIN);
      read32_pl(clk, wb_slave_i, wb_slave_o, addr, data);

      assert (data = c_WB_SP_MIN)
        report "wrong saturation limit at " & natural'image(addr)
        severity error;
    end loop;

    -- setting setpoints decimation ratios
    report "setting setpoints decimation ratios"
    severity note;

    offs := c_WB_FOFB_PROCESSING_REGS_CH_0_SP_DECIM_RATIO_ADDR -
      c_WB_FOFB_PROCESSING_REGS_CH_0_ADDR;
    for i in 0 to (g_CHANNELS - 1)
    loop
      wb_ratio := std_logic_vector(to_unsigned(i, 32));

      addr := f_get_ch_reg_addr(offs, i);

      write32_pl(clk, wb_slave_i, wb_slave_o, addr, wb_ratio);
      read32_pl(clk, wb_slave_i, wb_slave_o, addr, data);

      assert (data = wb_ratio)
        report "wrong setpoint decimation ratio at " & natural'image(addr)
        severity error;

    end loop;

    -- setting limit for loop interlock orbit distortion source via wishbone
    -- bus
    report
      "setting limit for loop interlock orbit distortion source via wishbone" &
      " bus"
    severity note;

    addr := c_WB_FOFB_PROCESSING_REGS_LOOP_INTLK_ORB_DISTORT_LIMIT_ADDR;

    write32_pl(clk, wb_slave_i, wb_slave_o, addr, c_WB_ORB_DISTORT_LIMIT);
    read32_pl(clk, wb_slave_i, wb_slave_o, addr, data);

    assert (data = c_WB_ORB_DISTORT_LIMIT)
      report "orbit distortion limit was not set"
      severity error;

    -- setting minimum number of packets for loop interlock source via wishbone
    -- bus
    report
      "setting minimum number of packets for loop interlock source via " &
      "wishbone bus"
    severity note;

    addr := c_WB_FOFB_PROCESSING_REGS_LOOP_INTLK_MIN_NUM_PKTS_ADDR;

    write32_pl(clk, wb_slave_i, wb_slave_o, addr, c_WB_MIN_NUM_PKTS);
    read32_pl(clk, wb_slave_i, wb_slave_o, addr, data);

    assert (data = c_WB_MIN_NUM_PKTS)
      report "minimum number of packets was not set"
      severity error;

    -- disabling loop interlock sources
    report "disabling loop interlock sources"
    severity note;

    addr := c_WB_FOFB_PROCESSING_REGS_LOOP_INTLK_CTL_ADDR;

    read32_pl(clk, wb_slave_i, wb_slave_o, addr, data);
    data(
      c_WB_FOFB_PROCESSING_REGS_LOOP_INTLK_CTL_SRC_EN_ORB_DISTORT_OFFSET) :=
        '0';
    data(
      c_WB_FOFB_PROCESSING_REGS_LOOP_INTLK_CTL_SRC_EN_PACKET_LOSS_OFFSET) :=
        '0';

    write32_pl(clk, wb_slave_i, wb_slave_o, addr, data);
    read32_pl(clk, wb_slave_i, wb_slave_o, addr, data);

    assert (data(
      c_WB_FOFB_PROCESSING_REGS_LOOP_INTLK_CTL_SRC_EN_ORB_DISTORT_OFFSET) =
        '0')
      report "loop interlock orbit distortion source was not disabled"
      severity error;

    assert (data(
      c_WB_FOFB_PROCESSING_REGS_LOOP_INTLK_CTL_SRC_EN_PACKET_LOSS_OFFSET) =
        '0')
      report "loop interlock packet loss source was not disabled"
      severity error;

    -- opening bpm positions file
    report "opening bpm positions file"
    severity note;

    bpm_pos_reader.open_bpm_pos_file(g_FOFB_BPM_POS_FILE);

    for c in 0 to (g_FOFB_NUM_CYC - 1)
    loop
      -- resetting the expected dot product state
      expec_dot_prod_arr := (others => 0.0);
      for i in 0 to 159 loop
        bpm_pos_reader.read_bpm_pos(bpm_x, bpm_y);

        -- wait for the fofb_processing core to be ready to receive new data
        f_wait_clocked_signal(clk, busy, '0');

        -- new data available (serves the next two clock cycles)
        bpm_pos_valid <= '1';

        -- send bpm x position
        bpm_pos_index <= to_unsigned(i, c_SP_COEFF_RAM_ADDR_WIDTH);
        bpm_pos <= to_signed(bpm_x, c_SP_POS_RAM_DATA_WIDTH);
        f_wait_cycles(clk, 1);

        -- send bpm y position
        bpm_pos_index <= to_unsigned(i + 256, c_SP_COEFF_RAM_ADDR_WIDTH);
        bpm_pos <= to_signed(bpm_y, c_SP_POS_RAM_DATA_WIDTH);
        f_wait_cycles(clk, 1);

        -- data ended
        bpm_pos_valid <= '0';

        -- ########## computing expected dot product internal state ##########
        -- computing bpm position errors
        bpm_x_err := sp_ram.get_sp_integer(i) - bpm_x;
        bpm_y_err := sp_ram.get_sp_integer(i + 256) - bpm_y;

        -- computing expected dot product internal state
        for j in 0 to g_CHANNELS-1
        loop
          expec_dot_prod_arr(j) := expec_dot_prod_arr(j) +
            real(bpm_x_err) * coeff_ram.get_coeff_real(i, g_COEFF_FRAC_WIDTH);
          expec_dot_prod_arr(j) := expec_dot_prod_arr(j) +
            real(bpm_y_err) * coeff_ram.get_coeff_real(i + 256, g_COEFF_FRAC_WIDTH);
        end loop;
        -- ####### end of: computing expected dot product internal state #######
      end loop;

      -- ########## computing expected fofb processing setpoint ##########
      for i in 0 to g_CHANNELS-1
      loop
        expec_fofb_proc_sp_arr(i) := expec_fofb_proc_sp_arr(i) +
          real_gain_arr(i) * expec_dot_prod_arr(i);

          -- saturation
          if expec_fofb_proc_sp_arr(i) > real(g_SP_MAX) then
            expec_fofb_proc_sp_arr(i) := real(g_SP_MAX);
          elsif expec_fofb_proc_sp_arr(i) < real(g_SP_MIN) then
            expec_fofb_proc_sp_arr(i) := real(g_SP_MIN);
          end if;
      end loop;
      -- ########## computing expected fofb processing setpoint ##########

      -- ######## computing expected fofb processing decimated setpoint ########
      for i in 0 to g_CHANNELS-1
      loop
        expec_fofb_proc_sp_decim_arr(i) := expec_fofb_proc_sp_decim_arr(i) +
          expec_fofb_proc_sp_arr(i);
      end loop;
      -- ######## computing expected fofb processing decimated setpoint ########

      -- time frame ended
      bpm_time_frame_end <= '1';
      f_wait_cycles(clk, 1);
      bpm_time_frame_end <= '0';
      f_wait_cycles(clk, 1);

      -- wait until the new set-point is ready
      f_wait_clocked_signal(clk, sp_valid_arr(0), '1');

      report "fofb processing cycle " & to_string(c)
      severity note;

      for i in 0 to g_CHANNELS-1
      loop
        sp_err := abs((real(to_integer(sp_arr(i))) /
          floor(expec_fofb_proc_sp_arr(i))) - 1.0);
        sp_diff := abs(real(to_integer(sp_arr(i))) - expec_fofb_proc_sp_arr(i));

        report "channel " & to_string(i) & ": " &
          "setpoint: " & to_string(to_integer(sp_arr(i))) & " (expected: " &
          to_string(integer(floor(expec_fofb_proc_sp_arr(i)))) & ")" & " difference: " &
          to_string(sp_diff)
        severity note;

        if sp_err > 0.01 and sp_diff > 2.0 then
          report "error: " & to_string(sp_err) & " is too large (> 1%)!"
          severity error;
        else
          report "error: " & to_string(sp_err) & " is ok!"
          severity note;
        end if;
      end loop;

      -- Checks if any new decimated/filtered setpoint is ready (if more than
      -- one, they happen at the same cycle)
      f_wait_clocked_signal(clk, is_there_any_sp_decim_valid, '1', 10);

      for i in 0 to g_CHANNELS-1
      loop
        if sp_decim_valid_arr(i) = '1' then
          -- TODO: this may be problematic for small values
          sp_decim_err := abs((real(to_integer(sp_decim_arr(i))) /
            floor(expec_fofb_proc_sp_decim_arr(i))) - 1.0);

          report "channel " & to_string(i) & ": " &
            "decimated setpoint: " & to_string(to_integer(sp_decim_arr(i))) &
            " (expected: " &
            to_string(integer(floor(expec_fofb_proc_sp_decim_arr(i)))) & ")"
          severity note;

            if sp_decim_err > 0.01 then
              report "error: " & to_string(sp_decim_err) & " is too large (> 1%)!"
              severity error;
            else
              report "error: " & to_string(sp_decim_err) & " is ok!"
              severity note;
            end if;

            expec_fofb_proc_sp_decim_arr(i) := 0.0;
        end if;
      end loop;

      -- checking decimated setpoints wishbone reading
      report "checking decimated setpoints wishbone reading"
      severity note;

      offs := c_WB_FOFB_PROCESSING_REGS_CH_0_SP_DECIM_DATA_ADDR -
        c_WB_FOFB_PROCESSING_REGS_CH_0_ADDR;
      for i in 0 to (g_CHANNELS - 1)
      loop
        addr := f_get_ch_reg_addr(offs, i);

        read32_pl(clk, wb_slave_i, wb_slave_o, addr, data);

        assert (data = std_logic_vector(sp_decim_arr(i)))
          report
            "wrong decimated setpoints wishbone reading at " &
            natural'image(addr)
          severity error;

      end loop;
    end loop;

    -- enabling loop interlock orbit distortion source
    report "enabling loop interlock orbit distortion source"
    severity note;

    addr := c_WB_FOFB_PROCESSING_REGS_LOOP_INTLK_CTL_ADDR;

    read32_pl(clk, wb_slave_i, wb_slave_o, addr, data);
    data(
      c_WB_FOFB_PROCESSING_REGS_LOOP_INTLK_CTL_SRC_EN_ORB_DISTORT_OFFSET) :=
        '1';

    write32_pl(clk, wb_slave_i, wb_slave_o, addr, data);
    read32_pl(clk, wb_slave_i, wb_slave_o, addr, data);

    assert (data(
      c_WB_FOFB_PROCESSING_REGS_LOOP_INTLK_CTL_SRC_EN_ORB_DISTORT_OFFSET) =
        '1')
      report "loop interlock orbit distortion source was not enabled"
      severity error;

    -- ########## performing two extra fofb processing cycles ##########
    report "performing two extra fofb processing cycles"
    severity note;

    for c in 0 to 1
    loop
      -- resetting the expected dot product state
      expec_dot_prod_arr := (others => 0.0);

      -- fofb loop should interlock when c = 1
      bpm_x := g_ORB_DISTORT_LIMIT + sp_ram.get_sp_integer(0) + c;
      bpm_y := sp_ram.get_sp_integer(256);

      -- wait for the fofb_processing core to be ready to receive new data
      f_wait_clocked_signal(clk, busy, '0');

      -- new data available (serves the next two clock cycles)
      bpm_pos_valid <= '1';

      -- send bpm x position
      bpm_pos_index <= to_unsigned(0, c_SP_COEFF_RAM_ADDR_WIDTH);
      bpm_pos <= to_signed(bpm_x, c_SP_POS_RAM_DATA_WIDTH);
      f_wait_cycles(clk, 1);

      -- send bpm y position
      bpm_pos_index <= to_unsigned(256, c_SP_COEFF_RAM_ADDR_WIDTH);
      bpm_pos <= to_signed(bpm_y, c_SP_POS_RAM_DATA_WIDTH);
      f_wait_cycles(clk, 1);

      -- data ended
      bpm_pos_valid <= '0';

      -- ########## computing expected dot product internal state ##########
      -- computing bpm position errors
      bpm_x_err := sp_ram.get_sp_integer(0) - bpm_x;
      bpm_y_err := sp_ram.get_sp_integer(256) - bpm_y;

      -- checking orbit distortion
      if abs(bpm_x_err) > g_ORB_DISTORT_LIMIT or
        abs(bpm_x_err) > g_ORB_DISTORT_LIMIT then
          expec_loop_intlk_state := true;
      end if;

      -- computing expected dot product internal state
      for j in 0 to g_CHANNELS-1
      loop
        expec_dot_prod_arr(j) := expec_dot_prod_arr(j) +
          real(bpm_x_err) * coeff_ram.get_coeff_real(0, g_COEFF_FRAC_WIDTH);
        expec_dot_prod_arr(j) := expec_dot_prod_arr(j) +
          real(bpm_y_err) * coeff_ram.get_coeff_real(256, g_COEFF_FRAC_WIDTH);
      end loop;
      -- ####### end of: computing expected dot product internal state #######

      -- ########## computing expected fofb processing setpoint ##########
      for i in 0 to g_CHANNELS-1
      loop
        if expec_loop_intlk_state = false then
          expec_fofb_proc_sp_arr(i) := expec_fofb_proc_sp_arr(i) +
            real_gain_arr(i) * expec_dot_prod_arr(i);

            -- saturation
            if expec_fofb_proc_sp_arr(i) > real(g_SP_MAX) then
              expec_fofb_proc_sp_arr(i) := real(g_SP_MAX);
            elsif expec_fofb_proc_sp_arr(i) < real(g_SP_MIN) then
              expec_fofb_proc_sp_arr(i) := real(g_SP_MIN);
            end if;
        end if;
      end loop;
      -- ########## computing expected fofb processing setpoint ##########

      -- time frame ended
      bpm_time_frame_end <= '1';
      f_wait_cycles(clk, 1);
      bpm_time_frame_end <= '0';
      f_wait_cycles(clk, 1);

      -- wait until the new set-point is ready
      f_wait_clocked_signal(clk, sp_valid_arr(0), '1');

      report "fofb processing extra cycle " & to_string(c)
      severity note;

      for i in 0 to g_CHANNELS-1
      loop
        -- TODO: this may be problematic for smaller setpoint values
        sp_err := abs((real(to_integer(sp_arr(i))) /
          floor(expec_fofb_proc_sp_arr(i))) - 1.0);

        report "channel " & to_string(i) & ": " &
          "setpoint: " & to_string(to_integer(sp_arr(i))) & " (expected: " &
          to_string(integer(floor(expec_fofb_proc_sp_arr(i)))) & ")"
        severity note;

        if sp_err > 0.01 then
          report "error: " & to_string(sp_err) & " is too large (> 1%)!"
          severity error;
        else
          report "error: " & to_string(sp_err) & " is ok!"
          severity note;
        end if;
      end loop;

      -- checking loop interlock orbit distortion source state
      report
        "checking loop interlock orbit distortion source state"
      severity note;

      addr := c_WB_FOFB_PROCESSING_REGS_LOOP_INTLK_STA_ADDR;

      read32_pl(clk, wb_slave_i, wb_slave_o, addr, data);

      if expec_loop_intlk_state = false then
        assert (data(
          c_WB_FOFB_PROCESSING_REGS_LOOP_INTLK_STA_ORB_DISTORT_OFFSET) = '0')
            report "loop interlock should not be interlocked"
            severity error;
      else -- expec_loop_intlk_state = true
        assert (data(
          c_WB_FOFB_PROCESSING_REGS_LOOP_INTLK_STA_ORB_DISTORT_OFFSET) = '1')
            report "loop interlock should be interlocked"
            severity error;
      end if;

    end loop;

    -- ########## end of two extra fofb processing cycles ##########
    report "end of two extra fofb processing cycles"
    severity note;

    -- disabling loop interlock orbit distortion source
    report "disabling loop interlock orbit distortion source"
    severity note;

    addr := c_WB_FOFB_PROCESSING_REGS_LOOP_INTLK_CTL_ADDR;

    read32_pl(clk, wb_slave_i, wb_slave_o, addr, data);
    data(
      c_WB_FOFB_PROCESSING_REGS_LOOP_INTLK_CTL_SRC_EN_ORB_DISTORT_OFFSET) :=
        '0';

    write32_pl(clk, wb_slave_i, wb_slave_o, addr, data);
    read32_pl(clk, wb_slave_i, wb_slave_o, addr, data);

    assert (data(
      c_WB_FOFB_PROCESSING_REGS_LOOP_INTLK_CTL_SRC_EN_ORB_DISTORT_OFFSET) =
        '0')
      report "loop interlock orbit distortion source was not disabled"
      severity error;

    -- clearing loop interlock state
    report "clearing loop interlock state"
    severity note;

    addr := c_WB_FOFB_PROCESSING_REGS_LOOP_INTLK_CTL_ADDR;

    read32_pl(clk, wb_slave_i, wb_slave_o, addr, data);
    data(c_WB_FOFB_PROCESSING_REGS_LOOP_INTLK_CTL_STA_CLR_OFFSET) := '1';

    write32_pl(clk, wb_slave_i, wb_slave_o, addr, data);

    -- NOTE: must wait 4 clk cycles for status register to update
    f_wait_cycles(clk, 4);

    -- checking if loop interlock state was cleared
    report
      "checking if loop interlock state was cleared"
    severity note;

    addr := c_WB_FOFB_PROCESSING_REGS_LOOP_INTLK_STA_ADDR;

    read32_pl(clk, wb_slave_i, wb_slave_o, addr, data);

    assert (or data(c_FOFB_LOOP_INTLK_TRIGS_WIDTH-1 downto 0) = '0')
      report "loop interlock state was not cleared"
      severity error;
    expec_loop_intlk_state := false;

    -- enabling loop interlock packet loss source
    report "enabling loop interlock packet loss source"
    severity note;

    addr := c_WB_FOFB_PROCESSING_REGS_LOOP_INTLK_CTL_ADDR;

    read32_pl(clk, wb_slave_i, wb_slave_o, addr, data);
    data(
      c_WB_FOFB_PROCESSING_REGS_LOOP_INTLK_CTL_SRC_EN_PACKET_LOSS_OFFSET) :=
        '1';

    write32_pl(clk, wb_slave_i, wb_slave_o, addr, data);
    read32_pl(clk, wb_slave_i, wb_slave_o, addr, data);

    assert (data(
      c_WB_FOFB_PROCESSING_REGS_LOOP_INTLK_CTL_SRC_EN_PACKET_LOSS_OFFSET) =
        '1')
      report "loop interlock packet loss source was not enabled"
      severity error;

    -- ########## performing two extra fofb processing cycles ##########
    report "performing two extra fofb processing cycles"
    severity note;

    for c in 0 to 1
    loop
      -- resetting the expected dot product state
      expec_dot_prod_arr := (others => 0.0);

      -- fofb loop should interlock when c = 1
      meas_cnt := 0;
      for meas in 1 to (2*g_MIN_NUM_PKTS)-c
      loop
        bpm_x := meas + sp_ram.get_sp_integer(0);

        -- wait for the fofb_processing core to be ready to receive new data
        f_wait_clocked_signal(clk, busy, '0');

        -- new data available
        bpm_pos_valid <= '1';

        -- send bpm x position
        bpm_pos_index <= to_unsigned(0, c_SP_COEFF_RAM_ADDR_WIDTH);
        bpm_pos <= to_signed(bpm_x, c_SP_POS_RAM_DATA_WIDTH);
        f_wait_cycles(clk, 1);

        -- data ended
        bpm_pos_valid <= '0';

        -- count measurements
        meas_cnt := meas_cnt + 1;

        -- ########## computing expected dot product internal state ##########
        -- computing bpm position errors
        bpm_x_err := sp_ram.get_sp_integer(0) - bpm_x;

        -- computing expected dot product internal state
        for j in 0 to g_CHANNELS-1
        loop
          expec_dot_prod_arr(j) := expec_dot_prod_arr(j) +
            real(bpm_x_err) * coeff_ram.get_coeff_real(0, g_COEFF_FRAC_WIDTH);
        end loop;
        -- ####### end of: computing expected dot product internal state #######
      end loop;

      -- detect loop interlock due to packet loss
      if meas_cnt < (2*g_MIN_NUM_PKTS) then
          expec_loop_intlk_state := true;
      end if;

      -- ########## computing expected fofb processing setpoint ##########
      for i in 0 to g_CHANNELS-1
      loop
        if expec_loop_intlk_state = false then
          expec_fofb_proc_sp_arr(i) := expec_fofb_proc_sp_arr(i) +
            real_gain_arr(i) * expec_dot_prod_arr(i);

            -- saturation
            if expec_fofb_proc_sp_arr(i) > real(g_SP_MAX) then
              expec_fofb_proc_sp_arr(i) := real(g_SP_MAX);
            elsif expec_fofb_proc_sp_arr(i) < real(g_SP_MIN) then
              expec_fofb_proc_sp_arr(i) := real(g_SP_MIN);
            end if;
        end if;
      end loop;
      -- ########## computing expected fofb processing setpoint ##########

      -- time frame ended
      bpm_time_frame_end <= '1';
      f_wait_cycles(clk, 1);
      bpm_time_frame_end <= '0';
      f_wait_cycles(clk, 1);

      -- wait until the new set-point is ready
      f_wait_clocked_signal(clk, sp_valid_arr(0), '1');

      report "fofb processing extra cycle " & to_string(c)
      severity note;

      for i in 0 to g_CHANNELS-1
      loop
        -- TODO: this may be problematic for smaller setpoint values
        sp_err := abs((real(to_integer(sp_arr(i))) /
          floor(expec_fofb_proc_sp_arr(i))) - 1.0);

        report "channel " & to_string(i) & ": " &
          "setpoint: " & to_string(to_integer(sp_arr(i))) & " (expected: " &
          to_string(integer(floor(expec_fofb_proc_sp_arr(i)))) & ")"
        severity note;

        if sp_err > 0.01 then
          report "error: " & to_string(sp_err) & " is too large (> 1%)!"
          severity error;
        else
          report "error: " & to_string(sp_err) & " is ok!"
          severity note;
        end if;
      end loop;

      -- checking loop interlock packet loss source state
      report
        "checking loop interlock packet loss source state"
      severity note;

      addr := c_WB_FOFB_PROCESSING_REGS_LOOP_INTLK_STA_ADDR;

      read32_pl(clk, wb_slave_i, wb_slave_o, addr, data);

      if expec_loop_intlk_state = false then
        assert (data(
          c_WB_FOFB_PROCESSING_REGS_LOOP_INTLK_STA_PACKET_LOSS_OFFSET) = '0')
            report "loop interlock should not be interlocked"
            severity error;
      else -- expec_loop_intlk_state = true
        assert (data(
          c_WB_FOFB_PROCESSING_REGS_LOOP_INTLK_STA_PACKET_LOSS_OFFSET) = '1')
            report "loop interlock should be interlocked"
            severity error;
      end if;

    end loop;

    -- ########## end of two extra fofb processing cycles ##########
    report "end of two extra fofb processing cycles"
    severity note;

    -- disabling loop interlock packet loss source
    report "disabling loop interlock packet loss source"
    severity note;

    addr := c_WB_FOFB_PROCESSING_REGS_LOOP_INTLK_CTL_ADDR;

    read32_pl(clk, wb_slave_i, wb_slave_o, addr, data);
    data(
      c_WB_FOFB_PROCESSING_REGS_LOOP_INTLK_CTL_SRC_EN_PACKET_LOSS_OFFSET) :=
        '0';

    write32_pl(clk, wb_slave_i, wb_slave_o, addr, data);
    read32_pl(clk, wb_slave_i, wb_slave_o, addr, data);

    assert (data(
      c_WB_FOFB_PROCESSING_REGS_LOOP_INTLK_CTL_SRC_EN_PACKET_LOSS_OFFSET) =
        '0')
      report "loop interlock packet loss source was not disabled"
      severity error;

    -- clearing loop interlock state
    report "clearing loop interlock state"
    severity note;

    addr := c_WB_FOFB_PROCESSING_REGS_LOOP_INTLK_CTL_ADDR;

    read32_pl(clk, wb_slave_i, wb_slave_o, addr, data);
    data(c_WB_FOFB_PROCESSING_REGS_LOOP_INTLK_CTL_STA_CLR_OFFSET) := '1';

    write32_pl(clk, wb_slave_i, wb_slave_o, addr, data);

    -- NOTE: must wait 4 clk cycles for status register to update
    f_wait_cycles(clk, 4);

    -- checking if loop interlock state was cleared
    report
      "checking if loop interlock state was cleared"
    severity note;

    addr := c_WB_FOFB_PROCESSING_REGS_LOOP_INTLK_STA_ADDR;

    read32_pl(clk, wb_slave_i, wb_slave_o, addr, data);

    assert (or data(c_FOFB_LOOP_INTLK_TRIGS_WIDTH-1 downto 0) = '0')
      report "loop interlock state was not cleared"
      severity error;
    expec_loop_intlk_state := false;

    -- freezing accumulators
    report "freezing accumulators"
    severity note;

    addr := c_WB_FOFB_PROCESSING_REGS_CH_0_ACC_CTL_ADDR;
    for i in 0 to (g_CHANNELS - 1)
    loop
      read32_pl(clk, wb_slave_i, wb_slave_o, addr, data);
      data(c_WB_FOFB_PROCESSING_REGS_CH_0_ACC_CTL_FREEZE_OFFSET) := '1';
      write32_pl(clk, wb_slave_i, wb_slave_o, addr, data);

      frozen_sp_arr(i) <= sp_arr(i);

      -- address should jump c_WB_FOFB_PROCESSING_REGS_CH_1_ACC_CTL_ADDR -
      -- c_WB_FOFB_PROCESSING_REGS_CH_0_ACC_CTL_ADDR on each iteration
      addr := addr + c_WB_FOFB_PROCESSING_REGS_CH_1_ACC_CTL_ADDR -
        c_WB_FOFB_PROCESSING_REGS_CH_0_ACC_CTL_ADDR;
    end loop;

    -- ########## performing an extra fofb processing cycle ##########
    report "performing an extra fofb processing cycle"
    severity note;

    for i in 0 to 159 loop
      -- wait for the fofb_processing core to be ready to receive new data
      f_wait_clocked_signal(clk, busy, '0');

      -- new data available (serves the next two clock cycles)
      bpm_pos_valid <= '1';

      -- send bpm x position
      bpm_pos_index <= to_unsigned(i, c_SP_COEFF_RAM_ADDR_WIDTH);
      bpm_pos <= to_signed(i, c_SP_POS_RAM_DATA_WIDTH);
      f_wait_cycles(clk, 1);

      -- send bpm y position
      bpm_pos_index <= to_unsigned(i + 256, c_SP_COEFF_RAM_ADDR_WIDTH);
      bpm_pos <= to_signed(i + 256, c_SP_POS_RAM_DATA_WIDTH);
      f_wait_cycles(clk, 1);

      -- data ended
      bpm_pos_valid <= '0';
    end loop;

    -- time frame ended
    bpm_time_frame_end <= '1';
    f_wait_cycles(clk, 1);
    bpm_time_frame_end <= '0';
    f_wait_cycles(clk, 1);

    -- wait until the new set-point is ready
    f_wait_clocked_signal(clk, sp_valid_arr(0), '1');

    for i in 0 to g_CHANNELS-1
    loop
      if (sp_arr(i) = frozen_sp_arr(i)) then
        report "accumulator from channel " & to_string(i) & " was frozen!"
        severity note;
      else
        report "accumulator from channel " & to_string(i) & " was not frozen!"
        severity error;
      end if;
    end loop;
    -- ########## end of: performing an extra fofb processing cycle ##########

    -- clearing accumulators
    report "clearing accumulators"
    severity note;

    addr := c_WB_FOFB_PROCESSING_REGS_CH_0_ACC_CTL_ADDR;
    for i in 0 to (g_CHANNELS - 1)
    loop
      read32_pl(clk, wb_slave_i, wb_slave_o, addr, data);
      data(c_WB_FOFB_PROCESSING_REGS_CH_0_ACC_CTL_CLEAR_OFFSET) := '1';
      write32_pl(clk, wb_slave_i, wb_slave_o, addr, data);

      valid_to_check <= sp_valid_arr(i);
      -- wait until the new setpoint (hopefully 0) is ready
      f_wait_clocked_signal(clk, valid_to_check, '1', 100);

      if (to_integer(sp_arr(i)) = 0) then
        report "accumulator from channel " & to_string(i) & " was cleared!"
        severity note;
      else
        report "accumulator from channel " & to_string(i) & " was not cleared!" &
          " (sp = " & to_string(to_integer(sp_arr(i))) & ")"
        severity error;
      end if;

      -- checking if autoclear is working
      read32_pl(clk, wb_slave_i, wb_slave_o, addr, data);

      assert (data(c_WB_FOFB_PROCESSING_REGS_CH_0_ACC_CTL_CLEAR_OFFSET) = '0')
        report "autoclear not working at " & natural'image(addr)
        severity error;

      -- address should jump c_WB_FOFB_PROCESSING_REGS_CH_1_ACC_CTL_ADDR -
      -- c_WB_FOFB_PROCESSING_REGS_CH_0_ACC_CTL_ADDR on each iteration
      addr := addr + c_WB_FOFB_PROCESSING_REGS_CH_1_ACC_CTL_ADDR -
        c_WB_FOFB_PROCESSING_REGS_CH_0_ACC_CTL_ADDR;
    end loop;

    report "success!"
    severity note;

    finish;
  end process;

  -- components
  cmp_xwb_fofb_processing : xwb_fofb_processing
    generic map (
      g_COEFF_INT_WIDTH              => g_COEFF_INT_WIDTH,
      g_COEFF_FRAC_WIDTH             => g_COEFF_FRAC_WIDTH,
      g_BPM_POS_INT_WIDTH            => g_BPM_POS_INT_WIDTH,
      g_BPM_POS_FRAC_WIDTH           => g_BPM_POS_FRAC_WIDTH,
      g_DOT_PROD_ACC_EXTRA_WIDTH     => g_DOT_PROD_ACC_EXTRA_WIDTH,
      g_DOT_PROD_MUL_PIPELINE_STAGES => g_DOT_PROD_MUL_PIPELINE_STAGES,
      g_DOT_PROD_ACC_PIPELINE_STAGES => g_DOT_PROD_ACC_PIPELINE_STAGES,
      g_ACC_GAIN_MUL_PIPELINE_STAGES => g_ACC_GAIN_MUL_PIPELINE_STAGES,
      g_CHANNELS                     => g_CHANNELS,
      g_INTERFACE_MODE               => PIPELINED,
      g_ADDRESS_GRANULARITY          => BYTE,
      g_WITH_EXTRA_WB_REG            => false
    )
    port map (
      clk_i                          => clk,
      rst_n_i                        => rst_n,
      busy_o                         => busy,
      bpm_pos_i                      => bpm_pos,
      bpm_pos_index_i                => bpm_pos_index,
      bpm_pos_valid_i                => bpm_pos_valid,
      bpm_time_frame_end_i           => bpm_time_frame_end,
      sp_arr_o                       => sp_arr,
      sp_valid_arr_o                 => sp_valid_arr,
      sp_decim_arr_o                 => sp_decim_arr,
      sp_decim_valid_arr_o           => sp_decim_valid_arr,
      wb_slv_i                       => wb_slave_i,
      wb_slv_o                       => wb_slave_o
    );

end architecture xwb_fofb_processing_tb_arch;

--------------------------------------------------------------------------------
-- Title      : Wrapper for FOFB system identification cores testbench
--------------------------------------------------------------------------------
-- Author     : Guilherme Ricioli <guilherme.riciolic@gmail.com>
-- Company    : CNPEM, LNLS - GIE
-- Platform   : Simulation
-- Standard   : VHDL 2008
--------------------------------------------------------------------------------
-- Description: Tests the wishbone inteface and wrapped cores.
--------------------------------------------------------------------------------
-- Copyright (c) 2023 CNPEM
-- Licensed under GNU Lesser General Public License (LGPL) v3.0
--------------------------------------------------------------------------------
-- Revisions  :
-- Date         Version  Author              Description
-- 2023-04-05   1.0      guilherme.ricioli   Created
-- 2023-05-03   1.1      guilherme.ricioli   Test PRBS distortion machinery
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.env.finish;
use std.textio.all;

library work;
use work.wishbone_pkg.all;
use work.fofb_ctrl_pkg.all;
use work.dot_prod_pkg.all;
use work.fofb_sys_id_pkg.all;
use work.wb_fofb_sys_id_regs_consts_pkg.all;
use work.sim_wishbone.all;
use work.fofb_tb_pkg.all;

entity xwb_fofb_sys_id_tb is
end entity xwb_fofb_sys_id_tb;

architecture test of xwb_fofb_sys_id_tb is
  constant c_SYS_CLOCK_FREQ   : natural := 100_000_000;

  -- Maximum number of BPM positions to flatenize per flatenizer
  -- Each flatenizer holds at most half of c_MAX_NUM_P2P_BPM_POS.
  constant c_MAX_NUM_BPM_POS_PER_FLAT :
    natural range 1 to 2**(natural(c_SP_COEFF_RAM_ADDR_WIDTH)) :=
      c_MAX_NUM_P2P_BPM_POS/2;

  constant c_BPM_ID_BASE                    : natural := 20;

  constant c_MAX_CHANNELS       : natural := 12;
  constant c_CHANNELS           : natural := c_MAX_CHANNELS;

  constant c_PRBS_STEP_DURATION     : natural := 5;
  constant c_PRBS_CTL_STEP_DURATION :
    std_logic_vector((c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_LFSR_LENGTH_OFFSET-
      c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_STEP_DURATION_OFFSET)-1 downto 0) :=
        std_logic_vector(to_unsigned(c_PRBS_STEP_DURATION-1,
          c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_LFSR_LENGTH_OFFSET -
          c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_STEP_DURATION_OFFSET));

  constant c_PRBS_LFSR_LENGTH     : natural := 7;
  constant c_PRBS_CTL_LFSR_LENGTH :
    std_logic_vector((c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_BPM_POS_DISTORT_EN_OFFSET -
      c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_LFSR_LENGTH_OFFSET)-1 downto 0) :=
        std_logic_vector(to_unsigned(c_PRBS_LFSR_LENGTH-2,
          c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_BPM_POS_DISTORT_EN_OFFSET -
          c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_LFSR_LENGTH_OFFSET));

  signal clk                          : std_logic := '0';
  signal rst_n                        : std_logic := '0';
  signal bpm_pos                      : signed(c_BPM_POS_WIDTH-1 downto 0);
  signal bpm_pos_index                : unsigned(c_SP_COEFF_RAM_ADDR_WIDTH-1 downto 0) := (others => '0');
  signal bpm_pos_valid                : std_logic := '0';
  signal bpm_pos_flat_clear           : std_logic := '0';
  signal sp_arr                       : t_sp_arr(c_CHANNELS-1 downto 0);
  signal sp_valid_arr                 : std_logic_vector(c_CHANNELS-1 downto 0) := (others => '0');
  signal prbs_iterate                 : std_logic := '0';
  signal trig                         : std_logic := '0';
  signal bpm_pos_flat_x               : t_bpm_pos_arr(c_MAX_NUM_BPM_POS_PER_FLAT-1 downto 0);
  signal bpm_pos_flat_x_rcvd          : std_logic_vector(c_MAX_NUM_BPM_POS_PER_FLAT-1 downto 0);
  signal bpm_pos_flat_y               : t_bpm_pos_arr(c_MAX_NUM_BPM_POS_PER_FLAT-1 downto 0);
  signal bpm_pos_flat_y_rcvd          : std_logic_vector(c_MAX_NUM_BPM_POS_PER_FLAT-1 downto 0);
  signal distort_bpm_pos              : signed(c_BPM_POS_WIDTH-1 downto 0);
  signal distort_bpm_pos_index        : unsigned(c_SP_COEFF_RAM_ADDR_WIDTH-1 downto 0);
  signal distort_bpm_pos_valid        : std_logic;
  signal distort_sp_arr               : t_sp_arr(c_CHANNELS-1 downto 0);
  signal distort_sp_valid_arr         : std_logic_vector(c_CHANNELS-1 downto 0);
  signal prbs                         : std_logic;
  signal prbs_valid                   : std_logic;
  signal distort_bpm_pos_flat_x       : t_bpm_pos_arr(c_MAX_NUM_BPM_POS_PER_FLAT-1 downto 0);
  signal distort_bpm_pos_flat_x_rcvd  : std_logic_vector(c_MAX_NUM_BPM_POS_PER_FLAT-1 downto 0);
  signal distort_bpm_pos_flat_y       : t_bpm_pos_arr(c_MAX_NUM_BPM_POS_PER_FLAT-1 downto 0);
  signal distort_bpm_pos_flat_y_rcvd  : std_logic_vector(c_MAX_NUM_BPM_POS_PER_FLAT-1 downto 0);

  -- Wishbone signals
  signal wb_slave_i           : t_wishbone_slave_in;
  signal wb_slave_o           : t_wishbone_slave_out;

begin
  f_gen_clk(c_SYS_CLOCK_FREQ, clk);

  process
    variable data : std_logic_vector(31 downto 0) := (others => '0');
    variable data_rb : std_logic_vector(31 downto 0) := (others => '0');
  begin
    init(wb_slave_i);
    f_wait_cycles(clk, 10);

    rst_n <= '0';
    f_wait_cycles(clk, 1);
    rst_n <= '1';
    f_wait_cycles(clk, 10);

    -- ####################### FLATENIZERS CONFIGURATION #######################

    -- Sets base BPM id

    read32_pl(clk, wb_slave_i, wb_slave_o,
      c_WB_FOFB_SYS_ID_REGS_BPM_POS_FLATENIZER_MAX_NUM_CTE_ADDR, data);
    assert data = std_logic_vector(to_unsigned(c_MAX_NUM_BPM_POS_PER_FLAT, 32))
      report
        "Unexpected BPM_POS_FLATENIZER_MAX_NUM_CTE: " & to_hstring(data) &
        " (expected: " &
        to_hstring(std_logic_vector(to_unsigned(c_MAX_NUM_BPM_POS_PER_FLAT, 32))) & ")"
      severity error;

    data :=  std_logic_vector(to_unsigned(c_BPM_ID_BASE, data'length));
    write32_pl(clk, wb_slave_i, wb_slave_o,
      c_WB_FOFB_SYS_ID_REGS_BPM_POS_FLATENIZER_CTL_ADDR, data);

    read32_pl(clk, wb_slave_i, wb_slave_o,
      c_WB_FOFB_SYS_ID_REGS_BPM_POS_FLATENIZER_CTL_ADDR, data_rb);
    assert data = data_rb
      report "Unexpected BPM_POS_FLATENIZER_CTL_BASE_BPM_ID: " &
        to_hstring(data_rb) & " (expected: " &
        to_hstring(data) & ")"
      severity error;

    -- ########################## PRBS CONFIGURATION ##########################

    -- Configures PRBS_CTL_STEP_DURATION, PRBS_CTL_LFSR_LENGTH and resets PRBS

    read32_pl(clk, wb_slave_i, wb_slave_o, c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_ADDR,
      data);

    data(c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_LFSR_LENGTH_OFFSET-1 downto
      c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_STEP_DURATION_OFFSET) :=
        c_PRBS_CTL_STEP_DURATION;
    data(c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_BPM_POS_DISTORT_EN_OFFSET-1 downto
      c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_LFSR_LENGTH_OFFSET) :=
        c_PRBS_CTL_LFSR_LENGTH;
    write32_pl(clk, wb_slave_i, wb_slave_o, c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_ADDR,
      data);

    read32_pl(clk, wb_slave_i, wb_slave_o, c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_ADDR,
      data);
    assert data(c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_LFSR_LENGTH_OFFSET-1 downto
      c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_STEP_DURATION_OFFSET) =
        c_PRBS_CTL_STEP_DURATION
          report
            "Unexpected PRBS_CTL_STEP_DURATION: " &
            to_hstring(data(c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_LFSR_LENGTH_OFFSET-1
            downto c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_STEP_DURATION_OFFSET)) &
            " (expected: " & to_hstring(c_PRBS_CTL_STEP_DURATION) & ")"
          severity error;

    assert data(c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_BPM_POS_DISTORT_EN_OFFSET-1
      downto c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_LFSR_LENGTH_OFFSET) =
        c_PRBS_CTL_LFSR_LENGTH
          report
            "Unexpected PRBS_CTL_LFSR_LENGTH: " &
            to_hstring(data(
            c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_BPM_POS_DISTORT_EN_OFFSET-1
            downto c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_LFSR_LENGTH_OFFSET)) &
            " (expected: " & to_hstring(c_PRBS_CTL_LFSR_LENGTH) & ")"
          severity error;

    data(c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_RST_OFFSET) := '1';
    write32_pl(clk, wb_slave_i, wb_slave_o, c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_ADDR,
      data);

    read32_pl(clk, wb_slave_i, wb_slave_o, c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_ADDR,
      data);
    assert data(c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_RST_OFFSET) = '1'
      report "PRBS_CTL_RST is expected to be '1'"
      severity error;

    trig <= '1';
    f_wait_cycles(clk, 1);
    trig <= '0';
    f_wait_cycles(clk, 1);

    data(c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_RST_OFFSET) := '0';
    write32_pl(clk, wb_slave_i, wb_slave_o, c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_ADDR,
      data);

    read32_pl(clk, wb_slave_i, wb_slave_o, c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_ADDR,
      data);
    assert data(c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_RST_OFFSET) = '0'
      report "PRBS_CTL_RST is expected to be '0'"
      severity error;

    -- ############# BPM POSITIONS DISTORTION LEVELS CONFIGURATION #############

    -- Configures BPM positions distortion levels for each BPM id
    -- PRBS_BPM_POS_DISTORT_DISTORT_RAM_LEVELS_LEVEL_{0, 1}(id) = {id, -id}

    for id in 0 to (c_WB_FOFB_SYS_ID_REGS_PRBS_BPM_POS_DISTORT_SIZE/
      c_WB_FOFB_SYS_ID_REGS_PRBS_BPM_POS_DISTORT_DISTORT_RAM_SIZE - 1)
    loop
      data(c_WB_FOFB_SYS_ID_REGS_PRBS_BPM_POS_DISTORT_DISTORT_RAM_LEVELS_LEVEL_1_OFFSET-1
        downto c_WB_FOFB_SYS_ID_REGS_PRBS_BPM_POS_DISTORT_DISTORT_RAM_LEVELS_LEVEL_0_OFFSET) :=
          std_logic_vector(to_signed(id,
            c_WB_FOFB_SYS_ID_REGS_PRBS_BPM_POS_DISTORT_DISTORT_RAM_LEVELS_LEVEL_1_OFFSET -
            c_WB_FOFB_SYS_ID_REGS_PRBS_BPM_POS_DISTORT_DISTORT_RAM_LEVELS_LEVEL_0_OFFSET));
      data(31 downto
        c_WB_FOFB_SYS_ID_REGS_PRBS_BPM_POS_DISTORT_DISTORT_RAM_LEVELS_LEVEL_1_OFFSET) :=
          std_logic_vector(to_signed(-id, 32 -
            c_WB_FOFB_SYS_ID_REGS_PRBS_BPM_POS_DISTORT_DISTORT_RAM_LEVELS_LEVEL_1_OFFSET));
      write32_pl(clk, wb_slave_i, wb_slave_o,
        c_WB_FOFB_SYS_ID_REGS_PRBS_BPM_POS_DISTORT_DISTORT_RAM_ADDR +
        c_WB_FOFB_SYS_ID_REGS_PRBS_BPM_POS_DISTORT_DISTORT_RAM_SIZE*id, data);

      read32_pl(clk, wb_slave_i, wb_slave_o,
        c_WB_FOFB_SYS_ID_REGS_PRBS_BPM_POS_DISTORT_DISTORT_RAM_ADDR +
        c_WB_FOFB_SYS_ID_REGS_PRBS_BPM_POS_DISTORT_DISTORT_RAM_SIZE*id,
        data_rb);
      assert data = data_rb
        report
          "Unexpected PRBS_BPM_POS_DISTORT_DISTORT_RAM(" & natural'image(id) &
          "): " & to_hstring(data_rb) & " (expected: " & to_hstring(data) & ")"
        severity error;
    end loop;

    -- ############### SETPOINTS DISTORTION LEVELS CONFIGURATION ###############

    -- Configures setpoints distortion levels for each channel as
    -- PRBS_SP_DISTORT_CH_ch_LEVELS_LEVEL_{0, 1} = {ch, -ch}

    for ch in 0 to c_MAX_CHANNELS-1
    loop
      data(c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_0_LEVELS_LEVEL_1_OFFSET-1
        downto c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_0_LEVELS_LEVEL_0_OFFSET)
          :=  std_logic_vector(to_signed(ch,
                c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_0_LEVELS_LEVEL_1_OFFSET -
                c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_0_LEVELS_LEVEL_0_OFFSET));
      data(31 downto
        c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_0_LEVELS_LEVEL_1_OFFSET) :=
          std_logic_vector(to_signed(-ch, 32 -
            c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_0_LEVELS_LEVEL_1_OFFSET));
      write32_pl(clk, wb_slave_i, wb_slave_o,
        c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_ADDR +
        ch*c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_0_SIZE, data);

      read32_pl(clk, wb_slave_i, wb_slave_o,
        c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_ADDR +
        ch*c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_0_SIZE, data_rb);
      assert data = data_rb
        report
          "Unexpected PRBS_SP_DISTORT_CH_" & natural'image(ch) & "_LEVELS: " &
          to_hstring(data_rb) & " (expected: " & to_hstring(data) & ")"
        severity error;
    end loop;

    -- ################## BPM POSITIONS FLATENIZERS CHECKING ##################

    -- Checks if flatenizers are working

    for id in 0 to 2**c_SP_COEFF_RAM_ADDR_WIDTH-1
    loop
      bpm_pos <= to_signed(id, bpm_pos'length);
      bpm_pos_index <= to_unsigned(id, bpm_pos_index'length);

      bpm_pos_valid <= '1';
      f_wait_cycles(clk, 1);
      bpm_pos_valid <= '0';
      f_wait_cycles(clk, 10);
    end loop;

    for bpm_pos_flat_idx in 0 to c_MAX_NUM_BPM_POS_PER_FLAT-1
    loop
      assert bpm_pos_flat_x_rcvd(bpm_pos_flat_idx) = '1'
        report
          "bpm_pos_flat_x_rcvd(" & natural'image(bpm_pos_flat_idx) &
          ") is expected to be '1'"
        severity error;

      assert bpm_pos_flat_x(bpm_pos_flat_idx) =
        to_signed(c_BPM_ID_BASE + bpm_pos_flat_idx,
          bpm_pos_flat_x(bpm_pos_flat_idx)'length)
        report
          "Unexpected bpm_pos_flat_x(" & natural'image(bpm_pos_flat_idx) & "): "
          & to_hstring(bpm_pos_flat_x(bpm_pos_flat_idx)) & " (expected: " &
          to_hstring(to_signed(c_BPM_ID_BASE + bpm_pos_flat_idx,
          bpm_pos_flat_x(bpm_pos_flat_idx)'length)) & ")"
        severity error;

      assert bpm_pos_flat_y_rcvd(bpm_pos_flat_idx) = '1'
        report
          "bpm_pos_flat_y_rcvd(" & natural'image(bpm_pos_flat_idx) &
          ") is expected to be '1'"
        severity error;

      assert bpm_pos_flat_y(bpm_pos_flat_idx) =
        to_signed(c_BPM_ID_BASE + 256 + bpm_pos_flat_idx,
          bpm_pos_flat_y(bpm_pos_flat_idx)'length)
        report
          "Unexpected bpm_pos_flat_y(" & natural'image(bpm_pos_flat_idx) & "): "
          & to_hstring(bpm_pos_flat_y(bpm_pos_flat_idx)) & " (expected: " &
          to_hstring(to_signed(c_BPM_ID_BASE + 256 + bpm_pos_flat_idx,
          bpm_pos_flat_y(bpm_pos_flat_idx)'length)) & ")"
        severity error;
    end loop;

    bpm_pos_flat_clear <= '1';
    f_wait_cycles(clk, 1);
    bpm_pos_flat_clear <= '0';
    f_wait_cycles(clk, 1);

    for bpm_pos_flat_idx in 0 to c_MAX_NUM_BPM_POS_PER_FLAT-1
    loop
      assert bpm_pos_flat_x_rcvd(bpm_pos_flat_idx) = '0'
        report
          "Unexpected bpm_pos_flat_x_rcvd(" &
          natural'image(bpm_pos_flat_idx) & ") after clearing it"
        severity error;

      assert bpm_pos_flat_x(bpm_pos_flat_idx) =
        to_signed(0, bpm_pos_flat_x(bpm_pos_flat_idx)'length)
        report
          "Unexpected bpm_pos_flat_x(" & natural'image(bpm_pos_flat_idx) &
          ") after clearing it: " & to_hstring(bpm_pos_flat_x(bpm_pos_flat_idx))
        severity error;

      assert bpm_pos_flat_y_rcvd(bpm_pos_flat_idx) = '0'
        report
          "Unexpected bpm_pos_flat_y_rcvd(" &
          natural'image(bpm_pos_flat_idx) & ") after clearing it"
        severity error;

      assert bpm_pos_flat_y(bpm_pos_flat_idx) =
        to_signed(0, bpm_pos_flat_y(bpm_pos_flat_idx)'length)
        report
          "Unexpected bpm_pos_flat_y(" & natural'image(bpm_pos_flat_idx) &
          ") after clearing it: " & to_hstring(bpm_pos_flat_y(bpm_pos_flat_idx))
        severity error;
    end loop;

    -- ####################### BPM POSITIONS PASSTHROUGH #######################

    -- Disables BPM positions distortion and checks if passthrough is working

    read32_pl(clk, wb_slave_i, wb_slave_o, c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_ADDR,
      data);

    data(c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_BPM_POS_DISTORT_EN_OFFSET) := '0';
    write32_pl(clk, wb_slave_i, wb_slave_o, c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_ADDR,
      data);

    read32_pl(clk, wb_slave_i, wb_slave_o, c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_ADDR,
      data);
    assert data(c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_BPM_POS_DISTORT_EN_OFFSET) = '0'
      report
        "PRBS_CTL_BPM_POS_DISTORT_EN is expected to be '0'"
      severity error;

    trig <= '1';
    f_wait_cycles(clk, 1);
    trig <= '0';
    f_wait_cycles(clk, 1);

    for trial in 0 to 200
    loop
      prbs_iterate <= '1';
      f_wait_cycles(clk, 1);
      prbs_iterate <= '0';
      f_wait_clocked_signal(clk, prbs_valid, '1');

      for id in 0 to (c_WB_FOFB_SYS_ID_REGS_PRBS_BPM_POS_DISTORT_SIZE/
        c_WB_FOFB_SYS_ID_REGS_PRBS_BPM_POS_DISTORT_DISTORT_RAM_SIZE - 1)
      loop
        bpm_pos <= to_signed(((-1)**id)*id, bpm_pos'length);
        bpm_pos_index <= to_unsigned(id, bpm_pos_index'length);

        bpm_pos_valid <= '1';
        f_wait_cycles(clk, 1);
        bpm_pos_valid <= '0';
        f_wait_clocked_signal(clk, distort_bpm_pos_valid, '1');

        assert distort_bpm_pos = bpm_pos
          report
            "Unexpected distort_bpm_pos (id: " & natural'image(id) & "): " &
            to_hstring(distort_bpm_pos) & " (expected: " & to_hstring(bpm_pos) &
            ")"
          severity error;
      end loop;
    end loop;

    -- ################ PRBS-BASED DISTORTION ON BPM POSITIONS ################

    -- Enables PRBS-based distortion on BPM positions and checks if it is
    -- working

    read32_pl(clk, wb_slave_i, wb_slave_o, c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_ADDR,
      data);

    data(c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_BPM_POS_DISTORT_EN_OFFSET) := '1';
    write32_pl(clk, wb_slave_i, wb_slave_o, c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_ADDR,
      data);

    read32_pl(clk, wb_slave_i, wb_slave_o, c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_ADDR,
      data);
    assert data(c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_BPM_POS_DISTORT_EN_OFFSET) = '1'
      report
        "PRBS_CTL_BPM_POS_DISTORT_EN is expected to be '1'"
      severity error;

    trig <= '1';
    f_wait_cycles(clk, 1);
    trig <= '0';
    f_wait_cycles(clk, 1);

    for trial in 0 to 200
    loop
      prbs_iterate <= '1';
      f_wait_cycles(clk, 1);
      prbs_iterate <= '0';
      f_wait_clocked_signal(clk, prbs_valid, '1');

      for id in 0 to (c_WB_FOFB_SYS_ID_REGS_PRBS_BPM_POS_DISTORT_SIZE/
        c_WB_FOFB_SYS_ID_REGS_PRBS_BPM_POS_DISTORT_DISTORT_RAM_SIZE - 1)
      loop
        bpm_pos <= to_signed(((-1)**id)*id, bpm_pos'length);
        bpm_pos_index <= to_unsigned(id, bpm_pos_index'length);

        bpm_pos_valid <= '1';
        f_wait_cycles(clk, 1);
        bpm_pos_valid <= '0';
        f_wait_clocked_signal(clk, distort_bpm_pos_valid, '1');

        if prbs = '0' then
          assert distort_bpm_pos - bpm_pos =
            to_signed(id, distort_bpm_pos'length)
              report
                "Unexpected distort_bpm_pos (id: " & natural'image(id) & "): " &
                to_hstring(distort_bpm_pos) & " (expected: " &
                to_hstring(bpm_pos + to_signed(id, distort_bpm_pos'length)) &
                ")"
              severity error;
        else
          assert distort_bpm_pos - bpm_pos =
            to_signed(-id, distort_bpm_pos'length)
              report
                "Unexpected distort_bpm_pos (id: " & natural'image(id) & "): " &
                to_hstring(distort_bpm_pos) & " (expected: " &
                to_hstring(bpm_pos + to_signed(-id, distort_bpm_pos'length)) &
                ")"
              severity error;
        end if;
      end loop;
    end loop;

    read32_pl(clk, wb_slave_i, wb_slave_o, c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_ADDR,
      data);

    data(c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_BPM_POS_DISTORT_EN_OFFSET) := '0';
    write32_pl(clk, wb_slave_i, wb_slave_o, c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_ADDR,
      data);

    read32_pl(clk, wb_slave_i, wb_slave_o, c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_ADDR,
      data);
    assert data(c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_BPM_POS_DISTORT_EN_OFFSET) = '0'
      report
        "PRBS_CTL_BPM_POS_DISTORT_EN is expected to be '0'"
      severity error;

    trig <= '1';
    f_wait_cycles(clk, 1);
    trig <= '0';
    f_wait_cycles(clk, 1);

    -- ############# DISTORTED BPM POSITIONS FLATENIZERS CHECKING #############

    -- Checks if flatenizers are working
    -- TODO


    -- ######################### SETPOINTS PASSTHROUGH #########################

    -- Disables setpoints distortion and checks if passthrough is working

    read32_pl(clk, wb_slave_i, wb_slave_o, c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_ADDR,
      data);

    data(c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_SP_DISTORT_EN_OFFSET) := '0';
    write32_pl(clk, wb_slave_i, wb_slave_o, c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_ADDR,
      data);

    read32_pl(clk, wb_slave_i, wb_slave_o, c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_ADDR,
      data);
    assert data(c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_SP_DISTORT_EN_OFFSET) = '0'
      report
        "PRBS_CTL_SP_DISTORT_EN is expected to be '0'"
      severity error;

    trig <= '1';
    f_wait_cycles(clk, 1);
    trig <= '0';
    f_wait_cycles(clk, 1);

    for trial in 0 to 200
    loop
      prbs_iterate <= '1';
      f_wait_cycles(clk, 1);
      prbs_iterate <= '0';
      f_wait_clocked_signal(clk, prbs_valid, '1');

      for ch in 0 to c_CHANNELS-1
      loop
        sp_arr(ch) <= to_signed(((-1)**ch)*ch, sp_arr(ch)'length);
        sp_valid_arr(ch) <= '1';
      end loop;
      f_wait_cycles(clk, 1);

      for ch in 0 to c_CHANNELS-1
      loop
        sp_valid_arr(ch) <= '0';
      end loop;
      f_wait_cycles(clk, 1);

      f_wait_clocked_signal(clk, distort_sp_valid_arr(0), '1');
      for ch in 0 to c_CHANNELS-1
      loop
        assert sp_arr(ch) = distort_sp_arr(ch)
          report
            "Unexpected distort_sp_arr(" & natural'image(ch) & "): " &
            to_hstring(distort_sp_arr(ch)) & " (expected: " &
            to_hstring(sp_arr(ch)) & ")"
          severity error;
      end loop;
    end loop;

    -- ################## PRBS-BASED DISTORTION ON SETPOINTS ##################

    -- Enables PRBS-based distortion on setpoints and checks if it is working

    read32_pl(clk, wb_slave_i, wb_slave_o, c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_ADDR,
      data);

    data(c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_SP_DISTORT_EN_OFFSET) := '1';
    write32_pl(clk, wb_slave_i, wb_slave_o, c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_ADDR,
      data);

    read32_pl(clk, wb_slave_i, wb_slave_o, c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_ADDR,
      data);
    assert data(c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_SP_DISTORT_EN_OFFSET) = '1'
      report
        "PRBS_CTL_SP_DISTORT_EN is expected to be '1'"
      severity error;

    trig <= '1';
    f_wait_cycles(clk, 1);
    trig <= '0';
    f_wait_cycles(clk, 1);

    for trial in 0 to 200
    loop
      prbs_iterate <= '1';
      f_wait_cycles(clk, 1);
      prbs_iterate <= '0';
      f_wait_clocked_signal(clk, prbs_valid, '1');

      for ch in 0 to c_CHANNELS-1
      loop
        sp_arr(ch) <= to_signed(((-1)**ch)*ch, sp_arr(ch)'length);
        sp_valid_arr(ch) <= '1';
      end loop;
      f_wait_cycles(clk, 1);

      for ch in 0 to c_CHANNELS-1
      loop
        sp_valid_arr(ch) <= '0';
      end loop;
      f_wait_cycles(clk, 1);

      f_wait_clocked_signal(clk, distort_sp_valid_arr(0), '1');
      for ch in 0 to c_CHANNELS-1
      loop
        if prbs = '0' then
          assert distort_sp_arr(ch) - sp_arr(ch) =
            to_signed(ch, distort_sp_arr'length)
              report
                "Unexpected distort_sp_arr(" & natural'image(ch) & "): " &
                to_hstring(distort_sp_arr(ch)) & " (expected: " &
                to_hstring(sp_arr(ch) + to_signed(ch, distort_sp_arr'length)) &
                ")"
              severity error;
        else
          assert distort_sp_arr(ch) - sp_arr(ch) =
            to_signed(-ch, distort_sp_arr'length)
              report
                "Unexpected distort_sp_arr(" & natural'image(ch) & "): " &
                to_hstring(distort_sp_arr(ch)) & " (expected: " &
                to_hstring(sp_arr(ch) + to_signed(-ch, distort_sp_arr'length)) &
                ")"
              severity error;
        end if;
      end loop;
    end loop;

    read32_pl(clk, wb_slave_i, wb_slave_o, c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_ADDR,
      data);

    data(c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_SP_DISTORT_EN_OFFSET) := '0';
    write32_pl(clk, wb_slave_i, wb_slave_o, c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_ADDR,
      data);

    read32_pl(clk, wb_slave_i, wb_slave_o, c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_ADDR,
      data);
    assert data(c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_SP_DISTORT_EN_OFFSET) = '0'
      report
        "PRBS_CTL_SP_DISTORT_EN is expected to be '0'"
      severity error;

    trig <= '1';
    f_wait_cycles(clk, 1);
    trig <= '0';
    f_wait_cycles(clk, 1);

    report "success!"
    severity note;

    finish;
  end process;

  uut : xwb_fofb_sys_id
    generic map (
      g_BPM_POS_INDEX_WIDTH         => c_SP_COEFF_RAM_ADDR_WIDTH,
      g_MAX_NUM_BPM_POS_PER_FLAT    => c_MAX_NUM_BPM_POS_PER_FLAT,
      g_CHANNELS                    => c_CHANNELS,
      g_INTERFACE_MODE              => PIPELINED,
      g_ADDRESS_GRANULARITY         => BYTE,
      g_WITH_EXTRA_WB_REG           => false
    )
    port map (
      clk_i                         => clk,
      rst_n_i                       => rst_n,
      bpm_pos_i                     => bpm_pos,
      bpm_pos_index_i               => bpm_pos_index,
      bpm_pos_valid_i               => bpm_pos_valid,
      bpm_pos_flat_clear_i          => bpm_pos_flat_clear,
      sp_arr_i                      => sp_arr,
      sp_valid_arr_i                => sp_valid_arr,
      prbs_valid_i                  => prbs_iterate,
      trig_i                        => trig,
      bpm_pos_flat_x_o              => bpm_pos_flat_x,
      bpm_pos_flat_x_rcvd_o         => bpm_pos_flat_x_rcvd,
      bpm_pos_flat_y_o              => bpm_pos_flat_y,
      bpm_pos_flat_y_rcvd_o         => bpm_pos_flat_y_rcvd,
      distort_bpm_pos_o             => distort_bpm_pos,
      distort_bpm_pos_index_o       => distort_bpm_pos_index,
      distort_bpm_pos_valid_o       => distort_bpm_pos_valid,
      distort_sp_arr_o              => distort_sp_arr,
      distort_sp_valid_arr_o        => distort_sp_valid_arr,
      prbs_o                        => prbs,
      prbs_valid_o                  => prbs_valid,
      distort_bpm_pos_flat_x_o      => distort_bpm_pos_flat_x,
      distort_bpm_pos_flat_x_rcvd_o => distort_bpm_pos_flat_x_rcvd,
      distort_bpm_pos_flat_y_o      => distort_bpm_pos_flat_y,
      distort_bpm_pos_flat_y_rcvd_o => distort_bpm_pos_flat_y_rcvd,
      wb_slv_i                      => wb_slave_i,
      wb_slv_o                      => wb_slave_o
    );
end architecture test;

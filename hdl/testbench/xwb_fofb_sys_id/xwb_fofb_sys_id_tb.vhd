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

  -- Maximum number of BPM positions to flatenize
  -- Each bpm_pos_flatenizer holds half of c_MAX_NUM_P2P_BPM_POS.
  constant c_MAX_NUM_BPM_POS  :
    natural range 1 to 2**(natural(c_SP_COEFF_RAM_ADDR_WIDTH)) :=
      c_MAX_NUM_P2P_BPM_POS/2;

  -- DCC packet base BPM id
  constant c_BPM_ID_BASE                        : natural := 20;
  constant c_BPM_POS_FLATENIZER_BASE_BPM_ID :
    std_logic_vector(31 downto 0) :=
      std_logic_vector(to_unsigned(c_BPM_ID_BASE, 32));

  signal clk                  : std_logic := '0';
  signal rst_n                : std_logic := '0';
  signal bpm_pos              : signed(c_SP_POS_RAM_DATA_WIDTH-1 downto 0);
  signal bpm_pos_index        : unsigned(c_SP_COEFF_RAM_ADDR_WIDTH-1 downto 0);
  signal bpm_pos_valid        : std_logic := '0';
  signal bpm_pos_flat_clear   : std_logic := '0';
  signal bpm_pos_flat_x       : t_bpm_pos_arr(c_MAX_NUM_BPM_POS-1 downto 0);
  signal bpm_pos_flat_x_rcvd  : std_logic_vector(c_MAX_NUM_BPM_POS-1 downto 0);
  signal bpm_pos_flat_y       : t_bpm_pos_arr(c_MAX_NUM_BPM_POS-1 downto 0);
  signal bpm_pos_flat_y_rcvd  : std_logic_vector(c_MAX_NUM_BPM_POS-1 downto 0);

  -- Wishbone signals
  signal wb_slave_i           : t_wishbone_slave_in;
  signal wb_slave_o           : t_wishbone_slave_out;

begin
  f_gen_clk(c_SYS_CLOCK_FREQ, clk);

  process
    variable addr                         : natural := 0;
    variable offs                         : natural := 0;
    variable data                         : std_logic_vector(31 downto 0) :=
      (others => '0');
  begin
    init(wb_slave_i);
    f_wait_cycles(clk, 10);

    -- Resetting cores
    rst_n <= '0';
    f_wait_cycles(clk, 1);
    rst_n <= '1';
    f_wait_cycles(clk, 10);

    -- Reads back the maximum number of BPMs positions supported by flatenizers
    read32_pl(clk, wb_slave_i, wb_slave_o,
      c_WB_FOFB_SYS_ID_REGS_BPM_POS_FLATENIZER_MAX_NUM_CTE_ADDR, data);
    assert (to_integer(unsigned(data)) = c_MAX_NUM_BPM_POS)
      report
        "Unexpected maximum number of BPMs positions supported by flatenizers: "
        & natural'image(to_integer(unsigned(data))) & " (expected: " &
        natural'image(c_MAX_NUM_BPM_POS) & ")"
      severity error;

    -- Writes base BPM id
    write32_pl(clk, wb_slave_i, wb_slave_o,
      c_WB_FOFB_SYS_ID_REGS_BPM_POS_FLATENIZER_BASE_BPM_ID_ADDR,
      c_BPM_POS_FLATENIZER_BASE_BPM_ID);

    -- Reads back base BPM id
    read32_pl(clk, wb_slave_i, wb_slave_o,
      c_WB_FOFB_SYS_ID_REGS_BPM_POS_FLATENIZER_BASE_BPM_ID_ADDR, data);
    assert (data = c_BPM_POS_FLATENIZER_BASE_BPM_ID)
      report "Unexpected base BPM id: " & to_hstring(data) & " (expected: " &
        to_hstring(c_BPM_POS_FLATENIZER_BASE_BPM_ID) & ")"
      severity error;

    -- Drives BPM positions with the same value of their assigned IDs
    for bpm_pos_id in 0 to 2**(natural(c_SP_COEFF_RAM_ADDR_WIDTH))-1
    loop
      bpm_pos <= to_signed(bpm_pos_id, bpm_pos'length);
      bpm_pos_index <= to_unsigned(bpm_pos_id, bpm_pos_index'length);

      bpm_pos_valid <= '1';
      f_wait_cycles(clk, 1);
      bpm_pos_valid <= '0';
      f_wait_cycles(clk, 10);
    end loop;

    for bpm_pos_flat_idx in 0 to c_MAX_NUM_BPM_POS-1
    loop
      -- Asserts bpm_pos_flat_x_rcvd
      assert (bpm_pos_flat_x_rcvd(bpm_pos_flat_idx) = '1')
        report "Expected BPM position stored on bpm_pos_flat_x index " &
          natural'image(bpm_pos_flat_idx)
        severity error;

      -- Asserts bpm_pos_flat_x
      assert (to_integer(bpm_pos_flat_x(bpm_pos_flat_idx)) =
        c_BPM_ID_BASE + bpm_pos_flat_idx)
        report "Unexpected BPM position value on bpm_pos_flat_x: " &
          integer'image(to_integer(bpm_pos_flat_x(bpm_pos_flat_idx))) &
          " (expected: " &
          integer'image(c_BPM_ID_BASE + bpm_pos_flat_idx) & ")"
        severity error;

      -- Asserts bpm_pos_flat_y_rcvd
      assert (bpm_pos_flat_y_rcvd(bpm_pos_flat_idx) = '1')
        report "Expected BPM position stored on bpm_pos_flat_y index " &
          natural'image(bpm_pos_flat_idx)
        severity error;

      -- Asserts bpm_pos_flat_y
      assert (to_integer(bpm_pos_flat_y(bpm_pos_flat_idx)) =
        c_BPM_ID_BASE + 256 + bpm_pos_flat_idx)
        report "Unexpected BPM position value on bpm_pos_flat_y: " &
          integer'image(to_integer(bpm_pos_flat_y(bpm_pos_flat_idx))) &
          " (expected: " &
          integer'image(c_BPM_ID_BASE + 256 + bpm_pos_flat_idx) & ")"
        severity error;
    end loop;

    -- Clears flatenizers
    bpm_pos_flat_clear <= '1';
    f_wait_cycles(clk, 1);
    bpm_pos_flat_clear <= '0';
    f_wait_cycles(clk, 1);

    for bpm_pos_flat_idx in 0 to c_MAX_NUM_BPM_POS-1
    loop
      -- Asserts bpm_pos_flat_x_rcvd
      assert (bpm_pos_flat_x_rcvd(bpm_pos_flat_idx) = '0')
        report "Unexpected BPM position stored on bpm_pos_flat_x index " &
          natural'image(bpm_pos_flat_idx) & " after clearing it"
        severity error;

      -- Asserts bpm_pos_flat_x
      assert (to_integer(bpm_pos_flat_x(bpm_pos_flat_idx)) = 0)
        report "Unexpected BPM position value on bpm_pos_flat_x after " &
          "clearing it: " &
          integer'image(to_integer(bpm_pos_flat_x(bpm_pos_flat_idx)))
        severity error;

      -- Asserts bpm_pos_flat_y_rcvd
      assert (bpm_pos_flat_y_rcvd(bpm_pos_flat_idx) = '0')
        report "Unexpected BPM position stored on bpm_pos_flat_y index " &
          natural'image(bpm_pos_flat_idx) & " after clearing it"
        severity error;

      -- Asserts bpm_pos_flat_y
      assert (to_integer(bpm_pos_flat_y(bpm_pos_flat_idx)) = 0)
        report "Unexpected BPM position value on bpm_pos_flat_y after " &
          "clearing it: " &
          integer'image(to_integer(bpm_pos_flat_x(bpm_pos_flat_idx)))
        severity error;
    end loop;

    report "success!"
    severity note;

    finish;
  end process;

  uut : xwb_fofb_sys_id
    generic map (
      g_BPM_POS_INDEX_WIDTH => 9,
      g_BPM_POS_WIDTH       => c_BPM_POS_WIDTH,
      g_MAX_NUM_BPM_POS     => c_MAX_NUM_BPM_POS,
      g_INTERFACE_MODE      => PIPELINED,
      g_ADDRESS_GRANULARITY => BYTE,
      g_WITH_EXTRA_WB_REG   => false
    )
    port map (
      clk_i                 => clk,
      rst_n_i               => rst_n,
      bpm_pos_i             => bpm_pos,
      bpm_pos_index_i       => bpm_pos_index,
      bpm_pos_valid_i       => bpm_pos_valid,
      bpm_pos_flat_clear_i  => bpm_pos_flat_clear,
      bpm_pos_flat_x_o      => bpm_pos_flat_x,
      bpm_pos_flat_x_rcvd_o => bpm_pos_flat_x_rcvd,
      bpm_pos_flat_y_o      => bpm_pos_flat_y,
      bpm_pos_flat_y_rcvd_o => bpm_pos_flat_y_rcvd,
      wb_slv_i              => wb_slave_i,
      wb_slv_o              => wb_slave_o
    );
end architecture test;

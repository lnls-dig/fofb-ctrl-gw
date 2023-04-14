--------------------------------------------------------------------------------
-- Title      : PRBS-based distortion for BPM positions testbench
--------------------------------------------------------------------------------
-- Author     : Guilherme Ricioli <guilherme.riciolic@gmail.com>
-- Company    : CNPEM, LNLS - GIE
-- Platform   : Simulation
-- Standard   : VHDL 2008
--------------------------------------------------------------------------------
-- Description: Tests chaining prbs_gen_for_sys_id with prbs_bpm_pos_distort.
--------------------------------------------------------------------------------
-- Copyright (c) 2023 CNPEM
-- Licensed under GNU Lesser General Public License (LGPL) v3.0
--------------------------------------------------------------------------------
-- Revisions  :
-- Date         Version  Author              Description
-- 2023-04-14   1.0      guilherme.ricioli   Created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fofb_tb_pkg.all;
use work.ifc_common_pkg.all;
use work.fofb_sys_id_pkg.all;

entity prbs_bpm_pos_distort_tb is
end prbs_bpm_pos_distort_tb;

architecture test of prbs_bpm_pos_distort_tb is
  constant c_BPM_POS_INDEX_WIDTH      : natural := 9;
  constant c_BPM_POS_WIDTH            : natural := 32;
  constant c_DISTORT_LEVEL_WIDTH      : natural := 16;
  constant c_DISTORT_LEVEL_0          : signed(c_DISTORT_LEVEL_WIDTH-1 downto 0)
    := to_signed(100, c_DISTORT_LEVEL_WIDTH);
  constant c_DISTORT_LEVEL_1          : signed(c_DISTORT_LEVEL_WIDTH-1 downto 0)
    := to_signed(-200, c_DISTORT_LEVEL_WIDTH);

  signal clk                          : std_logic := '0';
  signal rst_n                        : std_logic := '0';
  signal prbs                         : std_logic := '0';
  signal prbs_gen_for_sys_id_valid_i  : std_logic := '0';
  signal prbs_gen_for_sys_id_valid_o  : std_logic := '0';
  signal bpm_pos                      : signed(c_BPM_POS_WIDTH-1 downto 0);
  signal bpm_pos_index                :
    unsigned(c_BPM_POS_INDEX_WIDTH-1 downto 0);
  signal bpm_pos_valid                : std_logic := '0';
  signal distort_bpm_pos              : signed(c_BPM_POS_WIDTH-1 downto 0);
  signal distort_bpm_pos_index        :
    unsigned(c_BPM_POS_INDEX_WIDTH-1 downto 0);
  signal distort_bpm_pos_valid        : std_logic := '0';
begin
  f_gen_clk(100_000_000, clk);

  process
    variable v_expec_distort_bpm_pos_aux :
      signed(maximum(c_BPM_POS_WIDTH, c_DISTORT_LEVEL_WIDTH) downto 0);
    variable v_expec_distort_bpm_pos : signed(c_BPM_POS_WIDTH-1 downto 0);
    variable v_expec_distort_bpm_pos_index :
      unsigned(c_BPM_POS_INDEX_WIDTH-1 downto 0);
  begin
    rst_n <= '0';
    f_wait_cycles(clk, 5);
    rst_n <= '1';
    f_wait_cycles(clk, 5);

    for id in 0 to 2**(c_BPM_POS_INDEX_WIDTH-1)-1
    loop
      -- Iterate PRBS
      prbs_gen_for_sys_id_valid_i <= '1';
      f_wait_cycles(clk, 1);
      prbs_gen_for_sys_id_valid_i <= '0';
      f_wait_clocked_signal(clk, prbs_gen_for_sys_id_valid_o, '1');

      -- Drive BPM position
      bpm_pos_index <= to_unsigned(id, bpm_pos_index'length);
      bpm_pos <= to_signed(id, bpm_pos'length);
      bpm_pos_valid <= '1';
      f_wait_cycles(clk, 1);
      bpm_pos_valid <= '0';
      f_wait_clocked_signal(clk, distort_bpm_pos_valid, '1');

      v_expec_distort_bpm_pos_aux :=
        to_signed(id, maximum(c_BPM_POS_WIDTH, c_DISTORT_LEVEL_WIDTH)+1);
      if prbs = '0' then
        v_expec_distort_bpm_pos_aux :=
          v_expec_distort_bpm_pos_aux + c_DISTORT_LEVEL_0;
      else  -- prbs = '1'
        v_expec_distort_bpm_pos_aux :=
          v_expec_distort_bpm_pos_aux + c_DISTORT_LEVEL_1;
      end if;

      v_expec_distort_bpm_pos :=
        f_signed_saturate(v_expec_distort_bpm_pos_aux, distort_bpm_pos'length);

      -- Checks distorted BPM position
      assert distort_bpm_pos = v_expec_distort_bpm_pos
        report
          "Wrong distorted BPM position: " &
          integer'image(to_integer(distort_bpm_pos)) & " (expected " &
          integer'image(to_integer(v_expec_distort_bpm_pos)) & ")"
        severity error;

      v_expec_distort_bpm_pos_index := to_unsigned(id,
        v_expec_distort_bpm_pos_index'length);

      -- Checks distorted BPM position index
      assert distort_bpm_pos_index = v_expec_distort_bpm_pos_index
        report
          "Wrong distorted BPM position index: " &
          integer'image(to_integer(distort_bpm_pos_index)) & " (expected " &
          integer'image(to_integer(v_expec_distort_bpm_pos_index)) & ")"
        severity error;
    end loop;

    std.env.finish;
  end process;

  cmp_prbs_gen_for_sys_id : prbs_gen_for_sys_id
    port map (
      clk_i           => clk,
      rst_n_i         => rst_n,
      en_i            => '1',
      step_duration_i => 1,
      lfsr_length_i   => 7,
      valid_i         => prbs_gen_for_sys_id_valid_i,
      busy_o          => open,
      prbs_o          => prbs,
      valid_o         => prbs_gen_for_sys_id_valid_o
    );

  uut : prbs_bpm_pos_distort
    generic map (
      g_BPM_POS_INDEX_WIDTH   => c_BPM_POS_INDEX_WIDTH,
      g_BPM_POS_WIDTH         => c_BPM_POS_WIDTH,
      g_DISTORT_LEVEL_WIDTH   => c_DISTORT_LEVEL_WIDTH
    )
    port map (
      clk_i                   => clk,
      rst_n_i                 => rst_n,
      bpm_pos_index_i         => bpm_pos_index,
      bpm_pos_i               => bpm_pos,
      bpm_pos_valid_i         => bpm_pos_valid,
      prbs_i                  => prbs,
      distort_level_0_i       => c_DISTORT_LEVEL_0,
      distort_level_1_i       => c_DISTORT_LEVEL_1,
      distort_bpm_pos_index_o => distort_bpm_pos_index,
      distort_bpm_pos_o       => distort_bpm_pos,
      distort_bpm_pos_valid_o => distort_bpm_pos_valid
    );

end architecture test;

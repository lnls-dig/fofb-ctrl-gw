--------------------------------------------------------------------------------
-- Title      : PRBS-based distortion for FOFB processing sepoints testbench
--------------------------------------------------------------------------------
-- Author     : Guilherme Ricioli <guilherme.riciolic@gmail.com>
-- Company    : CNPEM, LNLS - GIE
-- Platform   : Simulation
-- Standard   : VHDL 2008
--------------------------------------------------------------------------------
-- Description: Tests prbs_gen_for_sys_id.
--------------------------------------------------------------------------------
-- Copyright (c) 2023 CNPEM
-- Licensed under GNU Lesser General Public License (LGPL) v3.0
--------------------------------------------------------------------------------
-- Revisions  :
-- Date         Version  Author              Description
-- 2023-04-17   1.0      guilherme.ricioli   Created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fofb_tb_pkg.all;
use work.fofb_sys_id_pkg.all;

entity prbs_sp_distort_tb is
end prbs_sp_distort_tb;

architecture test of prbs_sp_distort_tb is
  constant c_SP_WIDTH                 : natural := 15;
  constant c_DISTORT_LEVEL_WIDTH      : natural := 16;
  constant c_DISTORT_LEVEL_0          : signed(c_DISTORT_LEVEL_WIDTH-1 downto 0)
    := to_signed(100, c_DISTORT_LEVEL_WIDTH);
  constant c_DISTORT_LEVEL_1          : signed(c_DISTORT_LEVEL_WIDTH-1 downto 0)
    := to_signed(-200, c_DISTORT_LEVEL_WIDTH);

  signal clk                          : std_logic := '0';
  signal rst_n                        : std_logic := '0';
  signal en_distort                   : std_logic := '1';
  signal prbs_rst_n                   : std_logic := '1';
  signal prbs_step_duration           : natural range 1 to 1024 := 1;
  signal prbs_lfsr_length             : natural range 2 to 32 := 32;
  signal prbs_valid                   : std_logic;
  signal sp                           : signed(c_SP_WIDTH-1 downto 0);
  signal sp_valid                     : std_logic := '0';
  signal distort_sp                   : signed(c_SP_WIDTH-1 downto 0);
  signal distort_sp_valid             : std_logic := '0';
  signal prbs                         : std_logic := '0';
begin
  f_gen_clk(100_000_000, clk);

  process
    variable v_expec_distort_sp_aux :
      signed(maximum(c_SP_WIDTH, c_DISTORT_LEVEL_WIDTH) downto 0);
    variable v_expec_distort_sp : signed(c_SP_WIDTH-1 downto 0);
  begin
    prbs_step_duration <= 2;
    prbs_lfsr_length <= 7;

    rst_n <= '0';
    f_wait_cycles(clk, 5);
    rst_n <= '1';
    f_wait_cycles(clk, 5);

    en_distort <= '1';
    f_wait_cycles(clk, 5);

    -- PRBS-based distortion enabled
    for sp_val in -(2**(c_SP_WIDTH-1)) to 2**(c_SP_WIDTH-1)-1
    loop
      -- Iterate PRBS
      prbs_valid <= '1';
      f_wait_cycles(clk, 1);
      prbs_valid <= '0';
      f_wait_cycles(clk, 1);

      -- Drive setpoint
      sp <= to_signed(sp_val, sp'length);
      sp_valid <= '1';
      f_wait_cycles(clk, 1);
      sp_valid <= '0';
      f_wait_clocked_signal(clk, distort_sp_valid, '1');

      v_expec_distort_sp_aux :=
        to_signed(sp_val, maximum(c_SP_WIDTH, c_DISTORT_LEVEL_WIDTH)+1);
      if prbs = '0' then
        v_expec_distort_sp_aux :=
          v_expec_distort_sp_aux + c_DISTORT_LEVEL_0;
      else  -- prbs = '1'
        v_expec_distort_sp_aux :=
          v_expec_distort_sp_aux + c_DISTORT_LEVEL_1;
      end if;

      v_expec_distort_sp :=
        f_signed_saturate(v_expec_distort_sp_aux, distort_sp'length);

      -- Checks distorted sepoints
      assert distort_sp = v_expec_distort_sp
        report
          "Wrong distorted sepoints: " &
          integer'image(to_integer(distort_sp)) & " (expected " &
          integer'image(to_integer(v_expec_distort_sp)) & ")"
        severity error;
    end loop;

    en_distort <= '0';
    f_wait_cycles(clk, 5);

    -- PRBS-based distortion disabled
    for sp_val in -(2**(c_SP_WIDTH-1)) to 2**(c_SP_WIDTH-1)-1
    loop
      -- Drive setpoint
      sp <= to_signed(sp_val, sp'length);
      sp_valid <= '1';
      f_wait_cycles(clk, 1);
      sp_valid <= '0';
      f_wait_clocked_signal(clk, distort_sp_valid, '1');

      v_expec_distort_sp := to_signed(sp_val, distort_sp'length);

      -- Checks sepoints
      assert distort_sp = v_expec_distort_sp
        report
          "Wrong sepoints: " &
          integer'image(to_integer(distort_sp)) & " (expected " &
          integer'image(to_integer(v_expec_distort_sp)) & ")"
        severity error;
    end loop;

    std.env.finish;
  end process;

  uut : prbs_sp_distort
    generic map (
      g_SP_WIDTH            => c_SP_WIDTH,
      g_DISTORT_LEVEL_WIDTH => c_DISTORT_LEVEL_WIDTH
    )
    port map (
      clk_i                 => clk,
      rst_n_i               => rst_n,
      en_distort_i          => en_distort,
      prbs_rst_n_i          => prbs_rst_n,
      prbs_step_duration_i  => prbs_step_duration,
      prbs_lfsr_length_i    => prbs_lfsr_length,
      prbs_valid_i          => prbs_valid,
      sp_i                  => sp,
      sp_valid_i            => sp_valid,
      distort_level_0_i     => c_DISTORT_LEVEL_0,
      distort_level_1_i     => c_DISTORT_LEVEL_1,
      distort_sp_o          => distort_sp,
      distort_sp_valid_o    => distort_sp_valid,
      prbs_o                => prbs
    );

end architecture test;

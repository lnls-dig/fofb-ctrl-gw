-------------------------------------------------------------------------------
-- Title      : Dot Product testbench
-------------------------------------------------------------------------------
-- Author     : Augusto Fraga Giachero
-- Company    : CNPEM LNLS-GCA
-- Platform   : Simulation
-- Standard   : VHDL 2008
-------------------------------------------------------------------------------
-- Description: Dot Product testbench
-------------------------------------------------------------------------------
-- Copyright (c) 2022 CNPEM
-- Licensed under GNU Lesser General Public License (LGPL) v3.0
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                Description
-- 2022-08-23  1.0      augusto.fraga         Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.fixed_pkg.all;
use ieee.math_real.all;

library work;
use work.dot_prod_pkg.all;

entity dot_prod_tb is
  generic (
    g_A_INT_WIDTH : natural := 0;
    g_A_FRAC_WIDTH : natural := 17;
    g_B_INT_WIDTH : natural := 20;
    g_B_FRAC_WIDTH : natural := 0;
    g_ACC_EXTRA_WIDTH : natural := 4
    );
end dot_prod_tb;

architecture rtl of dot_prod_tb is
  procedure f_gen_clk(constant freq : in    natural;
                      signal   clk  : inout std_logic) is
  begin
    loop
      wait for (0.5 / real(freq)) * 1 sec;
      clk <= not clk;
    end loop;
  end procedure f_gen_clk;

  procedure f_wait_cycles(signal   clk    : in std_logic;
                          constant cycles : natural) is
  begin
    for i in 1 to cycles loop
      wait until rising_edge(clk);
    end loop;
  end procedure f_wait_cycles;

  procedure f_dot_prod_push_data(signal clk : in std_logic;
                                 a_i : in real;
                                 b_i : in real;
                                 signal a_o : out sfixed(g_A_INT_WIDTH downto -g_A_FRAC_WIDTH);
                                 signal b_o : out sfixed(g_B_INT_WIDTH downto -g_B_FRAC_WIDTH);
                                 signal valid_o : out std_logic) is
  begin
    a_o <= to_sfixed(a_i, g_A_INT_WIDTH, -g_A_FRAC_WIDTH);
    b_o <= to_sfixed(b_i, g_B_INT_WIDTH, -g_B_FRAC_WIDTH);
    valid_o <= '1';
    wait until rising_edge(clk);
    valid_o <= '0';
  end procedure f_dot_prod_push_data;

  signal clk : std_logic := '0';
  signal rst_n : std_logic := '0';
  signal clear_acc : std_logic := '0';
  signal valid : std_logic := '0';
  signal idle : std_logic;
  signal a : sfixed(g_A_INT_WIDTH downto -g_A_FRAC_WIDTH);
  signal b : sfixed(g_B_INT_WIDTH downto -g_B_FRAC_WIDTH);
  signal res : sfixed(g_ACC_EXTRA_WIDTH + g_A_INT_WIDTH + g_B_INT_WIDTH + 1
                     downto
                     -(g_A_FRAC_WIDTH + g_B_FRAC_WIDTH));
  signal acc_compare: real := 0.0;
begin
  cmp_dot_prod: dot_prod
    generic map (
      g_A_INT_WIDTH => g_A_INT_WIDTH,
      g_A_FRAC_WIDTH => g_A_FRAC_WIDTH,
      g_B_INT_WIDTH => g_B_INT_WIDTH,
      g_B_FRAC_WIDTH => g_B_FRAC_WIDTH,
      g_ACC_EXTRA_WIDTH => g_ACC_EXTRA_WIDTH,
      g_MULT_PIPELINE_STAGES => 1,
      g_ACC_PIPELINE_STAGES => 1
      )
    port map (
      clk_i => clk,
      rst_n_i => rst_n,
      clear_acc_i => clear_acc,
      valid_i => valid,
      a_i => a,
      b_i => b,
      idle_o => idle,
      result_o => res
      );

  -- Generate 100 MHz clock sinal
  f_gen_clk(100_000_000, clk);

  process
    variable s1 : integer := 742030307;
    variable s2 : integer := 656422083;
    variable rand_num : real;
    variable rand_a : real;
    variable rand_b : real;
    variable acc_err : real;
  begin
    -- Reset dot_prod
    a <= (others => '0');
    b <= (others => '0');
    rst_n <= '0';
    f_wait_cycles(clk, 2);
    rst_n <= '1';
    f_wait_cycles(clk, 1);

    -- Process 320 random samples
    for i in 0 to 319 loop
      uniform(s1, s2, rand_num);
      rand_a := (rand_num - 0.5);
      uniform(s1, s2, rand_num);
      rand_b := (rand_num - 0.5) * 200000.0;
      f_dot_prod_push_data(clk, rand_a, rand_b, a, b, valid);
      acc_compare <= (rand_a * rand_b) + acc_compare;
    end loop;

    -- Wait until the dot_prod core has finished all operations
    wait until idle = '1';
    f_wait_cycles(clk, 1);

    acc_err := abs((to_real(res) / acc_compare) - 1.0);

    report "Dot product result: " & to_string(to_real(res)) severity note;
    report "ACC compare result: " & to_string(acc_compare) severity note;

    if acc_err > 0.005 then
      report "ACC comparision error: " & to_string(acc_err) & " Too large!" severity error;
    else
      report "ACC comparision error: " & to_string(acc_err) & " OK!" severity note;
    end if;

    -- Clear the accumulator
    clear_acc <= '1';
    f_wait_cycles(clk, 1);
    clear_acc <= '0';
    f_wait_cycles(clk, 2);

    if to_real(res) = 0.0 then
      report "ACC clear ok!" severity note;
    else
      report "ACC clear error: result_o = " & to_string(to_real(res)) severity error;
    end if;

    std.env.finish;
  end process;
end architecture rtl;

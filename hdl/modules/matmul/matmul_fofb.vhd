-------------------------------------------------------------------------------
-- Title      :  Matrix multiplication module
-------------------------------------------------------------------------------
-- Author     :  Melissa Aguiar
-- Company    :  CNPEM LNLS-DIG
-- Platform   :  FPGA-generic
-------------------------------------------------------------------------------
-- Description:  Matrix multiplication module for the Fast Orbit Feedback
-------------------------------------------------------------------------------
-- Copyright (c) 2020 CNPEM
-- Licensed under GNU Lesser General Public License (LGPL) v3.0
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                Description
-- 2021-07-30  1.0      melissa.aguiar        Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

library work;
-- Matmul package
use work.mult_pkg.all;

entity matmul_fofb is
  generic(
    -- Width for inputs x and y
    g_a_width                             : natural := 32;
    -- Width for ram input
    g_b_width                             : natural := 32;
    -- Width for output c
    g_c_width                             : natural := 32
  );
  port (
    -- Core clock
    clk_i                                 : in std_logic;

    -- Reset
    rst_n_i                               : in std_logic;

    -- Clear
    clear_i                               : in std_logic;

    -- DCC interface
    dcc_valid_i                           : in std_logic;
    dcc_coeff_x_i                         : in signed(g_a_width-1 downto 0);
    dcc_coeff_y_i                         : in signed(g_a_width-1 downto 0);

    -- RAM interface
    ram_coeff_x_i                         : in std_logic_vector(g_b_width-1 downto 0);
    ram_coeff_y_i                         : in std_logic_vector(g_b_width-1 downto 0);

    -- Result output
    result_x_o                            : out signed(g_c_width-1 downto 0);
    result_y_o                            : out signed(g_c_width-1 downto 0);

    -- Data valid output
    result_valid_x_o                      : out std_logic;
    result_valid_y_o                      : out std_logic
  );
  end matmul_fofb;

architecture behave of matmul_fofb is

  signal valid_x_o_s, valid_y_o_s         : std_logic                     := '0';
  signal valid_i_s                        : std_logic                     := '0';
  signal clear_s                          : std_logic                     := '0';
  signal x_s, y_s                         : signed(g_a_width-1 downto 0)  := (others => '0');

begin

  matmul_X_INST : matmul
    port map (
      clk_i                               => clk_i,
      rst_n_i                             => rst_n_i,
      clear_acc_i                         => clear_s,
      valid_i                             => valid_i_s,
      a_i                                 => x_s,
      b_i                                 => signed(ram_coeff_x_i),
      c_o                                 => result_x_o,
      c_valid_o                           => result_valid_x_o
    );

  matmul_Y_INST : matmul
    port map (
      clk_i                               => clk_i,
      rst_n_i                             => rst_n_i,
      clear_acc_i                         => clear_s,
      valid_i                             => valid_i_s,
      a_i                                 => y_s,
      b_i                                 => signed(ram_coeff_y_i),
      c_o                                 => result_y_o,
      c_valid_o                           => result_valid_y_o
    );

  matmul_fofb_TOP : process(clk_i)
  begin
    if (rising_edge(clk_i)) then
      if rst_n_i = '0' then
        x_s                               <= (others => '0');
        y_s                               <= (others => '0');

      else
        clear_s                           <= clear_i;
        x_s                               <= dcc_coeff_x_i;
        y_s                               <= dcc_coeff_y_i;
        valid_i_s                         <= dcc_valid_i;
      end if; -- Reset
    end if; -- Clock
  end process matmul_fofb_TOP;
end architecture behave;

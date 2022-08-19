-------------------------------------------------------------------------------
-- Title      :  Dot product with RAM coefficients
-------------------------------------------------------------------------------
-- Author     :  Melissa Aguiar
-- Company    :  CNPEM LNLS-DIG
-- Platform   :  FPGA-generic
-------------------------------------------------------------------------------
-- Description:  Dot product with RAM coefficients for the Fast Orbit Feedback
-------------------------------------------------------------------------------
-- Copyright (c) 2020 CNPEM
-- Licensed under GNU Lesser General Public License (LGPL) v3.0
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                Description
-- 2021-08-26  1.0      melissa.aguiar        Created
-- 2022-07-27  1.1      guilherme.ricioli     Changed coeffs RAMs' wb interface
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

library work;
-- Dot product package
use work.dot_prod_pkg.all;

entity dot_prod_coeff_vec is
  generic(
    -- Width for DCC input
    g_A_WIDTH                      : natural := 32;

    -- Width for DCC addr
    g_ID_WIDTH                     : natural := 9;

    -- Width for RAM coeff
    g_B_WIDTH                      : natural;

    -- Width for RAM addr
    g_K_WIDTH                      : natural;

    -- Width for output
    g_C_WIDTH                      : natural := 16;

    -- Fixed point representation for output
    g_OUT_FIXED                    : natural := 26;

    -- Extra bits for accumulator
    g_EXTRA_WIDTH                  : natural := 4
  );
  port(
    -- Core clock
    clk_i                          : in std_logic;

    -- Reset
    rst_n_i                        : in std_logic;

    -- DCC interface
    dcc_valid_i                    : in std_logic;
    dcc_data_i                     : in signed(g_A_WIDTH-1 downto 0);
    dcc_addr_i                     : in std_logic_vector(g_ID_WIDTH-1 downto 0);
    dcc_time_frame_start_i         : in std_logic;
    dcc_time_frame_end_i           : in std_logic;

    -- RAM interface
    coeff_ram_addr_o               : out std_logic_vector(g_K_WIDTH-1 downto 0);
    coeff_ram_data_i               : in std_logic_vector(g_B_WIDTH-1 downto 0);

    -- Result output array
    sp_o                           : out signed(g_C_WIDTH-1 downto 0);
    sp_debug_o                     : out signed(g_C_WIDTH-1 downto 0);

    -- Valid output
    sp_valid_o                     : out std_logic;
    sp_valid_debug_o               : out std_logic
  );
  end dot_prod_coeff_vec;

architecture behave of dot_prod_coeff_vec is

  signal dcc_data_s                : signed(g_A_WIDTH-1 downto 0)               := (others => '0');
  signal dcc_data_reg_s            : signed(g_A_WIDTH-1 downto 0)               := (others => '0');
  signal dcc_addr_reg_s            : std_logic_vector(g_ID_WIDTH-1 downto 0)    := (others => '0');
  signal valid_i_s, valid_reg_s    : std_logic := '0';

begin

  coeff_ram_addr_o                 <= dcc_addr_reg_s(g_K_WIDTH-1 downto 0);

  dot_product_process : process(clk_i)
  begin
    if (rising_edge(clk_i)) then
      if rst_n_i = '0' then
        dcc_data_reg_s             <= (others => '0');
        dcc_data_s                 <= (others => '0');
        dcc_addr_reg_s             <= (others => '0');
        valid_reg_s                <= '0';
        valid_i_s                  <= '0';
      end if;
      -- Coeffs from DCC delayed to align with coeffs from DPRAM
      dcc_data_reg_s               <= dcc_data_i;
      dcc_data_s                   <= dcc_data_reg_s;

      dcc_addr_reg_s(g_ID_WIDTH-1 downto 0)
                                   <= dcc_addr_i;

      -- Valid bit delayed to align with coeffs from DPRAM
      valid_reg_s                  <= dcc_valid_i;
      valid_i_s                    <= valid_reg_s;
    end if;

  end process dot_product_process;

  dot_prod_interface : dot_prod
    generic map
    (
      -- Width for input a[k]
      g_A_WIDTH                    => g_A_WIDTH,
      -- Width for input b[k]
      g_B_WIDTH                    => g_B_WIDTH,
      -- Width for output
      g_C_WIDTH                    => g_C_WIDTH,
      -- Fixed point representation for output
      g_OUT_FIXED                  => g_OUT_FIXED,
      -- Extra bits for accumulator
      g_EXTRA_WIDTH                => g_EXTRA_WIDTH
    )
    port map
    (
      clk_i                        => clk_i,
      rst_n_i                      => rst_n_i,
      clear_acc_i                  => dcc_time_frame_start_i,
      valid_i                      => valid_i_s,
      time_frame_end_i             => dcc_time_frame_end_i,
      a_i                          => dcc_data_s,
      b_i                          => signed(coeff_ram_data_i),
      result_o                     => sp_o,
      result_debug_o               => sp_debug_o,
      result_valid_end_o           => sp_valid_o,
      result_valid_debug_o         => sp_valid_debug_o
    );

end architecture behave;

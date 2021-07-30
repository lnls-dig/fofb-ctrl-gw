-------------------------------------------------------------------------------
-- Title      :  Matrix multiplication interface
-------------------------------------------------------------------------------
-- Author     :  Melissa Aguiar
-- Company    :  CNPEM LNLS-DIG
-- Platform   :  FPGA-generic
-------------------------------------------------------------------------------
-- Description:  Matrix multiplication top level for the Fast Orbit Feedback
-------------------------------------------------------------------------------
-- Copyright (c) 2020 CNPEM
-- Licensed under GNU Lesser General Public License (LGPL) v3.0
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                Description
-- 2021-30-07  1.0      melissa.aguiar        Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

library std;
use std.textio.all;

library work;
use work.mult_pkg.all;
use work.genram_pkg.all;
use work.memory_loader_pkg.all;

entity fofb_matmul_top is
  generic(
    -- Standard parameters of generic_dpram
    g_data_width                 : natural := 32;
    g_size                       : natural := 16384;
    g_with_byte_enable           : boolean := false;
    g_addr_conflict_resolution   : string  := "read_first";
    g_init_file                  : string  := "../../testbench/matmul/coeff_bin.ram";
    g_dual_clock                 : boolean := true;
    g_fail_if_file_not_found     : boolean := true;

    -- Width for inputs x and y
    g_a_width                    : natural := 32;
    -- Width for ram addr
    g_k_width                    : natural := 9;
    -- Width for output c
    g_c_width                    : natural := 32;
    -- Matrix multiplication size
    g_mat_size                   : natural := 4
  );
  port (
    -- Core clock
    clk_i                        : in std_logic;

    -- Reset
    rst_n_i                      : in std_logic;

    -- Data valid input
    valid_i                      : in std_logic;

    -- Input x, y and addr from DCC
    coeff_x_dcc_i                : in signed(g_a_width-1 downto 0);
    coeff_y_dcc_i                : in signed(g_a_width-1 downto 0);
    coeff_dcc_addr_i             : in std_logic_vector(g_k_width-1 downto 0);

    -- Input RAM data
    coeff_ram_dat_x_i            : in signed(g_data_width-1 downto 0);
    coeff_ram_dat_y_i            : in signed(g_data_width-1 downto 0);

    -- Result output array
    c_x_o                        : out t_array;
    c_y_o                        : out t_array;

    -- Valid output for debugging
    valid_debug_o                : out std_logic_vector(g_mat_size-1 downto 0);

    -- Valid end of fofb cycle
    valid_end_o                  : out std_logic_vector(g_mat_size-1 downto 0)
  );
end fofb_matmul_top;

architecture behave of fofb_matmul_top is

  signal coeff_x_dcc_s           : signed(g_a_width-1 downto 0);
  signal coeff_y_dcc_s           : signed(g_a_width-1 downto 0);
  signal coeff_x_reg_s           : signed(g_a_width-1 downto 0);
  signal coeff_y_reg_s           : signed(g_a_width-1 downto 0);
  signal v_i_s, v_reg_s          : std_logic := '0';

  -- DPRAM-X port A (write)
  signal wea_x_s                 : std_logic := '0';
  signal aa_x_s                  : std_logic_vector(f_log2_size(g_size)-1 downto 0) := (others => '0');
  signal qa_x_s                  : std_logic_vector(g_data_width-1 downto 0)        := (others => '0');

  -- DPRAM-X port B (read)
  signal web_x_s                 : std_logic := '0';
  signal ab_x_s                  : std_logic_vector(f_log2_size(g_size)-1 downto 0) := (others => '0');
  signal db_x_s                  : std_logic_vector(g_data_width-1 downto 0)        := (others => '0');
  signal coeff_ram_dat_x_s       : std_logic_vector(g_data_width-1 downto 0)        := (others => '0');

  -- DPRAM-Y port A (write)
  signal wea_y_s                 : std_logic := '0';
  signal aa_y_s                  : std_logic_vector(f_log2_size(g_size)-1 downto 0) := (others => '0');
  signal qa_y_s                  : std_logic_vector(g_data_width-1 downto 0)        := (others => '0');

  -- DPRAM-Y port B (read)
  signal web_y_s                 : std_logic := '0';
  signal ab_y_s                  : std_logic_vector(f_log2_size(g_size)-1 downto 0) := (others => '0');
  signal db_y_s                  : std_logic_vector(g_data_width-1 downto 0)        := (others => '0');
  signal coeff_ram_dat_y_s       : std_logic_vector(g_data_width-1 downto 0)        := (others => '0');

begin

  matmul_top : process(clk_i)
  begin
    if (rising_edge(clk_i)) then
      -- Coeffs from DCC delayed to align with Coeffs from DPRAM
      coeff_x_reg_s <= coeff_x_dcc_i;
      coeff_x_dcc_s <= coeff_x_reg_s;
      coeff_y_reg_s <= coeff_y_dcc_i;
      coeff_y_dcc_s <= coeff_y_reg_s;

      -- Valid bit delayed to align with Coeffs from DPRAM
      v_reg_s       <= valid_i;
      v_i_s         <= v_reg_s;
    end if;
  end process;

  gen_matrix_multiplication : for i in 0 to g_mat_size-1 generate

    cmp_ram_interface_X : generic_dpram
      generic map (
        g_data_width               => g_data_width,
        g_size                     => g_size,
        g_with_byte_enable         => g_with_byte_enable,
        g_addr_conflict_resolution => g_addr_conflict_resolution,
        g_init_file                => g_init_file,
        g_dual_clock               => g_dual_clock,
        g_fail_if_file_not_found   => g_fail_if_file_not_found
      )
      port map(
        -- Synchronous reset
        rst_n_i                    => rst_n_i,

        -- Port A (write)
        clka_i                     => clk_i,
        bwea_i                     => (others => '1'),
        wea_i                      => wea_x_s,
        aa_i                       => coeff_dcc_addr_i,
        da_i                       => std_logic_vector(coeff_ram_dat_x_i),
        qa_o                       => qa_x_s,

        -- Port B (read)
        clkb_i                     => clk_i,
        bweb_i                     => (others => '1'),
        web_i                      => web_y_s,
        ab_i                       => coeff_dcc_addr_i,
        db_i                       => db_x_s,
        qb_o                       => coeff_ram_dat_x_s
      );

    matrix_multiplication_INST_X : mac_fofb
      port map (
        clk_i                      => clk_i,
        rst_n_i                    => rst_n_i,
        valid_i                    => v_i_s,
        coeff_a_dat_i              => coeff_x_dcc_s,
        coeff_b_dat_i              => signed(coeff_ram_dat_x_s),
        c_o                        => c_x_o(i),
        valid_debug_o              => valid_debug_o(i),
        valid_end_o                => valid_end_o(i)
      );

    cmp_ram_interface_Y : generic_dpram
      generic map (
        g_data_width               => g_data_width,
        g_size                     => g_size,
        g_with_byte_enable         => g_with_byte_enable,
        g_addr_conflict_resolution => g_addr_conflict_resolution,
        g_init_file                => g_init_file,
        g_dual_clock               => g_dual_clock,
        g_fail_if_file_not_found   => g_fail_if_file_not_found
      )
      port map(
        -- Synchronous reset
        rst_n_i                    => rst_n_i,

        -- Port A (write)
        clka_i                     => clk_i,
        bwea_i                     => (others => '1'),
        wea_i                      => wea_y_s,
        aa_i                       => coeff_dcc_addr_i,
        da_i                       => std_logic_vector(coeff_ram_dat_y_i),
        qa_o                       => qa_y_s,

        -- Port B (read)
        clkb_i                     => clk_i,
        bweb_i                     => (others => '1'),
        web_i                      => web_y_s,
        ab_i                       => coeff_dcc_addr_i,
        db_i                       => db_y_s,
        qb_o                       => coeff_ram_dat_y_s
      );

    matrix_multiplication_INST_Y : mac_fofb
      port map (
        clk_i                      => clk_i,
        rst_n_i                    => rst_n_i,
        valid_i                    => v_i_s,
        coeff_a_dat_i              => coeff_y_dcc_s,
        coeff_b_dat_i              => signed(coeff_ram_dat_y_s),
        c_o                        => c_y_o(i),
        valid_debug_o              => valid_debug_o(i),
        valid_end_o                => valid_end_o(i)
      );
  end generate;

end architecture behave;

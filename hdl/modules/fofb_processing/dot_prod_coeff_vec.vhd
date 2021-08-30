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
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

library work;
-- Dot product package
use work.dot_prod_pkg.all;
-- RAM package
use work.genram_pkg.all;

entity dot_prod_coeff_vec is
  generic(
    -- Standard parameters of generic_dpram
    g_data_width                   : natural := 32;
    g_size                         : natural := c_size_dpram;
    g_with_byte_enable             : boolean := false;
    g_addr_conflict_resolution     : string  := "read_first";
    g_init_file                    : string  := "";
    g_dual_clock                   : boolean := true;
    g_fail_if_file_not_found       : boolean := true;

    -- Width for DCC input
    g_a_width                      : natural := 32;

    -- Width for RAM data
    g_b_width                      : natural := 32;

    -- Width for RAM addr
    g_k_width                      : natural := 11;

    -- Width for output
    g_c_width                      : natural := 32
  );
  port (
    -- Core clock
    clk_i                          : in std_logic;

    -- Reset
    rst_n_i                        : in std_logic;

    -- Clear
    clear_i                        : in std_logic;

    -- DCC interface
    dcc_valid_i                    : in std_logic;
    dcc_coeff_i                    : in signed(g_a_width-1 downto 0);
    dcc_addr_i                     : in std_logic_vector(g_k_width-1 downto 0);

    -- RAM interface
    ram_coeff_dat_i                : in std_logic_vector(g_b_width-1 downto 0);
    ram_addr_i                     : in std_logic_vector(g_k_width-1 downto 0);
    ram_write_enable_i             : in std_logic;

    -- Result output array
    sp_o                           : out signed(g_c_width-1 downto 0);

    -- Valid output
    sp_valid_o                     : out std_logic
  );
  end dot_prod_coeff_vec;

architecture behave of dot_prod_coeff_vec is

  signal dcc_coeff_s               : signed(g_a_width-1 downto 0)               := (others => '0');
  signal dcc_coeff_reg_s           : signed(g_a_width-1 downto 0)               := (others => '0');
  signal ram_coeff_dat_s           : std_logic_vector(g_b_width-1 downto 0)     := (others => '0');
  signal dcc_addr_reg_s            : std_logic_vector(g_k_width-1 downto 0)     := (others => '0');
  signal valid_i_s, valid_reg_s    : std_logic := '0';

  -- DPRAM port A (write)
  signal wea_s                     : std_logic := '0';
  signal aa_s                      : std_logic_vector(g_k_width-1 downto 0)     := (others => '0');
  signal qa_s                      : std_logic_vector(g_data_width-1 downto 0)  := (others => '0');

  -- DPRAM port B (read)
  signal web_s                     : std_logic := '0';
  signal ab_s                      : std_logic_vector(g_k_width-1 downto 0)     := (others => '0');
  signal db_s                      : std_logic_vector(g_data_width-1 downto 0)  := (others => '0');
  signal ram_coeff_s               : std_logic_vector(g_b_width-1 downto 0);

begin

  dot_product_process : process(clk_i)
  begin
    if (rising_edge(clk_i)) then
      if rst_n_i = '0' then
        dcc_coeff_reg_s            <= (others => '0');
        dcc_coeff_s                <= (others => '0');
        dcc_addr_reg_s             <= (others => '0');
        ram_coeff_dat_s            <= (others => '0');
        valid_reg_s                <= '0';
        valid_i_s                  <= '0';
      end if;
      -- Coeffs from DCC delayed to align with coeffs from DPRAM
      dcc_coeff_reg_s              <= dcc_coeff_i;
      dcc_coeff_s                  <= dcc_coeff_reg_s;

      dcc_addr_reg_s               <= dcc_addr_i;
      ram_coeff_dat_s              <= ram_coeff_dat_i;

      -- Valid bit delayed to align with coeffs from DPRAM
      valid_reg_s                  <= dcc_valid_i;
      valid_i_s                    <= valid_reg_s;
    end if;
    end process dot_product_process;

  cmp_ram_interface : generic_dpram
    generic map (
      g_data_width                 => g_data_width,
      g_size                       => g_size,
      g_with_byte_enable           => g_with_byte_enable,
      g_addr_conflict_resolution   => g_addr_conflict_resolution,
      g_init_file                  => g_init_file,
      g_dual_clock                 => g_dual_clock,
      g_fail_if_file_not_found     => g_fail_if_file_not_found
    )
    port map(
      -- Synchronous reset
      rst_n_i                      => rst_n_i,

      -- Port A (write)
      clka_i                       => clk_i,
      bwea_i                       => (others => '1'),
      wea_i                        => ram_write_enable_i,
      aa_i                         => ram_addr_i,
      da_i                         => ram_coeff_dat_s,
      qa_o                         => qa_s,

      -- Port B (read)
      clkb_i                       => clk_i,
      bweb_i                       => (others => '1'),
      web_i                        => web_s,
      ab_i                         => dcc_addr_reg_s,
      db_i                         => db_s,
      qb_o                         => ram_coeff_s
    );

  dot_prod_interface : dot_prod
    port map (
      clk_i                        => clk_i,
      rst_n_i                      => rst_n_i,
      clear_acc_i                  => clear_i,
      valid_i                      => valid_i_s,
      a_i                          => dcc_coeff_s,
      b_i                          => signed(ram_coeff_s),
      c_o                          => sp_o,
      c_valid_o                    => sp_valid_o
    );

end architecture behave;

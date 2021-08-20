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
-- 2021-08-06  1.0      melissa.aguiar        Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

library work;
-- Matmul package
use work.mult_pkg.all;
-- RAM package
use work.genram_pkg.all;

entity fofb_matmul_top is
  generic(
    -- Standard parameters of generic_dpram
    g_data_width                   : natural := 32;
    g_size                         : natural := c_size_dpram;
    g_with_byte_enable             : boolean := false;
    g_addr_conflict_resolution     : string  := "read_first";
    g_init_file                    : string  := "";
    g_dual_clock                   : boolean := true;
    g_fail_if_file_not_found       : boolean := true;

    -- Width for inputs x and y
    g_a_width                      : natural := 32;
    -- Width for ram data
    g_b_width                      : natural := 32;
    -- Width for ram addr
    g_k_width                      : natural := 11;
    -- Width for output c
    g_c_width                      : natural := 32;
    -- Matrix multiplication size
    g_mat_size                     : natural := 4
  );
  port (
    -- Core clock
    clk_i                          : in std_logic;

    -- Reset
    rst_n_i                        : in std_logic;

    -- DCC interface
    dcc_valid_i                    : in std_logic;
    dcc_coeff_x_i                  : in signed(g_a_width-1 downto 0);
    dcc_coeff_y_i                  : in signed(g_a_width-1 downto 0);
    dcc_addr_i                     : in std_logic_vector(g_k_width-1 downto 0);

    -- RAM interface
    ram_coeff_dat_i                : in std_logic_vector(g_b_width-1 downto 0);
    ram_addr_i                     : in std_logic_vector(g_k_width-1 downto 0);
    ram_write_enable_i             : in std_logic;

    -- Result output array
    spx_o                          : out t_matmul_array_signed(g_mat_size-1 downto 0);
    spy_o                          : out t_matmul_array_signed(g_mat_size-1 downto 0);

    -- Valid output for debugging
    spx_valid_debug_o              : out std_logic_vector(g_mat_size-1 downto 0);
    spy_valid_debug_o              : out std_logic_vector(g_mat_size-1 downto 0);

    -- Valid end of fofb cycle
    spx_valid_end_o                : out std_logic_vector(g_mat_size-1 downto 0);
    spy_valid_end_o                : out std_logic_vector(g_mat_size-1 downto 0)
  );
end fofb_matmul_top;

architecture behave of fofb_matmul_top is

  signal dcc_coeff_x_s             : signed(g_a_width-1 downto 0)               := (others => '0');
  signal dcc_coeff_y_s             : signed(g_a_width-1 downto 0)               := (others => '0');
  signal coeff_x_reg_s             : signed(g_a_width-1 downto 0)               := (others => '0');
  signal coeff_y_reg_s             : signed(g_a_width-1 downto 0)               := (others => '0');
  signal ram_coeff_dat_s           : std_logic_vector(g_b_width-1 downto 0)     := (others => '0');
  signal dcc_addr_reg_s            : std_logic_vector(g_k_width-1 downto 0)     := (others => '0');
  signal valid_i_s, valid_reg_s    : std_logic := '0';

  -- DPRAM-X port A (write)
  signal wea_x_s                   : std_logic_vector(g_mat_size-1 downto 0)    := (others => '0');
  signal aa_x_s                    : std_logic_vector(g_k_width-1 downto 0)     := (others => '0');
  signal qa_x_s                    : std_logic_vector(g_data_width-1 downto 0)  := (others => '0');

  -- DPRAM-X port B (read)
  signal web_x_s                   : std_logic := '0';
  signal ab_x_s                    : std_logic_vector(g_k_width-1 downto 0)     := (others => '0');
  signal db_x_s                    : std_logic_vector(g_data_width-1 downto 0)  := (others => '0');
  signal ram_coeff_x_s             : t_matmul_array_logic(g_mat_size-1 downto 0);

  -- DPRAM-Y port A (write)
  signal wea_y_s                   : std_logic_vector(g_mat_size-1 downto 0)    := (others => '0');
  signal aa_y_s                    : std_logic_vector(g_k_width-1 downto 0)     := (others => '0');
  signal qa_y_s                    : std_logic_vector(g_data_width-1 downto 0)  := (others => '0');

  -- DPRAM-Y port B (read)
  signal web_y_s                   : std_logic := '0';
  signal ab_y_s                    : std_logic_vector(g_k_width-1 downto 0)     := (others => '0');
  signal db_y_s                    : std_logic_vector(g_data_width-1 downto 0)  := (others => '0');
  signal ram_coeff_y_s             : t_matmul_array_logic(g_mat_size-1 downto 0);

begin

  matmul_top : process(clk_i)
  begin
    if (rising_edge(clk_i)) then
      if rst_n_i = '0' then
        coeff_x_reg_s              <= (others => '0');
        dcc_coeff_x_s              <= (others => '0');
        coeff_y_reg_s              <= (others => '0');
        dcc_coeff_y_s              <= (others => '0');
        dcc_addr_reg_s             <= (others => '0');
        ram_coeff_dat_s            <= (others => '0');
        valid_reg_s                <= '0';
        valid_i_s                  <= '0';
      end if;
      -- Coeffs from DCC delayed to align with Coeffs from DPRAM
      coeff_x_reg_s                <= dcc_coeff_x_i;
      dcc_coeff_x_s                <= coeff_x_reg_s;

      coeff_y_reg_s                <= dcc_coeff_y_i;
      dcc_coeff_y_s                <= coeff_y_reg_s;

      dcc_addr_reg_s               <= dcc_addr_i;
      ram_coeff_dat_s              <= ram_coeff_dat_i;

      -- Valid bit delayed to align with Coeffs from DPRAM
      valid_reg_s                  <= dcc_valid_i;
      valid_i_s                    <= valid_reg_s;
    end if;
  end process matmul_top;

  ram_write : process(clk_i)
  begin
    if (rising_edge(clk_i)) then
      aa_x_s(g_k_width-4 downto 0) <= ram_addr_i(g_k_width-4 downto 0);
      aa_y_s(g_k_width-4 downto 0) <= ram_addr_i(g_k_width-4 downto 0);

      if ram_addr_i(g_k_width-1 downto g_k_width-3) = "000" then wea_x_s(0) <= ram_write_enable_i; else wea_x_s(0) <= '0'; end if;
      if ram_addr_i(g_k_width-1 downto g_k_width-3) = "001" then wea_y_s(0) <= ram_write_enable_i; else wea_y_s(0) <= '0'; end if;
      if ram_addr_i(g_k_width-1 downto g_k_width-3) = "010" then wea_x_s(1) <= ram_write_enable_i; else wea_x_s(1) <= '0'; end if;
      if ram_addr_i(g_k_width-1 downto g_k_width-3) = "011" then wea_y_s(1) <= ram_write_enable_i; else wea_y_s(1) <= '0'; end if;
      if ram_addr_i(g_k_width-1 downto g_k_width-3) = "100" then wea_x_s(2) <= ram_write_enable_i; else wea_x_s(2) <= '0'; end if;
      if ram_addr_i(g_k_width-1 downto g_k_width-3) = "101" then wea_y_s(2) <= ram_write_enable_i; else wea_y_s(2) <= '0'; end if;
      if ram_addr_i(g_k_width-1 downto g_k_width-3) = "110" then wea_x_s(3) <= ram_write_enable_i; else wea_x_s(3) <= '0'; end if;
      if ram_addr_i(g_k_width-1 downto g_k_width-3) = "111" then wea_y_s(3) <= ram_write_enable_i; else wea_y_s(3) <= '0'; end if;
    end if;
  end process ram_write;

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
        wea_i                      => wea_x_s(i),
        aa_i                       => aa_x_s,
        da_i                       => ram_coeff_dat_s,
        qa_o                       => qa_x_s,

        -- Port B (read)
        clkb_i                     => clk_i,
        bweb_i                     => (others => '1'),
        web_i                      => web_y_s,
        ab_i                       => dcc_addr_reg_s,
        db_i                       => db_x_s,
        qb_o                       => ram_coeff_x_s(i)
      );

    matrix_multiplication_INST_X : mac_fofb
      port map (
        clk_i                      => clk_i,
        rst_n_i                    => rst_n_i,
        valid_i                    => valid_i_s,
        coeff_a_dat_i              => dcc_coeff_x_s,
        coeff_b_dat_i              => signed(ram_coeff_x_s(i)),
        result_o                   => spx_o(i),
        result_valid_debug_o       => spx_valid_debug_o(i),
        result_valid_end_o         => spx_valid_end_o(i)
      );

    cmp_ram_interface_Y : generic_dpram
      generic map (
        g_data_width               => g_data_width,
        g_size                     => 2**g_k_width,
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
        wea_i                      => wea_y_s(i),
        aa_i                       => aa_y_s,
        da_i                       => ram_coeff_dat_s,
        qa_o                       => qa_y_s,

        -- Port B (read)
        clkb_i                     => clk_i,
        bweb_i                     => (others => '1'),
        web_i                      => web_y_s,
        ab_i                       => dcc_addr_reg_s,
        db_i                       => db_y_s,
        qb_o                       => ram_coeff_y_s(i)
      );

    matrix_multiplication_INST_Y : mac_fofb
      port map (
        clk_i                      => clk_i,
        rst_n_i                    => rst_n_i,
        valid_i                    => valid_i_s,
        coeff_a_dat_i              => dcc_coeff_y_s,
        coeff_b_dat_i              => signed(ram_coeff_y_s(i)),
        result_o                   => spy_o(i),
        result_valid_debug_o       => spy_valid_debug_o(i),
        result_valid_end_o         => spy_valid_end_o(i)
      );
  end generate;

end architecture behave;

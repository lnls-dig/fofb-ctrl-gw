-------------------------------------------------------------------------------
-- Title      :  Matrix multiplication interface
-------------------------------------------------------------------------------
-- Author     :  Melissa Aguiar
-- Company    : CNPEM LNLS-DIG
-- Platform   : FPGA-generic
-------------------------------------------------------------------------------
-- Description:  Matrix multiplication top level for the Fast Orbit Feedback
-------------------------------------------------------------------------------
-- Copyright (c) 2020 CNPEM
-- Licensed under GNU Lesser General Public License (LGPL) v3.0
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                Description
-- 2021-27-07  1.0      melissa.aguiar        Created
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
    g_data_width                        : natural := 32;
    g_size                              : natural := 512; -- Error using the value 16384: "declaration of a too large object (512 > --max-stack-alloc=128 KB)"
    g_with_byte_enable                  : boolean := false;
    g_addr_conflict_resolution          : string  := "read_first";
    g_init_file                         : string  := "../../testbench/matmul/coeff_bin.ram";
    g_dual_clock                        : boolean := true;
    g_fail_if_file_not_found            : boolean := true;
    -- Width for input a[k]
    g_a_width                           : natural := 32;
    -- Width for index k (coeff_x_addr)
    g_k_width                           : natural := 32;
    -- Width for input b[k] (coeff_x_dat)
    g_b_width                           : natural := 32;
    -- Width for output c
    g_c_width                           : natural := 32;
    -- Matrix multiplication size
    g_mat_size                          : natural := 8
    );

  port (
    -- Core clock
    clk_i                               : in std_logic;
    -- Reset
    rst_n_i                             : in std_logic;
    -- Data valid input
    valid_i                             : in std_logic;
    -- Input a[k]
    coeff_a_dat_i                       : in signed(g_a_width-1 downto 0);
    -- Input b[k]
    coeff_b_dat_i                       : in signed(g_b_width-1 downto 0); -- This input will be removed (coeff_b comes from generic_dpram)
    -- Input k
    coeff_k_addr_i                      : in std_logic_vector(g_k_width-1 downto 0);
    -- Result output array
    c_o                                 : out signed(g_c_width-1 downto 0);
    -- Data valid output for debugging
    valid_debug_o                       : out std_logic;
    -- Validate the end of fofb cycle
    valid_end_o                         : out std_logic
    );
  end fofb_matmul_top;

  architecture behave of fofb_matmul_top is

  component generic_dpram

  generic (
    g_data_width               : natural;
    g_size                     : natural;
    g_with_byte_enable         : boolean;
    g_addr_conflict_resolution : string;
    g_init_file                : string;
    g_dual_clock               : boolean;
    g_fail_if_file_not_found   : boolean
  );

  port(
    rst_n_i : in std_logic := '1';

    -- Port A
    clka_i : in  std_logic;
    bwea_i : in  std_logic_vector((g_data_width+7)/8-1 downto 0);
    wea_i  : in  std_logic;
    aa_i   : in  std_logic_vector(f_log2_size(g_size)-1 downto 0);
    da_i   : in  std_logic_vector(g_data_width-1 downto 0);
    qa_o   : out std_logic_vector(g_data_width-1 downto 0);

    -- Port B
    clkb_i : in  std_logic;
    bweb_i : in  std_logic_vector((g_data_width+7)/8-1 downto 0);
    web_i  : in  std_logic;
    ab_i   : in  std_logic_vector(f_log2_size(g_size)-1 downto 0);
    db_i   : in  std_logic_vector(g_data_width-1 downto 0);
    qb_o   : out std_logic_vector(g_data_width-1 downto 0)
  );
  end component;

  -- Port A
  signal wea_s          : std_logic := '0';
  signal aa_s           : std_logic_vector(f_log2_size(g_size)-1 downto 0);
  signal da_s           : std_logic_vector(g_data_width-1 downto 0);
  signal qa_s           : std_logic_vector(g_data_width-1 downto 0);
  -- Port B
  signal web_s          : std_logic := '0';
  signal ab_s           : std_logic_vector(f_log2_size(g_size)-1 downto 0);
  signal db_s           : std_logic_vector(g_data_width-1 downto 0);
  signal qb_s           : std_logic_vector(g_data_width-1 downto 0);

  begin

  --gen_matrix_multiplication : for i in 0 to g_mat_size-1 generate
  cmp_ram_interface : generic_dpram

  generic map (
    -- Standard parameters
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
    rst_n_i=> rst_n_i,
    -- Port A
    clka_i => clk_i,
    bwea_i => (others => '1'),
    wea_i  => wea_s,
    aa_i   => aa_s,
    da_i   => da_s,
    qa_o   => qa_s,
    -- Port B
    clkb_i => clk_i,
    bweb_i => (others => '1'),
    web_i  => web_s,
    ab_i   => ab_s,
    db_i   => db_s,
    qb_o   => qb_s
  );

  matrix_multiplication_INST : mac_fofb
  port map (
    clk_i          => clk_i,
    rst_n_i        => rst_n_i,
    valid_i        => valid_i,
    coeff_a_dat_i  => coeff_a_dat_i,
    coeff_b_dat_i  => coeff_b_dat_i,
    coeff_k_addr_i => coeff_k_addr_i,
    c_o            => c_o,
    valid_debug_o  => valid_debug_o,
    valid_end_o    => valid_end_o
    );
  --end generate;
end architecture behave;

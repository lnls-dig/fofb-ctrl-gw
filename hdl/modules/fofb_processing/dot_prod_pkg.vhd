-------------------------------------------------------------------------------
-- Title      :  Dot product package
-------------------------------------------------------------------------------
-- Author     :  Melissa Aguiar
-- Company    :  CNPEM LNLS-DIG
-- Platform   :  FPGA-generic
-------------------------------------------------------------------------------
-- Description:  Package for the dot product core
-------------------------------------------------------------------------------
-- Copyright (c) 2020 CNPEM
-- Licensed under GNU Lesser General Public License (LGPL) v3.0
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                Description
-- 2021-07-30  1.0      melissa.aguiar        Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package dot_prod_pkg is

  constant c_out_width             : natural := 32;
  constant c_size_dpram            : natural := 2048; -- 2**g_k_width

  type t_matmul_array_signed is array (natural range <>) of signed(c_out_width-1 downto 0);
  type t_matmul_array_logic  is array (natural range <>) of std_logic_vector(c_out_width-1 downto 0);

  component dot_prod is
    generic(
      -- Width for input a[k]
      g_a_width                    : natural := 32;

      -- Width for input b[k]
      g_b_width                    : natural := 32;

      -- Width for output c
      g_c_width                    : natural := 32
    );
    port(
      -- Core clock
      clk_i                        : in std_logic;

      -- Reset
      rst_n_i                      : in std_logic;

      -- Clear
      clear_acc_i                  : in std_logic;

      -- Data valid input
      valid_i                      : in std_logic;

      -- Input a[k]
      a_i                          : in signed(g_a_width-1 downto 0);

      -- Input b[k]
      b_i                          : in signed(g_b_width-1 downto 0);

      -- Result output
      c_o                          : out signed(g_c_width-1 downto 0);

      -- Data valid output
      c_valid_o                    : out std_logic
    );
  end component dot_prod;

  component dot_prod_coeff_vec is
    generic(
      -- Standard parameters of generic_dpram
      g_data_width                 : natural := 32;
      g_size                       : natural := c_size_dpram;
      g_with_byte_enable           : boolean := false;
      g_addr_conflict_resolution   : string  := "read_first";
      g_init_file                  : string  := "";
      g_dual_clock                 : boolean := true;
      g_fail_if_file_not_found     : boolean := true;

      -- Width for DCC input
      g_a_width                    : natural := 32;

      -- Width for RAM coeff
      g_b_width                    : natural := 32;

      -- Width for RAM addr
      g_k_width                    : natural := 11;

      -- Width for output
      g_c_width                    : natural := 32
    );
    port (
      -- Core clock
      clk_i                        : in std_logic;

      -- Reset
      rst_n_i                      : in std_logic;

      -- Clear
      clear_i                      : in std_logic;

      -- DCC interface
      dcc_valid_i                  : in std_logic;
      dcc_coeff_i                  : in signed(g_a_width-1 downto 0);
      dcc_addr_i                   : in std_logic_vector(g_k_width-1 downto 0);

      -- RAM interface
      ram_coeff_dat_i              : in std_logic_vector(g_b_width-1 downto 0);
      ram_addr_i                   : in std_logic_vector(g_k_width-1 downto 0);
      ram_write_enable_i           : in std_logic;

      -- Result output array
      sp_o                         : out signed(g_c_width-1 downto 0);

      -- Valid output
      sp_valid_o                   : out std_logic
    );
  end component dot_prod_coeff_vec;

  component fofb_processing_channel is
    generic(
      -- Standard parameters of generic_dpram
      g_data_width                 : natural := 32;
      g_size                       : natural := c_size_dpram;
      g_with_byte_enable           : boolean := false;
      g_addr_conflict_resolution   : string  := "read_first";
      g_init_file                  : string  := "";
      g_dual_clock                 : boolean := true;
      g_fail_if_file_not_found     : boolean := true;

      -- Width for DCC input
      g_a_width                    : natural := 32;

      -- Width for RAM data
      g_b_width                    : natural := 32;

      -- Width for RAM addr
      g_k_width                    : natural := 11;

      -- Width for output
      g_c_width                    : natural := 32
    );
    port (
      ---------------------------------------------------------------------------
      -- Clock, reset and clear interface
      ---------------------------------------------------------------------------
      clk_i                        : in std_logic;
      rst_n_i                      : in std_logic;
      clear_i                      : in std_logic;

      ---------------------------------------------------------------------------
      -- Dot product Interface Signals
      ---------------------------------------------------------------------------
      -- DCC interface
      dcc_valid_i                  : in std_logic;
      dcc_coeff_i                  : in signed(g_a_width-1 downto 0);
      dcc_addr_i                   : in std_logic_vector(g_k_width-1 downto 0);

      -- RAM interface
      ram_coeff_dat_i              : in std_logic_vector(g_b_width-1 downto 0);
      ram_addr_i                   : in std_logic_vector(g_k_width-1 downto 0);
      ram_write_enable_i           : in std_logic;

      -- Result output array
      sp_o                         : out signed(g_c_width-1 downto 0);

      -- Valid output
      sp_valid_o                   : out std_logic
    );
  end component fofb_processing_channel;

  component fofb_processing is
    generic(
      -- Standard parameters of generic_dpram
      g_data_width                 : natural := 32;
      g_size                       : natural := c_size_dpram;
      g_with_byte_enable           : boolean := false;
      g_addr_conflict_resolution   : string  := "read_first";
      g_init_file                  : string  := "";
      g_dual_clock                 : boolean := true;
      g_fail_if_file_not_found     : boolean := true;

      -- Width for DCC input
      g_a_width                    : natural := 32;

      -- Width for RAM data
      g_b_width                    : natural := 32;

      -- Width for RAM addr
      g_k_width                    : natural := 11;

      -- Width for output
      g_c_width                    : natural := 32
    );
    port (
      ---------------------------------------------------------------------------
      -- FOFB processing channel interface
      ---------------------------------------------------------------------------
      -- Clock core
      clk_i                        : in std_logic;

      -- Reset
      rst_n_i                      : in std_logic;

      -- Clear
      clear_i                      : in std_logic;

      -- DCC interface
      dcc_valid_i                  : in std_logic;
      dcc_coeff_i                  : in signed(g_a_width-1 downto 0);
      dcc_addr_i                   : in std_logic_vector(g_k_width-1 downto 0);

      -- RAM interface
      ram_coeff_dat_i              : in std_logic_vector(g_b_width-1 downto 0);
      ram_addr_i                   : in std_logic_vector(g_k_width-1 downto 0);
      ram_write_enable_i           : in std_logic;

      -- Result output array
      sp_o                         : out signed(g_c_width-1 downto 0);

      -- Valid output
      sp_valid_o                   : out std_logic
    );
  end component fofb_processing;

  component dot_prod_wb is
    port (
      rst_n_i                      : in    std_logic;
      clk_sys_i                    : in    std_logic;
      wb_adr_i                     : in    std_logic_vector(1 downto 0);
      wb_dat_i                     : in    std_logic_vector(31 downto 0);
      wb_dat_o                     : out   std_logic_vector(31 downto 0);
      wb_cyc_i                     : in    std_logic;
      wb_sel_i                     : in    std_logic_vector(3 downto 0);
      wb_stb_i                     : in    std_logic;
      wb_we_i                      : in    std_logic;
      wb_ack_o                     : out   std_logic;
      wb_stall_o                   : out   std_logic;
      dot_prod_clk_reg_i           : in    std_logic;

      -- Port for asynchronous (clock: matmul_clk_reg_i) std_logic_vector field: 'None' in reg: 'None'
      dot_prod_wb_ram_coeff_dat_o  : out   std_logic_vector(31 downto 0);

      -- Port for asynchronous (clock: matmul_clk_reg_i) std_logic_vector field: 'None' in reg: 'None'
      dot_prod_wb_ram_coeff_addr_o : out   std_logic_vector(31 downto 0);

      -- Port for asynchronous (clock: matmul_clk_reg_i) MONOSTABLE field: 'None' in reg: 'None'
      dot_prod_wb_ram_write_enable_o
                                   : out   std_logic
    );
  end component dot_prod_wb;

end package dot_prod_pkg;

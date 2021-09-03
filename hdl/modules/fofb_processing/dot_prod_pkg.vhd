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

    -----------------------------------------------------------------------------
    -- FOFB Processing constants
    -----------------------------------------------------------------------------
    -- Standard parameters of generic_dpram
    constant c_DATA_WIDTH          : natural := 32;
    constant c_SIZE                : natural := 2048; -- 2**g_K_WIDTH
    constant c_WITH_BYTE_ENABLE    : boolean := false;
    constant c_ADDR_CONFLICT_RESOLUTION
                                   : string  := "read_first";
    constant c_INIT_FILE           : string  := "";
    constant c_DUAL_CLOCK          : boolean := true;
    constant c_FAIL_IF_FILE_NOT_FOUND
                                   : boolean := true;

    -- Width for inputs x and y
    constant c_A_WIDTH             : natural := 32;
    -- Width for ram data
    constant c_B_WIDTH             : natural := 32;
    -- Width for ram addr
    constant c_K_WIDTH             : natural := 11;
    -- Width for output
    constant c_C_WIDTH             : natural := 16;
    -- Number of channels
    constant c_CHANNELS            : natural := 8;
    -- Extra bits for accumulator
    constant c_EXTRA_WIDTH         : natural := 4;

    -- Output array
    type t_dot_prod_array_signed is array (natural range <>) of signed(c_C_WIDTH-1 downto 0);

    -- Input record
    type t_dot_prod_record_fod is record
      valid                        : std_logic;                                -- data valid
      data                         : std_logic_vector(c_A_WIDTH-1 downto 0);   -- (2*c_A_WIDTH-1 downto 0); -- coeffs x and y
      addr                         : std_logic_vector(c_K_WIDTH-1 downto 0);   -- addr
    end record t_dot_prod_record_fod;

    -- Input array of record
    type t_dot_prod_array_record_fod is array (natural range <>) of t_dot_prod_record_fod;

  component dot_prod is
    generic(
      -- Width for input a[k]
      g_A_WIDTH                    : natural := c_A_WIDTH;

      -- Width for input b[k]
      g_B_WIDTH                    : natural := c_B_WIDTH;

      -- Width for output
      g_C_WIDTH                    : natural := c_C_WIDTH;

      -- Extra bits for accumulator
      g_EXTRA_WIDTH                : natural := c_EXTRA_WIDTH
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

      -- Time frame end
      time_frame_end_i             : in std_logic;

      -- Input a[k]
      a_i                          : in signed(g_A_WIDTH-1 downto 0);

      -- Input b[k]
      b_i                          : in signed(g_B_WIDTH-1 downto 0);

      -- Result output
      result_o                     : out signed(g_C_WIDTH-1 downto 0);
      result_debug_o               : out signed(g_C_WIDTH-1 downto 0);

      -- Data valid output
      result_valid_end_o           : out std_logic;
      result_valid_debug_o         : out std_logic
    );
  end component dot_prod;

  component dot_prod_coeff_vec is
    generic(
      -- Standard parameters of generic_dpram
      g_DATA_WIDTH                 : natural := c_DATA_WIDTH;
      g_SIZE                       : natural := c_SIZE;
      g_WITH_BYTE_ENABLE           : boolean := c_WITH_BYTE_ENABLE;
      g_ADDR_CONFLICT_RESOLUTION   : string  := c_ADDR_CONFLICT_RESOLUTION;
      g_INIT_FILE                  : string  := c_INIT_FILE;
      g_DUAL_CLOCK                 : boolean := c_DUAL_CLOCK;
      g_FAIL_IF_FILE_NOT_FOUND     : boolean := c_FAIL_IF_FILE_NOT_FOUND;

      -- Width for DCC input
      g_A_WIDTH                    : natural := c_A_WIDTH;

      -- Width for RAM coeff
      g_B_WIDTH                    : natural := c_B_WIDTH;

      -- Width for RAM addr
      g_K_WIDTH                    : natural := c_K_WIDTH;

      -- Width for output
      g_C_WIDTH                    : natural := c_C_WIDTH
    );
    port (
      -- Core clock
      clk_i                        : in std_logic;

      -- Reset
      rst_n_i                      : in std_logic;

      -- DCC interface
      dcc_valid_i                  : in std_logic;
      dcc_data_i                   : in signed(g_A_WIDTH-1 downto 0);
      dcc_addr_i                   : in std_logic_vector(g_K_WIDTH-1 downto 0);
      dcc_time_frame_start_i       : in std_logic;
      dcc_time_frame_end_i         : in std_logic;

      -- RAM interface
      ram_coeff_dat_i              : in std_logic_vector(g_B_WIDTH-1 downto 0);
      ram_addr_i                   : in std_logic_vector(g_K_WIDTH-1 downto 0);
      ram_write_enable_i           : in std_logic;

      -- Result output array
      sp_o                         : out signed(g_C_WIDTH-1 downto 0);
      sp_debug_o                   : out signed(g_C_WIDTH-1 downto 0);

      -- Valid output
      sp_valid_o                   : out std_logic;
      sp_valid_debug_o             : out std_logic
    );
  end component dot_prod_coeff_vec;

  component fofb_processing_channel is
    generic(
      -- Standard parameters of generic_dpram
      g_DATA_WIDTH                 : natural := c_DATA_WIDTH;
      g_SIZE                       : natural := c_SIZE;
      g_WITH_BYTE_ENABLE           : boolean := c_WITH_BYTE_ENABLE;
      g_ADDR_CONFLICT_RESOLUTION   : string  := c_ADDR_CONFLICT_RESOLUTION;
      g_INIT_FILE                  : string  := c_INIT_FILE;
      g_DUAL_CLOCK                 : boolean := c_DUAL_CLOCK;
      g_FAIL_IF_FILE_NOT_FOUND     : boolean := c_FAIL_IF_FILE_NOT_FOUND;

      -- Width for DCC input
      g_A_WIDTH                    : natural := c_A_WIDTH;

      -- Width for RAM coeff
      g_B_WIDTH                    : natural := c_B_WIDTH;

      -- Width for RAM addr
      g_K_WIDTH                    : natural := c_K_WIDTH;

      -- Width for output
      g_C_WIDTH                    : natural := c_C_WIDTH
    );
    port (
      ---------------------------------------------------------------------------
      -- Clock and reset interface
      ---------------------------------------------------------------------------
      clk_i                        : in std_logic;
      rst_n_i                      : in std_logic;

      ---------------------------------------------------------------------------
      -- Dot product Interface Signals
      ---------------------------------------------------------------------------
      -- DCC interface
      dcc_valid_i                  : in std_logic;
      dcc_data_i                   : in signed(g_A_WIDTH-1 downto 0);
      dcc_addr_i                   : in std_logic_vector(g_K_WIDTH-1 downto 0);
      dcc_time_frame_start_i       : in std_logic;
      dcc_time_frame_end_i         : in std_logic;

      -- RAM interface
      ram_coeff_dat_i              : in std_logic_vector(g_B_WIDTH-1 downto 0);
      ram_addr_i                   : in std_logic_vector(g_K_WIDTH-1 downto 0);
      ram_write_enable_i           : in std_logic;

      -- Result output array
      sp_o                         : out signed(g_C_WIDTH-1 downto 0);
      sp_debug_o                   : out signed(g_C_WIDTH-1 downto 0);

      -- Valid output
      sp_valid_o                   : out std_logic;
      sp_valid_debug_o             : out std_logic
    );
  end component fofb_processing_channel;

  component fofb_processing is
    generic(
      -- Standard parameters of generic_dpram
      g_DATA_WIDTH                 : natural := c_DATA_WIDTH;
      g_SIZE                       : natural := c_SIZE;
      g_WITH_BYTE_ENABLE           : boolean := c_WITH_BYTE_ENABLE;
      g_ADDR_CONFLICT_RESOLUTION   : string  := c_ADDR_CONFLICT_RESOLUTION;
      g_INIT_FILE                  : string  := c_INIT_FILE;
      g_DUAL_CLOCK                 : boolean := c_DUAL_CLOCK;
      g_FAIL_IF_FILE_NOT_FOUND     : boolean := c_FAIL_IF_FILE_NOT_FOUND;

      -- Width for DCC input
      g_A_WIDTH                    : natural := c_A_WIDTH;

      -- Width for RAM coeff
      g_B_WIDTH                    : natural := c_B_WIDTH;

      -- Width for RAM addr
      g_K_WIDTH                    : natural := c_K_WIDTH;

      -- Width for output
      g_C_WIDTH                    : natural := c_C_WIDTH;

      -- Number of channels
      g_CHANNELS                   : natural := c_CHANNELS
    );
    port (
      ---------------------------------------------------------------------------
      -- FOFB processing channel interface
      ---------------------------------------------------------------------------
      -- Clock core
      clk_i                        : in std_logic;

      -- Reset
      rst_n_i                      : in std_logic;

      -- DCC interface
      dcc_fod_i                    : in t_dot_prod_array_record_fod;
      dcc_time_frame_start_i       : in std_logic;
      dcc_time_frame_end_i    	   : in std_logic;

      -- RAM interface
      ram_coeff_dat_i              : in std_logic_vector(g_B_WIDTH-1 downto 0);
      ram_addr_i                   : in std_logic_vector(g_K_WIDTH-1 downto 0);
      ram_write_enable_i           : in std_logic;

      -- Result output array
      sp_o                         : out t_dot_prod_array_signed(g_CHANNELS-1 downto 0);
      sp_debug_o                   : out t_dot_prod_array_signed(g_CHANNELS-1 downto 0);

      -- Valid output
      sp_valid_o                   : out std_logic_vector(g_CHANNELS-1 downto 0);
      sp_valid_debug_o             : out std_logic_vector(g_CHANNELS-1 downto 0)
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

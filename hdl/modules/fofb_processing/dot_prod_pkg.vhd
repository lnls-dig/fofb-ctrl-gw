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

    -- Output array
    type t_dot_prod_array_signed is array (natural range <>) of signed(16-1 downto 0);

    -- RAM data output array
    type t_ram_data_out_array_logic_vector is array (natural range <>) of std_logic_vector(32-1 downto 0);

    -- Input record
    type t_dot_prod_record_fod is record
      valid                        : std_logic;
      data                         : std_logic_vector(32-1 downto 0);
      addr                         : std_logic_vector(9-1 downto 0);
    end record t_dot_prod_record_fod;

    -- Input array of record
    type t_dot_prod_array_record_fod is array (natural range <>) of t_dot_prod_record_fod;

  component dot_prod is
    generic(
      -- Width for input a[k]
      g_A_WIDTH                    : natural := 32;

      -- Width for input b[k]
      g_B_WIDTH                    : natural := 32;

      -- Width for output
      g_C_WIDTH                    : natural := 16;

      -- Fixed point representation for output
      g_OUT_FIXED                  : natural := 26;

      -- Extra bits for accumulator
      g_EXTRA_WIDTH                : natural := 4
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
      g_SIZE                       : natural := 512;
      g_WITH_BYTE_ENABLE           : boolean := false;
      g_ADDR_CONFLICT_RESOLUTION   : string  := "read_first";
      g_INIT_FILE                  : string  := "";
      g_DUAL_CLOCK                 : boolean := true;
      g_FAIL_IF_FILE_NOT_FOUND     : boolean := true;

      -- Width for DCC input
      g_A_WIDTH                    : natural := 32;

      -- Width for RAM coeff
      g_B_WIDTH                    : natural := 32;

      -- Width for DCC addr
      g_ID_WIDTH                   : natural := 9;

      -- Width for output
      g_C_WIDTH                    : natural := 16;

      -- Fixed point representation for output
      g_OUT_FIXED                  : natural := 26;

      -- Extra bits for accumulator
      g_EXTRA_WIDTH                : natural := 4
    );
    port(
      -- Core clock
      clk_i                        : in std_logic;

      -- Reset
      rst_n_i                      : in std_logic;

      -- DCC interface
      dcc_valid_i                  : in std_logic;
      dcc_data_i                   : in signed(g_A_WIDTH-1 downto 0);
      dcc_addr_i                   : in std_logic_vector(g_ID_WIDTH-1 downto 0);
      dcc_time_frame_start_i       : in std_logic;
      dcc_time_frame_end_i         : in std_logic;

      -- RAM interface
      ram_coeff_dat_i              : in std_logic_vector(g_B_WIDTH-1 downto 0);
      ram_addr_i                   : in std_logic_vector(g_ID_WIDTH-1 downto 0);
      ram_write_enable_i           : in std_logic;
      ram_coeff_dat_o              : out std_logic_vector(g_B_WIDTH-1 downto 0);

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
      g_SIZE                       : natural := 512;
      g_WITH_BYTE_ENABLE           : boolean := false;
      g_ADDR_CONFLICT_RESOLUTION   : string  := "read_first";
      g_INIT_FILE                  : string  := "";
      g_DUAL_CLOCK                 : boolean := true;
      g_FAIL_IF_FILE_NOT_FOUND     : boolean := true;

      -- Width for DCC input
      g_A_WIDTH                    : natural := 32;

      -- Width for RAM coeff
      g_B_WIDTH                    : natural := 32;

      -- Width for DCC addr
      g_ID_WIDTH                   : natural := 9;

      -- Width for output
      g_C_WIDTH                    : natural := 16;

      -- Fixed point representation for output
      g_OUT_FIXED                  : natural := 26;

      -- Extra bits for accumulator
      g_EXTRA_WIDTH                : natural := 4
    );
    port(
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
      dcc_addr_i                   : in std_logic_vector(g_ID_WIDTH-1 downto 0);
      dcc_time_frame_start_i       : in std_logic;
      dcc_time_frame_end_i         : in std_logic;

      -- RAM interface
      ram_coeff_dat_i              : in std_logic_vector(g_B_WIDTH-1 downto 0);
      ram_addr_i                   : in std_logic_vector(g_ID_WIDTH-1 downto 0);
      ram_write_enable_i           : in std_logic;
      ram_coeff_dat_o              : out std_logic_vector(g_B_WIDTH-1 downto 0);

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
      g_SIZE                       : natural := 512;
      g_WITH_BYTE_ENABLE           : boolean := false;
      g_ADDR_CONFLICT_RESOLUTION   : string  := "read_first";
      g_INIT_FILE                  : string  := "";
      g_DUAL_CLOCK                 : boolean := true;
      g_FAIL_IF_FILE_NOT_FOUND     : boolean := true;

      -- Width for DCC input
      g_A_WIDTH                    : natural := 32;

      -- Width for RAM coeff
      g_B_WIDTH                    : natural := 32;

      -- Width for RAM addr
      g_K_WIDTH                    : natural := 12;

      -- Width for DCC addr
      g_ID_WIDTH                   : natural := 9;

      -- Width for output
      g_C_WIDTH                    : natural := 16;

      -- Fixed point representation for output
      g_OUT_FIXED                  : natural := 26;

      -- Extra bits for accumulator
      g_EXTRA_WIDTH                : natural := 4;

      -- Number of channels
      g_CHANNELS                   : natural := 8
    );
    port(
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
      ram_coeff_dat_o              : out std_logic_vector(g_B_WIDTH-1 downto 0);

      -- Result output array
      sp_o                         : out t_dot_prod_array_signed(g_CHANNELS-1 downto 0);
      sp_debug_o                   : out t_dot_prod_array_signed(g_CHANNELS-1 downto 0);

      -- Valid output
      sp_valid_o                   : out std_logic_vector(g_CHANNELS-1 downto 0);
      sp_valid_debug_o             : out std_logic_vector(g_CHANNELS-1 downto 0)
    );
  end component fofb_processing;

  component wb_fofb_processing_regs is
    port(
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
      fofb_processing_clk_reg_i    : in    std_logic;
      -- Port for asynchronous (clock: fofb_processing_clk_reg_i) std_logic_vector field: 'None' in reg: 'None'
      wb_fofb_processing_regs_ram_data_in_o
                                   : out   std_logic_vector(31 downto 0);
      -- Port for asynchronous (clock: fofb_processing_clk_reg_i) std_logic_vector field: 'None' in reg: 'None'
      wb_fofb_processing_regs_ram_data_out_o
                                   : out   std_logic_vector(31 downto 0);
      -- Port for asynchronous (clock: fofb_processing_clk_reg_i) std_logic_vector field: 'None' in reg: 'None'
      wb_fofb_processing_regs_ram_addr_o
                                   : out   std_logic_vector(31 downto 0);
      -- Port for asynchronous (clock: fofb_processing_clk_reg_i) MONOSTABLE field: 'None' in reg: 'None'
      wb_fofb_processing_regs_ram_write_enable_o
                                   : out   std_logic
    );
  end component wb_fofb_processing_regs;
end package dot_prod_pkg;

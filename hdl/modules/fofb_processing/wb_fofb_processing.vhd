-------------------------------------------------------------------------------
-- Title      :  Wishbone matmul wrapper
-------------------------------------------------------------------------------
-- Author     :  Melissa Aguiar
-- Company    :  CNPEM LNLS-DIG
-- Platform   :  FPGA-generic
-------------------------------------------------------------------------------
-- Description:  Wishbone matmul wrapper for the Fast Orbit Feedback
-------------------------------------------------------------------------------
-- Copyright (c) 2020 CNPEM
-- Licensed under GNU Lesser General Public License (LGPL) v3.0
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                Description
-- 2021-08-13  1.0      melissa.aguiar        Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

library work;
-- Dot product package
use work.dot_prod_pkg.all;
-- RAM package
use work.genram_pkg.all;
-- Main Wishbone Definitions
use work.wishbone_pkg.all;
-- General common cores
use work.gencores_pkg.all;
-- FOFB CTRL package
use work.fofb_ctrl_pkg.all;

entity wb_fofb_processing is
  generic(
    -- Standard parameters of generic_dpram
    g_DATA_WIDTH                 : natural := 32;
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

    -- Number of channels
    g_CHANNELS                   : natural := 8;

    -- Wishbone parameters
    g_INTERFACE_MODE             : t_wishbone_interface_mode      := CLASSIC;
    g_ADDRESS_GRANULARITY        : t_wishbone_address_granularity := WORD;
    g_WITH_EXTRA_WB_REG          : boolean := false
  );
  port (
    ---------------------------------------------------------------------------
    -- Clock and reset interface
    ---------------------------------------------------------------------------
    clk_i                        : in std_logic;
    rst_n_i                      : in std_logic;
    clk_sys_i                    : in std_logic;
    rst_sys_n_i                  : in std_logic;

    ---------------------------------------------------------------------------
    -- FOFB Processing Interface signals
    ---------------------------------------------------------------------------
    -- DCC interface
    dcc_fod_i                    : in t_dot_prod_array_record_fod(g_CHANNELS-1 downto 0);
    dcc_time_frame_start_i       : in std_logic;
    dcc_time_frame_end_i         : in std_logic;

    -- Result output array
    sp_o                         : out t_dot_prod_array_signed(g_CHANNELS-1 downto 0);
    sp_debug_o                   : out t_dot_prod_array_signed(g_CHANNELS-1 downto 0);

    -- Valid output
    sp_valid_o                   : out std_logic_vector(g_CHANNELS-1 downto 0);
    sp_valid_debug_o             : out std_logic_vector(g_CHANNELS-1 downto 0);

    ---------------------------------------------------------------------------
    -- Wishbone Control Interface signals
    ---------------------------------------------------------------------------
    wb_adr_i                     : in  std_logic_vector(c_WISHBONE_ADDRESS_WIDTH-1 downto 0) := (others => '0');
    wb_dat_i                     : in  std_logic_vector(c_WISHBONE_DATA_WIDTH-1 downto 0) := (others => '0');
    wb_dat_o                     : out std_logic_vector(c_WISHBONE_DATA_WIDTH-1 downto 0);
    wb_sel_i                     : in  std_logic_vector(c_WISHBONE_DATA_WIDTH/8-1 downto 0) := (others => '0');
    wb_we_i                      : in  std_logic := '0';
    wb_cyc_i                     : in  std_logic := '0';
    wb_stb_i                     : in  std_logic := '0';
    wb_ack_o                     : out std_logic;
    wb_err_o                     : out std_logic;
    wb_rty_o                     : out std_logic;
    wb_stall_o                   : out std_logic
  );
  end wb_fofb_processing;

architecture rtl of wb_fofb_processing is

  -----------------------------
  -- RAM signals
  -----------------------------
  signal ram_coeff_dat_s         : std_logic_vector(31 downto 0);
  signal ram_coeff_addr_s        : std_logic_vector(31 downto 0);
  signal ram_write_enable_s      : std_logic;
  signal ram_wr_s                : std_logic;

  -----------------------------
  -- General contants
  -----------------------------
  -- Number of bits in Wishbone register interface. Plus 2 to account for BYTE addressing
  constant c_PERIPH_ADDR_SIZE    : natural := 2+2;

  -----------------------------
  -- Wishbone slave adapter signals/structures
  -----------------------------
  signal wb_slv_adp_out          : t_wishbone_master_out;
  signal wb_slv_adp_in           : t_wishbone_master_in;
  signal resized_addr            : std_logic_vector(c_wishbone_address_width-1 downto 0);

  -- Extra Wishbone registering stage
  signal wb_slave_in             : t_wishbone_slave_in_array (0 downto 0);
  signal wb_slave_out            : t_wishbone_slave_out_array(0 downto 0);
  signal wb_slave_in_reg0        : t_wishbone_slave_in_array (0 downto 0);
  signal wb_slave_out_reg0       : t_wishbone_slave_out_array(0 downto 0);

begin

  cmp_fofb_processing_interface: fofb_processing
    generic map(
    -- Standard parameters of generic_dpram
    g_DATA_WIDTH                 => g_DATA_WIDTH,
    g_SIZE                       => g_SIZE,
    g_WITH_BYTE_ENABLE           => g_WITH_BYTE_ENABLE,
    g_ADDR_CONFLICT_RESOLUTION   => g_ADDR_CONFLICT_RESOLUTION,
    g_INIT_FILE                  => g_INIT_FILE,
    g_DUAL_CLOCK                 => g_DUAL_CLOCK,
    g_FAIL_IF_FILE_NOT_FOUND     => g_FAIL_IF_FILE_NOT_FOUND,

    -- Width for inputs x and y
    g_A_WIDTH                    => g_A_WIDTH,
    -- Width for ram data
    g_B_WIDTH                    => g_B_WIDTH,
    -- Width for ram addr
    g_K_WIDTH                    => g_K_WIDTH,
    -- Width for dcc addr
    g_ID_WIDTH                   => g_ID_WIDTH,
    -- Width for output c
    g_C_WIDTH                    => g_C_WIDTH,
    -- Number of channels
    g_CHANNELS                   => g_CHANNELS
    )
    port map(
    -- Core clock
    clk_i                        => clk_i,

    -- Reset
    rst_n_i                      => rst_n_i,

    -- DCC interface
    dcc_fod_i                    => dcc_fod_i,
    dcc_time_frame_start_i       => dcc_time_frame_start_i,
    dcc_time_frame_end_i         => dcc_time_frame_end_i,

    -- RAM interface
    ram_coeff_dat_i              => ram_coeff_dat_s,
    ram_addr_i                   => ram_coeff_addr_s(g_K_WIDTH-1 downto 0),
    ram_write_enable_i           => ram_write_enable_s,

    -- Result output array
    sp_o                         => sp_o,
    sp_debug_o                   => sp_debug_o,

    -- Valid output for debugging
    sp_valid_o                   => sp_valid_o,
    sp_valid_debug_o             => sp_valid_debug_o
    );

  -----------------------------
  -- Insert extra Wishbone registering stage for ease timing.
  -- It effectively cuts the bandwidth in half!
  -----------------------------
  gen_with_extra_wb_reg : if g_WITH_EXTRA_WB_REG generate
    cmp_register_link : xwb_register_link -- puts a register of delay between crossbars
      port map (
        clk_sys_i                => clk_sys_i,
        rst_n_i                  => rst_sys_n_i,
        slave_i                  => wb_slave_in_reg0(0),
        slave_o                  => wb_slave_out_reg0(0),
        master_i                 => wb_slave_out(0),
        master_o                 => wb_slave_in(0)
      );

      wb_slave_in_reg0(0).adr    <= wb_adr_i;
      wb_slave_in_reg0(0).dat    <= wb_dat_i;
      wb_slave_in_reg0(0).sel    <= wb_sel_i;
      wb_slave_in_reg0(0).we     <= wb_we_i;
      wb_slave_in_reg0(0).cyc    <= wb_cyc_i;
      wb_slave_in_reg0(0).stb    <= wb_stb_i;

      wb_dat_o                   <= wb_slave_out_reg0(0).dat;
      wb_ack_o                   <= wb_slave_out_reg0(0).ack;
      wb_err_o                   <= wb_slave_out_reg0(0).err;
      wb_rty_o                   <= wb_slave_out_reg0(0).rty;
      wb_stall_o                 <= wb_slave_out_reg0(0).stall;
    end generate;

  gen_without_extra_wb_reg : if not g_WITH_EXTRA_WB_REG generate
    -- External master connection
    wb_slave_in(0).adr           <= wb_adr_i;
    wb_slave_in(0).dat           <= wb_dat_i;
    wb_slave_in(0).sel           <= wb_sel_i;
    wb_slave_in(0).we            <= wb_we_i;
    wb_slave_in(0).cyc           <= wb_cyc_i;
    wb_slave_in(0).stb           <= wb_stb_i;

    wb_dat_o                     <= wb_slave_out(0).dat;
    wb_ack_o                     <= wb_slave_out(0).ack;
    wb_err_o                     <= wb_slave_out(0).err;
    wb_rty_o                     <= wb_slave_out(0).rty;
    wb_stall_o                   <= wb_slave_out(0).stall;
  end generate;

  -----------------------------
  -- Slave adapter for Wishbone Register Interface
  -----------------------------
  cmp_slave_adapter : wb_slave_adapter
    generic map (
      g_master_use_struct        => true,
      g_master_mode              => PIPELINED,
      g_master_granularity       => WORD,
      g_slave_use_struct         => false,
      g_slave_mode               => g_INTERFACE_MODE,
      g_slave_granularity        => g_ADDRESS_GRANULARITY
    )
    port map (
      clk_sys_i                  => clk_sys_i,
      rst_n_i                    => rst_sys_n_i,
      master_i                   => wb_slv_adp_in,
      master_o                   => wb_slv_adp_out,
      sl_adr_i                   => resized_addr,
      sl_dat_i                   => wb_slave_in(0).dat,
      sl_sel_i                   => wb_slave_in(0).sel,
      sl_cyc_i                   => wb_slave_in(0).cyc,
      sl_stb_i                   => wb_slave_in(0).stb,
      sl_we_i                    => wb_slave_in(0).we,
      sl_dat_o                   => wb_slave_out(0).dat,
      sl_ack_o                   => wb_slave_out(0).ack,
      sl_rty_o                   => wb_slave_out(0).rty,
      sl_err_o                   => wb_slave_out(0).err,
      sl_stall_o                 => wb_slave_out(0).stall
    );
    -- By doing this zeroing we avoid the issue related to BYTE -> WORD  conversion
    -- slave addressing (possibly performed by the slave adapter component)
    -- in which a bit in the MSB of the peripheral addressing part (31 downto c_PERIPH_ADDR_SIZE in our case)
    -- is shifted to the internal register adressing part (c_PERIPH_ADDR_SIZE-1 downto 0 in our case).
    -- Therefore, possibly changing the these bits!
    resized_addr(c_PERIPH_ADDR_SIZE-1 downto 0)
                                 <= wb_slave_in(0).adr(c_PERIPH_ADDR_SIZE-1 downto 0);
    resized_addr(c_WISHBONE_ADDRESS_WIDTH-1 downto c_PERIPH_ADDR_SIZE)
                                 <= (others => '0');

  cmp_dot_prod_wb: dot_prod_wb
    port map(
      rst_n_i                    => rst_sys_n_i,
      clk_sys_i                  => clk_sys_i,

      wb_adr_i                   => wb_slv_adp_out.adr(1 downto 0),
      wb_dat_i                   => wb_slv_adp_out.dat,
      wb_dat_o                   => wb_slv_adp_in.dat,
      wb_cyc_i                   => wb_slv_adp_out.cyc,
      wb_sel_i                   => wb_slv_adp_out.sel,
      wb_stb_i                   => wb_slv_adp_out.stb,
      wb_we_i                    => wb_slv_adp_out.we,
      wb_ack_o                   => wb_slv_adp_in.ack,
      wb_stall_o                 => wb_slv_adp_in.stall,

      dot_prod_clk_reg_i         => clk_i,

      -- Port for asynchronous (clock: matmul_clk_reg_i) std_logic_vector field: 'None' in reg: 'None'
      dot_prod_wb_ram_coeff_dat_o
                                 => ram_coeff_dat_s,

      -- Port for asynchronous (clock: matmul_clk_reg_i) std_logic_vector field: 'None' in reg: 'None'
      dot_prod_wb_ram_coeff_addr_o
                                 => ram_coeff_addr_s,

      -- Port for asynchronous (clock: matmul_clk_reg_i) MONOSTABLE field: 'None' in reg: 'None'
      dot_prod_wb_ram_write_enable_o
                                 => ram_write_enable_s
    );

end architecture rtl;

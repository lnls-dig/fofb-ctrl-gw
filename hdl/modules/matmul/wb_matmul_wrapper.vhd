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
-- 2021-13-08  1.0      melissa.aguiar        Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

library work;
-- Matmul package
use work.mult_pkg.all;
-- RAM package
use work.genram_pkg.all;
-- Main Wishbone Definitions
use work.wishbone_pkg.all;
-- General common cores
use work.gencores_pkg.all;
-- FOFB CTRL package
use work.fofb_ctrl_pkg.all;

entity wb_matmul_wrapper is
  generic(
    -- Standard parameters of generic_dpram
    g_data_width                 : natural := 32;
    g_size                       : natural := c_size_dpram;
    g_with_byte_enable           : boolean := false;
    g_addr_conflict_resolution   : string  := "read_first";
    g_init_file                  : string  := "";
    g_dual_clock                 : boolean := true;
    g_fail_if_file_not_found     : boolean := true;

    -- Width for inputs x and y
    g_a_width                    : natural := 32;
    -- Width for ram data
    g_b_width                    : natural := 32;
    -- Width for ram addr
    g_k_width                    : natural := 11;
    -- Width for output c
    g_c_width                    : natural := 32;
    -- Matrix multiplication size
    g_mat_size                   : natural := 4;

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
    -- Matmul Top Level Interface Signals
    ---------------------------------------------------------------------------
    -- DCC interface
    dcc_valid_i                  : in std_logic;
    dcc_coeff_x_i                : in signed(g_a_width-1 downto 0);
    dcc_coeff_y_i                : in signed(g_a_width-1 downto 0);
    dcc_addr_i                   : in std_logic_vector(g_k_width-1 downto 0);

    -- Result output array
    spx_o                        : out t_matmul_array_signed(g_mat_size-1 downto 0);
    spy_o                        : out t_matmul_array_signed(g_mat_size-1 downto 0);

    -- Valid output for debugging
    spx_valid_debug_o            : out std_logic_vector(g_mat_size-1 downto 0);
    spy_valid_debug_o            : out std_logic_vector(g_mat_size-1 downto 0);

    -- Valid end of fofb cycle
    spx_valid_end_o              : out std_logic_vector(g_mat_size-1 downto 0);
    spy_valid_end_o              : out std_logic_vector(g_mat_size-1 downto 0);

    ---------------------------------------------------------------------------
    -- Wishbone Control Interface signals
    ---------------------------------------------------------------------------
    wb_adr_i                     : in std_logic_vector(c_WISHBONE_ADDRESS_WIDTH-1 downto 0) := (others => '0');
    wb_dat_i                     : in std_logic_vector(c_WISHBONE_DATA_WIDTH-1 downto 0) := (others => '0');
    wb_dat_o                     : out std_logic_vector(c_WISHBONE_DATA_WIDTH-1 downto 0);
    wb_cyc_i                     : in std_logic := '0';
    wb_sel_i                     : in std_logic_vector(c_WISHBONE_DATA_WIDTH/8-1 downto 0) := (others => '0');
    wb_stb_i                     : in std_logic := '0';
    wb_we_i                      : in std_logic := '0';
    wb_ack_o                     : out std_logic;
    wb_stall_o                   : out std_logic
  );
  end wb_matmul_wrapper;

architecture rtl of wb_matmul_wrapper is

  -----------------------------
  -- Matmul RAM signals
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

  cmp_fofb_matmul_top: fofb_matmul_top
    generic map(
    -- Standard parameters of generic_dpram
    g_data_width                 => g_data_width,
    g_size                       => g_size,
    g_with_byte_enable           => g_with_byte_enable,
    g_addr_conflict_resolution   => g_addr_conflict_resolution,
    g_init_file                  => g_init_file,
    g_dual_clock                 => g_dual_clock,
    g_fail_if_file_not_found     => g_fail_if_file_not_found,

    -- Width for inputs x and y
    g_a_width                    => g_a_width,
    -- Width for ram data
    g_b_width                    => g_b_width,
    -- Width for ram addr
    g_k_width                    => g_k_width,
    -- Width for output c
    g_c_width                    => g_c_width,
    -- Matrix multiplication size
    g_mat_size                   => g_mat_size
    )
    port map(
    -- Core clock
    clk_i                        => clk_i,

    -- Reset
    rst_n_i                      => rst_n_i,

    -- DCC interface
    dcc_valid_i                  => dcc_valid_i,
    dcc_coeff_x_i                => dcc_coeff_x_i,
    dcc_coeff_y_i                => dcc_coeff_y_i,
    dcc_addr_i                   => dcc_addr_i,

    -- RAM interface
    ram_coeff_dat_i              => ram_coeff_dat_s,
    ram_addr_i                   => ram_coeff_addr_s(g_k_width-1 downto 0),
    ram_write_enable_i           => ram_write_enable_s,

    -- Result output array
    spx_o                        => spx_o,
    spy_o                        => spy_o,

    -- Valid output for debugging
    spx_valid_debug_o            => spx_valid_debug_o,
    spy_valid_debug_o            => spy_valid_debug_o,

    -- Valid end of fofb cycle
    spx_valid_end_o              => spx_valid_end_o,
    spy_valid_end_o              => spy_valid_end_o
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

  cmp_matmul_wb: matmul_wb
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

      matmul_clk_reg_i           => clk_i,

      -- Port for asynchronous (clock: matmul_clk_reg_i) std_logic_vector field: 'None' in reg: 'None'
      matmul_wb_ram_coeff_dat_o  => ram_coeff_dat_s,

      -- Port for asynchronous (clock: matmul_clk_reg_i) std_logic_vector field: 'None' in reg: 'None'
      matmul_wb_ram_coeff_addr_o => ram_coeff_addr_s,

      -- Port for asynchronous (clock: matmul_clk_reg_i) MONOSTABLE field: 'None' in reg: 'None'
      matmul_wb_ram_write_enable_o
                                 => ram_write_enable_s
    );

end architecture rtl;

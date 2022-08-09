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
-- 2022-07-27  1.1      guilherme.ricioli     Changed coeffs RAMs' wb interface
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

library work;
-- Dot product package
use work.dot_prod_pkg.all;
-- Main Wishbone Definitions
use work.wishbone_pkg.all;
-- General common cores
use work.gencores_pkg.all;
-- FOFB CTRL package
use work.fofb_ctrl_pkg.all;

entity wb_fofb_processing is
  generic(
    -- Width for DCC input
    g_A_WIDTH                    : natural := 32;

    -- Width for DCC addr
    g_ID_WIDTH                   : natural := 9;

    -- Width for RAM coeff
    g_B_WIDTH                    : natural;

    -- Width for RAM addr
    g_K_WIDTH                    : natural;

    -- Width for output
    g_C_WIDTH                    : natural := 16;

    -- Fixed point representation for output
    g_OUT_FIXED                  : natural := 26;

    -- Extra bits for accumulator
    g_EXTRA_WIDTH                : natural := 4;

    -- Number of channels
    g_CHANNELS                   : natural;

    g_ANTI_WINDUP_UPPER_LIMIT    : integer; -- anti-windup upper limit
    g_ANTI_WINDUP_LOWER_LIMIT    : integer; -- anti-windup lower limit

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

    -- Setpoints
    sp_arr_o                     : out t_fofb_processing_setpoints(g_CHANNELS-1 downto 0);
    sp_valid_arr_o               : out std_logic_vector(g_CHANNELS-1 downto 0);

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
  -- General contants
  -----------------------------
  -- Number of bits in Wishbone register interface. Plus 2 to account for BYTE addressing
  constant c_PERIPH_ADDR_SIZE    : natural := 13+2;

  constant c_MAX_CHANNELS        : natural := 12;
  constant c_FIXED_POINT_POS_VAL : std_logic_vector(31 downto 0) :=
    std_logic_vector(to_unsigned(g_OUT_FIXED, 32));
  -----------------------------
  -- RAM signals
  -----------------------------
  signal coeff_ram_addr_arr      : t_arr_coeff_ram_addr(c_MAX_CHANNELS-1 downto 0);
  signal coeff_ram_data_arr      : t_arr_coeff_ram_data(c_MAX_CHANNELS-1 downto 0);

  -----------------------------
  -- Wishbone slave adapter signals/structures
  -----------------------------
  signal wb_slv_adp_out          : t_wishbone_master_out;
  signal wb_slv_adp_in           : t_wishbone_master_in;
  signal resized_addr            : std_logic_vector(c_WISHBONE_ADDRESS_WIDTH-1 downto 0);

  -- Extra Wishbone registering stage
  signal wb_slave_in             : t_wishbone_slave_in_array (0 downto 0);
  signal wb_slave_out            : t_wishbone_slave_out_array(0 downto 0);
  signal wb_slave_in_reg0        : t_wishbone_slave_in_array (0 downto 0);
  signal wb_slave_out_reg0       : t_wishbone_slave_out_array(0 downto 0);

begin

  cmp_fofb_processing_interface: fofb_processing
    generic map(
      -- Width for inputs x and y
      g_A_WIDTH                    => g_A_WIDTH,
      -- Width for dcc addr
      g_ID_WIDTH                   => g_ID_WIDTH,
      -- Width for ram data
      g_B_WIDTH                    => g_B_WIDTH,
      -- Width for ram addr
      g_K_WIDTH                    => g_K_WIDTH,
      -- Width for output c
      g_C_WIDTH                    => g_C_WIDTH,
      -- Fixed point representation for output
      g_OUT_FIXED                  => g_OUT_FIXED,
      -- Extra bits for accumulator
      g_EXTRA_WIDTH                => g_EXTRA_WIDTH,
      -- Number of channels
      g_CHANNELS                   => g_CHANNELS,

      g_ANTI_WINDUP_UPPER_LIMIT    => g_ANTI_WINDUP_UPPER_LIMIT,  -- anti-windup upper limit
      g_ANTI_WINDUP_LOWER_LIMIT    => g_ANTI_WINDUP_LOWER_LIMIT   -- anti-windup lower limit
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

      -- RAM interfaces
      coeff_ram_addr_arr_o         => coeff_ram_addr_arr,
      coeff_ram_data_arr_i         => coeff_ram_data_arr,

      -- Setpoints
      sp_arr_o                     => sp_arr_o,
      sp_valid_arr_o               => sp_valid_arr_o
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

  cmp_wb_fofb_processing_regs: wb_fofb_processing_regs
    port map (
      rst_n_i                                     => rst_sys_n_i,
      clk_sys_i                                   => clk_sys_i,

      wb_adr_i                                    => wb_slv_adp_out.adr(12 downto 0),
      wb_dat_i                                    => wb_slv_adp_out.dat(31 downto 0),
      wb_dat_o                                    => wb_slv_adp_in.dat(31 downto 0),
      wb_cyc_i                                    => wb_slv_adp_out.cyc,
      wb_sel_i                                    => wb_slv_adp_out.sel(3 downto 0),
      wb_stb_i                                    => wb_slv_adp_out.stb,
      wb_we_i                                     => wb_slv_adp_out.we,
      wb_ack_o                                    => wb_slv_adp_in.ack,
      wb_stall_o                                  => wb_slv_adp_in.stall,

      wb_fofb_processing_regs_clk_i               => clk_i,

      -- Port for asynchronous (clock: wb_fofb_processing_regs_clk_i) std_logic_vector field: 'fixed-point position constant value' in reg: 'fixed-point position constant register'
      wb_fofb_processing_regs_fixed_point_pos_val_i
                                                 => c_FIXED_POINT_POS_VAL,

      -- RAM bank 0
      -- Ports for RAM: FOFB PROCESSING RAM for register map
      wb_fofb_processing_regs_ram_bank_0_addr_i  => coeff_ram_addr_arr(0),
      -- Read data output
      wb_fofb_processing_regs_ram_bank_0_data_o  => coeff_ram_data_arr(0),
      -- Read strobe input (active high)
      wb_fofb_processing_regs_ram_bank_0_rd_i    => '0',
      -- Write data input
      wb_fofb_processing_regs_ram_bank_0_data_i  => (others => '0'),
      -- Write strobe (active high)
      wb_fofb_processing_regs_ram_bank_0_wr_i    => '0',

      -- RAM bank 1
      -- Ports for RAM: FOFB PROCESSING RAM for register map
      wb_fofb_processing_regs_ram_bank_1_addr_i  => coeff_ram_addr_arr(1),
      -- Read data output
      wb_fofb_processing_regs_ram_bank_1_data_o  => coeff_ram_data_arr(1),
      -- Read strobe input (active high)
      wb_fofb_processing_regs_ram_bank_1_rd_i    => '0',
      -- Write data input
      wb_fofb_processing_regs_ram_bank_1_data_i  => (others => '0'),
      -- Write strobe (active high)
      wb_fofb_processing_regs_ram_bank_1_wr_i    => '0',

      -- RAM bank 2
      -- Ports for RAM: FOFB PROCESSING RAM for register map
      wb_fofb_processing_regs_ram_bank_2_addr_i  => coeff_ram_addr_arr(2),
      -- Read data output
      wb_fofb_processing_regs_ram_bank_2_data_o  => coeff_ram_data_arr(2),
      -- Read strobe input (active high)
      wb_fofb_processing_regs_ram_bank_2_rd_i    => '0',
      -- Write data input
      wb_fofb_processing_regs_ram_bank_2_data_i  => (others => '0'),
      -- Write strobe (active high)
      wb_fofb_processing_regs_ram_bank_2_wr_i    => '0',

      -- RAM bank 3
      -- Ports for RAM: FOFB PROCESSING RAM for register map
      wb_fofb_processing_regs_ram_bank_3_addr_i  => coeff_ram_addr_arr(3),
      -- Read data output
      wb_fofb_processing_regs_ram_bank_3_data_o  => coeff_ram_data_arr(3),
      -- Read strobe input (active high)
      wb_fofb_processing_regs_ram_bank_3_rd_i    => '0',
      -- Write data input
      wb_fofb_processing_regs_ram_bank_3_data_i  => (others => '0'),
      -- Write strobe (active high)
      wb_fofb_processing_regs_ram_bank_3_wr_i    => '0',

      -- RAM bank 4
      -- Ports for RAM: FOFB PROCESSING RAM for register map
      wb_fofb_processing_regs_ram_bank_4_addr_i  => coeff_ram_addr_arr(4),
      -- Read data output
      wb_fofb_processing_regs_ram_bank_4_data_o  => coeff_ram_data_arr(4),
      -- Read strobe input (active high)
      wb_fofb_processing_regs_ram_bank_4_rd_i    => '0',
      -- Write data input
      wb_fofb_processing_regs_ram_bank_4_data_i  => (others => '0'),
      -- Write strobe (active high)
      wb_fofb_processing_regs_ram_bank_4_wr_i    => '0',

      -- RAM bank 5
      -- Ports for RAM: FOFB PROCESSING RAM for register map
      wb_fofb_processing_regs_ram_bank_5_addr_i  => coeff_ram_addr_arr(5),
      -- Read data output
      wb_fofb_processing_regs_ram_bank_5_data_o  => coeff_ram_data_arr(5),
      -- Read strobe input (active high)
      wb_fofb_processing_regs_ram_bank_5_rd_i    => '0',
      -- Write data input
      wb_fofb_processing_regs_ram_bank_5_data_i  => (others => '0'),
      -- Write strobe (active high)
      wb_fofb_processing_regs_ram_bank_5_wr_i    => '0',

      -- RAM bank 6
      -- Ports for RAM: FOFB PROCESSING RAM for register map
      wb_fofb_processing_regs_ram_bank_6_addr_i  => coeff_ram_addr_arr(6),
      -- Read data output
      wb_fofb_processing_regs_ram_bank_6_data_o  => coeff_ram_data_arr(6),
      -- Read strobe input (active high)
      wb_fofb_processing_regs_ram_bank_6_rd_i    => '0',
      -- Write data input
      wb_fofb_processing_regs_ram_bank_6_data_i  => (others => '0'),
      -- Write strobe (active high)
      wb_fofb_processing_regs_ram_bank_6_wr_i    => '0',

      -- RAM bank 7
      -- Ports for RAM: FOFB PROCESSING RAM for register map
      wb_fofb_processing_regs_ram_bank_7_addr_i  => coeff_ram_addr_arr(7),
      -- Read data output
      wb_fofb_processing_regs_ram_bank_7_data_o  => coeff_ram_data_arr(7),
      -- Read strobe input (active high)
      wb_fofb_processing_regs_ram_bank_7_rd_i    => '0',
      -- Write data input
      wb_fofb_processing_regs_ram_bank_7_data_i  => (others => '0'),
      -- Write strobe (active high)
      wb_fofb_processing_regs_ram_bank_7_wr_i    => '0',

      -- RAM bank 8
      -- Ports for RAM: FOFB PROCESSING RAM for register map
      wb_fofb_processing_regs_ram_bank_8_addr_i  => coeff_ram_addr_arr(8),
      -- Read data output
      wb_fofb_processing_regs_ram_bank_8_data_o  => coeff_ram_data_arr(8),
      -- Read strobe input (active high)
      wb_fofb_processing_regs_ram_bank_8_rd_i    => '0',
      -- Write data input
      wb_fofb_processing_regs_ram_bank_8_data_i  => (others => '0'),
      -- Write strobe (active high)
      wb_fofb_processing_regs_ram_bank_8_wr_i    => '0',

      -- RAM bank 9
      -- Ports for RAM: FOFB PROCESSING RAM for register map
      wb_fofb_processing_regs_ram_bank_9_addr_i  => coeff_ram_addr_arr(9),
      -- Read data output
      wb_fofb_processing_regs_ram_bank_9_data_o  => coeff_ram_data_arr(9),
      -- Read strobe input (active high)
      wb_fofb_processing_regs_ram_bank_9_rd_i    => '0',
      -- Write data input
      wb_fofb_processing_regs_ram_bank_9_data_i  => (others => '0'),
      -- Write strobe (active high)
      wb_fofb_processing_regs_ram_bank_9_wr_i    => '0',

      -- RAM bank 10
      -- Ports for RAM: FOFB PROCESSING RAM for register map
      wb_fofb_processing_regs_ram_bank_10_addr_i  => coeff_ram_addr_arr(10),
      -- Read data output
      wb_fofb_processing_regs_ram_bank_10_data_o  => coeff_ram_data_arr(10),
      -- Read strobe input (active high)
      wb_fofb_processing_regs_ram_bank_10_rd_i    => '0',
      -- Write data input
      wb_fofb_processing_regs_ram_bank_10_data_i  => (others => '0'),
      -- Write strobe (active high)
      wb_fofb_processing_regs_ram_bank_10_wr_i    => '0',

      -- RAM bank 11
      -- Ports for RAM: FOFB PROCESSING RAM for register map
      wb_fofb_processing_regs_ram_bank_11_addr_i  => coeff_ram_addr_arr(11),
      -- Read data output
      wb_fofb_processing_regs_ram_bank_11_data_o  => coeff_ram_data_arr(11),
      -- Read strobe input (active high)
      wb_fofb_processing_regs_ram_bank_11_rd_i    => '0',
      -- Write data input
      wb_fofb_processing_regs_ram_bank_11_data_i  => (others => '0'),
      -- Write strobe (active high)
      wb_fofb_processing_regs_ram_bank_11_wr_i    => '0'
    );

end architecture rtl;

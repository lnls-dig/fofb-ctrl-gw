--------------------------------------------------------------------------------
-- Title      : Wrapper for FOFB system identification cores
-- Project    : fofb-ctrl-gw
--------------------------------------------------------------------------------
-- File       : xwb_fofb_sys_id.vhd
-- Author     : Guilherme Ricioli <guilherme.riciolic@gmail.com>
-- Company    : CNPEM, LNLS - GIE
-- Platform   : Generic
-- Standard   : VHDL'08
--------------------------------------------------------------------------------
-- Description: Instantiates FOFB system identification cores and exposes some
--              of their signals on a wishbone bus.
--------------------------------------------------------------------------------
-- Copyright (c) 2023 CNPEM
-- Licensed under GNU Lesser General Public License (LGPL) v3.0
--------------------------------------------------------------------------------
-- Revisions  :
-- Date         Version  Author              Description
-- 2023-04-04   1.0      guilherme.ricioli   Created
-- 2023-05-03   1.1      guilherme.ricioli   Add PRBS distortion machinery
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

library work;
use work.wishbone_pkg.all;
use work.fofb_sys_id_pkg.all;
use work.fofb_ctrl_pkg.all;

entity xwb_fofb_sys_id is
  generic (
    -- Width of BPM position indexes
    g_BPM_POS_INDEX_WIDTH         : natural := 9;

    -- Maximum number of BPM positions to flatenize per flatenizer
    g_MAX_NUM_BPM_POS_PER_FLAT    : natural := c_MAX_NUM_P2P_BPM_POS/2;

    -- Number of channels
    g_CHANNELS                    : natural := 12;

    -- Wishbone generics
    g_INTERFACE_MODE              : t_wishbone_interface_mode := CLASSIC;
    g_ADDRESS_GRANULARITY         : t_wishbone_address_granularity := WORD;
    g_WITH_EXTRA_WB_REG           : boolean := false
  );
  port (
    -- Clock
    clk_i                         : in std_logic;

    -- Reset
    rst_n_i                       : in std_logic;

    -- BPM position
    bpm_pos_i                     : in  signed(c_BPM_POS_WIDTH-1 downto 0);

    -- BPM position index
    bpm_pos_index_i               : in unsigned(g_BPM_POS_INDEX_WIDTH-1 downto 0);

    -- BPM position valid
    bpm_pos_valid_i               : in std_logic;

    -- BPM positions flatenizers clear
    -- This clears the stored BPM positions (both undistorted and distorted).
    bpm_pos_flat_clear_i          : in std_logic;

    -- Setpoints array
    sp_arr_i                      : in t_sp_arr(g_CHANNELS-1 downto 0);

    -- Setpoints valid array
    sp_valid_arr_i                : in std_logic_vector(g_CHANNELS-1 downto 0);

    -- PRBS iteration signal
    prbs_valid_i                  : in std_logic;

    -- External trigger
    -- A pulse on this effectivates what was set via Wishbone on PRBS_CTL_RST,
    -- PRBS_CTL_BPM_POS_DISTORT_EN and PRBS_CTL_SP_DISTORT_EN.
    trig_i                        : in std_logic;

    -- BPM positions flatenized (instance x)
    bpm_pos_flat_x_o              : out t_bpm_pos_arr(g_MAX_NUM_BPM_POS_PER_FLAT-1 downto 0);

    -- Each bit indicates if the corresponding BPM position was received since
    -- the last clearing (or resetting). This is useful for debugging. (instance x)
    bpm_pos_flat_x_rcvd_o         : out std_logic_vector(g_MAX_NUM_BPM_POS_PER_FLAT-1 downto 0);

    -- BPM positions flatenized (instance y)
    bpm_pos_flat_y_o              : out t_bpm_pos_arr(g_MAX_NUM_BPM_POS_PER_FLAT-1 downto 0);

    -- Each bit indicates if the corresponding BPM position was received since
    -- the last clearing (or resetting). This is useful for debugging. (instance y)
    bpm_pos_flat_y_rcvd_o         : out std_logic_vector(g_MAX_NUM_BPM_POS_PER_FLAT-1 downto 0);

    -- Distorted BPM position
    distort_bpm_pos_o             : out signed(c_BPM_POS_WIDTH-1 downto 0);

    -- Distorted BPM position index (same as bpm_pos_index_i)
    distort_bpm_pos_index_o       : out unsigned(g_BPM_POS_INDEX_WIDTH-1 downto 0);

    -- Distorted BPM position valid
    distort_bpm_pos_valid_o       : out std_logic;

    -- Distorted setpoints array
    distort_sp_arr_o              : out t_sp_arr(g_CHANNELS-1 downto 0);

    -- Distorted setpoints valid array
    distort_sp_valid_arr_o        : out std_logic_vector(g_CHANNELS-1 downto 0);

    -- PRBS signal for debug
    prbs_o                        : out std_logic;

    -- PRBS valid signal for debug
    prbs_valid_o                  : out std_logic;

    -- Distorted BPM positions flatenized (instance x)
    distort_bpm_pos_flat_x_o      : out t_bpm_pos_arr(g_MAX_NUM_BPM_POS_PER_FLAT-1 downto 0);

    -- Each bit indicates if the corresponding BPM position was received since
    -- the last clearing (or resetting). This is useful for debugging. (instance x)
    distort_bpm_pos_flat_x_rcvd_o : out std_logic_vector(g_MAX_NUM_BPM_POS_PER_FLAT-1 downto 0);

    -- Distorted BPM positions flatenized (instance y)
    distort_bpm_pos_flat_y_o      : out t_bpm_pos_arr(g_MAX_NUM_BPM_POS_PER_FLAT-1 downto 0);

    -- Each bit indicates if the corresponding BPM position was received since
    -- the last clearing (or resetting). This is useful for debugging. (instance y)
    distort_bpm_pos_flat_y_rcvd_o : out std_logic_vector(g_MAX_NUM_BPM_POS_PER_FLAT-1 downto 0);

    -- Wishbone interface
    wb_slv_i                      : in t_wishbone_slave_in;
    wb_slv_o                      : out t_wishbone_slave_out
  );
end xwb_fofb_sys_id;

architecture beh of xwb_fofb_sys_id is

  -- Number of bits in Wishbone register interface; plus 2 to account for BYTE addressing.
  constant c_PERIPH_ADDR_SIZE    : natural := 2+2;

  constant c_MAX_CHANNELS        : natural := 12;
  constant c_DISTORT_LEVEL_WIDTH : natural := 16;

  type t_prbs_distort_levels is record
    level_0 : signed(c_DISTORT_LEVEL_WIDTH-1 downto 0);
    level_1 : signed(c_DISTORT_LEVEL_WIDTH-1 downto 0);
  end record;
  type t_prbs_distort_levels_arr is array(natural range <>) of t_prbs_distort_levels;
  signal prbs_distort_levels: t_prbs_distort_levels_arr(11 downto 0) :=
    (others => (
      level_0 => (others => '0'),
      level_1 => (others => '0')
    ));

  constant c_DISTORT_LEVELS_ZEROED  : t_prbs_distort_levels :=
    (level_0 => (others => '0'), level_1 => (others => '0'));

  signal prbs_rst_n                   : std_logic := '1';
  signal prbs_step_duration           : natural range 1 to 1024 := 1;
  signal prbs_lfsr_length             : natural range 2 to 32 := 2;
  signal prbs_bpm_pos_distort_en      : std_logic := '0';
  signal prbs_sp_distort_en           : std_logic := '0';
  signal prbs_bpm_pos_distort_levels  : t_prbs_distort_levels := c_DISTORT_LEVELS_ZEROED;
  signal prbs_sp_distort_levels_arr   : t_prbs_distort_levels_arr(c_MAX_CHANNELS-1 downto 0) := (others => c_DISTORT_LEVELS_ZEROED);
  signal bpm_pos_d1                   : signed(c_BPM_POS_WIDTH-1 downto 0);
  signal bpm_pos_index_d1             : unsigned(g_BPM_POS_INDEX_WIDTH-1 downto 0);
  signal bpm_pos_valid_d1             : std_logic := '0';
  signal distort_bpm_pos              : signed(c_BPM_POS_WIDTH-1 downto 0);
  signal distort_bpm_pos_index        : unsigned(g_BPM_POS_INDEX_WIDTH-1 downto 0);
  signal distort_bpm_pos_valid        : std_logic := '0';

  signal bpm_pos_flatenizer_ctl_base_bpm_id           : std_logic_vector(7 downto 0) := (others => '0');
  signal prbs_ctl_rst                                 : std_logic := '0';
  signal prbs_ctl_step_duration                       : std_logic_vector(9 downto 0) := (others => '0');
  signal prbs_ctl_lfsr_length                         : std_logic_vector(4 downto 0) := (others => '0');
  signal prbs_ctl_bpm_pos_distort_en                  : std_logic := '0';
  signal prbs_ctl_sp_distort_en                       : std_logic := '0';

  -- Wishbone signals
  signal wb_slv_adp_out          : t_wishbone_master_out;
  signal wb_slv_adp_in           : t_wishbone_master_in;
  signal resized_addr            : std_logic_vector(c_WISHBONE_ADDRESS_WIDTH-1 downto 0);

  -- Extra wishbone registering stage signals
  signal wb_slave_in             : t_wishbone_slave_in_array(0 downto 0);
  signal wb_slave_out            : t_wishbone_slave_out_array(0 downto 0);
  signal wb_slave_in_reg0        : t_wishbone_slave_in_array(0 downto 0);
  signal wb_slave_out_reg0       : t_wishbone_slave_out_array(0 downto 0);

begin

  process(clk_i) is
  begin
    if rising_edge(clk_i) then
      -- Compensating the BPM positions distortion RAM access delay
      bpm_pos_d1 <= bpm_pos_i;
      bpm_pos_index_d1 <= bpm_pos_index_i;
      bpm_pos_valid_d1 <= bpm_pos_valid_i;

      -- Effectivates what was set via Wishbone on PRBS_CTL_RST,
      -- PRBS_CTL_BPM_POS_DISTORT_EN and PRBS_CTL_SP_DISTORT_EN.
      -- NOTE: PRBS_CTL_RST = '1' generates a reset pulse
      prbs_rst_n <= '1';
      if trig_i = '1' then
        prbs_rst_n <= not prbs_ctl_rst;
        prbs_bpm_pos_distort_en <= prbs_ctl_bpm_pos_distort_en;
        prbs_sp_distort_en <= prbs_ctl_sp_distort_en;
      end if;
    end if;
  end process;

  -- BPM positions x flatenizer
  cmp_x_bpm_pos_flatenizer : bpm_pos_flatenizer
    generic map (
      g_BPM_POS_INDEX_WIDTH => g_BPM_POS_INDEX_WIDTH,
      g_MAX_NUM_BPM_POS     => g_MAX_NUM_BPM_POS_PER_FLAT
    )
    port map (
      clk_i                 => clk_i,
      rst_n_i               => rst_n_i,
      clear_i               => bpm_pos_flat_clear_i,
      -- The associated index is the same as the DCC packet BPM ID which
      -- contains it (ranges from 0 to 255).
      bpm_pos_base_index_i  => '0' & unsigned(bpm_pos_flatenizer_ctl_base_bpm_id),
      bpm_pos_index_i       => bpm_pos_index_i,
      bpm_pos_i             => bpm_pos_i,
      bpm_pos_valid_i       => bpm_pos_valid_i,
      bpm_pos_flat_o        => bpm_pos_flat_x_o,
      bpm_pos_flat_rcvd_o   => bpm_pos_flat_x_rcvd_o
    );

  -- BPM positions y flatenizer
  cmp_y_bpm_pos_flatenizer : bpm_pos_flatenizer
    generic map (
      g_BPM_POS_INDEX_WIDTH => g_BPM_POS_INDEX_WIDTH,
      g_MAX_NUM_BPM_POS     => g_MAX_NUM_BPM_POS_PER_FLAT
    )
    port map (
      clk_i                 => clk_i,
      rst_n_i               => rst_n_i,
      clear_i               => bpm_pos_flat_clear_i,
      -- The associated index is the same as the DCC packet BPM ID which
      -- contains it + 256 (ranges from 256 to 511).
      bpm_pos_base_index_i  => '1' & unsigned(bpm_pos_flatenizer_ctl_base_bpm_id),
      bpm_pos_index_i       => bpm_pos_index_i,
      bpm_pos_i             => bpm_pos_i,
      bpm_pos_valid_i       => bpm_pos_valid_i,
      bpm_pos_flat_o        => bpm_pos_flat_y_o,
      bpm_pos_flat_rcvd_o   => bpm_pos_flat_y_rcvd_o
    );

  -- PRBS distortion for BPM positions
  cmp_prbs_bpm_pos_distort : prbs_bpm_pos_distort
    generic map (
      g_BPM_POS_INDEX_WIDTH   => g_BPM_POS_INDEX_WIDTH,
      g_BPM_POS_WIDTH         => c_BPM_POS_WIDTH,
      g_DISTORT_LEVEL_WIDTH   => c_DISTORT_LEVEL_WIDTH
    )
    port map (
      clk_i                   => clk_i,
      rst_n_i                 => rst_n_i,
      en_distort_i            => prbs_bpm_pos_distort_en,
      prbs_rst_n_i            => prbs_rst_n,
      prbs_step_duration_i    => prbs_step_duration,
      prbs_lfsr_length_i      => prbs_lfsr_length,
      prbs_valid_i            => prbs_valid_i,
      bpm_pos_index_i         => bpm_pos_index_d1,
      bpm_pos_i               => bpm_pos_d1,
      bpm_pos_valid_i         => bpm_pos_valid_d1,
      distort_level_0_i       => prbs_bpm_pos_distort_levels.level_0,
      distort_level_1_i       => prbs_bpm_pos_distort_levels.level_1,
      distort_bpm_pos_index_o => distort_bpm_pos_index,
      distort_bpm_pos_o       => distort_bpm_pos,
      distort_bpm_pos_valid_o => distort_bpm_pos_valid,
      prbs_o                  => prbs_o,
      prbs_valid_o            => prbs_valid_o
    );

  -- PRBS distortion for setpoints
    gen_cmps_prbs_sp_distort :
      for ch in 0 to g_CHANNELS-1 generate
        cmp_prbs_sp_distort : prbs_sp_distort
          generic map (
            g_SP_WIDTH            => c_SP_WIDTH,
            g_DISTORT_LEVEL_WIDTH => c_DISTORT_LEVEL_WIDTH
          )
          port map (
            clk_i                 => clk_i,
            rst_n_i               => rst_n_i,
            en_distort_i          => prbs_sp_distort_en,
            prbs_rst_n_i          => prbs_rst_n,
            prbs_step_duration_i  => prbs_step_duration,
            prbs_lfsr_length_i    => prbs_lfsr_length,
            prbs_valid_i          => prbs_valid_i,
            sp_i                  => sp_arr_i(ch),
            sp_valid_i            => sp_valid_arr_i(ch),
            distort_level_0_i     => prbs_sp_distort_levels_arr(ch).level_0,
            distort_level_1_i     => prbs_sp_distort_levels_arr(ch).level_1,
            distort_sp_o          => distort_sp_arr_o(ch),
            distort_sp_valid_o    => distort_sp_valid_arr_o(ch),
            prbs_o                => open,  -- same as cmp_prbs_bpm_pos_distort's prbs_o
            prbs_valid_o          => open   -- same as cmp_prbs_bpm_pos_distort's prbs_valid_o
          );
      end generate;

  -- Distorted BPM positions x flatenizer
  cmp_x_distort_bpm_pos_flatenizer : bpm_pos_flatenizer
    generic map (
      g_BPM_POS_INDEX_WIDTH => g_BPM_POS_INDEX_WIDTH,
      g_MAX_NUM_BPM_POS     => g_MAX_NUM_BPM_POS_PER_FLAT
    )
    port map (
      clk_i                 => clk_i,
      rst_n_i               => rst_n_i,
      clear_i               => bpm_pos_flat_clear_i,
      -- The associated index is the same as the DCC packet BPM ID which
      -- contains it (ranges from 0 to 255).
      bpm_pos_base_index_i  => '0' & unsigned(bpm_pos_flatenizer_ctl_base_bpm_id),
      bpm_pos_index_i       => distort_bpm_pos_index,
      bpm_pos_i             => distort_bpm_pos,
      bpm_pos_valid_i       => distort_bpm_pos_valid,
      bpm_pos_flat_o        => distort_bpm_pos_flat_x_o,
      bpm_pos_flat_rcvd_o   => distort_bpm_pos_flat_x_rcvd_o
    );

  -- Distorted BPM positions y flatenizer
  cmp_y_distort_bpm_pos_flatenizer : bpm_pos_flatenizer
    generic map (
      g_BPM_POS_INDEX_WIDTH => g_BPM_POS_INDEX_WIDTH,
      g_MAX_NUM_BPM_POS     => g_MAX_NUM_BPM_POS_PER_FLAT
    )
    port map (
      clk_i                 => clk_i,
      rst_n_i               => rst_n_i,
      clear_i               => bpm_pos_flat_clear_i,
      -- The associated index is the same as the DCC packet BPM ID which
      -- contains it + 256 (ranges from 256 to 511).
      bpm_pos_base_index_i  => '1' & unsigned(bpm_pos_flatenizer_ctl_base_bpm_id),
      bpm_pos_index_i       => distort_bpm_pos_index,
      bpm_pos_i             => distort_bpm_pos,
      bpm_pos_valid_i       => distort_bpm_pos_valid,
      bpm_pos_flat_o        => distort_bpm_pos_flat_y_o,
      bpm_pos_flat_rcvd_o   => distort_bpm_pos_flat_y_rcvd_o
    );

  cmp_wb_fofb_sys_id_regs : entity work.wb_fofb_sys_id_regs
    port map (
      rst_n_i                                               => rst_n_i,
      clk_i                                                 => clk_i,
      wb_i                                                  => wb_slv_adp_out,
      wb_o                                                  => wb_slv_adp_in,
      bpm_pos_flatenizer_ctl_base_bpm_id_o                  => bpm_pos_flatenizer_ctl_base_bpm_id,
      bpm_pos_flatenizer_max_num_cte_i                      => std_logic_vector(to_unsigned(g_MAX_NUM_BPM_POS_PER_FLAT, 16)),
      prbs_ctl_rst_o                                        => prbs_ctl_rst,
      prbs_ctl_step_duration_o                              => prbs_ctl_step_duration,
      prbs_ctl_lfsr_length_o                                => prbs_ctl_lfsr_length,
      prbs_ctl_bpm_pos_distort_en_o                         => prbs_ctl_bpm_pos_distort_en,
      prbs_ctl_sp_distort_en_o                              => prbs_ctl_sp_distort_en,
      signed(prbs_sp_distort_ch_0_levels_level_0_o)         => prbs_sp_distort_levels_arr(0).level_0,
      signed(prbs_sp_distort_ch_0_levels_level_1_o)         => prbs_sp_distort_levels_arr(0).level_1,
      signed(prbs_sp_distort_ch_1_levels_level_0_o)         => prbs_sp_distort_levels_arr(1).level_0,
      signed(prbs_sp_distort_ch_1_levels_level_1_o)         => prbs_sp_distort_levels_arr(1).level_1,
      signed(prbs_sp_distort_ch_2_levels_level_0_o)         => prbs_sp_distort_levels_arr(2).level_0,
      signed(prbs_sp_distort_ch_2_levels_level_1_o)         => prbs_sp_distort_levels_arr(2).level_1,
      signed(prbs_sp_distort_ch_3_levels_level_0_o)         => prbs_sp_distort_levels_arr(3).level_0,
      signed(prbs_sp_distort_ch_3_levels_level_1_o)         => prbs_sp_distort_levels_arr(3).level_1,
      signed(prbs_sp_distort_ch_4_levels_level_0_o)         => prbs_sp_distort_levels_arr(4).level_0,
      signed(prbs_sp_distort_ch_4_levels_level_1_o)         => prbs_sp_distort_levels_arr(4).level_1,
      signed(prbs_sp_distort_ch_5_levels_level_0_o)         => prbs_sp_distort_levels_arr(5).level_0,
      signed(prbs_sp_distort_ch_5_levels_level_1_o)         => prbs_sp_distort_levels_arr(5).level_1,
      signed(prbs_sp_distort_ch_6_levels_level_0_o)         => prbs_sp_distort_levels_arr(6).level_0,
      signed(prbs_sp_distort_ch_6_levels_level_1_o)         => prbs_sp_distort_levels_arr(6).level_1,
      signed(prbs_sp_distort_ch_7_levels_level_0_o)         => prbs_sp_distort_levels_arr(7).level_0,
      signed(prbs_sp_distort_ch_7_levels_level_1_o)         => prbs_sp_distort_levels_arr(7).level_1,
      signed(prbs_sp_distort_ch_8_levels_level_0_o)         => prbs_sp_distort_levels_arr(8).level_0,
      signed(prbs_sp_distort_ch_8_levels_level_1_o)         => prbs_sp_distort_levels_arr(8).level_1,
      signed(prbs_sp_distort_ch_9_levels_level_0_o)         => prbs_sp_distort_levels_arr(9).level_0,
      signed(prbs_sp_distort_ch_9_levels_level_1_o)         => prbs_sp_distort_levels_arr(9).level_1,
      signed(prbs_sp_distort_ch_10_levels_level_0_o)        => prbs_sp_distort_levels_arr(10).level_0,
      signed(prbs_sp_distort_ch_10_levels_level_1_o)        => prbs_sp_distort_levels_arr(10).level_1,
      signed(prbs_sp_distort_ch_11_levels_level_0_o)        => prbs_sp_distort_levels_arr(11).level_0,
      signed(prbs_sp_distort_ch_11_levels_level_1_o)        => prbs_sp_distort_levels_arr(11).level_1,
      prbs_bpm_pos_distort_distort_ram_adr_i                => std_logic_vector(bpm_pos_index_i),
      prbs_bpm_pos_distort_distort_ram_levels_rd_i          => '1',
      signed(prbs_bpm_pos_distort_distort_ram_levels_dat_o(
        c_DISTORT_LEVEL_WIDTH-1 downto 0))                  => prbs_bpm_pos_distort_levels.level_0,
      signed(prbs_bpm_pos_distort_distort_ram_levels_dat_o(
        31 downto c_DISTORT_LEVEL_WIDTH))                   => prbs_bpm_pos_distort_levels.level_1
    );

  -- Extra wishbone registering stage for ease timing
  -- NOTE: It effectively cuts the bandwidth in half!
  gen_with_extra_wb_reg : if g_WITH_EXTRA_WB_REG generate
    cmp_register_link : xwb_register_link -- puts a register of delay between crossbars
      port map (
        clk_sys_i => clk_i,
        rst_n_i   => rst_n_i,
        slave_i   => wb_slave_in_reg0(0),
        slave_o   => wb_slave_out_reg0(0),
        master_i  => wb_slave_out(0),
        master_o  => wb_slave_in(0)
      );

      wb_slave_in_reg0(0) <= wb_slv_i;
      wb_slv_o            <= wb_slave_out_reg0(0);
    else generate
      -- External master connection
      wb_slave_in(0)      <= wb_slv_i;
      wb_slv_o            <= wb_slave_out(0);
    end generate;

  -- Wishbone slave adapter
  cmp_slave_adapter : wb_slave_adapter
    generic map (
      g_MASTER_USE_STRUCT   => true,
      g_MASTER_MODE         => PIPELINED,
      -- TODO: it seems that using cheby without wbgen compatibility requires
      -- g_MASTER_GRANULARITY to be byte
      g_MASTER_GRANULARITY  => BYTE,
      g_SLAVE_USE_STRUCT    => false,
      g_SLAVE_MODE          => g_INTERFACE_MODE,
      g_SLAVE_GRANULARITY   => g_ADDRESS_GRANULARITY
    )
    port map (
      clk_sys_i             => clk_i,
      rst_n_i               => rst_n_i,
      master_i              => wb_slv_adp_in,
      master_o              => wb_slv_adp_out,
      sl_adr_i              => resized_addr,
      sl_dat_i              => wb_slave_in(0).dat,
      sl_sel_i              => wb_slave_in(0).sel,
      sl_cyc_i              => wb_slave_in(0).cyc,
      sl_stb_i              => wb_slave_in(0).stb,
      sl_we_i               => wb_slave_in(0).we,
      sl_dat_o              => wb_slave_out(0).dat,
      sl_ack_o              => wb_slave_out(0).ack,
      sl_rty_o              => wb_slave_out(0).rty,
      sl_err_o              => wb_slave_out(0).err,
      sl_stall_o            => wb_slave_out(0).stall
    );

    gen_wb_slave_in_addr_conn : if g_ADDRESS_GRANULARITY = WORD generate
      -- By doing this zeroing we avoid the issue related to BYTE -> WORD
      -- conversion slave addressing (possibly performed by the slave adapter
      -- component) in which a bit in the MSB of the peripheral addressing part
      -- (31 downto c_PERIPH_ADDR_SIZE in our case) is shifted to the internal
      -- register adressing part (c_PERIPH_ADDR_SIZE-1 downto 0 in our case).
      -- Therefore, possibly changing the these bits!
      resized_addr(c_PERIPH_ADDR_SIZE-1 downto 0)
                                   <= wb_slave_in(0).adr(c_PERIPH_ADDR_SIZE-1 downto 0);
      resized_addr(c_WISHBONE_ADDRESS_WIDTH-1 downto c_PERIPH_ADDR_SIZE)
                                   <= (others => '0');
    else generate
      resized_addr <= wb_slave_in(0).adr;
    end generate;

  -- Decodes prbs_ctl_step_duration and prbs_ctl_lfsr_length
  prbs_step_duration <= to_integer(unsigned(prbs_ctl_step_duration)) + 1;
  prbs_lfsr_length <= to_integer(unsigned(prbs_ctl_lfsr_length)) + 2;

  distort_bpm_pos_o <= distort_bpm_pos;
  distort_bpm_pos_index_o <= distort_bpm_pos_index;
  distort_bpm_pos_valid_o <= distort_bpm_pos_valid;

end architecture beh;

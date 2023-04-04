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
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

library work;
use work.wishbone_pkg.all;
use work.dot_prod_pkg.all;
use work.fofb_sys_id_pkg.all;

entity xwb_fofb_sys_id is
  generic (
    -- Maximum number of BPM positions to flatenize
    g_MAX_NUM_BPM_POS     : natural range 1 to 2**(natural(c_SP_COEFF_RAM_ADDR_WIDTH)) := 16;

    -- Wishbone generics
    g_INTERFACE_MODE      : t_wishbone_interface_mode := CLASSIC;
    g_ADDRESS_GRANULARITY : t_wishbone_address_granularity := WORD;
    g_WITH_EXTRA_WB_REG   : boolean := false
  );
  port (
    -- Clock
    clk_i                 : in  std_logic;

    -- Reset
    rst_n_i               : in  std_logic;

    -- BPM position
    bpm_pos_i             : in  signed(c_SP_POS_RAM_DATA_WIDTH-1 downto 0);

    -- BPM position index
    bpm_pos_index_i       : in  unsigned(c_SP_COEFF_RAM_ADDR_WIDTH-1 downto 0);

    -- BPM position valid
    bpm_pos_valid_i       : in  std_logic;

    -- BPM flatenized positions clear
    -- This clears the stored BPM positions.
    bpm_pos_flat_clear_i  : in  std_logic;

    -- BPM positions flatenized (instance x)
    bpm_pos_flat_x_o      : out t_bpm_pos_arr(g_MAX_NUM_BPM_POS-1 downto 0);

    -- Each bit indicates if the corresponding BPM position was received since
    -- the last clearing (or resetting). This is useful for debugging. (instance x)
    bpm_pos_flat_x_rcvd_o : out std_logic_vector(g_MAX_NUM_BPM_POS-1 downto 0);

    -- BPM positions flatenized (instance y)
    bpm_pos_flat_y_o      : out t_bpm_pos_arr(g_MAX_NUM_BPM_POS-1 downto 0);

    -- Each bit indicates if the corresponding BPM position was received since
    -- the last clearing (or resetting). This is useful for debugging. (instance y)
    bpm_pos_flat_y_rcvd_o : out std_logic_vector(g_MAX_NUM_BPM_POS-1 downto 0);

    -- Wishbone interface
    wb_slv_i              : in t_wishbone_slave_in;
    wb_slv_o              : out t_wishbone_slave_out
  );
end xwb_fofb_sys_id;

architecture beh of xwb_fofb_sys_id is

  -- Number of bits in Wishbone register interface; plus 2 to account for BYTE addressing.
  constant c_PERIPH_ADDR_SIZE    : natural := 2+2;

  signal bpm_pos_flatenizer_base_bpm_id : std_logic_vector(7 downto 0);

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
  -- BPM positions x flatenizer
  cmp_x_bpm_pos_flatenizer : bpm_pos_flatenizer
    generic map (
      g_MAX_NUM_BPM_POS     => g_MAX_NUM_BPM_POS
    )
    port map (
      clk_i                 => clk_i,
      rst_n_i               => rst_n_i,
      clear_i               => bpm_pos_flat_clear_i,
      -- The associated index is the same as the DCC packet BPM ID which
      -- contains it (ranges from 0 to 255).
      bpm_pos_base_index_i  => '0' & unsigned(bpm_pos_flatenizer_base_bpm_id),
      bpm_pos_index_i       => bpm_pos_index_i,
      bpm_pos_i             => bpm_pos_i,
      bpm_pos_valid_i       => bpm_pos_valid_i,
      bpm_pos_flat_o        => bpm_pos_flat_x_o,
      bpm_pos_flat_rcvd_o   => bpm_pos_flat_x_rcvd_o
    );

  -- BPM positions y flatenizer
  cmp_y_bpm_pos_flatenizer : bpm_pos_flatenizer
    generic map (
      g_MAX_NUM_BPM_POS     => g_MAX_NUM_BPM_POS
    )
    port map (
      clk_i                 => clk_i,
      rst_n_i               => rst_n_i,
      clear_i               => bpm_pos_flat_clear_i,
      -- The associated index is the same as the DCC packet BPM ID which
      -- contains it + 256 (ranges from 256 to 511).
      bpm_pos_base_index_i  => '1' & unsigned(bpm_pos_flatenizer_base_bpm_id),
      bpm_pos_index_i       => bpm_pos_index_i,
      bpm_pos_i             => bpm_pos_i,
      bpm_pos_valid_i       => bpm_pos_valid_i,
      bpm_pos_flat_o        => bpm_pos_flat_y_o,
      bpm_pos_flat_rcvd_o   => bpm_pos_flat_y_rcvd_o
    );

  cmp_wb_fofb_sys_id_regs : entity work.wb_fofb_sys_id_regs
    port map (
      rst_n_i                           => rst_n_i,
      clk_i                             => clk_i,
      wb_i                              => wb_slv_adp_out,
      wb_o                              => wb_slv_adp_in,
      bpm_pos_flatenizer_max_num_cte_i  => std_logic_vector(to_unsigned(g_MAX_NUM_BPM_POS, 16)),
      bpm_pos_flatenizer_base_bpm_id_o  => bpm_pos_flatenizer_base_bpm_id
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

end architecture beh;

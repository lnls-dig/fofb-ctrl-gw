--------------------------------------------------------------------------------
-- Title      : BPM positions flatenizer
-- Project    : fofb-ctrl-gw
--------------------------------------------------------------------------------
-- File       : bpm_pos_flatenizer.vhd
-- Author     : Guilherme Ricioli <guilherme.riciolic@gmail.com>
-- Company    : CNPEM, LNLS - GIE
-- Platform   : Generic
-- Standard   : VHDL'08
--------------------------------------------------------------------------------
-- Description: Stores serialized BPM positions and exposes a flat interface to
--              access'em.
--------------------------------------------------------------------------------
-- Copyright (c) 2023 CNPEM
-- Licensed under GNU Lesser General Public License (LGPL) v3.0
--------------------------------------------------------------------------------
-- Revisions  :
-- Date         Version  Author              Description
-- 2023-03-31   1.0      guilherme.ricioli   Created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fofb_sys_id_pkg.all;

entity bpm_pos_flatenizer is
  generic (
    -- Width of BPM position indexes
    g_BPM_POS_INDEX_WIDTH : natural := 9;

    -- Maximum number of BPM positions to flatenize
    g_MAX_NUM_BPM_POS     : natural := c_MAX_NUM_P2P_BPM_POS/2
  );
  port (
    -- Clock
    clk_i                 : in std_logic;

    -- Reset
    rst_n_i               : in std_logic;

    -- Clear
    -- This clears the stored BPM positions.
    clear_i               : in std_logic;

    -- BPM position base index
    -- This, togheter with 'g_MAX_NUM_BPM_POS', defines the valid range of
    -- indexes:
    -- ['bpm_pos_base_index_i', 'bpm_pos_base_index_i' + 'g_MAX_NUM_BPM_POS').
    -- NOTE: Changing this will clear the stored BPM positions.
    bpm_pos_base_index_i  : in unsigned(g_BPM_POS_INDEX_WIDTH-1 downto 0);

    -- BPM position index
    bpm_pos_index_i       : in unsigned(g_BPM_POS_INDEX_WIDTH-1 downto 0);

    -- BPM position
    bpm_pos_i             : in signed(c_BPM_POS_WIDTH-1 downto 0);

    -- BPM position valid
    bpm_pos_valid_i       : in std_logic;

    -- BPM positions flatenized
    -- 'bpm_pos_flat_o(0)' -> BPM position index 'bpm_pos_base_index_i'
    -- 'bpm_pos_flat_o(1)' -> BPM position index 'bpm_pos_base_index_i' + 1
    -- ..., and so on
    bpm_pos_flat_o        : out t_bpm_pos_arr(g_MAX_NUM_BPM_POS-1 downto 0) := (others => (others => '0'));

    -- Each bit indicates if the corresponding BPM position was received since
    -- the last clearing (or resetting). This is useful for debugging.
    bpm_pos_flat_rcvd_o   : out std_logic_vector(g_MAX_NUM_BPM_POS-1 downto 0) := (others => '0')
  );
end entity bpm_pos_flatenizer;

architecture beh of bpm_pos_flatenizer is
  signal bpm_pos_flat : t_bpm_pos_arr(g_MAX_NUM_BPM_POS-1 downto 0) := (others => (others => '0'));
  signal bpm_pos_flat_rcvd : std_logic_vector(g_MAX_NUM_BPM_POS-1 downto 0) := (others => '0');
  signal bpm_pos_base_index_d1 : unsigned(g_BPM_POS_INDEX_WIDTH-1 downto 0) := (others => '0');
begin

  process(clk_i) is
    variable v_bpm_pos_rel_index : integer := 0;
  begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' or
        bpm_pos_base_index_i /= bpm_pos_base_index_d1 or
        clear_i = '1' then
          bpm_pos_flat <= (others => (others => '0'));
          bpm_pos_flat_rcvd <= (others => '0');
      else
        if bpm_pos_valid_i = '1' then
          v_bpm_pos_rel_index := to_integer(bpm_pos_index_i) -
                                 to_integer(bpm_pos_base_index_i);

          -- Checks if BPM position index is within valid range
          if v_bpm_pos_rel_index >= 0 and
            v_bpm_pos_rel_index < g_MAX_NUM_BPM_POS then
              bpm_pos_flat(v_bpm_pos_rel_index) <= bpm_pos_i;
              bpm_pos_flat_rcvd(v_bpm_pos_rel_index) <= '1';
          end if;
        end if;
      end if;

      -- Registers bpm_pos_base_index_i so to check if it changes
      bpm_pos_base_index_d1 <= bpm_pos_base_index_i;
    end if;
  end process;

  bpm_pos_flat_o <= bpm_pos_flat;
  bpm_pos_flat_rcvd_o <= bpm_pos_flat_rcvd;

end architecture beh;

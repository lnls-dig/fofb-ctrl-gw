--------------------------------------------------------------------------------
-- Title      : FOFB system identification package
-- Project    : fofb-ctrl-gw
--------------------------------------------------------------------------------
-- File       : fofb_sys_id_pkg.vhd
-- Author     : Guilherme Ricioli <guilherme.riciolic@gmail.com>
-- Company    : CNPEM, LNLS - GIE
-- Platform   : Generic
-- Standard   : VHDL'08
--------------------------------------------------------------------------------
-- Description: Package for FOFB system identification stuff.
--------------------------------------------------------------------------------
-- Copyright (c) 2023 CNPEM
-- Licensed under GNU Lesser General Public License (LGPL) v3.0
--------------------------------------------------------------------------------
-- Revisions  :
-- Date         Version  Author              Description
-- 2023-03-30   1.0      guilherme.ricioli   Created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.dot_prod_pkg.all;

package fofb_sys_id_pkg is

  constant c_MAX_NUM_P2P_BPM_POS : natural := 16;

  constant c_BPM_POS_WIDTH       : natural := c_SP_POS_RAM_DATA_WIDTH;
  type t_bpm_pos_arr is array (natural range <>) of signed(c_BPM_POS_WIDTH-1 downto 0);

  function f_signed_saturate(x : signed; trunc_x_len : natural) return signed;

  component bpm_pos_flatenizer is
    generic (
      g_BPM_POS_INDEX_WIDTH : natural := 9;
      g_MAX_NUM_BPM_POS     : natural := c_MAX_NUM_P2P_BPM_POS/2
    );
    port (
      clk_i                 : in std_logic;
      rst_n_i               : in std_logic;
      clear_i               : in std_logic;
      bpm_pos_base_index_i  : in unsigned(g_BPM_POS_INDEX_WIDTH-1 downto 0);
      bpm_pos_index_i       : in unsigned(g_BPM_POS_INDEX_WIDTH-1 downto 0);
      bpm_pos_i             : in signed(c_BPM_POS_WIDTH-1 downto 0);
      bpm_pos_valid_i       : in std_logic;
      bpm_pos_flat_o        : out t_bpm_pos_arr(g_MAX_NUM_BPM_POS-1 downto 0) := (others => (others => '0'));
      bpm_pos_flat_rcvd_o   : out std_logic_vector(g_MAX_NUM_BPM_POS-1 downto 0) := (others => '0')
    );
  end component bpm_pos_flatenizer;

  component prbs_bpm_pos_distort is
    generic (
      g_BPM_POS_INDEX_WIDTH   : natural := 9;
      g_BPM_POS_WIDTH         : natural := 32;
      g_DISTORT_LEVEL_WIDTH   : natural := 16
    );
    port (
      clk_i                   : in std_logic;
      rst_n_i                 : in std_logic;
      bpm_pos_index_i         : in unsigned(g_BPM_POS_INDEX_WIDTH-1 downto 0);
      bpm_pos_i               : in signed(g_BPM_POS_WIDTH-1 downto 0);
      bpm_pos_valid_i         : in std_logic;
      prbs_i                  : in std_logic;
      distort_level_0_i       : in signed(g_DISTORT_LEVEL_WIDTH-1 downto 0);
      distort_level_1_i       : in signed(g_DISTORT_LEVEL_WIDTH-1 downto 0);
      distort_bpm_pos_index_o : out unsigned(g_BPM_POS_INDEX_WIDTH-1 downto 0);
      distort_bpm_pos_o       : out signed(g_BPM_POS_WIDTH-1 downto 0);
      distort_bpm_pos_valid_o : out std_logic
    );
  end component prbs_bpm_pos_distort;
end package fofb_sys_id_pkg;

package body fofb_sys_id_pkg is

  function f_signed_saturate(x : signed; trunc_x_len : natural) return signed
  is
    variable v_x_sat : signed(trunc_x_len-1 downto 0);
  begin
    assert trunc_x_len <= x'length
      report "Truncate length is higher than the signal itself!"
      severity error;

    if x(x'left) = x(trunc_x_len-1) then
      -- Truncate wouldn't cause {over,under}flow would occur, just drop the
      -- redundant bits
      v_x_sat := x(trunc_x_len-1 downto 0);
    else
      -- Truncate would cause {over,under}flow would occur, so saturate x
      v_x_sat := (x(x'left), others => not x(x'left));
    end if;

    return v_x_sat;
  end f_signed_saturate;

end package body;

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
  type t_bpm_pos_arr is array (natural range <>) of signed(c_SP_POS_RAM_DATA_WIDTH-1 downto 0);

  component bpm_pos_flatenizer is
    generic (
      g_MAX_NUM_BPM_POS     : natural range 1 to 2**(natural(c_SP_COEFF_RAM_ADDR_WIDTH)) := 16
    );
    port (
      clk_i                 : in std_logic;
      rst_n_i               : in std_logic;
      clear_i               : in std_logic;
      bpm_pos_base_index_i  : in unsigned(c_SP_COEFF_RAM_ADDR_WIDTH-1 downto 0);
      bpm_pos_index_i       : in unsigned(c_SP_COEFF_RAM_ADDR_WIDTH-1 downto 0);
      bpm_pos_i             : in signed(c_SP_POS_RAM_DATA_WIDTH-1 downto 0);
      bpm_pos_valid_i       : in std_logic;
      bpm_pos_flat_o        : out t_bpm_pos_arr(g_MAX_NUM_BPM_POS-1 downto 0) := (others => (others => '0'));
      bpm_pos_flat_rcvd_o   : out std_logic_vector(g_MAX_NUM_BPM_POS-1 downto 0) := (others => '0')
    );
  end component bpm_pos_flatenizer;

end package fofb_sys_id_pkg;

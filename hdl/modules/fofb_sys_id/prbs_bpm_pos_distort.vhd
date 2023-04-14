--------------------------------------------------------------------------------
-- Title      : PRBS-based distortion for BPM positions
-- Project    : fofb-ctrl-gw
--------------------------------------------------------------------------------
-- File       : prbs_bpm_pos_distort.vhd
-- Author     : Guilherme Ricioli <guilherme.riciolic@gmail.com>
-- Company    : CNPEM, LNLS - GIE
-- Platform   : Generic
-- Standard   : VHDL'08
--------------------------------------------------------------------------------
-- Description: Sums PRBS-based distortion to BPM positions.
--------------------------------------------------------------------------------
-- Copyright (c) 2023 CNPEM
-- Licensed under GNU Lesser General Public License (LGPL) v3.0
--------------------------------------------------------------------------------
-- Revisions  :
-- Date         Version  Author              Description
-- 2023-04-14   1.0      guilherme.ricioli   Created
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fofb_sys_id_pkg.all;

entity prbs_bpm_pos_distort is
  generic (
    -- Width of BPM position indexes
    g_BPM_POS_INDEX_WIDTH   : natural := 9;

    -- Width of BPM positions
    g_BPM_POS_WIDTH         : natural := 32;

    -- Width of distortion levels
    g_DISTORT_LEVEL_WIDTH   : natural := 16
  );
  port (
    -- Clock
    clk_i                   : in std_logic;

    -- Reset
    rst_n_i                 : in std_logic;

    -- BPM position index
    bpm_pos_index_i         : in unsigned(g_BPM_POS_INDEX_WIDTH-1 downto 0);

    -- BPM position
    bpm_pos_i               : in signed(g_BPM_POS_WIDTH-1 downto 0);

    -- BPM position valid
    bpm_pos_valid_i         : in std_logic;

    -- PRBS signal
    prbs_i                  : in std_logic;

    -- Distortion level for PRBS value '0'
    distort_level_0_i       : in signed(g_DISTORT_LEVEL_WIDTH-1 downto 0);

    -- Distortion level for PRBS value '1'
    distort_level_1_i       : in signed(g_DISTORT_LEVEL_WIDTH-1 downto 0);

    -- Distorted BPM position index (same as bpm_pos_index_i)
    distort_bpm_pos_index_o : out unsigned(g_BPM_POS_INDEX_WIDTH-1 downto 0);

    -- Distorted BPM position
    distort_bpm_pos_o       : out signed(g_BPM_POS_WIDTH-1 downto 0);

    -- Distorted BPM position valid
    distort_bpm_pos_valid_o : out std_logic
  );
end entity prbs_bpm_pos_distort;

architecture beh of prbs_bpm_pos_distort is
  signal bpm_pos_index_d1 : unsigned(g_BPM_POS_INDEX_WIDTH-1 downto 0) := (others => '0');
  signal bpm_pos_valid_d1 : std_logic := '0';
  -- 1-bit larger than the largest between bpm_pos_i and distort_level_{0,1}_i
  -- so to accomodate their sum
  signal distort_bpm_pos_aux : signed(maximum(g_BPM_POS_WIDTH, g_DISTORT_LEVEL_WIDTH) downto 0);
begin

  process(clk_i) is
    -- 1-bit larger than the largest between bpm_pos_i and distort_level_{0,1}_i
    -- This is done so there's no {over,under}flow on signed '+' operation
    variable v_resized_bpm_pos : signed(maximum(g_BPM_POS_WIDTH, g_DISTORT_LEVEL_WIDTH) downto 0);
  begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        bpm_pos_valid_d1 <= '0';
        distort_bpm_pos_valid_o <= '0';
      else
        v_resized_bpm_pos := resize(bpm_pos_i, maximum(g_BPM_POS_WIDTH, g_DISTORT_LEVEL_WIDTH)+1);

        -- Pipeline stage 1 of 2: sum of PRBS distortion
        -- #####################################################################
        if prbs_i = '0' then
          distort_bpm_pos_aux <= v_resized_bpm_pos + distort_level_0_i;
        else  -- prbs_i = '1'
          distort_bpm_pos_aux <= v_resized_bpm_pos + distort_level_1_i;
        end if;

        bpm_pos_index_d1 <= bpm_pos_index_i;
        bpm_pos_valid_d1 <= bpm_pos_valid_i;
        -- #####################################################################

        -- Pipeline stage 2 of 2: saturation of distorted BPM position
        -- #####################################################################
        distort_bpm_pos_o <= f_signed_saturate(distort_bpm_pos_aux, distort_bpm_pos_o'length);
        distort_bpm_pos_index_o <= bpm_pos_index_d1;
        distort_bpm_pos_valid_o <= bpm_pos_valid_d1;
        -- #####################################################################
      end if;
    end if;
  end process;

end architecture beh;

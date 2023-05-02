--------------------------------------------------------------------------------
-- Title      : PRBS-based distortion for FOFB processing setpoints
-- Project    : fofb-ctrl-gw
--------------------------------------------------------------------------------
-- File       : prbs_sp_distort.vhd
-- Author     : Guilherme Ricioli <guilherme.riciolic@gmail.com>
-- Company    : CNPEM, LNLS - GIE
-- Platform   : Generic
-- Standard   : VHDL'08
--------------------------------------------------------------------------------
-- Description: Sums PRBS-based distortion to FOFB processing setpoints.
--------------------------------------------------------------------------------
-- Copyright (c) 2023 CNPEM
-- Licensed under GNU Lesser General Public License (LGPL) v3.0
--------------------------------------------------------------------------------
-- Revisions  :
-- Date         Version  Author              Description
-- 2023-04-17   1.0      guilherme.ricioli   Created
-- 2023-04-19   1.1      guilherme.ricioli   Wrap prbs_gen_for_sys_id
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fofb_sys_id_pkg.all;
use work.ifc_common_pkg.all;

entity prbs_sp_distort is
  generic (
    -- Width of setpoints
    g_SP_WIDTH            : natural := 15;

    -- Width of distortion levels
    g_DISTORT_LEVEL_WIDTH : natural := 16
  );
  port (
    -- Clock
    clk_i                 : in std_logic;

    -- Reset
    rst_n_i               : in std_logic;

    -- This signal enables the PRBS-based distortion.
    en_distort_i          : in std_logic;

    -- PRBS reset
    prbs_rst_n_i          : in std_logic;

    -- Duration of each PRBS step (in prbs_valid_i counts)
    -- NOTE: Changing this signal resets the internal counter. prbs_valid_i is
    --       ignored in this cycle.
    prbs_step_duration_i  : in natural range 1 to 1024 := 1;

    -- Length (in bits) of internal PRBS LFSR. This determines the duration of
    -- the generated sequence, which is given by:
    -- (2^{prbs_lfsr_length_i} - 1)*prbs_step_duration_i
    -- NOTE: Changing this signal resets the internal LFSR. prbs_valid_i is
    --       ignored in this cycle.
    prbs_lfsr_length_i    : in natural range 2 to 32 := 32;

    -- PRBS iteration signal
    prbs_valid_i          : in std_logic;

    -- Setpoint
    sp_i                  : in signed(g_SP_WIDTH-1 downto 0);

    -- Setpoint valid
    sp_valid_i            : in std_logic;

    -- Distortion level for PRBS value '0'
    distort_level_0_i     : in signed(g_DISTORT_LEVEL_WIDTH-1 downto 0);

    -- Distortion level for PRBS value '1'
    distort_level_1_i     : in signed(g_DISTORT_LEVEL_WIDTH-1 downto 0);

    -- Distorted setpoint
    distort_sp_o          : out signed(g_SP_WIDTH-1 downto 0);

    -- Distorted setpoint valid
    distort_sp_valid_o    : out std_logic;

    -- PRBS signal for debug
    prbs_o                : out std_logic;

    -- PRBS valid signal for debug
    prbs_valid_o          : out std_logic
  );
end entity prbs_sp_distort;

architecture beh of prbs_sp_distort is
  signal prbs : std_logic := '0';
  signal sp_valid_d1 : std_logic := '0';
  -- 1-bit larger than the largest between sp_i and distort_level_{0,1}_i
  -- so to accomodate their sum
  signal distort_sp_aux : signed(maximum(g_SP_WIDTH, g_DISTORT_LEVEL_WIDTH) downto 0);
begin

  process(clk_i) is
    -- 1-bit larger than the largest between sp_i and distort_level_{0,1}_i
    -- This is done so there's no {over,under}flow on signed '+' operation
    variable v_resized_sp : signed(maximum(g_SP_WIDTH, g_DISTORT_LEVEL_WIDTH) downto 0);
  begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        sp_valid_d1 <= '0';
        distort_sp_valid_o <= '0';
      else
        v_resized_sp := resize(sp_i, maximum(g_SP_WIDTH, g_DISTORT_LEVEL_WIDTH)+1);

        -- Pipeline stage 1 of 2: sum or bypass PRBS distortion
        -- #####################################################################
        if en_distort_i = '1' then
          if prbs = '0' then
            distort_sp_aux <= v_resized_sp + distort_level_0_i;
          else  -- prbs_i = '1'
            distort_sp_aux <= v_resized_sp + distort_level_1_i;
          end if;
        else  -- en_distort_i = '0'
          distort_sp_aux <= v_resized_sp;
        end if;

        sp_valid_d1 <= sp_valid_i;
        -- #####################################################################

        -- Pipeline stage 2 of 2: saturation of distorted setpoint
        -- #####################################################################
        distort_sp_o <= f_signed_saturate(distort_sp_aux, distort_sp_o'length);
        distort_sp_valid_o <= sp_valid_d1;
        -- #####################################################################
      end if;
    end if;
  end process;

  cmp_prbs_gen_for_sys_id : prbs_gen_for_sys_id
    port map (
      clk_i           => clk_i,
      rst_n_i         => rst_n_i and prbs_rst_n_i,
      en_i            => '1',
      step_duration_i => prbs_step_duration_i,
      lfsr_length_i   => prbs_lfsr_length_i,
      valid_i         => prbs_valid_i,
      busy_o          => open,
      prbs_o          => prbs,
      valid_o         => prbs_valid_o
    );

  prbs_o <= prbs;

end architecture beh;

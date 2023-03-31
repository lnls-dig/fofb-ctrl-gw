--------------------------------------------------------------------------------
-- Title      : BPM positions flatenizer testbench
--------------------------------------------------------------------------------
-- Author     : Guilherme Ricioli <guilherme.riciolic@gmail.com>
-- Company    : CNPEM, LNLS - GIE
-- Platform   : Simulation
-- Standard   : VHDL 2008
--------------------------------------------------------------------------------
-- Description: Tests chaining fofb_processing_dcc_adapter with
--              bpm_pos_flatenizer.
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
use work.dot_prod_pkg.all;
use work.fofb_ctrl_pkg.all;
use work.fofb_tb_pkg.all;
use work.fofb_sys_id_pkg.all;

entity bpm_pos_flatenizer_tb is
end bpm_pos_flatenizer_tb;

architecture test of bpm_pos_flatenizer_tb is
  constant c_MAX_NUM_BPM_POS      : natural range 1 to 2**(natural(c_SP_COEFF_RAM_ADDR_WIDTH)) := c_MAX_NUM_P2P_BPM_POS/2;
  signal clk                      : std_logic := '0';
  signal rst_n                    : std_logic := '0';
  signal clk_dcc                  : std_logic := '0';
  signal rst_dcc_n                : std_logic := '0';
  signal dcc_time_frame_end       : std_logic := '0';
  signal dcc_packet               : t_fofb_cc_packet;
  signal dcc_packet_valid         : std_logic := '0';
  signal fofb_proc_bpm_pos        : signed(c_SP_POS_RAM_DATA_WIDTH-1 downto 0);
  signal fofb_proc_bpm_pos_index  : unsigned(c_SP_COEFF_RAM_ADDR_WIDTH-1 downto 0);
  signal fofb_proc_bpm_pos_valid  : std_logic;
  signal fofb_proc_time_frame_end : std_logic;
  signal clear                    : std_logic;
  signal bpm_pos_base_index       : unsigned(c_SP_COEFF_RAM_ADDR_WIDTH-1 downto 0) := (others => '0');
  signal bpm_pos_flat             : t_bpm_pos_arr(c_MAX_NUM_BPM_POS-1 downto 0) := (others => (others => '0'));
  signal bpm_pos_flat_rcvd        : std_logic_vector(c_MAX_NUM_BPM_POS-1 downto 0) := (others => '0');
begin
  f_gen_clk(100_000_000, clk);
  f_gen_clk(156_250_000, clk_dcc);

  process
    variable v_BPM_POS_BASE_INDEX : natural := 0;
  begin
    f_wait_cycles(clk, 5);
    rst_n <= '1';
    f_wait_cycles(clk_dcc, 5);
    rst_dcc_n <= '1';

    for cycle in 0 to 1
    loop
      if cycle = 0 then
        v_BPM_POS_BASE_INDEX := 20;
      else
        v_BPM_POS_BASE_INDEX := 70;
      end if;

      bpm_pos_base_index <= to_unsigned(v_BPM_POS_BASE_INDEX, bpm_pos_base_index'length);
      f_wait_cycles(clk, 10);

      -- Writes DCC packets with BPM positions matching their (to-be-)assigned
      -- IDs. 'fofb_processing_dcc_adapter' serializes BPM positions and tags'em
      -- using the following:
      -- {BPM position x id, BPM position y id} = {BPM id, BPM id + 256}.
      for id in 0 to 2**(natural(c_SP_COEFF_RAM_ADDR_WIDTH)-1)-1
      loop
        dcc_packet.bpm_data_x <= to_signed(id, dcc_packet.bpm_data_x'length);
        dcc_packet.bpm_data_y <= to_signed(id + 256, dcc_packet.bpm_data_y'length);
        dcc_packet.bpm_id <= to_unsigned(id, dcc_packet.bpm_id'length);

        dcc_packet_valid <= '1';
        f_wait_cycles(clk_dcc, 1);
        dcc_packet_valid <= '0';
        f_wait_cycles(clk_dcc, 10);
      end loop;

      for bpm_pos in 0 to c_MAX_NUM_BPM_POS-1
      loop
        if bpm_pos_flat_rcvd(bpm_pos) /= '1' then
          report "expected a bpm position stored"
          severity failure;
        end if;

        if to_integer(bpm_pos_flat(bpm_pos)) /= v_BPM_POS_BASE_INDEX + bpm_pos then
          report
            "wrong bpm position stored: " &
            integer'image(to_integer(bpm_pos_flat(bpm_pos))) & " (expected: " &
            integer'image(v_BPM_POS_BASE_INDEX + bpm_pos) & ")"
          severity failure;
        end if;
      end loop;

      clear <= '1';
      f_wait_cycles(clk, 1);
      clear <= '0';
      f_wait_cycles(clk, 1);
    end loop;

    std.env.finish;
  end process;

  inst_fofb_processing_dcc_adapter : fofb_processing_dcc_adapter
    port map (
      clk_i                       => clk,
      rst_n_i                     => rst_n,
      clk_dcc_i                   => clk_dcc,
      rst_dcc_n_i                 => rst_dcc_n,
      dcc_time_frame_end_i        => dcc_time_frame_end,
      dcc_packet_i                => dcc_packet,
      dcc_packet_valid_i          => dcc_packet_valid,
      fofb_proc_busy_i            => '0',
      fofb_proc_bpm_pos_o         => fofb_proc_bpm_pos,
      fofb_proc_bpm_pos_index_o   => fofb_proc_bpm_pos_index,
      fofb_proc_bpm_pos_valid_o   => fofb_proc_bpm_pos_valid,
      fofb_proc_time_frame_end_o  => fofb_proc_time_frame_end,
      acq_dcc_packet_o            => open,
      acq_dcc_valid_o             => open
    );

  uut : bpm_pos_flatenizer
    generic map (
      g_MAX_NUM_BPM_POS     => c_MAX_NUM_BPM_POS
    )
    port map (
      clk_i                 => clk,
      rst_n_i               => rst_n,
      clear_i               => clear,
      bpm_pos_base_index_i  => bpm_pos_base_index,
      bpm_pos_index_i       => fofb_proc_bpm_pos_index,
      bpm_pos_i             => fofb_proc_bpm_pos,
      bpm_pos_valid_i       => fofb_proc_bpm_pos_valid,
      bpm_pos_flat_o        => bpm_pos_flat,
      bpm_pos_flat_rcvd_o   => bpm_pos_flat_rcvd
    );
end architecture test;

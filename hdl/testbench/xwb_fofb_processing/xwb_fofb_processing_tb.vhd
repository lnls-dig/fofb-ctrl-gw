------------------------------------------------------------------------------
-- Title      : xwb_fofb_processing_tb testbench
------------------------------------------------------------------------------
-- Author     : Guilherme Ricioli Cruz
-- Company    : CNPEM LNLS-GCA
-- Platform   : Simulation
-- Standard   : VHDL 2008
-------------------------------------------------------------------------------
-- Description:  Testbench for the xwb_fofb_processing_tb module.
--
--               Files usage:
--               * 'coeffs.dat' holds all of the 12x512=6144 coefficients;
--               * 'dcc_packets.dat' holds [1 - 256] DCC packet fields
--                  organized at each 3 lines (BPM id, x measurement and y
--                  measurement).
-------------------------------------------------------------------------------
-- Copyright (c) 2022 CNPEM
-- Licensed under GNU Lesser General Public License (LGPL) v3.0
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author             Description
-- 2022-07-26  1.0      guilherme.ricioli  Created
-- 2022-09-05  2.0      augusto.fraga      Update testbench to match the new
--                                         xwb_fofb_processing interface
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library std;
use std.env.finish;
use std.textio.all;

library work;
-- FOFC CC wrapper
use work.fofb_ctrl_pkg.all;
-- FOFB Processing definitions
use work.dot_prod_pkg.all;
-- Main Wishbone Definitions
use work.wishbone_pkg.all;
-- wishbone read/write procedures
use work.sim_wishbone.all;
-- wb_fofb_processing register constants
use work.wb_fofb_processing_regs_consts_pkg.all;
use work.fofb_tb_pkg.all;

entity xwb_fofb_processing_tb is
  generic (
    -- Integer width for the inverse responce matrix coefficient input
    g_COEFF_INT_WIDTH              : natural := 0;

    -- Fractionary width for the inverse responce matrix coefficient input
    g_COEFF_FRAC_WIDTH             : natural := 17;

    -- Integer width for the BPM position error input
    g_BPM_POS_INT_WIDTH            : natural := 20;

    -- Fractionary width for the BPM position error input
    g_BPM_POS_FRAC_WIDTH           : natural := 0;

    -- Extra bits for the dot product accumulator
    g_DOT_PROD_ACC_EXTRA_WIDTH     : natural := 4;

    -- Dot product multiply pipeline stages
    g_DOT_PROD_MUL_PIPELINE_STAGES : natural := 2;

    -- Dot product accumulator pipeline stages
    g_DOT_PROD_ACC_PIPELINE_STAGES : natural := 2;

    -- Gain multiplication pipeline stages
    g_ACC_GAIN_MUL_PIPELINE_STAGES : natural := 2;

    -- Number of FOFB cycles to simulate
    g_FOFB_NUM_CYC                 : natural := 4;

    -- Inverse response matrix coefficients file (in binary)
    g_COEFF_RAM_FILE               : string  := "../coeff_norm_q31.dat";

    -- DCC packets file
    g_DCC_PACKETS_FILE             : string  := "../dcc_packets.dat";

    -- BPM reference orbit data (set-point)
    g_FOFB_BPM_REF_FILE            : string  := "../fofb_bpm_ref.dat"
  );
end entity xwb_fofb_processing_tb;

architecture xwb_fofb_processing_tb_arch of xwb_fofb_processing_tb is
  -- procedures
  procedure f_gen_clk(constant freq : in    natural;
                      signal   clk  : inout std_logic) is
  begin
    loop
      wait for (0.5 / real(freq)) * 1 sec;
      clk <= not clk;
    end loop;
  end procedure f_gen_clk;

  procedure f_wait_cycles(signal   clk    : in std_logic;
                          constant cycles : natural) is
  begin
    for i in 1 to cycles loop
      wait until rising_edge(clk);
    end loop;
  end procedure f_wait_cycles;

  -- constants
  constant c_SYS_CLOCK_FREQ     : natural := 100_000_000;

  constant c_NUM_OF_TIME_FRAMES : natural := 1;

  constant c_CHANNELS           : natural := 12;

  constant c_FOFB_PROCESSING_REGS_RAM_BANK_SIZE
    : natural :=
      c_ADDR_WB_FOFB_PROCESSING_REGS_RAM_BANK_1 -
      c_ADDR_WB_FOFB_PROCESSING_REGS_RAM_BANK_0;

  -- signals
  signal clk                    : std_logic := '0';
  signal rst_n                  : std_logic := '0';

  signal dcc_time_frame_end     : std_logic := '0';

  signal sp_arr                              :
    t_fofb_processing_sp_arr(c_CHANNELS-1 downto 0);
  signal sp_valid_arr                        :
    std_logic_vector(c_CHANNELS-1 downto 0):= (others => '0');

  signal busy                   : std_logic;
  signal bpm_pos                : signed(c_SP_POS_RAM_DATA_WIDTH-1 downto 0) := (others => '0');
  signal bpm_pos_index          : unsigned(c_SP_COEFF_RAM_ADDR_WIDTH-1 downto 0)  := (others => '0');
  signal bpm_pos_valid          : std_logic := '0';

  signal wb_slave_i             : t_wishbone_slave_in;
  signal wb_slave_o             : t_wishbone_slave_out;

begin
  f_gen_clk(c_SYS_CLOCK_FREQ, clk);

  -- main process
  process
    variable addr                            : natural := 0;
    variable data                            : std_logic_vector(31 downto 0) := (others => '0');

    file fd_coeffs, fd_dcc                   : text;
    variable aux_line                        : line;
    variable bpm_id                          : natural;
    variable bpm_x_reading,
      bpm_y_reading                          : integer;
    variable coeff                           : std_logic_vector(31 downto 0);

  begin
    -- resetting cores
    report "resetting cores" severity note;

    init(wb_slave_i);
    f_wait_cycles(clk, 10);

    rst_n <= '0';
    f_wait_cycles(clk, 1);
    rst_n <= '1';
    f_wait_cycles(clk, 10);

    -- writing on coefficients rams via wishbone bus
    report
      "writing on coefficients rams via wishbone bus"
    severity note;

    file_open(fd_coeffs, g_COEFF_RAM_FILE, read_mode);

    read32_pl(clk, wb_slave_i, wb_slave_o, c_ADDR_WB_FOFB_PROCESSING_REGS_FIXED_POINT_POS, data);
    report "fixed-point position constant register: " & to_hstring(data)
    severity note;

    for i in 0 to ((c_CHANNELS*c_FOFB_PROCESSING_REGS_RAM_BANK_SIZE /
      c_WB_FOFB_PROCESSING_REGS_RAM_BANK_0_SIZE) - 1)
    loop
      readline(fd_coeffs, aux_line);
      read(aux_line, coeff);

      -- address should jump c_WB_FOFB_PROCESSING_REGS_RAM_BANK_0_SIZE on each
      -- iteration (wishbone bus is using byte-granularity)
      addr := c_ADDR_WB_FOFB_PROCESSING_REGS_RAM_BANK_0 +
        i * c_WB_FOFB_PROCESSING_REGS_RAM_BANK_0_SIZE;

      write32_pl(clk, wb_slave_i, wb_slave_o, addr, coeff);
      read32_pl(clk, wb_slave_i, wb_slave_o, addr, data);

      assert (data = coeff)
        report
          "wrong ram coefficient at " & natural'image(addr)
        severity error;
    end loop;

    file_close(fd_coeffs);

    for j in 0 to (c_NUM_OF_TIME_FRAMES - 1)
    loop

      -- loading BPM readings and performing dot product
      report
        "loading BPM readings and performing dot product (time frame: " &
        natural'image(j) & ")"
      severity note;

      file_open(fd_dcc, g_DCC_PACKETS_FILE, read_mode);

      -- synthetic dcc data
      while not endfile(fd_dcc)
      loop
        f_wait_cycles(clk, 1);

        readline(fd_dcc, aux_line);
        read(aux_line, bpm_id);

        readline(fd_dcc, aux_line);
        read(aux_line, bpm_x_reading);

        readline(fd_dcc, aux_line);
        read(aux_line, bpm_y_reading);

          -- bpm x reading
        bpm_pos <= to_signed(bpm_x_reading, bpm_pos'length);
        bpm_pos_index <= to_unsigned(bpm_id, bpm_pos_index);

        -- signalling a valid dcc data
        bpm_pos_valid <= '1';
        f_wait_cycles(clk, 1);
        bpm_pos_valid <= '0';
        f_wait_cycles(clk, 1);

        bpm_pos <= to_signed(bpm_y_reading, bpm_pos'length);
        bpm_pos_index <= to_unsigned(bpm_id + 256, bpm_pos_index);

        -- signalling a valid dcc data
        bpm_pos_valid <= '1';
        f_wait_cycles(clk, 1);
        bpm_pos_valid <= '0';
        f_wait_cycles(clk, 1);
      end loop;

      -- Time frame ended
      dcc_time_frame_end <= '1';
      f_wait_cycles(clk, 1);
      dcc_time_frame_end <= '0';
      f_wait_cycles(clk, 1);

      -- Wait until the new set-point is ready
      f_wait_clocked_signal(clk, sp_valid_arr(0), '1');

      file_close(fd_dcc);
    end loop;

    for i in 0 to (c_CHANNELS - 1)
    loop
      report
        "fofb processing channel " & natural'image(i) & " result: " &
        integer'image(to_integer(sp_arr(i)))
      severity note;
    end loop;

    finish;
  end process;

  -- components
  cmp_xwb_fofb_processing : xwb_fofb_processing
    generic map (
      g_COEFF_INT_WIDTH              => g_COEFF_INT_WIDTH,
      g_COEFF_FRAC_WIDTH             => g_COEFF_FRAC_WIDTH,
      g_BPM_POS_INT_WIDTH            => g_BPM_POS_INT_WIDTH,
      g_BPM_POS_FRAC_WIDTH           => g_BPM_POS_FRAC_WIDTH,
      g_DOT_PROD_ACC_EXTRA_WIDTH     => g_DOT_PROD_ACC_EXTRA_WIDTH,
      g_DOT_PROD_MUL_PIPELINE_STAGES => g_DOT_PROD_MUL_PIPELINE_STAGES,
      g_DOT_PROD_ACC_PIPELINE_STAGES => g_DOT_PROD_ACC_PIPELINE_STAGES,
      g_ACC_GAIN_MUL_PIPELINE_STAGES => g_ACC_GAIN_MUL_PIPELINE_STAGES,
      g_CHANNELS                     => c_CHANNELS,
      g_INTERFACE_MODE               => PIPELINED,
      g_ADDRESS_GRANULARITY          => BYTE,
      g_WITH_EXTRA_WB_REG            => false
    )
    port map (
      clk_i                          => clk,
      rst_n_i                        => rst_n,
      busy_o                         => busy,
      bpm_pos_i                      => bpm_pos,
      bpm_pos_index_i                => bpm_pos_index,
      bpm_pos_valid_i                => bpm_pos_valid,
      bpm_time_frame_end_i           => dcc_time_frame_end,
      sp_arr_o                       => sp_arr,
      sp_valid_arr_o                 => sp_valid_arr,
      wb_slv_i                       => wb_slave_i,
      wb_slv_o                       => wb_slave_o
    );

end architecture xwb_fofb_processing_tb_arch;

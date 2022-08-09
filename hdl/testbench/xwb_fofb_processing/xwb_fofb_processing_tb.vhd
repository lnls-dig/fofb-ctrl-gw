------------------------------------------------------------------------------
-- Title      : xwb_fofb_processing_tb testbench
------------------------------------------------------------------------------
-- Author     : Guilherme Ricioli Cruz
-- Company    : CNPEM LNLS-GCA
-- Platform   : Simulation
-------------------------------------------------------------------------------
-- Description:  Testbench for the xwb_fofb_processing_tb module.
--
--               Files usage:
--               * 'coeffs.txt' holds all of the 12x512=6144 coefficients;
--               * 'dcc_packets.txt' holds [1 - 256] DCC packet fields
--                  organized at each 3 lines (BPM id, x measurement and y
--                  measurement).
-------------------------------------------------------------------------------
-- Copyright (c) 2022 CNPEM
-- Licensed under GNU Lesser General Public License (LGPL) v3.0
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author             Description
-- 2022-07-26  1.0      guilherme.ricioli  Created
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

entity xwb_fofb_processing_tb is
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
  constant c_SYS_CLOCK_FREQ                  : natural := 156250000;

  constant c_NUM_OF_TIME_FRAMES              : natural := 1;

  constant c_A_WIDTH                         : natural := 32;
  constant c_ID_WIDTH                        : natural := 9;
  constant c_B_WIDTH                         : natural := 32;
  constant c_K_WIDTH                         : natural := 9;
  constant c_C_WIDTH                         : natural := 16;
  constant c_CHANNELS                        : natural := 12;

  constant c_OUT_FIXED                       : natural := 26;
  constant c_EXTRA_WIDTH                     : natural := 4;

  constant c_ANTI_WINDUP_UPPER_LIMIT         : integer := 1000;
  constant c_ANTI_WINDUP_LOWER_LIMIT         : integer := -1000;
  constant c_FOFB_PROCESSING_REGS_RAM_BANK_SIZE
    : natural :=
      c_ADDR_WB_FOFB_PROCESSING_REGS_RAM_BANK_1 -
      c_ADDR_WB_FOFB_PROCESSING_REGS_RAM_BANK_0;

  -- 1.0 fixed-point representation based on c_OUT_FIXED
  constant c_DUMMY_RAM_COEFF                 :
    std_logic_vector(c_B_WIDTH-1 downto 0) :=
      std_logic_vector(shift_left(to_unsigned(1, c_B_WIDTH), c_OUT_FIXED));

  constant c_DCC_FOD_RESET                   :
    t_dot_prod_record_fod :=
      (valid => '0', data => (others => '0'), addr => (others => '0'));

  -- signals
  signal clk                                 : std_logic := '0';
  signal rst_n                               : std_logic := '0';

  signal dcc_fod                             :
    t_dot_prod_array_record_fod(c_CHANNELS-1 downto 0) :=
      (others => c_DCC_FOD_RESET);
  signal dcc_time_frame_start                : std_logic := '0';
  signal dcc_time_frame_end                  : std_logic := '0';

  signal sp_arr                              :
    t_fofb_processing_setpoints(c_CHANNELS-1 downto 0);
  signal sp_valid_arr                        :
    std_logic_vector(c_CHANNELS-1 downto 0):= (others => '0');

  signal wb_slave_i                          : t_wishbone_slave_in;
  signal wb_slave_o                          : t_wishbone_slave_out;

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

    file_open(fd_coeffs, "../coeffs.txt", read_mode);

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

      file_open(fd_dcc, "../dcc_packets.txt", read_mode);

      f_wait_cycles(clk, 1);
      dcc_time_frame_start <= '1';
      f_wait_cycles(clk, 1);
      dcc_time_frame_start <= '0';

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

        for i in 0 to (c_CHANNELS - 1)
        loop
          -- bpm x reading
          dcc_fod(i).data <=
            std_logic_vector(to_signed(bpm_x_reading, dcc_fod(i).data'length));
          dcc_fod(i).addr <=
            std_logic_vector(to_unsigned(2*bpm_id, dcc_fod(i).addr'length));

          -- signalling a valid dcc data
          dcc_fod(i).valid <= '1';
          f_wait_cycles(clk, 1);
          dcc_fod(i).valid <= '0';
          f_wait_cycles(clk, 1);

          -- bpm y reading
          dcc_fod(i).data <=
            std_logic_vector(to_signed(bpm_y_reading, dcc_fod(i).data'length));
          dcc_fod(i).addr <=
            std_logic_vector(to_unsigned(2*bpm_id + 1, dcc_fod(i).addr'length));

          -- signalling a valid dcc data
          dcc_fod(i).valid <= '1';
          f_wait_cycles(clk, 1);
          dcc_fod(i).valid <= '0';
          f_wait_cycles(clk, 1);
        end loop;

      end loop;

      -- NOTE:  This waiting has to be enough for dot_prod_coeff_vec to finish its
      --        processing. It was defined empirically.
      f_wait_cycles(clk, 11);
      dcc_time_frame_end <= '1';
      f_wait_cycles(clk, 1);
      dcc_time_frame_end <= '0';
      f_wait_cycles(clk, 2);

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
      g_A_WIDTH                              => c_A_WIDTH,
      g_ID_WIDTH                             => c_ID_WIDTH,
      g_B_WIDTH                              => c_B_WIDTH,
      g_K_WIDTH                              => c_K_WIDTH,
      g_C_WIDTH                              => c_C_WIDTH,

      g_OUT_FIXED                            => c_OUT_FIXED,
      g_EXTRA_WIDTH                          => c_EXTRA_WIDTH,

      g_CHANNELS                             => c_CHANNELS,

      g_ANTI_WINDUP_UPPER_LIMIT              => c_ANTI_WINDUP_UPPER_LIMIT,
      g_ANTI_WINDUP_LOWER_LIMIT              => c_ANTI_WINDUP_LOWER_LIMIT,

      g_INTERFACE_MODE                       => PIPELINED,
      g_ADDRESS_GRANULARITY                  => BYTE,
      g_WITH_EXTRA_WB_REG                    => false
    )
    port map (
      clk_i                                  => clk,
      rst_n_i                                => rst_n,
      clk_sys_i                              => clk,
      rst_sys_n_i                            => rst_n,

      dcc_fod_i                              => dcc_fod,
      dcc_time_frame_start_i                 => dcc_time_frame_start,
      dcc_time_frame_end_i                   => dcc_time_frame_end,

      sp_arr_o                               => sp_arr,
      sp_valid_arr_o                         => sp_valid_arr,

      wb_slv_i                               => wb_slave_i,
      wb_slv_o                               => wb_slave_o
    );

end architecture xwb_fofb_processing_tb_arch;

-------------------------------------------------------------------------------
-- Title      :  fofb_processing testbench
-------------------------------------------------------------------------------
-- Author     :  Guilherme Ricioli Cruz
-- Company    :  CNPEM LNLS GCA
-- Platform   :  Simulation
-------------------------------------------------------------------------------
-- Description:  Testbench for the fofb_processing module.
--
--               Files usage:
--               * 'coeffs.txt' holds each of the 512 coefficients;
--               * 'dcc_packets.txt' holds [1 - 256] DCC packet fields
--                  organized at each 3 lines (BPM id, x measurement and y
--                  measurement).
-------------------------------------------------------------------------------
-- Copyright (c) 2022 CNPEM
-- Licensed under GNU Lesser General Public License (LGPL) v3.0
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                Description
-- 2022-07-27  1.0      guilherme.ricioli     Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.env.finish;
use std.textio.all;

library work;
use work.dot_prod_pkg.all;
-- generic_dpram package
use work.genram_pkg.all;

entity fofb_processing_tb is
end fofb_processing_tb;

architecture behave of fofb_processing_tb is

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
  constant c_SYS_CLOCK_FREQ           : natural := 156250000;

  constant c_NUM_OF_TIME_FRAMES       : natural := 1;

  constant c_A_WIDTH                  : natural := 32;
  constant c_ID_WIDTH                 : natural := 9;
  constant c_B_WIDTH                  : natural := 32;
  constant c_K_WIDTH                  : natural := 9;
  constant c_C_WIDTH                  : natural := 16;
  constant c_CHANNELS                 : natural := 12;

  constant c_DCC_FOD                  :
    t_dot_prod_record_fod := (valid => '0',
                              data  => (others => '0'),
                              addr  => (others => '0'));

  constant c_ANTI_WINDUP_UPPER_LIMIT  : integer := 1000;
  constant c_ANTI_WINDUP_LOWER_LIMIT  : integer := -1000;

  -- signals
  signal clk                          : std_logic := '0';
  signal rst_n                        : std_logic := '0';

  signal dcc_time_frame_start         : std_logic := '0';
  signal dcc_time_frame_end           : std_logic := '0';
  signal dcc_fod                      :
    t_dot_prod_array_record_fod(c_CHANNELS-1 downto 0)
      := (others => c_DCC_FOD);

  signal coeff_ram_data_arr           :
    t_arr_coeff_ram_data(c_CHANNELS-1 downto 0);
  signal coeff_ram_addr_arr           :
    t_arr_coeff_ram_addr(c_CHANNELS-1 downto 0);

  signal sp_arr                       :
    t_fofb_processing_setpoints(c_CHANNELS-1 downto 0);
  signal sp_valid_arr                 :
    std_logic_vector(c_CHANNELS-1 downto 0) := (others => '0');

begin
  f_gen_clk(c_SYS_CLOCK_FREQ, clk);

  -- main process
  process
    file fd_dcc                       : text;
    variable aux_line                 : line;
    variable bpm_id                   : natural;
    variable bpm_x_reading,
      bpm_y_reading                   : integer;

  begin
    -- resetting cores
    report "resetting cores"
    severity note;

    rst_n <= '0';
    f_wait_cycles(clk, 1);
    rst_n <= '1';
    f_wait_cycles(clk, 10);

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
  cmp_fofb_processing : fofb_processing
    generic map (
      g_A_WIDTH                         => c_A_WIDTH,
      g_ID_WIDTH                        => c_ID_WIDTH,
      g_B_WIDTH                         => c_B_WIDTH,
      g_K_WIDTH                         => c_K_WIDTH,
      g_C_WIDTH                         => c_C_WIDTH,
      g_CHANNELS                        => c_CHANNELS,

      g_ANTI_WINDUP_UPPER_LIMIT         => c_ANTI_WINDUP_UPPER_LIMIT,
      g_ANTI_WINDUP_LOWER_LIMIT         => c_ANTI_WINDUP_LOWER_LIMIT
    )
    port map (
      clk_i                             => clk,
      rst_n_i                           => rst_n,

      dcc_fod_i                         => dcc_fod,
      dcc_time_frame_start_i            => dcc_time_frame_start,
      dcc_time_frame_end_i              => dcc_time_frame_end,

      coeff_ram_addr_arr_o              => coeff_ram_addr_arr,
      coeff_ram_data_arr_i              => coeff_ram_data_arr,

      sp_arr_o                          => sp_arr,
      sp_valid_arr_o                    => sp_valid_arr
    );

  gen_cmps_generic_dpram :
    for i in 0 to c_CHANNELS-1
    generate
      cmp_generic_dpram : generic_dpram
        generic map (
          g_DATA_WIDTH                 => c_B_WIDTH,
          g_SIZE                       => 512,
          g_WITH_BYTE_ENABLE           => false,
          g_ADDR_CONFLICT_RESOLUTION   => "read_first",
          g_INIT_FILE                  => "../coeffs.txt",
          g_DUAL_CLOCK                 => true,
          g_FAIL_IF_FILE_NOT_FOUND     => true
        )
        port map (
          rst_n_i                      => '0',

          clka_i                       => clk,
          bwea_i                       => (others => '1'),
          wea_i                        => '0',
          aa_i                         => coeff_ram_addr_arr(i),
          da_i                         => (others => '0'),
          qa_o                         => coeff_ram_data_arr(i),

          -- not used
          clkb_i                       => '0',
          bweb_i                       => (others => '1'),
          web_i                        => '0',
          ab_i                         => (others => '0'),
          db_i                         => (others => '0'),
          qb_o                         => open
        );
    end generate;
end architecture behave;

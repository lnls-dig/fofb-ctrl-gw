-------------------------------------------------------------------------------
-- Title      :  dot_prod_coeff_vec testbench
-------------------------------------------------------------------------------
-- Author     :  Melissa Aguiar
-- Company    :  CNPEM LNLS GCA
-- Platform   :  FPGA-generic
-------------------------------------------------------------------------------
-- Description:  Testbench for the dot_prod_coeff_vec module.
--
--               Files usage:
--               * 'coeffs.txt' holds each of the 512 coefficients;
--               * 'dcc_packets.txt' holds [1 - 256] DCC packet fields
--                  organized at each 3 lines (BPM id, x measurement and y
--                  measurement).
-------------------------------------------------------------------------------
-- Copyright (c) 2020 CNPEM
-- Licensed under GNU Lesser General Public License (LGPL) v3.0
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                Description
-- 2021-07-30  1.0      melissa.aguiar        Created
-- 2022-07-27  1.1      guilherme.ricioli     Refactored
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

entity dot_prod_coeff_vec_tb is
end dot_prod_coeff_vec_tb;

architecture behave of dot_prod_coeff_vec_tb is
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

  constant c_A_WIDTH                  : natural := 32;
  constant c_ID_WIDTH                 : natural := 9;
  constant c_B_WIDTH                  : natural := 32;
  constant c_K_WIDTH                  : natural := 9;
  constant c_C_WIDTH                  : natural := 16;

  constant c_OUT_FIXED                : natural := 26;
  constant c_EXTRA_WIDTH              : natural := 4;

  constant c_DUMMY_DCC_FOD            :
    t_dot_prod_record_fod := (valid => '0',
                              data  => (others => '0'),
                              addr  => (others => '0'));

  -- signals
  signal clk                          : std_logic := '0';
  signal rst_n                        : std_logic := '0';

  signal dcc_time_frame_start         : std_logic := '0';
  signal dcc_time_frame_end           : std_logic := '0';
  signal dcc_fod                      :
    t_dot_prod_record_fod := c_DUMMY_DCC_FOD;

  signal coeff_ram_addr               : std_logic_vector(c_K_WIDTH-1 downto 0);
  signal coeff_ram_data               : std_logic_vector(c_B_WIDTH-1 downto 0);

  signal sp                           : signed(c_C_WIDTH-1 downto 0);
  signal sp_valid                     : std_logic;

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

    -- loading BPM readings and performing dot product
    report "loading BPM readings and performing dot product"
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

      -- bpm x reading
      dcc_fod.data <=
        std_logic_vector(to_signed(bpm_x_reading, dcc_fod.data'length));
      dcc_fod.addr <=
        std_logic_vector(to_unsigned(2*bpm_id, dcc_fod.addr'length));

      -- signalling a valid dcc data
      dcc_fod.valid <= '1';
      f_wait_cycles(clk, 1);
      dcc_fod.valid <= '0';
      f_wait_cycles(clk, 1);

      -- bpm y reading
      dcc_fod.data <=
        std_logic_vector(to_signed(bpm_y_reading, dcc_fod.data'length));
      dcc_fod.addr <=
        std_logic_vector(to_unsigned(2*bpm_id + 1, dcc_fod.addr'length));

      -- signalling a valid dcc data
      dcc_fod.valid <= '1';
      f_wait_cycles(clk, 1);
      dcc_fod.valid <= '0';
      f_wait_cycles(clk, 1);

    end loop;

    -- NOTE:  This waiting has to be enough for dot_prod_coeff_vec to finish its
    --        processing. It was defined empirically.
    f_wait_cycles(clk, 11);
    dcc_time_frame_end <= '1';
    f_wait_cycles(clk, 1);
    dcc_time_frame_end <= '0';
    f_wait_cycles(clk, 1);

    report "dot product result: " & integer'image(to_integer(sp))
    severity note;

    file_close(fd_dcc);

    finish;
  end process;

  coeff_ram_addr <= dcc_fod.addr;

  -- components
  cmp_dot_prod_coeff_vec : dot_prod_coeff_vec
    generic map (
      g_A_WIDTH                   => c_A_WIDTH,
      g_ID_WIDTH                  => c_ID_WIDTH,
      g_B_WIDTH                   => c_B_WIDTH,
      g_K_WIDTH                   => c_K_WIDTH,
      g_C_WIDTH                   => c_C_WIDTH,

      g_OUT_FIXED                 => c_OUT_FIXED,
      g_EXTRA_WIDTH               => c_EXTRA_WIDTH
    )
    port map (
      clk_i                       => clk,
      rst_n_i                     => rst_n,

      dcc_valid_i                 => dcc_fod.valid,
      dcc_data_i                  => signed(dcc_fod.data),
      dcc_addr_i                  => dcc_fod.addr,
      dcc_time_frame_start_i      => dcc_time_frame_start,
      dcc_time_frame_end_i        => dcc_time_frame_end,

      coeff_ram_addr_o            => open,
      coeff_ram_data_i            => coeff_ram_data,

      sp_o                        => sp,
      sp_debug_o                  => open,

      sp_valid_o                  => sp_valid,
      sp_valid_debug_o            => open
    );

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
      aa_i                         => coeff_ram_addr,
      da_i                         => (others => '0'),
      qa_o                         => coeff_ram_data,

      -- not used
      clkb_i                       => '0',
      bweb_i                       => (others => '1'),
      web_i                        => '0',
      ab_i                         => (others => '0'),
      db_i                         => (others => '0'),
      qb_o                         => open
    );

end architecture behave;

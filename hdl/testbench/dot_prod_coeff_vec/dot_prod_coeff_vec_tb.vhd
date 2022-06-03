-------------------------------------------------------------------------------
-- Title      :  dot_prod_coeff_vec_tb testbench
-------------------------------------------------------------------------------
-- Author     :  Melissa Aguiar
-- Company    :  CNPEM LNLS GCA
-- Platform   :  FPGA-generic
-------------------------------------------------------------------------------
-- Description:  Testbench for the dot_prod_coeff_vec_tb module.
-------------------------------------------------------------------------------
-- Copyright (c) 2020 CNPEM
-- Licensed under GNU Lesser General Public License (LGPL) v3.0
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                Description
-- 2021-07-30  1.0      melissa.aguiar        Created
-- 2022-06-03  1.1      guilherme.ricioli     Refactored
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.env.finish;
use std.textio.all;

library work;
use work.dot_prod_pkg.all;

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

  constant c_CHANNELS                 : natural := 8;

  constant c_A_WIDTH                  : natural := 32;
  constant c_B_WIDTH                  : natural := 32;
  constant c_ID_WIDTH                 : natural := 9;
  constant c_C_WIDTH                  : natural := 16;

  constant c_OUT_FIXED                : natural := 26;
  constant c_EXTRA_WIDTH              : natural := 4;

  constant c_DCC_FOD                  :
    t_dot_prod_record_fod := (valid => '0',
                              data  => (others => '0'),
                              addr  => (others => '0'));

  -- signals
  signal clk_s                        : std_logic := '0';
  signal rst_n_s                      : std_logic := '0';

  signal dcc_time_frame_start_s       : std_logic := '0';
  signal dcc_time_frame_end_s         : std_logic := '0';
  signal dcc_fod_s                    :
    t_dot_prod_array_record_fod(c_CHANNELS-1 downto 0) := (others => c_DCC_FOD);

  signal sp_arr_s                     :
    t_fofb_processing_setpoints(c_CHANNELS-1 downto 0);
  signal sp_valid_arr_s               :
    std_logic_vector(c_CHANNELS-1 downto 0) := (others => '0');

begin
  f_gen_clk(c_SYS_CLOCK_FREQ, clk_s);

  -- main process
  process
    file BPM_x_file                   : text;
    file BPM_y_file                   : text;
    file k_file                       : text;
    variable x_line, y_line, k_line   : line;
    variable x_datain, y_datain       : integer;
    variable k_datain                 : bit_vector(c_ID_WIDTH-1 downto 0);

  begin
    -- resetting cores
    report "resetting cores"
    severity note;

    rst_n_s <= '0';
    f_wait_cycles(clk_s, 1);
    rst_n_s <= '1';
    f_wait_cycles(clk_s, 10);

    -- loading BPM readings and performing dot product
    report "loading BPM readings and performing dot product"
    severity note;

    file_open(BPM_x_file, "../BPM_x.txt", read_mode);
    file_open(BPM_y_file, "../BPM_y.txt", read_mode);
    file_open(k_file, "../k.txt", read_mode);

    f_wait_cycles(clk_s, 1);
    dcc_time_frame_start_s <= '1';
    f_wait_cycles(clk_s, 1);
    dcc_time_frame_start_s <= '0';

    while not endfile(k_file)
    loop
      f_wait_cycles(clk_s, 1);

      readline(BPM_x_file, x_line);
      read(x_line, x_datain);

      readline(BPM_y_file, y_line);
      read(y_line, y_datain);

      readline(k_file, k_line);
      read(k_line, k_datain);

      -- synthetic dcc data
      for i in 0 to (c_CHANNELS/2 - 1)
      loop
        -- data x goes to even channels
        dcc_fod_s(2*i).data <=
          std_logic_vector(to_signed(x_datain, dcc_fod_s(2*i).data'length));
        dcc_fod_s(2*i).addr <= to_stdlogicvector(k_datain);

        -- data y goes to odd channels
        dcc_fod_s(2*i + 1).data <=
          std_logic_vector(to_signed(y_datain, dcc_fod_s(2*i + 1).data'length));
        dcc_fod_s(2*i + 1).addr <= to_stdlogicvector(k_datain);

        -- signalling that dcc data has 'arrived'
        dcc_fod_s(2*i).valid <= '1';
        dcc_fod_s(2*i + 1).valid  <= '1';
      end loop;

      f_wait_cycles(clk_s, 1);

      for i in 0 to (c_CHANNELS - 1)
      loop
        dcc_fod_s(i).valid <= '0';
      end loop;
    end loop;

    -- NOTE:  This waiting has to be enough for dot_prod_coeff_vec to finish its
    --        processing. It was defined empirically.
    f_wait_cycles(clk_s, 12);
    dcc_time_frame_end_s <= '1';
    f_wait_cycles(clk_s, 1);
    dcc_time_frame_end_s <= '0';

    -- delay added to allow sp_arr_s update to be shown
    f_wait_cycles(clk_s, 20);

    file_close(BPM_x_file);
    file_close(BPM_y_file);
    file_close(k_file);

    finish;
  end process;

  -- components
  gen_cmps_dot_prod_coeff_vec :
    for i in 0 to c_CHANNELS-1
    generate
      cmp_dot_prod_coeff_vec : dot_prod_coeff_vec
        generic map
        (
          g_SIZE                      => 512,
          g_WITH_BYTE_ENABLE          => false,
          g_ADDR_CONFLICT_RESOLUTION  => "read_first",
          g_INIT_FILE                 => "../coeffs.txt",
          g_DUAL_CLOCK                => true,
          g_FAIL_IF_FILE_NOT_FOUND    => true,

          g_A_WIDTH                   => c_A_WIDTH,
          g_B_WIDTH                   => c_B_WIDTH,
          g_ID_WIDTH                  => c_ID_WIDTH,
          g_C_WIDTH                   => c_C_WIDTH,

          g_OUT_FIXED                 => c_OUT_FIXED,
          g_EXTRA_WIDTH               => c_EXTRA_WIDTH
        )
        port map
        (
          clk_i                       => clk_s,
          rst_n_i                     => rst_n_s,

          dcc_valid_i                 => dcc_fod_s(i).valid,
          dcc_data_i                  => signed(dcc_fod_s(i).data),
          dcc_addr_i                  => dcc_fod_s(i).addr,
          dcc_time_frame_start_i      => dcc_time_frame_start_s,
          dcc_time_frame_end_i        => dcc_time_frame_end_s,

          -- not used
          ram_coeff_dat_i             => (others => '0'),
          ram_addr_i                  => (others => '0'),
          ram_write_enable_i          => '0',
          ram_coeff_dat_o             => open,

          sp_o                        => sp_arr_s(i),
          sp_debug_o                  => open,

          sp_valid_o                  => sp_valid_arr_s(i),
          sp_valid_debug_o            => open
        );
    end generate;

end architecture behave;

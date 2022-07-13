-------------------------------------------------------------------------------
-- Title      :  FOFB processing testbench
-------------------------------------------------------------------------------
-- Author     :  Guilherme Ricioli
-- Company    :  CNPEM LNLS GCA
-- Platform   :  FPGA-generic
-------------------------------------------------------------------------------
-- Description:  Testbench for the FOFB processing module.
-------------------------------------------------------------------------------
-- Copyright (c) 2022 CNPEM
-- Licensed under GNU Lesser General Public License (LGPL) v3.0
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                Description
-- 2022-05-31  1.0      guilherme.ricioli     Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.env.finish;
use std.textio.all;

library work;
use work.dot_prod_pkg.all;

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

  constant c_A_WIDTH                  : natural := 32;
  constant c_B_WIDTH                  : natural := 32;
  constant c_K_WIDTH                  : natural := 12;
  constant c_ID_WIDTH                 : natural := 9;
  constant c_C_WIDTH                  : natural := 16;
  constant c_CHANNELS                 : natural := 8;

  constant c_DCC_FOD                  :
    t_dot_prod_record_fod := (valid => '0',
                              data  => (others => '0'),
                              addr  => (others => '0'));

  constant c_ANTI_WINDUP_UPPER_LIMIT  : integer := 1000;
  constant c_ANTI_WINDUP_LOWER_LIMIT  : integer := -1000;

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
    std_logic_vector(c_CHANNELS-1 downto 0);

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
    variable i                        : natural := 0;

  begin
    -- resetting cores
    report "resetting cores"
    severity note;

    rst_n_s <= '0';
    f_wait_cycles(clk_s, 1);
    rst_n_s <= '1';
    f_wait_cycles(clk_s, 10);

    while i < 10
    loop
      -- loading BPM readings
      report "loading BPM readings"
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
        for j in 0 to (c_CHANNELS/2 - 1)
        loop
          -- data x goes to even channels
          dcc_fod_s(2*j).data <=
            std_logic_vector(to_signed(x_datain, dcc_fod_s(2*j).data'length));
          dcc_fod_s(2*j).addr <=
            to_stdlogicvector(k_datain);

          -- data y goes to odd channels
          dcc_fod_s(2*j + 1).data <=
            std_logic_vector(
              to_signed(y_datain, dcc_fod_s(2*j + 1).data'length)
            );
          dcc_fod_s(2*j + 1).addr <=
            to_stdlogicvector(k_datain);

          -- signalling that dcc data has 'arrived'
          dcc_fod_s(2*j).valid <= '1';
          dcc_fod_s(2*j + 1).valid  <= '1';
        end loop;

        f_wait_cycles(clk_s, 1);

        for j in 0 to (c_CHANNELS - 1)
        loop
          dcc_fod_s(j).valid <= '0';
        end loop;
      end loop;

      f_wait_cycles(clk_s, 20);
      dcc_time_frame_end_s <= '1';
      f_wait_cycles(clk_s, 1);
      dcc_time_frame_end_s <= '0';

      file_close(BPM_x_file);
      file_close(BPM_y_file);
      file_close(k_file);

      i := i + 1;
    end loop;

    finish;
  end process;

  -- components
  cmp_fofb_processing : fofb_processing
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
      g_K_WIDTH                   => c_K_WIDTH,
      g_ID_WIDTH                  => c_ID_WIDTH,
      g_C_WIDTH                   => c_C_WIDTH,
      g_CHANNELS                  => c_CHANNELS,

      g_ANTI_WINDUP_UPPER_LIMIT   => c_ANTI_WINDUP_UPPER_LIMIT,
      g_ANTI_WINDUP_LOWER_LIMIT   => c_ANTI_WINDUP_LOWER_LIMIT
    )
    port map
    (
      clk_i                       => clk_s,
      rst_n_i                     => rst_n_s,

      dcc_fod_i                   => dcc_fod_s,
      dcc_time_frame_start_i      => dcc_time_frame_start_s,
      dcc_time_frame_end_i        => dcc_time_frame_end_s,

      ram_coeff_dat_i             => (others => '0'),
      ram_addr_i                  => (others => '0'),
      ram_write_enable_i          => '0',
      ram_coeff_dat_o             => open,

      sp_arr_o                    => sp_arr_s,
      sp_valid_arr_o              => sp_valid_arr_s
    );

end architecture behave;

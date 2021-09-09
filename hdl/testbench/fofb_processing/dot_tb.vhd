-------------------------------------------------------------------------------
-- Title      :  Dot product testbench
-------------------------------------------------------------------------------
-- Author     :  Melissa Aguiar
-- Company    :  CNPEM LNLS-DIG
-- Platform   :  FPGA-generic
-------------------------------------------------------------------------------
-- Description:  Testbench for the dot product top level
-------------------------------------------------------------------------------
-- Copyright (c) 2020 CNPEM
-- Licensed under GNU Lesser General Public License (LGPL) v3.0
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                Description
-- 2021-07-30  1.0      melissa.aguiar        Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.textio.all;

library work;
use work.dot_prod_pkg.all;

entity dot_tb is
end dot_tb;

architecture behave of dot_tb is

  constant clk_period                : time                                       := 6.4 ns;
  constant fofb_ctrl_period          : time                                       := 40 us;

  constant c_a_width                 : natural                                    := 32;
  constant c_k_width                 : natural                                    := 11;
  constant c_id_width                : natural                                    := 9;
  constant c_b_width                 : natural                                    := 32;
  constant c_c_width                 : natural                                    := 16;
  constant c_channels                : natural                                    := 8;

  signal clk_s                       : std_logic                                  := '0';
  signal rst_n_s                     : std_logic                                  := '0';

  signal dcc_time_frame_start_s      : std_logic                                  := '0';
  signal dcc_time_frame_end_s        : std_logic                                  := '0';

  signal fofb_ctrl_s                 : std_logic                                  := '0';
  signal valid_fofb_ctrl_s           : std_logic                                  := '0';
  signal valid_tr                    : std_logic                                  := '0';

  signal ram_write_s                 : std_logic                                  := '1';
  signal ram_finish_s                : std_logic                                  := '0';
  signal ram_data_s                  : std_logic_vector(c_b_width-1 downto 0)     := (others => '0');
  signal ram_addr_s                  : std_logic_vector(c_k_width-1 downto 0)     := (others => '0');

  signal valid_o_s                   : std_logic_vector(c_channels-1 downto 0)    := (others => '0');
  signal valid_debug_s               : std_logic_vector(c_channels-1 downto 0)    := (others => '0');

  signal sp_s                        : t_dot_prod_array_signed(c_channels-1 downto 0);
  signal sp_debug_s                  : t_dot_prod_array_signed(c_channels-1 downto 0);

  constant c_dcc_fod_s               : t_dot_prod_record_fod                      := (valid => '0',
                                                                                      data  => (others => '0'),
                                                                                      addr  => (others => '0'));

  signal dcc_fod_s                   : t_dot_prod_array_record_fod(c_CHANNELS-1 downto 0)
                                                                                  := (others => c_dcc_fod_s);

begin

    fofb_processing_interface : fofb_processing
      port map (
        clk_i                        => clk_s,
        rst_n_i                      => rst_n_s,
        dcc_fod_i                    => dcc_fod_s,
        dcc_time_frame_start_i       => dcc_time_frame_start_s,
        dcc_time_frame_end_i         => dcc_time_frame_end_s,
        ram_coeff_dat_i              => ram_data_s,
        ram_addr_i                   => ram_addr_s,
        ram_write_enable_i           => ram_write_s,
        sp_o                         => sp_s,
        sp_debug_o                   => sp_debug_s,
        sp_valid_o                   => valid_o_s,
        sp_valid_debug_o             => valid_debug_s
      );

  clk_process : process is
  begin
    wait for clk_period/2;
    clk_s                            <= not clk_s;
  end process clk_process;

  fofb_ctrl_process : process is
  begin
    wait for fofb_ctrl_period/2;
    fofb_ctrl_s                      <= not fofb_ctrl_s;
  end process fofb_ctrl_process;

  valid_fofb_ctrl_process : process is
  -- time necessary for testing the product with 160 input elements
  begin
    wait for fofb_ctrl_period/2;
    valid_fofb_ctrl_s                <= '1';
    wait for 2.0576 us;
    valid_fofb_ctrl_s                <= '0';
    wait for 17.9424 us;
  end process valid_fofb_ctrl_process;

  time_frame_start_process : process is
  -- clear accumulator and registers to start the fofb cycle
  begin
    wait for fofb_ctrl_period/2;
    dcc_time_frame_start_s           <= '1';
    wait for clk_period;
    dcc_time_frame_start_s           <= '0';
    wait for fofb_ctrl_period/2-clk_period;
  end process time_frame_start_process;

  time_frame_end_process : process is
  -- validate te output
  begin
    wait for fofb_ctrl_period;
    dcc_time_frame_end_s             <= '1';
    wait for clk_period;
    dcc_time_frame_end_s             <= '0';
    wait for fofb_ctrl_period-clk_period;
  end process time_frame_end_process;

  valid_tr_gen_process : process is
  begin
    if rst_n_s = '0' then
      wait for clk_period;
      rst_n_s                        <= '1';
    end if;

    if rst_n_s = '1' then
      valid_tr                       <= '1';
      wait for clk_period;
      valid_tr                       <= '0';
      wait for clk_period;
    else
      valid_tr                       <= '0';
    end if;
  end process valid_tr_gen_process;

  input_read_process : process(clk_s)
    file a_data_file                 : text open read_mode is "a_k.txt";
    file k_data_file                 : text open read_mode is "k.txt";
    variable a_line, k_line          : line;
    variable a_datain                : integer;
    variable k_datain                : bit_vector(c_id_width-1 downto 0);

  begin
    if rising_edge(clk_s) then
      if not endfile(a_data_file) and valid_tr = '1' and ram_finish_s = '1' and valid_fofb_ctrl_s = '1' and dcc_time_frame_start_s = '0' then
        -- Reading input a[k] from a txt file
        readline(a_data_file, a_line);
        read(a_line, a_datain);

        -- Reading input k from a txt file
        readline(k_data_file, k_line);
        read(k_line, k_datain);

        -- Pass the variable to a signal
        dcc_fod_s(0).data            <= std_logic_vector(to_signed(a_datain, dcc_fod_s(0).data'length));
        dcc_fod_s(0).addr            <= to_stdlogicvector(k_datain);

        -- Update valid input bit
        dcc_fod_s(0).valid           <= '1';

      else
        -- Update valid input bit
        dcc_fod_s(0).valid           <= '0';
      end if;
    end if;
  end process input_read_process;

  ram_input_read_process : process(clk_s)
    file ram_b_data_file             : text open read_mode is "ram_b_k256x8.txt";
    file ram_k_data_file             : text open read_mode is "ram_k256x8.txt";
    variable ram_b_line, ram_k_line  : line;
    variable ram_b_datain            : bit_vector(c_b_width-1 downto 0);
    variable ram_k_datain            : bit_vector(c_k_width-1 downto 0);

  begin
    if rising_edge(clk_s) then
      if  rst_n_s = '1' then
        if not endfile(ram_b_data_file) then
          -- Reading input a[k] from a txt file
          readline(ram_b_data_file, ram_b_line);
          read(ram_b_line, ram_b_datain);

          -- Reading input k from a txt file
          readline(ram_k_data_file, ram_k_line);
          read(ram_k_line, ram_k_datain);

          -- Pass the variable to a signal
          ram_data_s                 <= to_stdlogicvector(ram_b_datain);
          ram_addr_s                 <= to_stdlogicvector(ram_k_datain);
        else
          ram_write_s                <= '0';
          ram_finish_s               <= '1';
        end if;
      end if;
    end if;
  end process ram_input_read_process;

  output_write_process : process(clk_s)
    file ouput_file                  : text open write_mode is "my_output.txt";
    file c_data_file                 : text open read_mode is "c_acc.txt";
    variable o_line, c_line          : line;
    variable dataout, c_datain       : integer;
    variable pass_test               : std_logic := '0';

  begin
    if valid_debug_s(0) = '1' then
      dataout                        := to_integer(sp_debug_s(0));

      if rising_edge(clk_s) then
        -- Write output to a txt file
        write(o_line, dataout);
        writeline(ouput_file, o_line);

        -- Reading input c_acc from a txt file
        readline(c_data_file, c_line);
        read(c_line, c_datain);

        -- Report if the test fails
        if dataout /= c_datain then
          report "FAIL";
          pass_test                  := '0';
        else
          pass_test                  := '1';
        end if;
       end if;

      if endfile(c_data_file) and pass_test = '1' then
        report "SUCESS";
      end if;
    end if;
  end process output_write_process;

end architecture behave;

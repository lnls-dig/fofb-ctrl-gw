-------------------------------------------------------------------------------
-- Title      :  Matrix multiplication testbench
-------------------------------------------------------------------------------
-- Author     :  Melissa Aguiar
-- Company    : CNPEM LNLS-DIG
-- Platform   : FPGA-generic
-------------------------------------------------------------------------------
-- Description:  Testbench for the matrix multiplication core
-------------------------------------------------------------------------------
-- Copyright (c) 2020 CNPEM
-- Licensed under GNU Lesser General Public License (LGPL) v3.0
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                Description
-- 2021-20-07  1.0      melissa.aguiar        Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library std;
use std.textio.all;

library work;
use work.mult_pkg.all;
use work.genram_pkg.all;
use work.memory_loader_pkg.all;

entity mult_tb is
end mult_tb;

architecture behave of mult_tb is

  constant clk_period : time                                       := 0.25 ms;

  constant c_a_width  : natural                                    := 32;
  constant c_k_width  : natural                                    := 9;
  constant c_b_width  : natural                                    := 32;
  constant c_c_width  : natural                                    := 32;
  constant c_mat_size : natural                                    := 8;

  signal clk_s        : std_logic                                  := '0';
  signal rst_s        : std_logic                                  := '0';
  signal v_i_s        : std_logic                                  := '0';
  signal v_o_s        : std_logic                                  := '0';
  signal v_end_s      : std_logic                                  := '0';
  signal valid_tr     : std_logic                                  := '0';

  signal x_s, y_s     : signed(c_a_width-1 downto 0)               := (others => '0');
  signal k_s          : std_logic_vector(c_k_width-1 downto 0)     := (others => '0');
  signal c_s          : signed(c_c_width-1 downto 0)               := (others => '0');

  signal c_acc_s      : signed(c_c_width-1 downto 0)               := (others => '0');
  signal my_out_s     : signed(c_c_width-1 downto 0)               := (others => '0');

begin

  --gen_matrix_multiplication : for i in 0 to c_mat_size-1 generate
    fofb_matmul_top_INST : fofb_matmul_top
      port map (
        clk_i          => clk_s,
        rst_n_i        => rst_s,
        valid_i        => v_i_s,
        coeff_x_dat_i  => x_s,
        coeff_y_dat_i  => y_s,
        coeff_k_addr_i => k_s,
        c_o            => c_s,
        valid_debug_o  => v_o_s,
        valid_end_o    => v_end_s
      );
  --end generate;

  clk_process : process is
  begin
    wait for clk_period/2;
    clk_s <= not clk_s;
  end process clk_process;

  valid_tr_gen : process
  begin
  if rst_s = '1' then
    valid_tr <= '0';
    wait for clk_period;
    valid_tr <= '1';
    wait for clk_period;
  else
    valid_tr <= '0';
    wait for clk_period;
  end if;
  end process;

  input_read : process(clk_s)

   file a_data_file                      : text open read_mode is "a_k.txt";
   file k_data_file                      : text open read_mode is "k.txt";
   variable a_line, k_line               : line;
   variable a_datain                     : integer;
   variable k_datain                     : bit_vector(c_k_width-1 downto 0);

    begin
      if rising_edge(clk_s) then
        rst_s <= '1';

        if not endfile(a_data_file) and valid_tr = '1' then
          -- Reading input a[k] from a txt file
          readline(a_data_file, a_line);
          read(a_line, a_datain);

          -- Reading input k from a txt file
          readline(k_data_file, k_line);
          read(k_line, k_datain);

          -- Pass the variable to a signal
          x_s <= to_signed(a_datain, x_s'length);
          k_s <= to_stdlogicvector(k_datain);

          -- Update valid input bit
          v_i_s <= '1';

        else
          -- Update valid input bit
          v_i_s <= '0';
        end if;
      end if;
  end process input_read;

  output_write : process(clk_s)
    file ouput_file             : text open write_mode is "my_output.txt";
    file c_data_file            : text open read_mode is "c_acc.txt";
    variable o_line, c_line     : line;
    variable dataout, c_datain  : integer;
    variable pass_test          : std_logic := '0';

    begin
      if v_o_s = '1' then
        dataout := to_integer(c_s);

        if rising_edge(clk_s) then
          -- Write output to a txt file
          write(o_line, dataout);
          writeline(ouput_file, o_line);

          -- Reading input c_acc from a txt file
          readline(c_data_file, c_line);
          read(c_line, c_datain);

          -- Report if it the test fail
          if dataout /= c_datain then
            report "FAIL";
            pass_test := '0';
          else
            pass_test := '1';
          end if;
        end if;

        if endfile(c_data_file) and pass_test = '1' then
          report "SUCESS";
        end if;
      end if;
  end process output_write;
end architecture behave;

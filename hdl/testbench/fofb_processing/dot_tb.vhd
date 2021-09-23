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

  constant c_B_WIDTH                 : natural                                    := 32;
  constant c_K_WIDTH                 : natural                                    := 12;
  constant c_ID_WIDTH                : natural                                    := 9;
  constant c_CHANNELS                : natural                                    := 8;

  signal clk_s                       : std_logic                                  := '0';
  signal rst_n_s                     : std_logic                                  := '0';

  signal dcc_time_frame_start_s      : std_logic                                  := '0';
  signal dcc_time_frame_end_s        : std_logic                                  := '0';

  signal fofb_ctrl_s                 : std_logic                                  := '0';
  signal valid_fofb_ctrl_s           : std_logic                                  := '0';
  signal valid_tr                    : std_logic                                  := '0';

  signal ram_write_s                 : std_logic                                  := '1';
  signal ram_finish_s                : std_logic                                  := '0';
  signal ram_data_s                  : std_logic_vector(c_B_WIDTH-1 downto 0)     := (others => '0');
  signal ram_addr_s                  : std_logic_vector(c_K_WIDTH-1 downto 0)     := (others => '0');

  signal valid_o_s                   : std_logic_vector(c_CHANNELS-1 downto 0)    := (others => '0');
  signal valid_debug_s               : std_logic_vector(c_CHANNELS-1 downto 0)    := (others => '0');

  signal sp_s                        : t_dot_prod_array_signed(c_CHANNELS-1 downto 0);
  signal sp_debug_s                  : t_dot_prod_array_signed(c_CHANNELS-1 downto 0);

  constant c_dcc_fod_s               : t_dot_prod_record_fod                      := (valid  => '0',
                                                                                      data   => (others => '0'),
                                                                                      addr   => (others => '0'));

  signal dcc_fod_s                   : t_dot_prod_array_record_fod(c_CHANNELS-1 downto 0)
                                                                                  := (others => c_dcc_fod_s);

begin

    fofb_processing_interface : fofb_processing
      generic map
      (
        -- Standard parameters of generic_dpram
        g_DATA_WIDTH                 => 32,
        g_SIZE                       => 512,
        g_WITH_BYTE_ENABLE           => false,
        g_ADDR_CONFLICT_RESOLUTION   => "read_first",
        g_INIT_FILE                  => "",
        g_DUAL_CLOCK                 => true,
        g_FAIL_IF_FILE_NOT_FOUND     => true,
        -- Width for inputs x and y
        g_A_WIDTH                    => 32,
        -- Width for ram data
        g_B_WIDTH                    => 32,
        -- Width for ram addr
        g_K_WIDTH                    => 12,
        -- Width for dcc addr
        g_ID_WIDTH                   => 9,
        -- Width for output
        g_C_WIDTH                    => 16,
        -- Number of channels
        g_CHANNELS                   => 8
      )
      port map
      (
        clk_i                        => clk_s,
        rst_n_i                      => rst_n_s,
        dcc_fod_i                    => dcc_fod_s,
        dcc_time_frame_start_i       => dcc_time_frame_start_s,
        dcc_time_frame_end_i         => dcc_time_frame_end_s,
        ram_coeff_dat_i              => ram_data_s,
        ram_addr_i                   => ram_addr_s,
        ram_write_enable_i           => '0',
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
  -- validate output
  begin
    wait for fofb_ctrl_period;
    dcc_time_frame_end_s             <= '1';
    wait for clk_period;
    dcc_time_frame_end_s             <= '0';
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
    file x_data_file                 : text open read_mode is "BPM_x.txt";
    file y_data_file                 : text open read_mode is "BPM_y.txt";
    file k_data_file                 : text open read_mode is "k.txt";
    variable x_line, y_line, k_line  : line;
    variable x_datain                : integer;
    variable y_datain                : integer;
    variable k_datain                : bit_vector(c_ID_WIDTH-1 downto 0);

  begin
    if rising_edge(clk_s) then
      if not endfile(x_data_file) and valid_tr = '1' and valid_fofb_ctrl_s = '1' and dcc_time_frame_start_s = '0' then -- and ram_finish_s = '1'
        -- Reading input BPM_x from a txt file
        readline(x_data_file, x_line);
        read(x_line, x_datain);

        -- Reading input BPM_y from a txt file
        readline(y_data_file, y_line);
        read(y_line, y_datain);

        -- Reading input k from a txt file
        readline(k_data_file, k_line);
        read(k_line, k_datain);

        for i in 0 to c_CHANNELS/2-1 loop
          -- Data x
          dcc_fod_s(2*i).data          <= std_logic_vector(to_signed(x_datain, dcc_fod_s(2*i).data'length));
          dcc_fod_s(2*i).addr          <= to_stdlogicvector(k_datain);
          -- Update valid input bit
          dcc_fod_s(2*i).valid         <= '1';

          -- Data y
          dcc_fod_s(2*i+1).data        <= std_logic_vector(to_signed(y_datain, dcc_fod_s(2*i+1).data'length));
          dcc_fod_s(2*i+1).addr        <= to_stdlogicvector(k_datain);
          -- Update valid input bit
          dcc_fod_s(2*i+1).valid       <= '1';
        end loop;
      else
        for i in 0 to c_CHANNELS-1 loop
          -- Update valid input bit
          dcc_fod_s(i).valid         <= '0';
        end loop;
      end if;
    end if;
  end process input_read_process;

--   ram_input_read_process : process(clk_s)
--     file ram_b_data_file             : text open read_mode is "ram_sofb_Q28.txt";
--     file ram_k_data_file             : text open read_mode is "ram_k256x8.txt";
--     variable ram_b_line, ram_k_line  : line;
--     variable ram_b_datain            : bit_vector(c_b_width-1 downto 0);
--     variable ram_k_datain            : bit_vector(c_k_width-1 downto 0);
--
--   begin
--     if rising_edge(clk_s) then
--       if  rst_n_s = '1' then
--         if not endfile(ram_b_data_file) then
--           -- Reading input a[k] from a txt file
--           readline(ram_b_data_file, ram_b_line);
--           read(ram_b_line, ram_b_datain);
--
--           -- Reading input k from a txt file
--           readline(ram_k_data_file, ram_k_line);
--           read(ram_k_line, ram_k_datain);
--
--           -- Pass the variable to a signal
--           ram_data_s                 <= to_stdlogicvector(ram_b_datain);
--           ram_addr_s                 <= to_stdlogicvector(ram_k_datain);
--         else
--           ram_write_s                <= '0';
--           ram_finish_s               <= '1';
--         end if;
--       end if;
--     end if;
--   end process ram_input_read_process;

  output_write_process_SPX : process(clk_s)
    file ouput_file                  : text open write_mode is "my_output_x.txt";
    file c_data_file                 : text open read_mode is "sp_out_x.txt";
    variable o_line, c_line          : line;
    variable dataout, c_datain       : integer;
    variable fail_test               : integer := 0;

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
        if (c_datain /= dataout) then
          fail_test                  := fail_test + 1;
        end if;

        if endfile(c_data_file) and (fail_test = 0) then
          report                     "Horizontal sp_o[0]: SUCESS";
        elsif (fail_test /= 0) then
          report                     "Horizontal sp_o[0]: FAIL";
        end if;
      end if;
    end if;
  end process output_write_process_SPX;

  output_write_process_SPY : process(clk_s)
    file ouput_file                  : text open write_mode is "my_output_y.txt";
    file c_data_file                 : text open read_mode is "sp_out_y.txt";
    variable o_line, c_line          : line;
    variable dataout, c_datain       : integer;
    variable fail_test               : integer := 0;

  begin
    if valid_debug_s(1) = '1' then
      dataout                        := to_integer(sp_debug_s(1));

      if rising_edge(clk_s) then
        -- Write output to a txt file
        write(o_line, dataout);
        writeline(ouput_file, o_line);

        -- Reading input c_acc from a txt file
        readline(c_data_file, c_line);
        read(c_line, c_datain);

        -- Report if the test fails
        if (c_datain /= dataout) then
          fail_test                  := fail_test + 1;
        end if;

        if endfile(c_data_file) and (fail_test = 0) then
          report                     "Vertical sp_o[1]: SUCESS";
        elsif (fail_test /= 0) then
          report                     "Vertical sp_o[1]: FAIL";
        end if;
      end if;
    end if;
  end process output_write_process_SPY;

end architecture behave;

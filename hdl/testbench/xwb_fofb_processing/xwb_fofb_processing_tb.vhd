------------------------------------------------------------------------------
-- Title      : xwb_fofb_processing_tb testbench
------------------------------------------------------------------------------
-- Author     : Guilherme Ricioli Cruz
-- Company    : CNPEM LNLS-GCA
-- Platform   : Simulation
-- Standard   : VHDL 2008
-------------------------------------------------------------------------------
-- Description:  Testbench for the xwb_fofb_processing_tb module.
-------------------------------------------------------------------------------
-- Copyright (c) 2022 CNPEM
-- Licensed under GNU Lesser General Public License (LGPL) v3.0
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author             Description
-- 2022-07-26  1.0      guilherme.ricioli  Created
-- 2022-09-05  2.0      augusto.fraga      Update testbench to match the new
--                                         xwb_fofb_processing interface

-- 2022-09-13  2.1      guilherme.ricioli  Include reference ram and compute/
--                                         check xwb_fofb_processing expected
--                                         output
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library std;
use std.env.finish;
use std.textio.all;

library work;
use work.fofb_ctrl_pkg.all;
use work.dot_prod_pkg.all;
use work.wishbone_pkg.all;
use work.sim_wishbone.all;
use work.wb_fofb_processing_regs_consts_pkg.all;
use work.fofb_tb_pkg.all;

entity xwb_fofb_processing_tb is
  generic (
    -- integer width for the inverse response matrix coefficient input
    g_COEFF_INT_WIDTH              : natural := 0;

    -- fractionary width for the inverse response matrix coefficient input
    g_COEFF_FRAC_WIDTH             : natural := 17;

    -- integer width for the bpm position error input
    g_BPM_POS_INT_WIDTH            : natural := 20;

    -- fractionary width for the bpm position error input
    g_BPM_POS_FRAC_WIDTH           : natural := 0;

    -- extra bits for the dot product accumulator
    g_DOT_PROD_ACC_EXTRA_WIDTH     : natural := 4;

    -- dot product multiply pipeline stages
    g_DOT_PROD_MUL_PIPELINE_STAGES : natural := 2;

    -- dot product accumulator pipeline stages
    g_DOT_PROD_ACC_PIPELINE_STAGES : natural := 2;

    -- gain multiplication pipeline stages
    g_ACC_GAIN_MUL_PIPELINE_STAGES : natural := 2;

    -- number of fofb cycles to simulate
    g_FOFB_NUM_CYC                 : natural := 4;

    -- inverse response matrix coefficients file (in binary)
    g_COEFF_RAM_FILE               : string  := "../coeff_norm.dat";

    -- bpm positions data
    g_FOFB_BPM_POS_FILE            : string  := "../fofb_bpm_pos.dat";

    -- bpm reference orbit data (set-point)
    g_FOFB_BPM_REF_FILE            : string  := "../fofb_bpm_ref.dat";

    -- number of fofb processing channels
    g_CHANNELS                : natural := 12
  );
end entity xwb_fofb_processing_tb;

architecture xwb_fofb_processing_tb_arch of xwb_fofb_processing_tb is
  -- constants
  constant c_SYS_CLOCK_FREQ             : natural := 100_000_000;

  constant c_RAM_BANK_SIZE              : natural :=
    (c_ADDR_WB_FOFB_PROCESSING_REGS_COEFFS_RAM_BANK_1 -
      c_ADDR_WB_FOFB_PROCESSING_REGS_COEFFS_RAM_BANK_0);

  constant c_NUM_OF_COEFFS_PER_CHANNEL  : natural :=
    c_RAM_BANK_SIZE / c_WB_FOFB_PROCESSING_REGS_COEFFS_RAM_BANK_0_SIZE;

  constant c_NUM_OF_SETPOINTS           : natural :=
    c_NUM_OF_COEFFS_PER_CHANNEL;

  -- signals
  signal clk                            : std_logic := '0';
  signal rst_n                          : std_logic := '0';

  signal busy                           : std_logic;
  signal bpm_pos                        :
    signed(c_SP_POS_RAM_DATA_WIDTH-1 downto 0) := (others => '0');
  signal bpm_pos_index                  :
    unsigned(c_SP_COEFF_RAM_ADDR_WIDTH-1 downto 0) := (others => '0');
  signal bpm_pos_valid                  : std_logic := '0';
  signal bpm_time_frame_end             : std_logic := '0';

  signal sp_arr                         :
    t_fofb_processing_sp_arr(g_CHANNELS-1 downto 0);
  signal sp_valid_arr                   :
    std_logic_vector(g_CHANNELS-1 downto 0):= (others => '0');

  signal wb_slave_i                     : t_wishbone_slave_in;
  signal wb_slave_o                     : t_wishbone_slave_out;

  -- shared variables
  shared variable coeff_ram             : t_coeff_ram_data;
  shared variable sp_ram                : t_sp_ram_data;

begin
  f_gen_clk(c_SYS_CLOCK_FREQ, clk);

  -- main process
  process
    variable addr                         : natural := 0;
    variable data                         : std_logic_vector(31 downto 0) :=
      (others => '0');

    variable bpm_pos_reader               : t_bpm_pos_reader;
    variable bpm_x, bpm_y                 : integer;
    variable bpm_x_err, bpm_y_err         : integer;
    variable expec_dot_prod_arr           :
      real_vector(g_CHANNELS-1 downto 0) := (others => 0.0);
    variable expec_fofb_proc_sp_arr       :
      real_vector(g_CHANNELS-1 downto 0) := (others => 0.0);
    variable sp_err                       : real := 0.0;

  begin
    -- loading coefficients and set-point from files
    report "loading coefficients and set-point from files"
    severity note;

    coeff_ram.load_coeff_from_file(g_COEFF_RAM_FILE);
    sp_ram.load_sp_from_file(g_FOFB_BPM_REF_FILE);

    -- resetting cores
    report "resetting cores"
    severity note;

    init(wb_slave_i);
    f_wait_cycles(clk, 10);

    rst_n <= '0';
    f_wait_cycles(clk, 1);
    rst_n <= '1';
    f_wait_cycles(clk, 10);

    -- writing on coefficients rams via wishbone bus
    report "writing on coefficients rams via wishbone bus"
    severity note;

    read32_pl(clk, wb_slave_i, wb_slave_o,
      c_ADDR_WB_FOFB_PROCESSING_REGS_COEFFS_FIXED_POINT_POS, data);
    report "coefficients fixed-point position: " & to_hstring(data)
    severity note;

    addr := c_ADDR_WB_FOFB_PROCESSING_REGS_COEFFS_RAM_BANK_0;
    for i in 0 to (g_CHANNELS - 1)
    loop
      for j in 0 to (c_NUM_OF_COEFFS_PER_CHANNEL - 1)
      loop
        write32_pl(clk, wb_slave_i, wb_slave_o, addr, coeff_ram.get_coeff(j));
        read32_pl(clk, wb_slave_i, wb_slave_o, addr, data);

        assert (data = coeff_ram.get_coeff(j))
          report "wrong ram coefficient at " & natural'image(addr)
          severity error;

        -- address should jump c_WB_FOFB_PROCESSING_REGS_COEFFS_RAM_BANK_0_SIZE
        -- on each iteration (wishbone bus is using byte-granularity)
        addr := addr + c_WB_FOFB_PROCESSING_REGS_COEFFS_RAM_BANK_0_SIZE;
      end loop;
    end loop;

    -- writing on setpoints ram via wishbone bus
    report "writing on setpoints ram via wishbone bus"
    severity note;

    addr := c_ADDR_WB_FOFB_PROCESSING_REGS_SETPOINTS_RAM_BANK;
    for i in 0 to (c_NUM_OF_SETPOINTS - 1)
    loop
      write32_pl(clk, wb_slave_i, wb_slave_o, addr, sp_ram.get_sp(i));
      read32_pl(clk, wb_slave_i, wb_slave_o, addr, data);

      assert (data = sp_ram.get_sp(i))
        report "wrong ram setpoint at " & natural'image(addr)
        severity error;

      -- address should jump c_WB_FOFB_PROCESSING_REGS_SETPOINTS_RAM_BANK_SIZE
      -- on each iteration (wishbone bus is using byte-granularity)
      addr := addr + c_WB_FOFB_PROCESSING_REGS_SETPOINTS_RAM_BANK_SIZE;
    end loop;

    -- opening bpm positions file
    report "opening bpm positions file"
    severity note;

    bpm_pos_reader.open_bpm_pos_file(g_FOFB_BPM_POS_FILE);

    for c in 0 to (g_FOFB_NUM_CYC - 1)
    loop
      -- resetting the expected dot product state
      expec_dot_prod_arr := (others => 0.0);
      for i in 0 to 159 loop
        bpm_pos_reader.read_bpm_pos(bpm_x, bpm_y);

        -- wait for the fofb_processing core to be ready to receive new data
        f_wait_clocked_signal(clk, busy, '0');

        -- new data available (serves the next two clock cycles)
        bpm_pos_valid <= '1';

        -- send bpm x position
        bpm_pos_index <= to_unsigned(i, c_SP_COEFF_RAM_ADDR_WIDTH);
        bpm_pos <= to_signed(bpm_x, c_SP_POS_RAM_DATA_WIDTH);
        f_wait_cycles(clk, 1);

        -- send bpm y position
        bpm_pos_index <= to_unsigned(i + 256, c_SP_COEFF_RAM_ADDR_WIDTH);
        bpm_pos <= to_signed(bpm_y, c_SP_POS_RAM_DATA_WIDTH);
        f_wait_cycles(clk, 1);

        -- data ended
        bpm_pos_valid <= '0';

        -- ########## computing expected dot product internal state ##########
        -- computing bpm position errors
        bpm_x_err := bpm_x - sp_ram.get_sp_integer(i);
        bpm_y_err := bpm_y - sp_ram.get_sp_integer(i + 256);

        -- computing expected dot product internal state
        for j in 0 to g_CHANNELS-1
        loop
          expec_dot_prod_arr(j) := expec_dot_prod_arr(j) +
            real(bpm_x_err) * coeff_ram.get_coeff_real(i, g_COEFF_FRAC_WIDTH);
          expec_dot_prod_arr(j) := expec_dot_prod_arr(j) +
            real(bpm_y_err) * coeff_ram.get_coeff_real(i + 256, g_COEFF_FRAC_WIDTH);
        end loop;
        -- ####### end of: computing expected dot product internal state #######
      end loop;

      -- ########## computing expected fofb processing setpoint ##########
      for i in 0 to g_CHANNELS-1
      loop
        expec_fofb_proc_sp_arr(i) := expec_fofb_proc_sp_arr(i) +
          expec_dot_prod_arr(i);
      end loop;
      -- ########## computing expected fofb processing setpoint ##########

      -- time frame ended
      bpm_time_frame_end <= '1';
      f_wait_cycles(clk, 1);
      bpm_time_frame_end <= '0';
      f_wait_cycles(clk, 1);

      -- wait until the new set-point is ready
      f_wait_clocked_signal(clk, sp_valid_arr(0), '1');

      report "fofb processing cycle " & to_string(c)
      severity note;

      for i in 0 to g_CHANNELS-1
      loop
        -- TODO: this may be problematic for smaller setpoint values
        sp_err := abs((real(to_integer(sp_arr(i))) /
          floor(expec_fofb_proc_sp_arr(i))) - 1.0);

        report "channel: " & to_string(i)
        severity note;

        report "expected setpoint: " &
          to_string(integer(floor(expec_fofb_proc_sp_arr(i))))
        severity note;

        report "setpoint: " & to_string(to_integer(sp_arr(i)))
        severity note;

        if sp_err > 0.01 then
          report "setpoint error: " & to_string(sp_err) & ", too large (> 1%)!"
          severity error;
        else
          report "setpoint error: " & to_string(sp_err) & ", ok!"
          severity note;
        end if;
      end loop;
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
      g_CHANNELS                     => g_CHANNELS,
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
      bpm_time_frame_end_i           => bpm_time_frame_end,
      sp_arr_o                       => sp_arr,
      sp_valid_arr_o                 => sp_valid_arr,
      wb_slv_i                       => wb_slave_i,
      wb_slv_o                       => wb_slave_o
    );

end architecture xwb_fofb_processing_tb_arch;

-------------------------------------------------------------------------------
-- Title      : fofb_processing testbench
-------------------------------------------------------------------------------
-- Author     : Guilherme Ricioli Cruz
-- Company    : CNPEM LNLS GCA
-- Platform   : Simulation
-- Standard   : VHDL 2008
-------------------------------------------------------------------------------
-- Description: Testbench for the fofb_processing module.
--
--               Files usage:
--               * 'coeffs.dat' holds each of the 512 coefficients;
--               * 'dcc_packets.dat' holds [1 - 256] DCC packet fields
--                  organized at each 3 lines (BPM id, x measurement and y
--                  measurement).
-------------------------------------------------------------------------------
-- Copyright (c) 2022 CNPEM
-- Licensed under GNU Lesser General Public License (LGPL) v3.0
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                Description
-- 2022-07-27  1.0      guilherme.ricioli     Created
-- 2022-09-02  2.0      augusto.fraga         Update the testbench to match the
--                                            new fofb_processing version
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library std;
use std.textio.all;

library work;
use work.dot_prod_pkg.all;
use work.genram_pkg.all;
use work.fofb_tb_pkg.all;

entity fofb_processing_tb is
  generic (
    -- Integer width for the inverse response matrix coefficient input
    g_COEFF_INT_WIDTH              : natural := 0;

    -- Fractionary width for the inverse response matrix coefficient input
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

    -- If true, take the average of the last 2 positions for each BPM
    g_USE_MOVING_AVG               : boolean := true;

    -- Number of FOFB cycles to simulate
    g_FOFB_NUM_CYC                 : natural := 4;

    -- Inverse response matrix coefficients file
    g_COEFF_RAM_FILE               : string  := "../coeff_norm.dat";

    -- BPM position data
    g_FOFB_BPM_POS_FILE            : string  := "../fofb_bpm_pos.dat";

    -- BPM reference orbit data (set-point)
    g_FOFB_BPM_REF_FILE            : string  := "../fofb_bpm_ref.dat";

    -- Number of FOFB processing channels
    g_FOFB_CHANNELS                : natural := 2
  );
end fofb_processing_tb;

architecture behave of fofb_processing_tb is
  -- Constants
  constant c_SYS_CLOCK_FREQ   : natural := 100_000_000;

  -- Signals
  signal clk                  : std_logic := '0';
  signal rst_n                : std_logic := '0';

  signal busy                 : std_logic;
  signal bpm_time_frame_end   : std_logic := '0';

  signal bpm_pos              : signed(c_SP_POS_RAM_DATA_WIDTH-1 downto 0) := (others => '0');
  signal bpm_pos_index        : unsigned(c_SP_COEFF_RAM_ADDR_WIDTH-1 downto 0)  := (others => '0');
  signal bpm_pos_valid        : std_logic := '0';

  signal coeff_ram_data_arr   : t_arr_coeff_ram_data(g_FOFB_CHANNELS-1 downto 0);
  signal coeff_ram_addr_arr   : t_arr_coeff_ram_addr(g_FOFB_CHANNELS-1 downto 0);

  signal sp_max               : signed(c_FOFB_SP_WIDTH-1 downto 0) := to_signed(32767, c_FOFB_SP_WIDTH);
  signal sp_min               : signed(c_FOFB_SP_WIDTH-1 downto 0) := to_signed(-32768, c_FOFB_SP_WIDTH);

  signal sp_arr               : t_fofb_processing_sp_arr(g_FOFB_CHANNELS-1 downto 0);
  signal sp_valid_arr         : std_logic_vector(g_FOFB_CHANNELS-1 downto 0) := (others => '0');
  signal clear_acc_arr        : std_logic_vector(g_FOFB_CHANNELS-1 downto 0) := (others => '0');

  signal sp_pos_ram_addr      : std_logic_vector(c_SP_COEFF_RAM_ADDR_WIDTH-1 downto 0);
  signal sp_pos_ram_data      : std_logic_vector(c_SP_POS_RAM_DATA_WIDTH-1 downto 0);

  signal gain_arr             : t_fofb_processing_gain_arr(g_FOFB_CHANNELS-1 downto 0);

  shared variable coeff_ram   : t_coeff_ram_data;
  shared variable sp_ram      : t_sp_ram_data;

  signal fofb_proc_gains      : real_vector(g_FOFB_CHANNELS-1 downto 0) := (others => 0.0);
begin
  -- Generate clock signal
  f_gen_clk(c_SYS_CLOCK_FREQ, clk);

  gen_gains: for i in 0 to g_FOFB_CHANNELS-1 generate
    fofb_proc_gains(i) <= 0.25 + 0.25 * real(i);
    gain_arr(i) <= to_signed(integer(fofb_proc_gains(i) * 2.0**c_FOFB_GAIN_FRAC_WIDTH), c_FOFB_GAIN_WIDTH);
  end generate;

  -- Main simulation process
  process
    variable bpm_pos_reader       : t_bpm_pos_reader;
    variable bpm_x, bpm_y         : integer;
    variable bpm_err_x, bpm_err_y : integer;
    variable dot_prod_acc_simu    : real_vector(g_FOFB_CHANNELS-1 downto 0) := (others => 0.0);
    variable fofb_proc_acc_simu   : real_vector(g_FOFB_CHANNELS-1 downto 0) := (others => 0.0);
    variable bpm_prev_x           : integer_vector(2**c_SP_COEFF_RAM_ADDR_WIDTH-1 downto 0) := (others => 0);
    variable bpm_prev_y           : integer_vector(2**c_SP_COEFF_RAM_ADDR_WIDTH-1 downto 0) := (others => 0);
    variable sp_err               : real := 0.0;
  begin
    -- Load BPM position, set-point and coefficients files
    bpm_pos_reader.open_bpm_pos_file(g_FOFB_BPM_POS_FILE);
    coeff_ram.load_coeff_from_file(g_COEFF_RAM_FILE);
    sp_ram.load_sp_from_file(g_FOFB_BPM_REF_FILE);

    -- Reset all cores
    rst_n <= '0';
    f_wait_cycles(clk, 1);
    rst_n <= '1';
    f_wait_cycles(clk, 10);

    for fofb_cyc in 1 to g_FOFB_NUM_CYC
    loop
      -- Reset the simulated dot product accumulator
      dot_prod_acc_simu := (others => 0.0);
      for i in 0 to 159 loop
        bpm_pos_reader.read_bpm_pos(bpm_x, bpm_y);

        -- Wait for the fofb_processing core to be ready to receive new data
        f_wait_clocked_signal(clk, busy, '0');

        -- New data available
        bpm_pos_valid <= '1';

        -- Send BPM x position
        bpm_pos_index <= to_unsigned(i, c_SP_COEFF_RAM_ADDR_WIDTH);
        bpm_pos <= to_signed(bpm_x, c_SP_POS_RAM_DATA_WIDTH);
        f_wait_cycles(clk, 1);

        -- Send BPM y position
        bpm_pos_index <= to_unsigned(i + 256, c_SP_COEFF_RAM_ADDR_WIDTH);
        bpm_pos <= to_signed(bpm_y, c_SP_POS_RAM_DATA_WIDTH);
        f_wait_cycles(clk, 1);

        -- BPM data ended
        bpm_pos_valid <= '0';

        -- Compute the BPM position error
        if g_USE_MOVING_AVG then
          -- Take the average with the BPM position from the last time frame
          bpm_err_x := ((bpm_x + bpm_prev_x(i)) / 2) - sp_ram.get_sp_integer(i);
          bpm_err_y := ((bpm_y + bpm_prev_y(i)) / 2) - sp_ram.get_sp_integer(i + 256);
        else
          bpm_err_x := bpm_x - sp_ram.get_sp_integer(i);
          bpm_err_y := bpm_y - sp_ram.get_sp_integer(i + 256);
        end if;

        -- Store the current BPM position for computing the average in the next
        -- time frame
        bpm_prev_x(i) := bpm_x;
        bpm_prev_y(i) := bpm_y;

        -- Compute the simulated dot product
        for j in 0 to g_FOFB_CHANNELS-1 loop
          dot_prod_acc_simu(j) := dot_prod_acc_simu(j) + real(bpm_err_x) * coeff_ram.get_coeff_real(i, g_COEFF_FRAC_WIDTH);
          dot_prod_acc_simu(j) := dot_prod_acc_simu(j) + real(bpm_err_y) * coeff_ram.get_coeff_real(i + 256, g_COEFF_FRAC_WIDTH);
        end loop;
      end loop;

      -- Accumulate the simulated dot product result
      for i in 0 to g_FOFB_CHANNELS-1 loop
        fofb_proc_acc_simu(i) := fofb_proc_acc_simu(i) + dot_prod_acc_simu(i) * fofb_proc_gains(i);
      end loop;

      -- Time frame ended
      bpm_time_frame_end <= '1';
      f_wait_cycles(clk, 1);
      bpm_time_frame_end <= '0';
      f_wait_cycles(clk, 1);

      -- Wait until the new set-point is ready
      f_wait_clocked_signal(clk, sp_valid_arr(0), '1');

      report "---- Iteration  " & to_string(fofb_cyc) & " ----" severity note;

      for i in 0 to g_FOFB_CHANNELS-1 loop
        -- This may be problematic for smaller set-point values
        sp_err := abs((real(to_integer(sp_arr(i))) / floor(fofb_proc_acc_simu(i))) - 1.0);

        report "Instance: " & to_string(i) severity note;
        report "Gain: " & to_string(fofb_proc_gains(i)) severity note;
        report "Set point: " & to_string(to_integer(sp_arr(i))) severity note;
        report "Set point simulated: " & to_string(integer(floor(fofb_proc_acc_simu(i)))) severity note;

        if sp_err > 0.01 then
          report "Set point error: " & to_string(sp_err) & " Too large!" severity error;
        else
          report "Set point error: " & to_string(sp_err) & " OK!" severity note;
        end if;
      end loop;
    end loop;

    report "Clearing the set-point accumulator for each channel..." severity note;
    clear_acc_arr <= (others => '1');
    f_wait_cycles(clk, 1);
    clear_acc_arr <= (others => '0');
    f_wait_cycles(clk, 1);

    -- Wait until the new set-point is ready, set timeout to 100 cycles
    f_wait_clocked_signal(clk, sp_valid_arr(0), '1', 100);

    for i in 0 to g_FOFB_CHANNELS-1 loop
      if to_integer(sp_arr(i)) = 0 then
        report "Set-point accumulator " & to_string(i) &" cleared!" severity note;
      else
        report "Set-point accumulator " & to_string(i) &" not cleared! sp = " & to_string(to_integer(sp_arr(i))) severity error;
      end if;
    end loop;

    std.env.finish;
  end process;

  -- Simulate the coefficients and set-point RAM
  process(clk)
  begin
    if rising_edge(clk) then
      for i in 0 to g_FOFB_CHANNELS-1 loop
        coeff_ram_data_arr(i) <= coeff_ram.get_coeff(to_integer(unsigned(coeff_ram_addr_arr(i))));
      end loop;
      sp_pos_ram_data <= sp_ram.get_sp(to_integer(unsigned(sp_pos_ram_addr)));
    end if;
  end process;

  cmp_fofb_processing: fofb_processing
    generic map (
    g_COEFF_INT_WIDTH              => g_COEFF_INT_WIDTH,
    g_COEFF_FRAC_WIDTH             => g_COEFF_FRAC_WIDTH,
    g_BPM_POS_INT_WIDTH            => g_BPM_POS_INT_WIDTH,
    g_BPM_POS_FRAC_WIDTH           => g_BPM_POS_FRAC_WIDTH,
    g_DOT_PROD_ACC_EXTRA_WIDTH     => g_DOT_PROD_ACC_EXTRA_WIDTH,
    g_DOT_PROD_MUL_PIPELINE_STAGES => g_DOT_PROD_MUL_PIPELINE_STAGES,
    g_DOT_PROD_ACC_PIPELINE_STAGES => g_DOT_PROD_ACC_PIPELINE_STAGES,
    g_ACC_GAIN_MUL_PIPELINE_STAGES => g_ACC_GAIN_MUL_PIPELINE_STAGES,
    g_USE_MOVING_AVG               => g_USE_MOVING_AVG,
    g_CHANNELS                     => g_FOFB_CHANNELS
    )
    port map (
      clk_i                        => clk,
      rst_n_i                      => rst_n,

      busy_o                       => busy,

      bpm_pos_i                    => bpm_pos,
      bpm_pos_index_i              => bpm_pos_index,
      bpm_pos_valid_i              => bpm_pos_valid,
      bpm_time_frame_end_i         => bpm_time_frame_end,

      coeff_ram_addr_arr_o         => coeff_ram_addr_arr,
      coeff_ram_data_arr_i         => coeff_ram_data_arr,

      freeze_acc_arr_i             => (others => '0'),
      clear_acc_arr_i              => clear_acc_arr,

      sp_pos_ram_addr_o            => sp_pos_ram_addr,
      sp_pos_ram_data_i            => sp_pos_ram_data,

      gain_arr_i                   => gain_arr,

      sp_max_arr_i                 => (others => sp_max),
      sp_min_arr_i                 => (others => sp_min),

      sp_arr_o                     => sp_arr,
      sp_valid_arr_o               => sp_valid_arr
    );

end architecture behave;

-------------------------------------------------------------------------------
-- Title      : FOFB processing channel testbench
-------------------------------------------------------------------------------
-- Author     : Augusto Fraga Giachero
-- Company    : CNPEM LNLS-GCA
-- Platform   : Simulation
-- Standard   : VHDL 2008
-------------------------------------------------------------------------------
-- Description: FOFB processing channel testbench
-------------------------------------------------------------------------------
-- Copyright (c) 2022 CNPEM
-- Licensed under GNU Lesser General Public License (LGPL) v3.0
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                Description
-- 2022-08-26  1.0      augusto.fraga         Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;
use ieee.fixed_pkg.all;
use ieee.math_real.all;

library std;
use std.textio.all;

library work;
use work.dot_prod_pkg.all;
use work.fofb_tb_pkg.all;

entity fofb_processing_channel_tb is
  generic (
    -- Integer width for the inverse response matrix coefficient input
    g_COEFF_INT_WIDTH              : natural := 0;

    -- Fractionary width for the inverse response matrix coefficient input
    g_COEFF_FRAC_WIDTH             : natural := 17;

    -- Integer width for the BPM position error input
    g_BPM_POS_INT_WIDTH            : natural := 20;

    -- Fractionary width for the BPM position error input
    g_BPM_POS_FRAC_WIDTH           : natural := 0;

    -- Integer width for the accumulator gain input
    g_GAIN_INT_WIDTH               : natural := 7;

    -- Fractionary width for the accumulator gain input
    g_GAIN_FRAC_WIDTH              : natural := 8;

    -- Integer width for the set-point output
    g_SP_INT_WIDTH                 : natural := 15;

    -- Fractionary width for the set-point output
    g_SP_FRAC_WIDTH                : natural := 0;

    -- Extra bits for the dot product accumulator
    g_DOT_PROD_ACC_EXTRA_WIDTH     : natural := 4;

    -- Dot product multiply pipeline stages
    g_DOT_PROD_MUL_PIPELINE_STAGES : natural := 2;

    -- Dot product accumulator pipeline stages
    g_DOT_PROD_ACC_PIPELINE_STAGES : natural := 2;

    -- Gain multiplication pipeline stages
    g_ACC_GAIN_MUL_PIPELINE_STAGES : natural := 2;

    -- Number of FOFB cycles to simulate
    g_FOFB_NUM_CYC                 : natural := 4;

    -- Inverse response matrix coefficients file
    g_COEFF_RAM_FILE               : string  := "../coeff_norm_q31.dat";

    -- BPM position error data
    g_FOFB_BPM_ERR_FILE            : string  := "../fofb_bpm_err.dat"
  );
end fofb_processing_channel_tb;

architecture fofb_processing_channel_tb_arch of fofb_processing_channel_tb is
  -- Send the BPM position error xy pair to the fofb_processing_channel core
  procedure f_send_bpm_err_pos_xy(signal clk               : in std_logic;
                                  bpm_index                : in natural;
                                  bpm_err_x                : in integer;
                                  bpm_err_y                : in integer;
                                  signal busy              : in std_logic;
                                  signal bpm_pos_err       : out signed((g_BPM_POS_INT_WIDTH + g_BPM_POS_FRAC_WIDTH) downto 0);
                                  signal bpm_pos_err_index : out integer;
                                  signal bpm_pos_err_valid : out std_logic
                                  ) is
  begin
    -- Wait for the fofb_processing_channel core to be ready to receive new
    -- data
    f_wait_clocked_signal(clk, busy, '0');
    bpm_pos_err_valid <= '1';
    bpm_pos_err <= to_signed(bpm_err_x, bpm_pos_err'length);
    bpm_pos_err_index <= bpm_index;
    wait until rising_edge(clk);
    bpm_pos_err <= to_signed(bpm_err_y, bpm_pos_err'length);
    -- The coefficients memory has a total of 512 data words, the first 160
    -- words are reserved to the x axis, the following 160 data words starting from
    -- the address 256 are reserved to the y axis
    bpm_pos_err_index <= bpm_index + 256;
    wait until rising_edge(clk);
    bpm_pos_err_valid <= '0';
  end procedure f_send_bpm_err_pos_xy;

  -- Convert the accumulator gain from real to signed with integer and
  -- fractionary parts
  function f_conv_gain(gain : real) return signed is
    constant gain_width : integer := g_GAIN_INT_WIDTH + g_GAIN_FRAC_WIDTH + 1;
  begin
    return to_signed(integer(gain * 2.0**g_GAIN_FRAC_WIDTH), gain_width);
  end function f_conv_gain;

  constant c_COEFF_RAM_ADDR_WIDTH : natural := 9;
  constant c_COEFF_RAM_DATA_WIDTH : natural := 32;
  signal clk                   : std_logic := '0';
  signal rst_n                 : std_logic := '0';
  signal busy                  : std_logic;
  signal bpm_pos_err           : signed((g_BPM_POS_INT_WIDTH + g_BPM_POS_FRAC_WIDTH) downto 0) := (others => '0');
  signal acc_gain              : signed((g_GAIN_INT_WIDTH + g_GAIN_FRAC_WIDTH) downto 0) := (others => '0');
  signal acc_gain_real         : real := 0.5;
  signal clear_acc             : std_logic := '0';
  signal freeze_acc            : std_logic := '0';
  signal bpm_pos_err_valid     : std_logic := '0';
  signal bpm_pos_err_index     : integer range 0 to (2**c_COEFF_RAM_ADDR_WIDTH)-1 := 0;
  signal bpm_time_frame_end    : std_logic := '0';
  signal coeff_ram_addr        : std_logic_vector(c_COEFF_RAM_ADDR_WIDTH-1 downto 0) := (others => '0');
  signal coeff_ram_data        : std_logic_vector(c_COEFF_RAM_DATA_WIDTH-1 downto 0);
  signal sp                    : signed((g_SP_INT_WIDTH + g_SP_FRAC_WIDTH) downto 0) := (others => '0');
  signal sp_max                : sp'subtype := to_signed(32767, sp'length);
  signal sp_min                : sp'subtype := to_signed(-32768, sp'length);
  signal sp_valid              : std_logic := '0';
  shared variable coeff_ram    : t_coeff_ram_data;
begin

  cmp_fofb_processing_channel: fofb_processing_channel
  generic map (
    g_COEFF_INT_WIDTH              => g_COEFF_INT_WIDTH,
    g_COEFF_FRAC_WIDTH             => g_COEFF_FRAC_WIDTH,
    g_BPM_POS_INT_WIDTH            => g_BPM_POS_INT_WIDTH,
    g_BPM_POS_FRAC_WIDTH           => g_BPM_POS_FRAC_WIDTH,
    g_GAIN_INT_WIDTH               => g_GAIN_INT_WIDTH,
    g_GAIN_FRAC_WIDTH              => g_GAIN_FRAC_WIDTH,
    g_SP_INT_WIDTH                 => g_SP_INT_WIDTH,
    g_SP_FRAC_WIDTH                => g_SP_FRAC_WIDTH,
    g_DOT_PROD_ACC_EXTRA_WIDTH     => g_DOT_PROD_ACC_EXTRA_WIDTH,
    g_DOT_PROD_MUL_PIPELINE_STAGES => g_DOT_PROD_MUL_PIPELINE_STAGES,
    g_DOT_PROD_ACC_PIPELINE_STAGES => g_DOT_PROD_ACC_PIPELINE_STAGES,
    g_ACC_GAIN_MUL_PIPELINE_STAGES => g_ACC_GAIN_MUL_PIPELINE_STAGES,
    g_COEFF_RAM_ADDR_WIDTH         => c_COEFF_RAM_ADDR_WIDTH,
    g_COEFF_RAM_DATA_WIDTH         => c_COEFF_RAM_DATA_WIDTH
  )
  port map (
    clk_i                          => clk,
    rst_n_i                        => rst_n,
    busy_o                         => busy,
    bpm_pos_err_i                  => bpm_pos_err,
    bpm_pos_err_valid_i            => bpm_pos_err_valid,
    bpm_pos_err_index_i            => bpm_pos_err_index,
    bpm_time_frame_end_i           => bpm_time_frame_end,
    coeff_ram_addr_o               => coeff_ram_addr,
    coeff_ram_data_i               => coeff_ram_data,
    gain_i                         => acc_gain,
    freeze_acc_i                   => freeze_acc,
    clear_acc_i                    => clear_acc,
    sp_max_i                       => sp_max,
    sp_min_i                       => sp_min,
    sp_o                           => sp,
    sp_valid_o                     => sp_valid
  );

  f_gen_clk(100_000_000, clk);
  acc_gain <= f_conv_gain(acc_gain_real);

  process
    file     fd_fofb_bpm_err                : text;
    variable lin                            : line;
    variable bpm_err_x_data, bpm_err_y_data : integer;
    variable dot_prod_acc_simu              : real := 0.0;
    variable fofb_proc_acc_simu             : real := 0.0;
    variable sp_err                         : real := 0.0;
  begin
    -- Load the coefficients of the inverse response matrix for a single
    -- corrector
    coeff_ram.load_coeff_from_file_binstr(g_COEFF_RAM_FILE);

    -- Wait a single clock cycle to reset all cores
    f_wait_cycles(clk, 1);
    rst_n <= '1';
    f_wait_cycles(clk, 1);

    file_open(fd_fofb_bpm_err, g_FOFB_BPM_ERR_FILE, read_mode);

    for fofb_cyc in 1 to g_FOFB_NUM_CYC loop
      -- Freeze the accumulator in the last iteration
      if fofb_cyc = g_FOFB_NUM_CYC then
        freeze_acc <= '1';
      end if;

      -- Clear the simulated dot product accumulator for each iteraction
      dot_prod_acc_simu := 0.0;

      -- Read the 160 xy BPM position errors for a single time frame
      for i in 0 to 159 loop
        if not endfile(fd_fofb_bpm_err) then
          readline(fd_fofb_bpm_err, lin);
          read(lin, bpm_err_x_data);
          readline(fd_fofb_bpm_err, lin);
          read(lin, bpm_err_y_data);
          f_send_bpm_err_pos_xy(clk, i, bpm_err_x_data, bpm_err_y_data, busy, bpm_pos_err, bpm_pos_err_index, bpm_pos_err_valid);
          dot_prod_acc_simu := dot_prod_acc_simu + real(bpm_err_x_data) * coeff_ram.get_coeff_real(i, g_COEFF_FRAC_WIDTH);
          dot_prod_acc_simu := dot_prod_acc_simu + real(bpm_err_y_data) * coeff_ram.get_coeff_real(i + 256, g_COEFF_FRAC_WIDTH);
        else
          report "File " & g_FOFB_BPM_ERR_FILE & " ended prematurely!" severity error;
        end if;
      end loop;

      if freeze_acc = '0' then
        -- Multiply the simulated dot product result by the gain and accumulate
        fofb_proc_acc_simu := fofb_proc_acc_simu + dot_prod_acc_simu * acc_gain_real;
      end if;

      -- Time frame ended
      bpm_time_frame_end <= '1';
      f_wait_cycles(clk, 1);
      bpm_time_frame_end <= '0';
      f_wait_cycles(clk, 1);

      -- Wait until the new set-point is ready
      f_wait_clocked_signal(clk, sp_valid, '1');

      -- This may be problematic for smaller set-point values
      sp_err := abs((real(to_integer(sp)) / floor(fofb_proc_acc_simu)) - 1.0);

      report "---- Iteration  " & to_string(fofb_cyc) & " ----" severity note;
      report "Gain: " & to_string(acc_gain_real) severity note;
      report "ACC Freeze: " & to_string(freeze_acc) severity note;
      report "Set point: " & to_string(to_integer(sp)) severity note;
      report "Set point simulated: " & to_string(integer(floor(fofb_proc_acc_simu))) severity note;

      if sp_err > 0.005 then
        report "Set point error: " & to_string(sp_err) & " Too large!" severity error;
      else
        report "Set point error: " & to_string(sp_err) & " OK!" severity note;
      end if;

      acc_gain_real <= acc_gain_real + 0.5;
    end loop;

    report "Clearing the set-point accumulator..." severity note;
    clear_acc <= '1';
    f_wait_cycles(clk, 1);
    clear_acc <= '0';
    f_wait_cycles(clk, 1);

    -- Wait until the new set-point is ready, set timeout to 100 cycles
    f_wait_clocked_signal(clk, sp_valid, '1', 100);

    if to_integer(sp) = 0 then
      report "Set-point accumulator cleared!" severity note;
    else
      report "Set-point accumulator not cleared! sp = " & to_string(to_integer(sp)) severity error;
    end if;

    std.env.finish;
  end process;

  -- Simulate the coefficients RAM
  p_coeff_ram: process(clk)
  begin
    if rising_edge(clk) then
      coeff_ram_data <= coeff_ram.get_coeff(to_integer(unsigned(coeff_ram_addr)));
    end if;
  end process;

end architecture;

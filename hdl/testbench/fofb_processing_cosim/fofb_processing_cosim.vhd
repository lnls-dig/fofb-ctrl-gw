-------------------------------------------------------------------------------
-- Title      : FOFB processing co-simulation
-------------------------------------------------------------------------------
-- Author     : Augusto Fraga Giachero
-- Company    : CNPEM LNLS-GCA
-- Platform   : Simulation
-- Standard   : VHDL 2008
-------------------------------------------------------------------------------
-- Description: This testbench is intended to be run as a daemon listening to
--              a TCP port for commands. Valid commads are:
--              - coefficients <list of numbers>
--              - bpm_setpoints <list of numbers>
--              - bpm_positions <list of numbers>
--              - gain <number>
--              - clear_acc
--              - debug
--              - disconnect
--              - exit
-------------------------------------------------------------------------------
-- Copyright (c) 2022 CNPEM
-- Licensed under GNU Lesser General Public License (LGPL) v3.0
-------------------------------------------------------------------------------
-- Revisions   :
-- Date        Version  Author                Description
-- 2022-09-08  1.0      augusto.fraga         Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.dot_prod_pkg.all;
use work.fofb_tb_pkg.all;
use work.fofb_server_pkg.all;

entity fofb_processing_cosim is
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

    -- Maximum setpoint value (saturation)
    g_SP_MAX                       : integer := 32767;

    -- Minimum setpoint value (saturation)
    g_SP_MIN                       : integer := -32768;

    -- TCP port to listen to
    g_TCP_PORT                     : natural := 14050
  );
end fofb_processing_cosim;

architecture rtl of fofb_processing_cosim is
  -- Types
  type t_word32_arr is array (natural range <>) of std_logic_vector(31 downto 0);

  -- Constants
  constant c_FOFB_CHANNELS  : integer := 1;

  -- Signals
  signal clk                : std_logic := '0';
  signal rst_n              : std_logic := '0';
  signal busy               : std_logic;
  signal bpm_pos            : signed(c_SP_POS_RAM_DATA_WIDTH-1 downto 0) := (others => '0');
  signal bpm_pos_index      : unsigned(c_SP_COEFF_RAM_ADDR_WIDTH-1 downto 0)  := (others => '0');
  signal bpm_pos_valid      : std_logic := '0';
  signal bpm_time_frame_end : std_logic := '0';
  signal coeff_ram_data_arr : t_arr_coeff_ram_data(c_FOFB_CHANNELS-1 downto 0);
  signal coeff_ram_addr_arr : t_arr_coeff_ram_addr(c_FOFB_CHANNELS-1 downto 0);
  signal coeff_data_arr     : t_word32_arr(511 downto 0) := (others => x"00000000");
  signal clear_acc_arr      : std_logic_vector(c_FOFB_CHANNELS-1 downto 0) := (others => '0');
  signal sp_max             : signed(c_FOFB_SP_WIDTH-1 downto 0) := to_signed(g_SP_MAX, c_FOFB_SP_WIDTH);
  signal sp_min             : signed(c_FOFB_SP_WIDTH-1 downto 0) := to_signed(g_SP_MIN, c_FOFB_SP_WIDTH);
  signal sp_arr             : t_fofb_processing_sp_arr(c_FOFB_CHANNELS-1 downto 0);
  signal sp_valid_arr       : std_logic_vector(c_FOFB_CHANNELS-1 downto 0) := (others => '0');
  signal sp_data_arr        : t_word32_arr(511 downto 0) := (others => x"00000000");
  signal sp_pos_ram_addr    : std_logic_vector(c_SP_COEFF_RAM_ADDR_WIDTH-1 downto 0);
  signal sp_pos_ram_data    : std_logic_vector(c_SP_POS_RAM_DATA_WIDTH-1 downto 0);
  signal gain_arr           : t_fofb_processing_gain_arr(c_FOFB_CHANNELS-1 downto 0) := (others => (others => '0'));

begin

  -- Generate clock signal
  f_gen_clk(100_000_000, clk);

  process
    variable fofb_server  : t_fofb_server;
    variable sp_o         : integer := 0;
    variable fofb_msg     : t_fofb_server_msg_type;
    variable connected    : boolean := false;
    variable end_simu     : boolean := false;
    variable data         : std_logic_vector(31 downto 0);
    variable data_sig     : signed(31 downto 0);
    variable data_int     : integer;
  begin
    -- Create a new instance of fofb_server
    fofb_server := new_fofb_server(g_TCP_PORT,
                                   c_FOFB_GAIN_FRAC_WIDTH,
                                   31 - g_COEFF_INT_WIDTH,
                                   g_BPM_POS_FRAC_WIDTH);
    -- Reset all cores
    rst_n <= '0';
    f_wait_cycles(clk, 1);
    rst_n <= '1';
    f_wait_cycles(clk, 1);

    -- Main simulation loop
    while end_simu = false loop
      -- Waits for new connections, can only handle one at maximum at any given
      -- time
      report "Waiting for a new connection on port " & to_string(g_TCP_PORT) & " ...";
      fofb_server_wait_con(fofb_server);
      connected := true;

      -- Client connection loop
      while connected loop
        -- Wait for new data from the client
        fofb_server_wait_data(fofb_server, fofb_msg);

        -- Match the received message from the client
        case fofb_msg is
          -- New coefficients received, update the coefficients array
          when COEFF_DATA    =>
            report "New coefficients data";
            for i in 0 to 511 loop
              fofb_server_read_coeff(fofb_server, i, data);
              coeff_data_arr(i) <= data;
            end loop;

          -- New BPM set-point (reference orbit) received, update the
          -- set-point array
          when SETPOINT_DATA =>
            report "New BPM set-point data";
            for i in 0 to 511 loop
              fofb_server_read_sp(fofb_server, i, data);
              sp_data_arr(i) <= data;
            end loop;

          -- New gain value received, update the gain
          when GAIN_DATA     =>
            report "New gain value";
            fofb_server_read_gain(fofb_server, data_int);
            gain_arr(0) <= to_signed(data_int, c_FOFB_GAIN_WIDTH);

          -- New BPM position data, compute a new current set-point
          when BPMPOS_DATA   =>
            report "New BPM Position data";
            for i in 0 to 511 loop
              fofb_server_read_bpm_pos(fofb_server, i, data_sig);
              -- Wait for the fofb_processing core to be ready to receive new data
              f_wait_clocked_signal(clk, busy, '0');
              -- Send BPM position
              bpm_pos_index <= to_unsigned(i, c_SP_COEFF_RAM_ADDR_WIDTH);
              bpm_pos <= data_sig;
              bpm_pos_valid <= '1';
              f_wait_cycles(clk, 1);
              bpm_pos_valid <= '0';
            end loop;

            -- Time frame ended
            bpm_time_frame_end <= '1';
            f_wait_cycles(clk, 1);
            bpm_time_frame_end <= '0';
            f_wait_cycles(clk, 1);

            -- Wait until the new set-point is ready
            f_wait_clocked_signal(clk, sp_valid_arr(0), '1');

            -- Send the fofb_processing output to the client
            sp_o := to_integer(sp_arr(0));
            fofb_server_write_sp(fofb_server, sp_o);

          -- Clear the fofb_processing accumulator
          when CLEAR_ACC     =>
            report "Clear ACC";
            clear_acc_arr <= (others => '1');
            f_wait_cycles(clk, 1);
            clear_acc_arr <= (others => '0');
            f_wait_cycles(clk, 1);

          -- Debug event, do nothing
          when DEBUG         =>
            report "Debug event!";

          -- Finishes the simulation
          when EXIT_SIMU     =>
            report "Exiting...";
            end_simu := true;
            connected := false;

          -- Client disconnected,
          when DISCONNECTED  =>
            report "Client disconnected.";
            connected := false;

          -- Parsing error, ignore message
          when PARSEERR      =>
            report "Could not parse the received data!" severity warning;

          -- This shouldn't be reacheble, but if the fofb_server library
          -- returns an invalid enum, abort
          when others        =>
            report "Invalid message type!" severity error;
        end case;
      end loop;
    end loop;
    std.env.finish;
  end process;

  -- Simulate the coefficients and set-point RAM
  process(clk)
  begin
    if rising_edge(clk) then
      coeff_ram_data_arr(0) <= coeff_data_arr(to_integer(unsigned(coeff_ram_addr_arr(0))));
      sp_pos_ram_data <= sp_data_arr(to_integer(unsigned(sp_pos_ram_addr)));
    end if;
  end process;

  cmp_fofb_processing: fofb_processing
    generic map (
      g_COEFF_INT_WIDTH               => g_COEFF_INT_WIDTH,
      g_COEFF_FRAC_WIDTH              => g_COEFF_FRAC_WIDTH,
      g_BPM_POS_INT_WIDTH             => g_BPM_POS_INT_WIDTH,
      g_BPM_POS_FRAC_WIDTH            => g_BPM_POS_FRAC_WIDTH,
      g_DOT_PROD_ACC_EXTRA_WIDTH      => g_DOT_PROD_ACC_EXTRA_WIDTH,
      g_DOT_PROD_MUL_PIPELINE_STAGES  => g_DOT_PROD_MUL_PIPELINE_STAGES,
      g_DOT_PROD_ACC_PIPELINE_STAGES  => g_DOT_PROD_ACC_PIPELINE_STAGES,
      g_ACC_GAIN_MUL_PIPELINE_STAGES  => g_ACC_GAIN_MUL_PIPELINE_STAGES,
      g_CHANNELS                      => c_FOFB_CHANNELS
    )
    port map (
      clk_i                           => clk,
      rst_n_i                         => rst_n,
      busy_o                          => busy,
      bpm_pos_i                       => bpm_pos,
      bpm_pos_index_i                 => bpm_pos_index,
      bpm_pos_valid_i                 => bpm_pos_valid,
      bpm_time_frame_end_i            => bpm_time_frame_end,
      coeff_ram_addr_arr_o            => coeff_ram_addr_arr,
      coeff_ram_data_arr_i            => coeff_ram_data_arr,
      freeze_acc_arr_i                => (others => '0'),
      clear_acc_arr_i                 => clear_acc_arr,
      sp_pos_ram_addr_o               => sp_pos_ram_addr,
      sp_pos_ram_data_i               => sp_pos_ram_data,
      gain_arr_i                      => gain_arr,
      sp_max_arr_i                    => (others => sp_max),
      sp_min_arr_i                    => (others => sp_min),
      sp_arr_o                        => sp_arr,
      sp_valid_arr_o                  => sp_valid_arr,
      loop_intlk_src_en_i             => (others => '0'),
      loop_intlk_state_clr_i          => '0',
      loop_intlk_state_o              => open,
      loop_intlk_distort_limit_i      => (others => '0'),
      loop_intlk_min_num_meas_i       => (others => '0')
    );

end architecture rtl;

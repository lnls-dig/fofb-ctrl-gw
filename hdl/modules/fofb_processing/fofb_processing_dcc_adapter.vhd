-------------------------------------------------------------------------------
-- Title      : FOFB processing DCC adapter
-------------------------------------------------------------------------------
-- Author     : Augusto Fraga Giachero
-- Company    : CNPEM LNLS-GCA
-- Platform   : FPGA-generic
-- Standard   : VHDL 2008
-------------------------------------------------------------------------------
-- Description: Serialize data comming from the DCC interface, cross clock
--              domains and interface with fofb_processing/xwb_fofb_processing
-------------------------------------------------------------------------------
-- Copyright (c) 2020-2022 CNPEM
-- Licensed under GNU Lesser General Public License (LGPL) v3.0
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                Description
-- 2022-09-26  1.0      augusto.fraga         Created

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

library work;
use work.dot_prod_pkg.all;
use work.fofb_ctrl_pkg.all;
use work.fofb_cc_pkg.all;
use work.genram_pkg.all;

entity fofb_processing_dcc_adapter is
  generic (
    -- DCC packet FIFO depth
    g_FIFO_DATA_DEPTH          : natural := 16
  );
  port (
    -- System clock input
    clk_i                      : in  std_logic;

    -- System reset input (clock domain: clk_i)
    rst_n_i                    : in  std_logic;

    -- DCC clock input
    clk_dcc_i                  : in  std_logic;

    -- DCC reset input (clock domain: clk_dcc_i)
    rst_dcc_n_i                : in  std_logic;

    -- DCC timeframe end signal (clock domain: clk_dcc_i)
    dcc_time_frame_end_i       : in  std_logic;

    -- DCC data packet input (clock domain: clk_dcc_i). You can use the
    -- f_slv_to_fofb_cc_packet() function to convert from std_logic_vector to
    -- t_fofb_cc_packet
    dcc_packet_i               : in  t_fofb_cc_packet;

    -- DCC packet valid (clock domain: clk_dcc_i),
    dcc_packet_valid_i         : in  std_logic;

    -- FOFB processing busy input (clock domain: clk_i)
    fofb_proc_busy_i           : in  std_logic;

    -- FOFB processing BPM position output (clock domain: clk_i)
    fofb_proc_bpm_pos_o        : out signed(c_SP_POS_RAM_DATA_WIDTH-1 downto 0);

    -- FOFB processing BPM index output (clock domain: clk_i). First 256 IDs
    -- are horizontal measurements, last 256 IDs are vertical
    fofb_proc_bpm_pos_index_o  : out unsigned(c_SP_COEFF_RAM_ADDR_WIDTH-1 downto 0);

    -- FOFB processing BPM position valid output (clock domain: clk_i)
    fofb_proc_bpm_pos_valid_o  : out std_logic;

    -- FOFB processing timeframe end output (clock domain: clk_i)
    fofb_proc_time_frame_end_o : out std_logic;

    -- DCC raw data packet from FIFO output for debugging (clock domain: clk_i)
    acq_dcc_packet_o           : out t_fofb_cc_packet;

    -- DCC raw data packet valid (clock domain: clk_i)
    acq_dcc_valid_o            : out std_logic
  );
end entity fofb_processing_dcc_adapter;

architecture rtl of fofb_processing_dcc_adapter is
  type t_state is (IDLE, WAIT_FIFO, SEND_X_DATA, SEND_Y_DATA);
  signal state : t_state;
  signal rd_fifo_pulse: std_logic;
  signal rd_fifo_empty: std_logic;
  signal rd_fifo_data: std_logic_vector(32*PacketSize downto 0);
  signal rd_fifo_decoded_timeframe_end: std_logic;
  signal rd_fifo_decoded_packet: t_fofb_cc_packet;
begin

  cmp_generic_async_fifo : generic_async_fifo
    generic map (
      g_data_width                            => 32*PacketSize+1,
      g_size                                  => g_FIFO_DATA_DEPTH,
      g_show_ahead                            => false,
      g_with_rd_empty                         => true,
      g_with_rd_full                          => false,
      g_with_rd_almost_empty                  => false,
      g_with_rd_almost_full                   => false,
      g_with_rd_count                         => false,
      g_with_wr_empty                         => false,
      g_with_wr_full                          => true,
      g_with_wr_almost_empty                  => false,
      g_with_wr_almost_full                   => false,
      g_with_wr_count                         => false,
      g_almost_empty_threshold                => 0,
      g_almost_full_threshold                 => 0
    )
    port map (
      rst_n_i                                 => rst_dcc_n_i,
      clk_wr_i                                => clk_dcc_i,
      d_i                                     => dcc_time_frame_end_i & f_fofb_cc_packet_to_slv(dcc_packet_i),
      we_i                                    => dcc_time_frame_end_i or dcc_packet_valid_i,
      wr_empty_o                              => open,
      wr_full_o                               => open,
      wr_almost_empty_o                       => open,
      wr_almost_full_o                        => open,
      wr_count_o                              => open,
      clk_rd_i                                => clk_i,
      q_o                                     => rd_fifo_data,
      rd_i                                    => rd_fifo_pulse,
      rd_empty_o                              => rd_fifo_empty,
      rd_full_o                               => open,
      rd_almost_empty_o                       => open,
      rd_almost_full_o                        => open,
      rd_count_o                              => open
    );

  -- Decode DCC packet
  rd_fifo_decoded_timeframe_end <= rd_fifo_data(rd_fifo_data'left);
  rd_fifo_decoded_packet <= f_slv_to_fofb_cc_packet(rd_fifo_data(rd_fifo_data'left-1 downto 0));

  process(clk_i)
    begin
      if rising_edge(clk_i) then
        if rst_n_i = '0' then
          state <= IDLE;
          fofb_proc_bpm_pos_valid_o <= '0';
          fofb_proc_time_frame_end_o <= '0';
          rd_fifo_pulse <= '0';
          acq_dcc_valid_o <= '0';
          fofb_proc_bpm_pos_o <= (others => '0');
          fofb_proc_bpm_pos_index_o <= (others => '0');
          acq_dcc_packet_o.bpm_id <= (others => '0');
          acq_dcc_packet_o.bpm_data_x <= (others => '0');
          acq_dcc_packet_o.bpm_data_y <= (others => '0');
          acq_dcc_packet_o.time_stamp <= (others => '0');
          acq_dcc_packet_o.time_frame <= (others => '0');
        else
        end if;
        case state is
          when IDLE =>
            fofb_proc_bpm_pos_valid_o <= '0';
            fofb_proc_time_frame_end_o <= '0';
            -- If there is any data to be read from the FIFO, read it in the
            -- SEND_X_DATA state
            if rd_fifo_empty = '0' then
              rd_fifo_pulse <= '1';
              state <= WAIT_FIFO;
            end if;
          when WAIT_FIFO =>
            -- Wait a dummy cycle for the FIFO data to be available
            rd_fifo_pulse <= '0';
            state <= SEND_X_DATA;
          when SEND_X_DATA =>
            -- Check if the received data is a timeframe end signal
            if rd_fifo_decoded_timeframe_end = '1' then
              -- Send a end of timeframe condition and go back to IDLE
              fofb_proc_time_frame_end_o <= '1';
              state <= IDLE;
            elsif fofb_proc_busy_i = '0' then
              -- Send BPM horizontal measurement
              fofb_proc_bpm_pos_o <= rd_fifo_decoded_packet.bpm_data_x;
              fofb_proc_bpm_pos_index_o <= rd_fifo_decoded_packet.bpm_id;
              fofb_proc_bpm_pos_valid_o <= '1';

              -- Indicate that a new DCC packet has been read
              acq_dcc_packet_o <= rd_fifo_decoded_packet;
              acq_dcc_valid_o <= '1';

              -- Goto SEND_Y_DATA state
              state <= SEND_Y_DATA;
            end if;
          when SEND_Y_DATA =>
            acq_dcc_valid_o <= '0';

              -- Send BPM vertical measurement
            fofb_proc_bpm_pos_o <= rd_fifo_decoded_packet.bpm_data_y;
            fofb_proc_bpm_pos_index_o <= rd_fifo_decoded_packet.bpm_id;
            -- Set the bpm index MSB to indicate it is a vertical measurement
            fofb_proc_bpm_pos_index_o(fofb_proc_bpm_pos_index_o'left) <= '1';

            -- Go back to IDLE
            state <= IDLE;
        end case;
      end if;
  end process;
end architecture rtl;

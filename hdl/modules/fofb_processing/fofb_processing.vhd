-------------------------------------------------------------------------------
-- Title      :  FOFB processing module
-------------------------------------------------------------------------------
-- Author     :  Melissa Aguiar
-- Company    :  CNPEM LNLS-DIG
-- Platform   :  FPGA-generic
-------------------------------------------------------------------------------
-- Description:  Processing module for the Fast Orbit Feedback
-------------------------------------------------------------------------------
-- Copyright (c) 2020 CNPEM
-- Licensed under GNU Lesser General Public License (LGPL) v3.0
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                Description
-- 2021-08-26  1.0      melissa.aguiar        Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

library work;
-- Dot product package
use work.dot_prod_pkg.all;
-- RAM package
use work.genram_pkg.all;

entity fofb_processing is
  generic(
    -- Standard parameters of generic_dpram
    g_SIZE                         : natural := 512;
    g_WITH_BYTE_ENABLE             : boolean := false;
    g_ADDR_CONFLICT_RESOLUTION     : string  := "read_first";
    g_INIT_FILE                    : string  := "";
    g_DUAL_CLOCK                   : boolean := true;
    g_FAIL_IF_FILE_NOT_FOUND       : boolean := true;

    -- Width for DCC input
    g_A_WIDTH                      : natural := 32;

    -- Width for RAM coeff
    g_B_WIDTH                      : natural := 32;

    -- Width for RAM addr
    g_K_WIDTH                      : natural := 12;

    -- Width for DCC addr
    g_ID_WIDTH                     : natural := 9;

    -- Width for output
    g_C_WIDTH                      : natural := 16;

    -- Fixed point representation for output
    g_OUT_FIXED                    : natural := 26;

    -- Extra bits for accumulator
    g_EXTRA_WIDTH                  : natural := 4;

    -- Number of channels
    g_CHANNELS                     : natural := 8
  );
  port(
    ---------------------------------------------------------------------------
    -- FOFB processing interface
    ---------------------------------------------------------------------------
    -- Clock core
    clk_i                          : in std_logic;

    -- Reset
    rst_n_i                        : in std_logic;

    -- DCC interface
    dcc_fod_i                      : in t_dot_prod_array_record_fod(g_CHANNELS-1 downto 0);
    dcc_time_frame_start_i         : in std_logic;
    dcc_time_frame_end_i           : in std_logic;

    -- RAM interface
    ram_coeff_dat_i                : in std_logic_vector(g_B_WIDTH-1 downto 0);
    ram_addr_i                     : in std_logic_vector(g_K_WIDTH-1 downto 0);
    ram_write_enable_i             : in std_logic;
    ram_coeff_dat_o                : out std_logic_vector(g_B_WIDTH-1 downto 0);

    -- Result output array
    sp_o                           : out t_dot_prod_array_signed(g_CHANNELS-1 downto 0);
    sp_debug_o                     : out t_dot_prod_array_signed(g_CHANNELS-1 downto 0);

    -- Valid output
    sp_valid_o                     : out std_logic_vector(g_CHANNELS-1 downto 0);
    sp_valid_debug_o               : out std_logic_vector(g_CHANNELS-1 downto 0)
  );
  end fofb_processing;

architecture behave of fofb_processing is
  signal aa_s                      : std_logic_vector(g_ID_WIDTH-1 downto 0) := (others => '0');
  signal wea_s                     : std_logic_vector(g_CHANNELS-1 downto 0) := (others => '0');
begin

  ram_write : process(clk_i)
  begin
    if (rising_edge(clk_i)) then

      if dcc_time_frame_start_i = '1' then
        aa_s                       <= (others => '0');
        wea_s                      <= (others => '0');
      else
        aa_s                       <= ram_addr_i(g_K_WIDTH-f_log2_size(g_CHANNELS)-1 downto 0);

        for i in 0 to g_CHANNELS-1 loop
          if ram_addr_i(g_K_WIDTH-1 downto g_K_WIDTH-f_log2_size(g_CHANNELS)) = std_logic_vector(to_unsigned(i, f_log2_size(g_CHANNELS))) then
            wea_s(i)               <= ram_write_enable_i;
          else
            wea_s(i)               <= '0';
          end if;
        end loop;
      end if; -- Clear
    end if; -- Clock
  end process ram_write;

  gen_channels : for i in 0 to g_CHANNELS-1 generate
    fofb_processing_channel_interface : fofb_processing_channel
      generic map
      (
        -- Standard parameters of generic_dpram
        g_SIZE                     => g_SIZE,
        g_WITH_BYTE_ENABLE         => g_WITH_BYTE_ENABLE,
        g_ADDR_CONFLICT_RESOLUTION => g_ADDR_CONFLICT_RESOLUTION,
        g_INIT_FILE                => g_INIT_FILE,
        g_DUAL_CLOCK               => g_DUAL_CLOCK,
        g_FAIL_IF_FILE_NOT_FOUND   => g_FAIL_IF_FILE_NOT_FOUND,
        -- Width for inputs x and y
        g_A_WIDTH                  => g_A_WIDTH,
        -- Width for ram data
        g_B_WIDTH                  => g_B_WIDTH,
        -- Width for dcc addr
        g_ID_WIDTH                 => g_ID_WIDTH,
        -- Width for output
        g_C_WIDTH                  => g_C_WIDTH,
        -- Fixed point representation for output
        g_OUT_FIXED                => g_OUT_FIXED,
        -- Extra bits for accumulator
        g_EXTRA_WIDTH              => g_EXTRA_WIDTH
      )
      port map
      (
        clk_i                      => clk_i,
        rst_n_i                    => rst_n_i,
        dcc_valid_i                => dcc_fod_i(i).valid,
        dcc_data_i                 => signed(dcc_fod_i(i).data),
        dcc_addr_i                 => dcc_fod_i(i).addr,
        dcc_time_frame_start_i	   => dcc_time_frame_start_i,
        dcc_time_frame_end_i       => dcc_time_frame_end_i,
        ram_coeff_dat_i            => ram_coeff_dat_i,
        ram_addr_i                 => aa_s,
        ram_write_enable_i         => wea_s(i),
        ram_coeff_dat_o            => ram_coeff_dat_o,
        sp_o                       => sp_o(i),
        sp_debug_o                 => sp_debug_o(i),
        sp_valid_o                 => sp_valid_o(i),
        sp_valid_debug_o           => sp_valid_debug_o(i)
      );
    end generate;

end architecture behave;

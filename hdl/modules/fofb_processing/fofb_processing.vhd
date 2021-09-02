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

entity fofb_processing is
  generic(
    -- Standard parameters of generic_dpram
    g_data_width                   : natural := 32;
    g_size                         : natural := c_size_dpram;
    g_with_byte_enable             : boolean := false;
    g_addr_conflict_resolution     : string  := "read_first";
    g_init_file                    : string  := "";
    g_dual_clock                   : boolean := true;
    g_fail_if_file_not_found       : boolean := true;

    -- Width for DCC input
    g_a_width                      : natural := 32;

    -- Width for RAM data
    g_b_width                      : natural := 32;

    -- Width for RAM addr
    g_k_width                      : natural := 11;

    -- Width for output
    g_c_width                      : natural := 32;

    -- Number of channels
    g_channels                     : natural := 8
  );
  port (
    ---------------------------------------------------------------------------
    -- FOFB processing interface
    ---------------------------------------------------------------------------
    -- Clock core
    clk_i                          : in std_logic;

    -- Reset
    rst_n_i                        : in std_logic;

    -- DCC interface
    dcc_valid_i                    : in std_logic;
    dcc_coeff_i                    : in signed(g_a_width-1 downto 0);
    dcc_addr_i                     : in std_logic_vector(g_k_width-1 downto 0);
    dcc_time_frame_start_i				 : in std_logic;
    dcc_time_frame_end_i					 : in std_logic;

    -- RAM interface
    ram_coeff_dat_i                : in std_logic_vector(g_b_width-1 downto 0);
    ram_addr_i                     : in std_logic_vector(g_k_width-1 downto 0);
    ram_write_enable_i             : in std_logic;

    -- Result output array
    sp_o                           : out t_dot_prod_array_signed(g_channels-1 downto 0);
    sp_debug_o                     : out t_dot_prod_array_signed(g_channels-1 downto 0);

    -- Valid output
    sp_valid_o                     : out std_logic_vector(g_channels-1 downto 0);
    sp_valid_debug_o               : out std_logic_vector(g_channels-1 downto 0)
  );
  end fofb_processing;

architecture behave of fofb_processing is
  signal aa_s                      : std_logic_vector(g_k_width-1 downto 0)  := (others => '0');
  signal wea_s                     : std_logic_vector(g_channels-1 downto 0) := (others => '0');
begin

  ram_write : process(clk_i)
  begin
    if (rising_edge(clk_i)) then

    	if dcc_time_frame_start_i = '1' then
    		aa_s										 	 <= (others => '0');
    		wea_s										   <= (others => '0');
    	end if;

      aa_s(g_k_width-4 downto 0)   <= ram_addr_i(g_k_width-4 downto 0);

      if ram_addr_i(g_k_width-1 downto g_k_width-3) = "000" then wea_s(0) <= ram_write_enable_i; else wea_s(0) <= '0'; end if;
      if ram_addr_i(g_k_width-1 downto g_k_width-3) = "001" then wea_s(1) <= ram_write_enable_i; else wea_s(1) <= '0'; end if;
      if ram_addr_i(g_k_width-1 downto g_k_width-3) = "010" then wea_s(2) <= ram_write_enable_i; else wea_s(2) <= '0'; end if;
      if ram_addr_i(g_k_width-1 downto g_k_width-3) = "011" then wea_s(3) <= ram_write_enable_i; else wea_s(3) <= '0'; end if;
      if ram_addr_i(g_k_width-1 downto g_k_width-3) = "100" then wea_s(4) <= ram_write_enable_i; else wea_s(4) <= '0'; end if;
      if ram_addr_i(g_k_width-1 downto g_k_width-3) = "101" then wea_s(5) <= ram_write_enable_i; else wea_s(5) <= '0'; end if;
      if ram_addr_i(g_k_width-1 downto g_k_width-3) = "110" then wea_s(6) <= ram_write_enable_i; else wea_s(6) <= '0'; end if;
      if ram_addr_i(g_k_width-1 downto g_k_width-3) = "111" then wea_s(7) <= ram_write_enable_i; else wea_s(7) <= '0'; end if;
    end if;
  end process ram_write;

  gen_channels : for i in 0 to g_channels-1 generate
    fofb_processing_channel_interface : fofb_processing_channel
      port map (
        clk_i                        => clk_i,
        rst_n_i                      => rst_n_i,
        dcc_valid_i                  => dcc_valid_i,
        dcc_coeff_i                  => dcc_coeff_i,
        dcc_addr_i                   => dcc_addr_i,
        dcc_time_frame_start_i			 => dcc_time_frame_start_i,
    		dcc_time_frame_end_i				 => dcc_time_frame_end_i,
        ram_coeff_dat_i              => ram_coeff_dat_i,
        ram_addr_i                   => aa_s,
        ram_write_enable_i           => wea_s(i),
        sp_o                         => sp_o(i),
        sp_debug_o                   => sp_debug_o(i),
        sp_valid_o                   => sp_valid_o(i),
        sp_valid_debug_o             => sp_valid_debug_o(i)
      );
    end generate;

end architecture behave;

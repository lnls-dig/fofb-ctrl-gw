-------------------------------------------------------------------------------
-- Title      : FOFB Testbench package
-------------------------------------------------------------------------------
-- Author     : Augusto Fraga Giachero
-- Company    : CNPEM LNLS-GCA
-- Platform   : Simulation
-- Standard   : VHDL 2008
-------------------------------------------------------------------------------
-- Description: Reusable procedures, functions and types for the FOFB
--              testbenches
-------------------------------------------------------------------------------
-- Copyright (c) 2022 CNPEM
-- Licensed under GNU Lesser General Public License (LGPL) v3.0
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                Description
-- 2022-09-02  1.0      augusto.fraga         Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library std;
use std.textio.all;

package fofb_tb_pkg is
  -- Generate periodic clock signal
  procedure f_gen_clk(constant freq : in    natural;
                      signal   clk  : inout std_logic);

  -- Wait for a number of clock cycles
  procedure f_wait_cycles(signal   clk    : in std_logic;
                          constant cycles : natural);

  -- Wait for clocked signal with a timeout
  procedure f_wait_clocked_signal(signal clk : in std_logic;
                                  signal sig : in std_logic;
                                  val        : in std_logic;
                                  timeout    : in natural := 2147483647);

  -- Define protected type to store the coefficients data
  type t_coeff_ram_data is protected
    procedure load_coeff_from_file(fname : string);
    procedure load_coeff_from_file_binstr(fname : string);
    impure function get_coeff(coeff_index : natural) return std_logic_vector;
    impure function get_coeff_real(coeff_index : natural; precision : natural) return real;
  end protected t_coeff_ram_data;

  -- Define protected type to store the reference orbit (set-point)
  type t_sp_ram_data is protected
    procedure load_sp_from_file(fname : string);
    impure function get_sp(sp_index : natural) return std_logic_vector;
    impure function get_sp_integer(sp_index : natural) return integer;
  end protected t_sp_ram_data;

  type t_bpm_pos_reader is protected
    procedure open_bpm_pos_file(fname : string);
    procedure read_bpm_pos(bpm_x : out integer; bpm_y : out integer);
  end protected t_bpm_pos_reader;

end package fofb_tb_pkg;

package body fofb_tb_pkg is
  procedure f_gen_clk(constant freq : in    natural;
                      signal   clk  : inout std_logic) is
  begin
    loop
      wait for (0.5 / real(freq)) * 1 sec;
      clk <= not clk;
    end loop;
  end procedure f_gen_clk;

  procedure f_wait_cycles(signal   clk    : in std_logic;
                          constant cycles : natural) is
  begin
    for i in 1 to cycles loop
      wait until rising_edge(clk);
    end loop;
  end procedure f_wait_cycles;

  -- Wait for the input signal 'sig' to reach the value specified in the 'val'
  -- input, advance clock signals until the codition is met
  procedure f_wait_clocked_signal(signal clk : in std_logic;
                                  signal sig : in std_logic;
                                  val        : in std_logic;
                                  timeout    : in natural := 2147483647) is
  variable cnt : natural := timeout;
  begin
    while sig /= val and cnt > 0 loop
      wait until rising_edge(clk);
      cnt := cnt - 1;
    end loop;
  end procedure f_wait_clocked_signal;

  type t_coeff_ram_data is protected body
    type t_coeff_array is array (natural range <>) of std_logic_vector(31 downto 0);
    variable coeff_array : t_coeff_array(511 downto 0) := (others => x"00000000");

    -- Load coefficients from a file, it assumes a text file with each line
    -- containing the coefficient value in floating point format, normalized
    -- between -1.0 and +1.0
    procedure load_coeff_from_file(fname : string) is
      file     fin        : text;
      variable status     : file_open_status;
      variable lin        : line;
      variable coeff_real : real;
      variable coeff_int  : integer;
      begin
        file_open(status, fin, fname, read_mode);
        for i in 0 to coeff_array'length-1 loop
          if not endfile(fin) then
            readline(fin, lin);
            read(lin, coeff_real);
          else
            coeff_real := 0.0;
          end if;
          -- TODO: there is a subtle bug here if the vhdl REAL type is
          -- using 64 bits float types, there are numbers > 1.0 that multiplied
          -- by 2^31 might be rounded to integer 2^31, exceeding the maximum
          -- representable 32-bits integer number
          if coeff_real >= 1.0 then
            coeff_array(i) := x"7FFFFFFF";
          elsif coeff_real <= -1.0 then
            coeff_array(i) := x"80000000";
          else
            coeff_int := integer(coeff_real * 2.0**31);
            coeff_array(i) := std_logic_vector(to_signed(coeff_int, 32));
          end if;
        end loop;
    end procedure load_coeff_from_file;

    -- Load coefficients from a file, it assumes a text file with each line
    -- containing the coefficient value in a binary string
    procedure load_coeff_from_file_binstr(fname : string) is
      file fin          : text;
      variable status   : file_open_status;
      variable lin      : line;
      variable coeff_bv : bit_vector(31 downto 0);
      begin
        file_open(status, fin, fname, read_mode);
        for i in 0 to coeff_array'length-1 loop
          if not endfile(fin) then
            readline(fin, lin);
            read(lin, coeff_bv);
          else
            coeff_bv := (others => '0');
          end if;
          coeff_array(i) := to_stdlogicvector(coeff_bv);
        end loop;
    end procedure load_coeff_from_file_binstr;

    -- Get the coefficient data as an 32 bits std_logic_vector
    impure function get_coeff(coeff_index : natural) return std_logic_vector is
    begin
      return coeff_array(coeff_index);
    end function get_coeff;

    -- Get the coefficient converted to real, take in consideration the
    -- specified precision in bits
    impure function get_coeff_real(coeff_index : natural; precision : natural) return real is
    begin
      return real(to_integer(signed(coeff_array(coeff_index)(31 downto 31 - precision)))) * 2.0**(-precision);
    end function get_coeff_real;
  end protected body t_coeff_ram_data;

  type t_sp_ram_data is protected body
    type t_sp_array is array (natural range <>) of std_logic_vector(31 downto 0);
    variable sp_array : t_sp_array(511 downto 0) := (others => x"00000000");

    -- Load bpm setpoints from a file, it assumes a text file with first 256
    -- lines been the bpm x positions, and last 256 lines been the bpm y
    -- positions in nanometers (integer)
    procedure load_sp_from_file(fname : string) is
      file fin          : text;
      variable status   : file_open_status;
      variable lin      : line;
      variable sp_int   : integer;
      begin
        file_open(status, fin, fname, read_mode);
        for i in 0 to sp_array'length-1 loop
          if not endfile(fin) then
            readline(fin, lin);
            read(lin, sp_int);
          else
            sp_int := 0;
          end if;
          sp_array(i) := std_logic_vector(to_signed(sp_int, 32));
        end loop;
    end procedure;

    -- Get the bpm set-point data as an 32 bits std_logic_vector
    impure function get_sp(sp_index : natural) return std_logic_vector is
    begin
      return sp_array(sp_index);
    end function get_sp;

    -- Get the bpm set-point data as an integer
    impure function get_sp_integer(sp_index : natural) return integer is
    begin
      return to_integer(signed(sp_array(sp_index)));
    end function get_sp_integer;
  end protected body t_sp_ram_data;

  type t_bpm_pos_reader is protected body
    file fin : text;
    -- Open BPM positions file, each pair of lines represents a position in
    -- nanometers, the first line of the pair is the horizontal position, the
    -- other is the vertical position
    procedure open_bpm_pos_file(fname : string) is
    begin
      file_open(fin, fname, read_mode);
    end procedure;

    -- Read the next bpm position
    procedure read_bpm_pos(bpm_x : out integer; bpm_y : out integer) is
    variable lin : line;
    begin
      if not endfile(fin) then
        readline(fin, lin);
        read(lin, bpm_x);
        readline(fin, lin);
        read(lin, bpm_y);
      else
        report "File ended prematurely!" severity error;
      end if;
    end procedure;
  end protected body t_bpm_pos_reader;

end package body fofb_tb_pkg;

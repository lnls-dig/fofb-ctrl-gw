-------------------------------------------------------------------------------
-- Title      : FOFB Server wrapper functions and procedures
-------------------------------------------------------------------------------
-- Author     : Augusto Fraga Giachero
-- Company    : CNPEM LNLS-GCA
-- Platform   : Simulation / GHDL
-------------------------------------------------------------------------------
-- Description: Interface between the fofb_server library using VHPIDIRECT
-------------------------------------------------------------------------------
-- Copyright (c) 2022 CNPEM
-- Licensed under GNU Lesser General Public License (LGPL) v3.0
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                Description
-- 2022-09-13  1.0      augusto.fraga         Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package fofb_server_pkg is
  -- VHDL doesn't have pointers like other languages, so when interfacing with
  -- Rust code we need a type that can hold an opaque pointer that refers to
  -- the object instance. Turns out that an 'access' type is effectively a
  -- pointer from the GHDL perspective, so we can use it to hold the FOFBServer
  -- struct reference. The only caveats are that we can only pass it as an
  -- argument to procedures and it seems that GHDL will automatically free
  -- the memory pointed by the 'access' type.
  type t_fofb_server is access integer;
  type t_fofb_server_msg_type is (COEFF_DATA, SETPOINT_DATA, BPMPOS_DATA, GAIN_DATA, CLEAR_ACC, DEBUG, DISCONNECTED, PARSEERR, EXIT_SIMU);

  -- Create a new fofb server instance.
  impure function new_fofb_server (tcp_port          : natural range 0 to 65535;
                                   gain_frac_width   : natural range 0 to 31;
                                   coeffs_frac_width : natural range 0 to 31;
                                   bpm_frac_width    : natural range 0 to 31)
                                   return t_fofb_server;
  attribute foreign of new_fofb_server : function is "VHPIDIRECT new_fofb_server";

  -- Wait for a new client connection.
  procedure fofb_server_wait_con(variable obj : in  t_fofb_server);
  attribute foreign of fofb_server_wait_con: procedure is "VHPIDIRECT fofb_server_wait_con";

  -- Wait for new data from the client, should only be called when there is an
  -- active connection with the client. The message type will be written to
  -- msg_type, so the message data can be retrieved by the corresponding read
  -- procedures
  procedure fofb_server_wait_data(variable obj      : in  t_fofb_server;
                                  variable msg_type : out t_fofb_server_msg_type);
  attribute foreign of fofb_server_wait_data: procedure is "VHPIDIRECT fofb_server_wait_data";

  -- Read one matrix inverse response coefficient indexed by 'index'. It is
  -- non-blocking, always return a copy of the last received data.
  procedure fofb_server_read_coeff(variable obj   : in  t_fofb_server;
                                   index          : in  integer range 0 to 511;
                                   variable coeff : out std_logic_vector(31 downto 0));
  attribute foreign of fofb_server_read_coeff: procedure is "VHPIDIRECT fofb_server_read_coeff";

  -- Read one BPM set-point value indexed by 'index'. It is non-blocking,
  -- always return a copy of the last received data.
  procedure fofb_server_read_sp(variable obj   : in  t_fofb_server;
                                index          : in  integer range 0 to 511;
                                variable sp    : out std_logic_vector(31 downto 0));
  attribute foreign of fofb_server_read_sp: procedure is "VHPIDIRECT fofb_server_read_sp";

  -- Read one BPM position value indexed by 'index'. It is non-blocking,
  -- always return a copy of the last received data.
  procedure fofb_server_read_bpm_pos(variable obj     : in  t_fofb_server;
                                     index            : in  integer range 0 to 511;
                                     variable bpm_pos : out signed(31 downto 0));
  attribute foreign of fofb_server_read_bpm_pos: procedure is "VHPIDIRECT fofb_server_read_bpm_pos";

  -- Read the gain value. It is non-blocking, always return a copy of the
  -- last received data.
  procedure fofb_server_read_gain(variable obj  : in  t_fofb_server;
                                  variable gain : out integer);
  attribute foreign of fofb_server_read_gain: procedure is "VHPIDIRECT fofb_server_read_gain";

  -- Send the set-point value to the client
  procedure fofb_server_write_sp(variable obj : in t_fofb_server;
                                 variable sp  : in integer);
  attribute foreign of fofb_server_write_sp: procedure is "VHPIDIRECT fofb_server_write_sp";
end package fofb_server_pkg;

package body fofb_server_pkg is
  impure function new_fofb_server (tcp_port          : natural range 0 to 65535;
                                   gain_frac_width   : natural range 0 to 31;
                                   coeffs_frac_width : natural range 0 to 31;
                                   bpm_frac_width    : natural range 0 to 31)
                                   return t_fofb_server is
  begin report "VHPIDIRECT new_fofb_server" severity failure; end;

  procedure fofb_server_wait_con(variable obj : in  t_fofb_server
                                 ) is
  begin report "VHPIDIRECT fofb_server_wait_con" severity failure; end;

  procedure fofb_server_wait_data(variable obj      : in  t_fofb_server;
                                  variable msg_type : out t_fofb_server_msg_type
                                  ) is
  begin report "VHPIDIRECT fofb_server_wait_data" severity failure; end;

  procedure fofb_server_read_coeff(variable obj   : in  t_fofb_server;
                                   index          : in  integer range 0 to 511;
                                   variable coeff : out std_logic_vector(31 downto 0)
                                   ) is
  begin report "VHPIDIRECT fofb_server_read_coeff" severity failure; end;

  procedure fofb_server_read_sp(variable obj   : in  t_fofb_server;
                                index          : in  integer range 0 to 511;
                                variable sp    : out std_logic_vector(31 downto 0)
                                ) is
  begin report "VHPIDIRECT fofb_server_read_sp" severity failure; end;

  procedure fofb_server_read_bpm_pos(variable obj     : in  t_fofb_server;
                                     index            : in  integer range 0 to 511;
                                     variable bpm_pos : out signed(31 downto 0)
                                     ) is
  begin report "VHPIDIRECT fofb_server_read_bpm_pos" severity failure; end;

  procedure fofb_server_read_gain(variable obj  : in  t_fofb_server;
                                  variable gain : out integer
                                  ) is
  begin report "VHPIDIRECT fofb_server_read_gain" severity failure; end;

  procedure fofb_server_write_sp(variable obj : in t_fofb_server;
                                 variable sp  : in integer
                                 ) is
  begin report "VHPIDIRECT fofb_server_write_sp" severity failure; end;
end package body fofb_server_pkg;

//! # FOFB Server library
//! Provides an interface for VHDL code to comunicate via TCP sockets.
//!
//! ## Usage example
//!
//! ```vhdl
//! library ieee;
//! use ieee.std_logic_1164.all;
//! use ieee.numeric_std.all;
//!
//! entity testbench is
//! end entity testbench;
//!
//! architecture simu of testbench is
//!   type t_fofb_server is access integer;
//!   type t_fofb_server_msg_type is (COEFF_DATA, SETPOINT_DATA, BPMPOS_DATA, GAIN_DATA, CLEAR_ACC, DEBUG, DISCONNECTED, PARSEERR, EXIT_SIMU);
//!   impure function new_fofb_server (tcp_port          : natural range 0 to 65535;
//!                                    gain_frac_width   : natural range 0 to 31;
//!                                    coeffs_frac_width : natural range 0 to 31;
//!                                    bpm_frac_width    : natural range 0 to 31
//!                                    ) return t_fofb_server is
//!   begin report "VHPIDIRECT new_fofb_server" severity failure; end;
//!   attribute foreign of new_fofb_server : function is "VHPIDIRECT new_fofb_server";
//!
//!   procedure fofb_server_wait_con(variable obj : in  t_fofb_server
//!                                  ) is
//!   begin report "VHPIDIRECT fofb_server_wait_con" severity failure; end;
//!   attribute foreign of fofb_server_wait_con: procedure is "VHPIDIRECT fofb_server_wait_con";
//!
//!   procedure fofb_server_wait_data(variable obj      : in  t_fofb_server;
//!                                   variable msg_type : out t_fofb_server_msg_type
//!                                   ) is
//!   begin report "VHPIDIRECT fofb_server_wait_data" severity failure; end;
//!   attribute foreign of fofb_server_wait_data: procedure is "VHPIDIRECT fofb_server_wait_data";
//!   procedure fofb_server_read_coeff(variable obj   : in  t_fofb_server;
//!                                    index          : in  integer range 0 to 511;
//!                                    variable coeff : out std_logic_vector(31 downto 0)
//!                                    ) is
//!   begin report "VHPIDIRECT fofb_server_read_coeff" severity failure; end;
//!   attribute foreign of fofb_server_read_coeff: procedure is "VHPIDIRECT fofb_server_read_coeff";
//!
//!   procedure fofb_server_read_sp(variable obj   : in  t_fofb_server;
//!                                 index          : in  integer range 0 to 511;
//!                                 variable sp    : out std_logic_vector(31 downto 0)
//!                                 ) is
//!   begin report "VHPIDIRECT fofb_server_read_sp" severity failure; end;
//!   attribute foreign of fofb_server_read_sp: procedure is "VHPIDIRECT fofb_server_read_sp";
//!
//!   procedure fofb_server_read_bpm_pos(variable obj     : in  t_fofb_server;
//!                                      index            : in  integer range 0 to 511;
//!                                      variable bpm_pos : out signed(31 downto 0)
//!                                      ) is
//!   begin report "VHPIDIRECT fofb_server_read_bpm_pos" severity failure; end;
//!   attribute foreign of fofb_server_read_bpm_pos: procedure is "VHPIDIRECT fofb_server_read_bpm_pos";
//!
//!   procedure fofb_server_read_gain(variable obj  : in  t_fofb_server;
//!                                   variable gain : out integer
//!                                   ) is
//!   begin report "VHPIDIRECT fofb_server_read_gain" severity failure; end;
//!   attribute foreign of fofb_server_read_gain: procedure is "VHPIDIRECT fofb_server_read_gain";
//!
//!   procedure fofb_server_write_sp(variable obj : in t_fofb_server;
//!                                  sp           : in integer
//!                                  ) is
//!   begin report "VHPIDIRECT fofb_server_write_sp" severity failure; end;
//!   attribute foreign of fofb_server_write_sp: procedure is "VHPIDIRECT fofb_server_write_sp";
//! begin
//!
//!   process
//!     variable fofb_server: t_fofb_server;
//!     variable fofb_msg   : t_fofb_server_msg_type;
//!     variable data_int   : integer;
//!     variable data       : std_logic_vector(31 downto 0);
//!     variable data_sig   : signed(31 downto 0);
//!   begin
//!     fofb_server := new_fofb_server(14000, 12, 31, 0);
//!     fofb_server_wait_con(fofb_server);
//!     fofb_server_wait_data(fofb_server, fofb_msg);
//!     case fofb_msg is
//!       when COEFF_DATA =>
//!         report "New coefficients data";
//!         for i in 0 to 511 loop
//!           fofb_server_read_coeff(fofb_server, i, data);
//!           report "Coeff " & to_string(i) & ": " & to_string(data);
//!         end loop;
//!
//!       when SETPOINT_DATA =>
//!         report "New set-points data";
//!         for i in 0 to 511 loop
//!           fofb_server_read_sp(fofb_server, i, data);
//!           report "BPM set-point " & to_string(i) & ": " & to_string(data);
//!         end loop;
//!
//!       when BPMPOS_DATA =>
//!         report "New BPM Position data";
//!         for i in 0 to 511 loop
//!           fofb_server_read_bpm_pos(fofb_server, i, data_sig);
//!           report "BPM Position " & to_string(i) & ": " & to_string(data);
//!         end loop;
//!
//!       when GAIN_DATA =>
//!         fofb_server_read_gain(fofb_server, data_int);
//!         report "New gain value: " & to_string(data_int);
//!
//!       when CLEAR_ACC =>
//!         report "Clear ACC";
//!
//!       when DEBUG =>
//!         report "Debug event !";
//!
//!       when DISCONNECTED =>
//!         report "Client disconnected";
//!
//!       when PARSEERR =>
//!         report "Parsing error !";
//!
//!       when EXIT_SIMU =>
//!         report "Exit simulation";
//!     end case;
//!
//!     report "Send set-point value to client";
//!     fofb_server_write_sp(fofb_server, 101);
//!
//!     std.env.finish;
//!   end process;
//! end architecture simu;
//! ```

// Copyright (c) 2022 CNPEM
// Licensed under GNU Lesser General Public License (LGPL) v3.0
// Author: Augusto Fraga Giachero

use core::slice;
use std::net::{TcpListener, TcpStream, SocketAddr, Shutdown};
use std::io::prelude::*;
use std::io::BufReader;

/// Indicate the message type
#[repr(C)]
pub enum FOFBMsgType {
    /// Inverse response matrix coefficients received
    Coeff,
    /// BPM set-points received
    SetPoint,
    /// BPM positions received
    BPMPos,
    /// Gain received
    Gain,
    /// Clear accumulator command received
    ClearACC,
    /// Debug event
    Debug,
    /// Client disconnected
    Disconnected,
    /// Parsing error
    ParseErr,
    /// Exit command received
    Exit,
}

/// FOFB Server struct
pub struct FOFBServer {
    listener: TcpListener,
    stream: Option<TcpStream>,
    reader: Option<BufReader<TcpStream>>,
    gain_frac_width: i32,
    coeffs_frac_width: i32,
    bpm_frac_width: i32,
    gain: i32,
    coeffs: [i32; 512],
    bpm_sp: [i32; 512],
    bpm_pos: [i32; 512],
}

/// Returns a pointer to a new `FOFBServer` instance
///
/// # Arguments
/// * `port` - Local TCP port to listen to
/// * `gain_frac_width` - Fractionary part width in bits of the Gain
/// * `coeffs_frac_width` - Fractionary part width in bits of the inverse response matrix coefficients'
/// * `bpm_frac_width` - Fractionary part width in bits of the BPM set-point and position data
#[no_mangle]
pub extern fn new_fofb_server(port: u32, gain_frac_width: i32, coeffs_frac_width: i32, bpm_frac_width: i32) -> *mut FOFBServer {
    let addr = SocketAddr::from(([127, 0, 0, 1], port as u16));
    Box::into_raw(Box::new(
        FOFBServer {
            listener: TcpListener::bind(addr).unwrap(),
            stream: None,
            reader: None,
            gain_frac_width,
            coeffs_frac_width,
            bpm_frac_width,
            gain: 0,
            coeffs: [0; 512],
            bpm_sp: [0; 512],
            bpm_pos: [0; 512],
        }))
}

/// Wait for a new TCP connection
///
/// # Arguments
/// * `fsrv` - FOFBServer instance pointer
#[no_mangle]
pub extern fn fofb_server_wait_con(fsrv: &mut FOFBServer) {
    let (socket, addr) = fsrv.listener.accept().unwrap();
    println!("Connected! {:?}", addr);
    fsrv.reader = Some(BufReader::new(socket.try_clone().unwrap()));
    fsrv.stream = Some(socket);
}

/// Print internal state of the FOFBServer struct
///
/// # Arguments
/// * `fsrv` - FOFBServer instance pointer
fn fofb_server_print_state(fsrv: &FOFBServer) {
    println!("Gain Fraction: {}", fsrv.gain_frac_width);
    println!("Gain: {}", fsrv.gain);
    println!("Coefficients Fraction: {}", fsrv.coeffs_frac_width);
    println!("Coefficients: ");
    for coeff in &fsrv.coeffs {
        print!("{} ", coeff);
    }
    print!("\n");

    println!("BPM Position Fraction: {}", fsrv.bpm_frac_width);
    println!("BPM Positions: ");
    for bpm_pos in &fsrv.bpm_pos {
        print!("{} ", bpm_pos);
    }
    print!("\n");

    println!("BPM Set-Point Fraction: {}", fsrv.bpm_frac_width);
    println!("BPM Set-Points: ");
    for bpm_sp in &fsrv.bpm_sp {
        print!("{} ", bpm_sp);
    }
    print!("\n");
}

/// Convert from floating point (f64) to fixed point (i32).
///
/// # Arguments
/// * `num` - Floating point number to be converted
/// * `frac_width` - Fractionary width in bits
fn fofb_server_float_to_fixed(num: f64, frac_width: i32) -> i32 {
    let num_scaled: f64 = num * 2.0_f64.powi(frac_width);
    if num_scaled > i32::MAX as f64 {
        i32::MAX
    } else if num_scaled < i32::MIN as f64 {
        i32::MIN
    } else {
        num_scaled as i32
    }
}

fn fofb_server_parse_num_list(fsrv: &mut FOFBServer, num_str_list: &[&str], mut msg_type: FOFBMsgType) -> FOFBMsgType {
    // Get a mutable reference to a i32 slice for the respective
    // buffer depending on the message type. Also get the
    // corresponding fixed point fractionary bit width
    let (int_list, frac_width) = match msg_type {
        FOFBMsgType::Coeff => (&mut fsrv.coeffs[..], fsrv.coeffs_frac_width),
        FOFBMsgType::SetPoint => (&mut fsrv.bpm_sp[..], fsrv.bpm_frac_width),
        FOFBMsgType::BPMPos => (&mut fsrv.bpm_pos[..], fsrv.bpm_frac_width),
        FOFBMsgType::Gain => (slice::from_mut(&mut fsrv.gain), fsrv.gain_frac_width),
        _ => panic!("Invalid message type for parsing integer list"),
    };

    // Modern rust versions have the std::iter::zip() function that
    // joins two iterators in a single tuple, I choosed using the
    // std::iter::Iterator::zip method to keep it compatible with
    // older Rust versions instead. It will iterate over the
    // 'num_str_list' and 'int_list' until any of them reaches the
    // end.
    for (num_str, buf) in num_str_list.iter().zip(int_list.iter_mut()) {
        // Parse each string from num_str_list as a floating point number
        let num: f64 = match num_str.parse() {
            Ok(n) => n,
            Err(_) => {
                // Parsing error occurred, return an error code
                msg_type = FOFBMsgType::ParseErr;
                break
            },
        };
        // Convert from f64 to i32 fixed point preserving the
        // fractionary part
        *buf = fofb_server_float_to_fixed(num, frac_width);
    }
    msg_type
}

fn fofb_server_parse_line(fsrv: &mut FOFBServer, line: &String) -> FOFBMsgType {
    let args: Vec<&str> = line.trim_matches(|c| c == ' '  ||
                                                c == '\n' ||
                                                c == '\r').split(" ").collect();

    if args.len() > 0 {
        match &args[0] {
            &"coefficients" => {
                fofb_server_parse_num_list(fsrv, &args[1..], FOFBMsgType::Coeff)
            },
            &"bpm_setpoints" => {
                fofb_server_parse_num_list(fsrv, &args[1..], FOFBMsgType::SetPoint)
            },
            &"bpm_positions" => {
                fofb_server_parse_num_list(fsrv, &args[1..], FOFBMsgType::BPMPos)
            },
            &"gain" => {
                fofb_server_parse_num_list(fsrv, &args[1..], FOFBMsgType::Gain)
            },
            &"clear_acc" => FOFBMsgType::ClearACC,
            &"debug" => {
                fofb_server_print_state(fsrv);
                FOFBMsgType::Debug
            },
            &"disconnect" => {
                fsrv.stream.as_mut().unwrap().shutdown(Shutdown::Both).unwrap();
                FOFBMsgType::Disconnected
            },
            &"exit" => FOFBMsgType::Exit,
            _ => {FOFBMsgType::ParseErr},
        }
    } else {
        FOFBMsgType::ParseErr
    }
}

/// Wait for the client to send new data
///
/// # Arguments
/// * `fsrv` - FOFBServer instance pointer
/// * `msg_type` - A FOFBMsgType enum pointer for returning the message type received
#[no_mangle]
pub extern fn fofb_server_wait_data(fsrv: &mut FOFBServer, msg_type: &mut FOFBMsgType) {
    match &mut fsrv.reader {
        None => *msg_type = FOFBMsgType::Disconnected,
        Some(reader) => {
            let mut line = String::new();
            let bytes = reader.read_line(&mut line).unwrap();
            if bytes > 0 {
                *msg_type = fofb_server_parse_line(fsrv, &line);
            } else {
                *msg_type = FOFBMsgType::Disconnected;
            }
        },
    }
}

/// Convert a 32 bits number to GHDL's internal representation of std_logic_vector
///
/// # Arguments
/// * `num` - Input number to be converted
/// * `std_vec` - std_logic_vector(31 downto 0) output
fn fofb_server_u32_to_std_vec(mut num: u32, std_vec: &mut [u8; 32]) {
    for element in std_vec.iter_mut() {
        if num & 0x80000000 == 0 {
            *element = 2;
        } else {
            *element = 3;
        }
        num = num << 1;
    }
}

/// Read a single coefficient as a std_logic_vector / signed
///
/// # Arguments
/// * `fsrv` - FOFBServer instance pointer
/// * `index` - Coefficient index, mut be < 512
/// * `coeff` - Coefficient buffer as std_logic_vector(31 downto 0) / signed(31 downto 0)
#[no_mangle]
pub extern fn fofb_server_read_coeff(fsrv: &mut FOFBServer, index: u32, coeff: &mut [u8; 32]) {
    if (index as usize) < fsrv.coeffs.len() {
        fofb_server_u32_to_std_vec(fsrv.coeffs[index as usize] as u32, coeff);
    }
}

/// Read a single BPM set-point as a std_logic_vector / signed
///
/// # Arguments
/// * `fsrv` - FOFBServer instance pointer
/// * `index` - BPM set-point index, mut be < 512
/// * `bpm_sp` - BPM set-point buffer as std_logic_vector(31 downto 0) / signed(31 downto 0)
#[no_mangle]
pub extern fn fofb_server_read_sp(fsrv: &mut FOFBServer, index: u32, bpm_sp: &mut [u8; 32]) {
    if (index as usize) < fsrv.coeffs.len() {
        fofb_server_u32_to_std_vec(fsrv.bpm_sp[index as usize] as u32, bpm_sp);
    }
}

/// Read a single BPM position measurement as a std_logic_vector / signed
///
/// # Arguments
/// * `fsrv` - FOFBServer instance pointer
/// * `index` - BPM position index, mut be < 512
/// * `bpm_sp` - BPM position buffer as std_logic_vector(31 downto 0) / signed(31 downto 0)
#[no_mangle]
pub extern fn fofb_server_read_bpm_pos(fsrv: &mut FOFBServer, index: u32, bpm_pos: &mut [u8; 32]) {
    if (index as usize) < fsrv.coeffs.len() {
        fofb_server_u32_to_std_vec(fsrv.bpm_pos[index as usize] as u32, bpm_pos);
    }
}

/// Read the gain as an integer
///
/// # Arguments
/// * `fsrv` - FOFBServer instance pointer
/// * `gain` - Mutable reference of the gain variable to be written
#[no_mangle]
pub extern fn fofb_server_read_gain(fsrv: &mut FOFBServer, gain: &mut i32) {
    *gain = fsrv.gain;
}

/// Send the current set-point to the client
///
/// # Arguments
/// * `fsrv` - FOFBServer instance pointer
/// * `corrector_sp` - Current set-point to be sent to the client
#[no_mangle]
pub extern fn fofb_server_write_sp(fsrv: &mut FOFBServer, corrector_sp: i32) {
    match &mut fsrv.stream {
        Some(stream) => {
            let corrector_sp_str = corrector_sp.to_string();
            stream.write(corrector_sp_str.as_bytes()).unwrap();
            stream.write("\n".as_bytes()).unwrap();
        },
        None => (),
    }
}

/// Delete a FOFBServer instance
///
/// # Arguments
/// * `fsrv` - FOFBServer instance pointer
#[no_mangle]
pub extern fn fofb_server_delete(fsrv: *mut FOFBServer) {
    if !fsrv.is_null() {
        unsafe {
            Box::from_raw(fsrv);
        }
    }
}

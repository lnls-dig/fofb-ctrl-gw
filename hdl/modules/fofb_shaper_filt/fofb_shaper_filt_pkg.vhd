--------------------------------------------------------------------------------
-- Title      : FOFB shaper filters package
-- Project    : fofb-ctrl-gw
--------------------------------------------------------------------------------
-- File       : fofb_shaper_filt_pkg.vhd
-- Author     : Guilherme Ricioli <guilherme.riciolic@gmail.com>
-- Company    : CNPEM, LNLS - GIE
-- Platform   : Generic
-- Standard   : VHDL'08
--------------------------------------------------------------------------------
-- Description: Package for FOFB shaper filters stuff.
--------------------------------------------------------------------------------
-- Copyright (c) 2023 CNPEM
-- Licensed under GNU Lesser General Public License (LGPL) v3.0
--------------------------------------------------------------------------------
-- Revisions  :
-- Date         Version  Author              Description
-- 2023-09-28   1.0      guilherme.ricioli   Created
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.fixed_pkg.ALL;

LIBRARY work;
USE work.wishbone_pkg.ALL;

PACKAGE fofb_shaper_filt_pkg IS
  -- The number of internal biquads each IIR filter has
  CONSTANT c_NUM_BIQUADS : NATURAL := 4;

  -- The signed fixed-point representation of filters' coefficients
  CONSTANT c_COEFF_INT_WIDTH : NATURAL := 2;
  CONSTANT c_COEFF_FRAC_WIDTH : NATURAL := 16;
END PACKAGE fofb_shaper_filt_pkg;

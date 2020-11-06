#!/bin/bash

cheby -i fofb_cc_csr.cheby --hdl vhdl --gen-wbgen-hdl fofb_cc_csr.vhd --doc html --gen-doc doc/fofb_cc_csr_wb.html --gen-c fofb_cc_csr.h --consts-style verilog --gen-consts ../../../sim/regs/fofb_cc_csr.vh

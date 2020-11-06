#!/bin/bash

cheby -i fofb_cc_csr.cheby --hdl vhdl --gen-wbgen-hdl wb_fofb_cc_csr.vhd --doc html --gen-doc doc/wb_fofb_cc_csr_wb.html --gen-c wb_fofb_cc_csr.h --consts-style verilog --gen-consts ../../../sim/regs/wb_fofb_cc_csr.vh

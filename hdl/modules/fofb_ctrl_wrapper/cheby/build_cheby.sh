#!/bin/bash

cheby -i fofb_cc_regs.cheby --hdl vhdl --gen-wbgen-hdl wb_fofb_cc_regs.vhd --doc html --gen-doc doc/wb_fofb_cc_regs_wb.html --gen-c wb_fofb_cc_regs.h --consts-style verilog --gen-consts ../../../sim/regs/wb_fofb_cc_regs.vh

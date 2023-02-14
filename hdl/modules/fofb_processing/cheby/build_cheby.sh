#!/bin/bash

cheby -i wb_fofb_processing_regs.cheby --hdl vhdl --gen-hdl wb_fofb_processing_regs.vhd --doc html --gen-doc doc/wb_fofb_processing_regs.html --gen-c wb_fofb_processing_regs.h --consts-style verilog --gen-consts ../../../sim/regs/wb_fofb_processing_regs.vh --consts-style vhdl-ohwr --gen-consts ../../../sim/regs/wb_fofb_processing_regs_consts_pkg.vhd

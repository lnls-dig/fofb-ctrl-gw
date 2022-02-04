#!/bin/bash

cheby -i wb_fofb_processing_regs.cheby --hdl vhdl --gen-wbgen-hdl wb_fofb_processing_regs.vhd --gen-c wb_fofb_processing_regs.h --consts-style verilog --gen-consts ../../../sim/regs/wb_fofb_processing_regs.vh
#!/bin/bash

cheby -i dot_prod_wb.cheby --hdl vhdl --gen-wbgen-hdl dot_prod_wb.vhd --doc html --gen-doc doc/dot_prod_wb.html --gen-c dot_prod_wb.h --consts-style verilog --gen-consts ../../../sim/regs/dot_prod_wb.vh

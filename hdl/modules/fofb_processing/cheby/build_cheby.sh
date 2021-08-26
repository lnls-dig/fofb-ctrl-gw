#!/bin/bash

cheby -i matmul_wb.cheby --hdl vhdl --gen-wbgen-hdl matmul_wb.vhd --doc html --gen-doc doc/matmul_wb.html --gen-c matmul_wb.h --consts-style verilog --gen-consts ../../../sim/regs/matmul_wb.vh

#!/bin/bash

mkdir -p doc
cheby -i wb_fofb_shaper_filt_regs.cheby --hdl vhdl --gen-hdl wb_fofb_shaper_filt_regs.vhd --doc html --gen-doc doc/wb_fofb_shaper_filt_regs.html --gen-c wb_fofb_shaper_filt_regs.h --consts-style vhdl-ohwr --gen-consts ../../../sim/regs/wb_fofb_shaper_filt_regs_consts_pkg.vhd

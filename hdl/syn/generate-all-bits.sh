#!/bin/bash

for target in  \
    afc_rtm_sfp_design\
    afcv3_ref_design \
    afcv4_ref_design \
    ; do
    TOP=$(pwd)
    cd ${target} && hdlmake makefile && make clean && ./build_bitstream_local.sh ; cd ${TOP};
done

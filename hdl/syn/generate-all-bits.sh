#!/bin/bash

for target in  \
    afcv3_rtm_sfp_design\
    afcv3_ref_design \
    afcv4_ref_design \
    ; do
    TOP=$(pwd)
    cd ${target} && hdlmake makefile && make clean && rm -rf *.sim && ./build_bitstream_local.sh ; cd ${TOP};
done

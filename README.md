# Fast Orbit Feedback Controller Gateware

![Latest tag](https://img.shields.io/github/tag/lnls-dig/fofb-ctrl-gw.svg?style=flat)
[![Latest release](https://img.shields.io/github/release/lnls-dig/fofb-ctrl-gw.svg?style=flat)](https://github.com/lnls-dig/fofb-ctrl-gw/releases)
[![LGPL License 3.0](https://img.shields.io/github/license/lnls-dig/fofb-ctrl-gw.svg?style=flat)](COPYING)

Gateware for the Fast Orbit Feedback Controller

## Project Folder Organization

```
*
|
|-- hdl:
|    |   HDL (Verilog/VHDL) cores related to the FOFB controller.
|    |
|    |-- board:
|    |        Board support package for the FOFB controller.
|    |
|    |-- ip_cores:
|    |    |   Third party reusable modules, primarily Open hardware
|    |    |     modules (http://www.ohwr.org).
|    |    |
|    |    |-- infra-cores:
|    |    |       Generic reusable module from LNLS.
|    |    |-- general-cores (fork from original project):
|    |    |       General reusable modules.
|    |    |-- afc-gw:
|    |            AFC BSP (board support package).
|    |
|    |-- modules:
|    |        Modules specific to FOFB controller.
|    |
|    |-- platform:
|    |        Platform-specific code, such as Xilinx Chipscope wrappers.
|    |
|    |-- sim:
|    |        Generic simulation files, reusable Bus Functional Modules (BFMs),
|    |          constants definitions.
|    |
|    |-- syn:
|    |        Synthesis specific files (user constraints files and top design
|    |          specification).
|    |
|    |-- testbench:
|    |        Testbenches for modules and top level designs. May use modules
|    |          defined elsewhere (specific within the 'sim" directory).
|    |
|    |-- top:
|             Top design modules.
|
|-- loader:
|        FPGA programming scripts.
```

## Cloning Instructions

This repository makes use of git submodules, located at 'hdl/ip_cores' folder:
  hdl/ip_cores/general-cores
  hdl/ip_cores/infra-cores
  hdl/ip_cores/afc-gw

To clone the whole repository use the following command:

    git clone --recursive https://github.com/lnls-dig/fofb-ctrl-gw

or (if using ssh authentication keys)

    git clone --recursive git@github.com:lnls-dig/fofb-ctrl-gw.git

For older versions of Git (<1.6.5), use the following:

    git clone git://github.com/lnls-dig/fofb-ctrl-gw.git

or

    git clone git@github.com:lnls-dig/fofb-ctrl-gw.git

    git submodule init
    git submodule update

To update each submodule within this project use:

    git submodule foreach git rebase origin master

## Simulation Instructions

Go to a testbench directory. It must have a top manifest file:

    cd hdl/testbench/path_to_testbench

Run the following commands. You must have hdlmake command available
in your PATH environment variable.

Create the simualation makefile

    hdlmake

Compile the project

    make

Execute the simulation with GUI and aditional commands

    vsim -do run.do &

## Synthesis Instructions

Go to a syn directory. It must have a synthesis manifest file:

    cd hdl/syn/path_to_syn_design

Run the following commands. You must have hdlmake command available
in your PATH environment variable.

    ./build_bitstream_local.sh

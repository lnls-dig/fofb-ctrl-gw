write_cfgmem -force -format mcs -size 32 -interface SPIx4 -loadbit {up 0x00000000 SYN_PROJECT.bit } -file SYN_PROJECT.mcs

open_hw
current_hw_target [get_hw_targets */xilinx_tcf/Xilinx/nat-mch-dighomolog:2542]
connect_hw_server -url localhost:3121
create_hw_target flash_afcv4
open_hw_target

create_hw_device -part xc7a200t_0
create_hw_device -part xc2c256_1
create_hw_cfgmem -hw_device [lindex [get_hw_devices xc7a200t_0] 0] -mem_dev  [lindex [get_cfgmem_parts {mt25ql256-spi-x1_x2_x4}] 0]

current_hw_device [get_hw_devices xc7a200t_0]
refresh_hw_device -update_hw_probes false [lindex [get_hw_devices xc7a200t_0] 0]

set_property PROGRAM.ADDRESS_RANGE  {use_file} [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7a200t_0] 0 ]]
set_property PROGRAM.FILES [list "SYN_PROJECT.mcs" ] [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7a200t_0] 0]]
set_property PROGRAM.UNUSED_PIN_TERMINATION {pull-up} [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7a200t_0] 0 ]]
set_property PROGRAM.BLANK_CHECK  0 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7a200t_0] 0 ]]
set_property PROGRAM.ERASE  1 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7a200t_0] 0 ]]
set_property PROGRAM.CFG_PROGRAM  1 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7a200t_0] 0 ]]
set_property PROGRAM.VERIFY  1 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7a200t_0] 0 ]]
set_property PROGRAM.CHECKSUM  0 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7a200t_0] 0 ]]

startgroup
if {![string equal \
        [get_property PROGRAM.HW_CFGMEM_TYPE [lindex [get_hw_devices xc7a200t_0] 0]] \
        [get_property MEM_TYPE [get_property CFGMEM_PART [get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7a200t_0] 0 ]]]]
    ]} {
        create_hw_bitstream -hw_device [lindex [get_hw_devices xc7a200t_0] 0] [get_property \
            PROGRAM.HW_CFGMEM_BITFILE [ lindex [get_hw_devices xc7a200t_0] 0]];
            program_hw_devices [lindex [get_hw_devices xc7a200t_0] 0];
    };

program_hw_cfgmem -hw_cfgmem [get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7a200t_0] 0 ]]
write_hw_svf "SVF_NAME.svf"

close_hw_target
exit

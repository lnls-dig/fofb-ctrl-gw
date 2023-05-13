package wb_fofb_sys_id_regs_consts_pkg is
  constant c_WB_FOFB_SYS_ID_REGS_SIZE : Natural := 8192;
  constant c_WB_FOFB_SYS_ID_REGS_BPM_POS_FLATENIZER_ADDR : Natural := 16#0#;
  constant c_WB_FOFB_SYS_ID_REGS_BPM_POS_FLATENIZER_SIZE : Natural := 8;
  constant c_WB_FOFB_SYS_ID_REGS_BPM_POS_FLATENIZER_CTL_ADDR : Natural := 16#0#;
  constant c_WB_FOFB_SYS_ID_REGS_BPM_POS_FLATENIZER_CTL_BASE_BPM_ID_OFFSET : Natural := 0;
  constant c_WB_FOFB_SYS_ID_REGS_BPM_POS_FLATENIZER_MAX_NUM_CTE_ADDR : Natural := 16#4#;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_ADDR : Natural := 16#1000#;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SIZE : Natural := 4096;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_ADDR : Natural := 16#1000#;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_RST_OFFSET : Natural := 0;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_STEP_DURATION_OFFSET : Natural := 1;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_LFSR_LENGTH_OFFSET : Natural := 11;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_BPM_POS_DISTORT_EN_OFFSET : Natural := 16;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_SP_DISTORT_EN_OFFSET : Natural := 17;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_CTL_SP_DISTORT_MOV_AVG_NUM_TAPS_SEL_OFFSET : Natural := 18;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_MOV_AVG_MAX_NUM_TAPS_SEL_CTE_ADDR : Natural := 16#1004#;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_ADDR : Natural := 16#1040#;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_SIZE : Natural := 64;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_ADDR : Natural := 16#1040#;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_SIZE : Natural := 64;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_0_ADDR : Natural := 16#1040#;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_0_SIZE : Natural := 4;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_0_LEVELS_ADDR : Natural := 16#1040#;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_0_LEVELS_LEVEL_0_OFFSET : Natural := 0;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_0_LEVELS_LEVEL_1_OFFSET : Natural := 16;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_1_ADDR : Natural := 16#1044#;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_1_SIZE : Natural := 4;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_1_LEVELS_ADDR : Natural := 16#1044#;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_1_LEVELS_LEVEL_0_OFFSET : Natural := 0;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_1_LEVELS_LEVEL_1_OFFSET : Natural := 16;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_2_ADDR : Natural := 16#1048#;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_2_SIZE : Natural := 4;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_2_LEVELS_ADDR : Natural := 16#1048#;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_2_LEVELS_LEVEL_0_OFFSET : Natural := 0;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_2_LEVELS_LEVEL_1_OFFSET : Natural := 16;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_3_ADDR : Natural := 16#104c#;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_3_SIZE : Natural := 4;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_3_LEVELS_ADDR : Natural := 16#104c#;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_3_LEVELS_LEVEL_0_OFFSET : Natural := 0;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_3_LEVELS_LEVEL_1_OFFSET : Natural := 16;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_4_ADDR : Natural := 16#1050#;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_4_SIZE : Natural := 4;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_4_LEVELS_ADDR : Natural := 16#1050#;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_4_LEVELS_LEVEL_0_OFFSET : Natural := 0;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_4_LEVELS_LEVEL_1_OFFSET : Natural := 16;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_5_ADDR : Natural := 16#1054#;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_5_SIZE : Natural := 4;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_5_LEVELS_ADDR : Natural := 16#1054#;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_5_LEVELS_LEVEL_0_OFFSET : Natural := 0;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_5_LEVELS_LEVEL_1_OFFSET : Natural := 16;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_6_ADDR : Natural := 16#1058#;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_6_SIZE : Natural := 4;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_6_LEVELS_ADDR : Natural := 16#1058#;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_6_LEVELS_LEVEL_0_OFFSET : Natural := 0;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_6_LEVELS_LEVEL_1_OFFSET : Natural := 16;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_7_ADDR : Natural := 16#105c#;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_7_SIZE : Natural := 4;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_7_LEVELS_ADDR : Natural := 16#105c#;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_7_LEVELS_LEVEL_0_OFFSET : Natural := 0;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_7_LEVELS_LEVEL_1_OFFSET : Natural := 16;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_8_ADDR : Natural := 16#1060#;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_8_SIZE : Natural := 4;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_8_LEVELS_ADDR : Natural := 16#1060#;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_8_LEVELS_LEVEL_0_OFFSET : Natural := 0;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_8_LEVELS_LEVEL_1_OFFSET : Natural := 16;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_9_ADDR : Natural := 16#1064#;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_9_SIZE : Natural := 4;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_9_LEVELS_ADDR : Natural := 16#1064#;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_9_LEVELS_LEVEL_0_OFFSET : Natural := 0;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_9_LEVELS_LEVEL_1_OFFSET : Natural := 16;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_10_ADDR : Natural := 16#1068#;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_10_SIZE : Natural := 4;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_10_LEVELS_ADDR : Natural := 16#1068#;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_10_LEVELS_LEVEL_0_OFFSET : Natural := 0;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_10_LEVELS_LEVEL_1_OFFSET : Natural := 16;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_11_ADDR : Natural := 16#106c#;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_11_SIZE : Natural := 4;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_11_LEVELS_ADDR : Natural := 16#106c#;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_11_LEVELS_LEVEL_0_OFFSET : Natural := 0;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_11_LEVELS_LEVEL_1_OFFSET : Natural := 16;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_BPM_POS_DISTORT_ADDR : Natural := 16#1800#;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_BPM_POS_DISTORT_SIZE : Natural := 2048;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_BPM_POS_DISTORT_DISTORT_RAM_ADDR : Natural := 16#1800#;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_BPM_POS_DISTORT_DISTORT_RAM_SIZE : Natural := 4;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_BPM_POS_DISTORT_DISTORT_RAM_LEVELS_ADDR : Natural := 16#0#;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_BPM_POS_DISTORT_DISTORT_RAM_LEVELS_LEVEL_0_OFFSET : Natural := 0;
  constant c_WB_FOFB_SYS_ID_REGS_PRBS_BPM_POS_DISTORT_DISTORT_RAM_LEVELS_LEVEL_1_OFFSET : Natural := 16;
end package wb_fofb_sys_id_regs_consts_pkg;

#ifndef __CHEBY__WB_FOFB_SYS_ID_REGS__H__
#define __CHEBY__WB_FOFB_SYS_ID_REGS__H__
#define WB_FOFB_SYS_ID_REGS_SIZE 8192 /* 0x2000 = 8KB */

/* Interface to BPM positions flatenizers regs */
#define WB_FOFB_SYS_ID_REGS_BPM_POS_FLATENIZER 0x0UL
#define WB_FOFB_SYS_ID_REGS_BPM_POS_FLATENIZER_SIZE 8 /* 0x8 */

/* BPM positions flatenizers control register
 */
#define WB_FOFB_SYS_ID_REGS_BPM_POS_FLATENIZER_CTL 0x0UL
#define WB_FOFB_SYS_ID_REGS_BPM_POS_FLATENIZER_CTL_BASE_BPM_ID_MASK 0xffUL
#define WB_FOFB_SYS_ID_REGS_BPM_POS_FLATENIZER_CTL_BASE_BPM_ID_SHIFT 0

/* Maximum number of BPM positions that can be flatenized per axis
(x or y)
 */
#define WB_FOFB_SYS_ID_REGS_BPM_POS_FLATENIZER_MAX_NUM_CTE 0x4UL

/* Interface to PRBS-related regs */
#define WB_FOFB_SYS_ID_REGS_PRBS 0x1000UL
#define WB_FOFB_SYS_ID_REGS_PRBS_SIZE 4096 /* 0x1000 = 4KB */

/* PRBS distortion control register
 */
#define WB_FOFB_SYS_ID_REGS_PRBS_CTL 0x1000UL
#define WB_FOFB_SYS_ID_REGS_PRBS_CTL_RST 0x1UL
#define WB_FOFB_SYS_ID_REGS_PRBS_CTL_STEP_DURATION_MASK 0x7feUL
#define WB_FOFB_SYS_ID_REGS_PRBS_CTL_STEP_DURATION_SHIFT 1
#define WB_FOFB_SYS_ID_REGS_PRBS_CTL_LFSR_LENGTH_MASK 0xf800UL
#define WB_FOFB_SYS_ID_REGS_PRBS_CTL_LFSR_LENGTH_SHIFT 11
#define WB_FOFB_SYS_ID_REGS_PRBS_CTL_BPM_POS_DISTORT_EN 0x10000UL
#define WB_FOFB_SYS_ID_REGS_PRBS_CTL_SP_DISTORT_EN 0x20000UL

/* Interface to setpoints distortion levels regs */
#define WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT 0x1040UL
#define WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_SIZE 64 /* 0x40 */

/* Setpoints distortion levels registers for each channel
 */
#define WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH 0x1040UL
#define WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_SIZE 4 /* 0x4 */

/* Two signed 16-bit distortion levels in RTM-LAMP ADC
counts, one for each PRBS value.

15 - 0: distortion level for PRBS value 0
31 - 16: distortion level for PRBS value 1
 */
#define WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_LEVELS 0x0UL
#define WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_LEVELS_LEVEL_0_MASK 0xffffUL
#define WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_LEVELS_LEVEL_0_SHIFT 0
#define WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_LEVELS_LEVEL_1_MASK 0xffff0000UL
#define WB_FOFB_SYS_ID_REGS_PRBS_SP_DISTORT_CH_LEVELS_LEVEL_1_SHIFT 16

/* Interface to prbs_bpm_pos_distort regs */
#define WB_FOFB_SYS_ID_REGS_PRBS_BPM_POS_DISTORT 0x1800UL
#define WB_FOFB_SYS_ID_REGS_PRBS_BPM_POS_DISTORT_SIZE 2048 /* 0x800 = 2KB */

/* Distortion levels RAM */
#define WB_FOFB_SYS_ID_REGS_PRBS_BPM_POS_DISTORT_DISTORT_RAM 0x1800UL
#define WB_FOFB_SYS_ID_REGS_PRBS_BPM_POS_DISTORT_DISTORT_RAM_SIZE 4 /* 0x4 */

/* Two signed 16-bit distortion levels in nanometers,
one for each PRBS value.

15 - 0: distortion level for PRBS value 0
31 - 16: distortion level for PRBS value 1
 */
#define WB_FOFB_SYS_ID_REGS_PRBS_BPM_POS_DISTORT_DISTORT_RAM_LEVELS 0x0UL
#define WB_FOFB_SYS_ID_REGS_PRBS_BPM_POS_DISTORT_DISTORT_RAM_LEVELS_LEVEL_0_MASK 0xffffUL
#define WB_FOFB_SYS_ID_REGS_PRBS_BPM_POS_DISTORT_DISTORT_RAM_LEVELS_LEVEL_0_SHIFT 0
#define WB_FOFB_SYS_ID_REGS_PRBS_BPM_POS_DISTORT_DISTORT_RAM_LEVELS_LEVEL_1_MASK 0xffff0000UL
#define WB_FOFB_SYS_ID_REGS_PRBS_BPM_POS_DISTORT_DISTORT_RAM_LEVELS_LEVEL_1_SHIFT 16

struct wb_fofb_sys_id_regs {
  /* [0x0]: BLOCK Interface to BPM positions flatenizers regs */
  struct bpm_pos_flatenizer {
    /* [0x0]: REG (rw) BPM positions flatenizers control register
 */
    uint32_t ctl;

    /* [0x4]: REG (ro) Maximum number of BPM positions that can be flatenized per axis
(x or y)
 */
    uint16_t max_num_cte;

    /* padding to: 4 words */
    uint8_t __padding_0[2];
  } bpm_pos_flatenizer;

  /* padding to: 1024 words */
  uint32_t __padding_0[1022];

  /* [0x1000]: BLOCK Interface to PRBS-related regs */
  struct prbs {
    /* [0x0]: REG (rw) PRBS distortion control register
 */
    uint32_t ctl;

    /* padding to: 16 words */
    uint32_t __padding_0[15];

    /* [0x40]: BLOCK Interface to setpoints distortion levels regs */
    struct sp_distort {
      /* [0x0]: REPEAT Setpoints distortion levels registers for each channel
 */
      struct ch {
        /* [0x0]: REG (rw) Two signed 16-bit distortion levels in RTM-LAMP ADC
counts, one for each PRBS value.

15 - 0: distortion level for PRBS value 0
31 - 16: distortion level for PRBS value 1
 */
        uint32_t levels;
      } ch[12];
    } sp_distort;

    /* padding to: 512 words */
    uint32_t __padding_1[480];

    /* NOTE: 'struct bpm_pos_distort' offset doesn't match
     *       WB_FOFB_SYS_ID_REGS_PRBS_BPM_POS_DISTORT_DISTORT_RAM.
     *       This is temporarily fixed by this padding. */
    uint32_t __padding_cheby_bug_fix[4];

    /* [0x800]: BLOCK Interface to prbs_bpm_pos_distort regs */
    struct bpm_pos_distort {
      /* [0x0]: MEMORY Distortion levels RAM */
      struct distort_ram {
        /* [0x0]: REG (rw) Two signed 16-bit distortion levels in nanometers,
one for each PRBS value.

15 - 0: distortion level for PRBS value 0
31 - 16: distortion level for PRBS value 1
 */
        uint32_t levels;
      } distort_ram[512];
    } bpm_pos_distort;
  } prbs;
};

#endif /* __CHEBY__WB_FOFB_SYS_ID_REGS__H__ */

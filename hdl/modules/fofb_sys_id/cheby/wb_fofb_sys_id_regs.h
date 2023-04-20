#ifndef __CHEBY__WB_FOFB_SYS_ID_REGS__H__
#define __CHEBY__WB_FOFB_SYS_ID_REGS__H__
#define WB_FOFB_SYS_ID_REGS_SIZE 8 /* 0x8 */

/* Interface to bpm_pos_flatenizer regs */
#define WB_FOFB_SYS_ID_REGS_BPM_POS_FLATENIZER 0x0UL
#define WB_FOFB_SYS_ID_REGS_BPM_POS_FLATENIZER_SIZE 8 /* 0x8 */

/* Maximum number of BPM positions that can be flatenized per axis
 */
#define WB_FOFB_SYS_ID_REGS_BPM_POS_FLATENIZER_MAX_NUM_CTE 0x0UL

/* Together with max_num_cte, defines the range of BPM position
indexes being flatenized, which is given by
[base_bpm_id, base_bpm_id + max_num_cte) -> BPM x positions; and
[base_bpm_id + 256, base_bpm_id + 256 + max_num_cte) -> BPM y
positions. The valid range of this register is [0, 255].
 */
#define WB_FOFB_SYS_ID_REGS_BPM_POS_FLATENIZER_BASE_BPM_ID 0x4UL

struct wb_fofb_sys_id_regs {
  /* [0x0]: BLOCK Interface to bpm_pos_flatenizer regs */
  struct bpm_pos_flatenizer {
    /* [0x0]: REG (ro) Maximum number of BPM positions that can be flatenized per axis
 */
    uint16_t max_num_cte;

    /* padding to: 4 words */
    uint8_t __padding_0[2];

    /* [0x4]: REG (rw) Together with max_num_cte, defines the range of BPM position
indexes being flatenized, which is given by
[base_bpm_id, base_bpm_id + max_num_cte) -> BPM x positions; and
[base_bpm_id + 256, base_bpm_id + 256 + max_num_cte) -> BPM y
positions. The valid range of this register is [0, 255].
 */
    uint8_t base_bpm_id;

    /* padding to: 4 words */
    uint8_t __padding_1[3];
  } bpm_pos_flatenizer;
};

#endif /* __CHEBY__WB_FOFB_SYS_ID_REGS__H__ */

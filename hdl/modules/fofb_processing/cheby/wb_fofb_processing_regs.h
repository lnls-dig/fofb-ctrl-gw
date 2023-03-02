#ifndef __CHEBY__WB_FOFB_PROCESSING_REGS__H__
#define __CHEBY__WB_FOFB_PROCESSING_REGS__H__
#define WB_FOFB_PROCESSING_REGS_SIZE 53248 /* 0xd000 = 52KB */

/* fofb processing fixed-point position constants */
#define WB_FOFB_PROCESSING_REGS_FIXED_POINT_POS 0x0UL
#define WB_FOFB_PROCESSING_REGS_FIXED_POINT_POS_SIZE 64 /* 0x40 */

/* fofb processing coefficients fixed-point position constant */
#define WB_FOFB_PROCESSING_REGS_FIXED_POINT_POS_COEFF 0x0UL
#define WB_FOFB_PROCESSING_REGS_FIXED_POINT_POS_COEFF_VAL_MASK 0xffffffffUL
#define WB_FOFB_PROCESSING_REGS_FIXED_POINT_POS_COEFF_VAL_SHIFT 0

/* fofb processing accumulators' gains fixed-point position register */
#define WB_FOFB_PROCESSING_REGS_FIXED_POINT_POS_ACCS_GAINS 0x4UL
#define WB_FOFB_PROCESSING_REGS_FIXED_POINT_POS_ACCS_GAINS_VAL_MASK 0xffffffffUL
#define WB_FOFB_PROCESSING_REGS_FIXED_POINT_POS_ACCS_GAINS_VAL_SHIFT 0

/* fofb processing loop interlock registers */
#define WB_FOFB_PROCESSING_REGS_LOOP_INTLK 0x40UL
#define WB_FOFB_PROCESSING_REGS_LOOP_INTLK_SIZE 64 /* 0x40 */

/* fofb processing loop interlock control register */
#define WB_FOFB_PROCESSING_REGS_LOOP_INTLK_CTL 0x40UL
#define WB_FOFB_PROCESSING_REGS_LOOP_INTLK_CTL_STA_CLR 0x1UL
#define WB_FOFB_PROCESSING_REGS_LOOP_INTLK_CTL_SRC_EN_ORB_DISTORT 0x2UL
#define WB_FOFB_PROCESSING_REGS_LOOP_INTLK_CTL_SRC_EN_PACKET_LOSS 0x4UL

/* fofb processing loop interlock status register */
#define WB_FOFB_PROCESSING_REGS_LOOP_INTLK_STA 0x44UL
#define WB_FOFB_PROCESSING_REGS_LOOP_INTLK_STA_ORB_DISTORT 0x1UL
#define WB_FOFB_PROCESSING_REGS_LOOP_INTLK_STA_PACKET_LOSS 0x2UL

/* fofb processing loop interlock orbit distortion limit value register */
#define WB_FOFB_PROCESSING_REGS_LOOP_INTLK_ORB_DISTORT_LIMIT 0x48UL
#define WB_FOFB_PROCESSING_REGS_LOOP_INTLK_ORB_DISTORT_LIMIT_VAL_MASK 0xffffffffUL
#define WB_FOFB_PROCESSING_REGS_LOOP_INTLK_ORB_DISTORT_LIMIT_VAL_SHIFT 0

/* fofb processing loop interlock minimum number of packets per timeframe value register */
#define WB_FOFB_PROCESSING_REGS_LOOP_INTLK_MIN_NUM_PKTS 0x4cUL
#define WB_FOFB_PROCESSING_REGS_LOOP_INTLK_MIN_NUM_PKTS_VAL_MASK 0xffffffffUL
#define WB_FOFB_PROCESSING_REGS_LOOP_INTLK_MIN_NUM_PKTS_VAL_SHIFT 0

/* fofb processing maximum setpoint decimation ratio constant */
#define WB_FOFB_PROCESSING_REGS_SP_DECIM_RATIO_MAX 0x80UL
#define WB_FOFB_PROCESSING_REGS_SP_DECIM_RATIO_MAX_CTE_MASK 0xffffffffUL
#define WB_FOFB_PROCESSING_REGS_SP_DECIM_RATIO_MAX_CTE_SHIFT 0

/* fofb processing setpoints ram bank */
#define WB_FOFB_PROCESSING_REGS_SPS_RAM_BANK 0x800UL
#define WB_FOFB_PROCESSING_REGS_SPS_RAM_BANK_SIZE 4 /* 0x4 */

/* None */
#define WB_FOFB_PROCESSING_REGS_SPS_RAM_BANK_DATA 0x0UL

/* None */
#define WB_FOFB_PROCESSING_REGS_CH 0x1000UL
#define WB_FOFB_PROCESSING_REGS_CH_SIZE 4096 /* 0x1000 = 4KB */

/* fofb processing coefficients ram bank (per channel) */
#define WB_FOFB_PROCESSING_REGS_CH_COEFF_RAM_BANK 0x0UL
#define WB_FOFB_PROCESSING_REGS_CH_COEFF_RAM_BANK_SIZE 4 /* 0x4 */

/* None */
#define WB_FOFB_PROCESSING_REGS_CH_COEFF_RAM_BANK_DATA 0x0UL

/* fofb processing accumulator registers (per channel) */
#define WB_FOFB_PROCESSING_REGS_CH_ACC 0x800UL
#define WB_FOFB_PROCESSING_REGS_CH_ACC_SIZE 32 /* 0x20 */

/* fofb processing accumulator control register (per channel) */
#define WB_FOFB_PROCESSING_REGS_CH_ACC_CTL 0x800UL
#define WB_FOFB_PROCESSING_REGS_CH_ACC_CTL_CLEAR 0x1UL
#define WB_FOFB_PROCESSING_REGS_CH_ACC_CTL_FREEZE 0x2UL

/* fofb processing accumulator gain register (per channel) */
#define WB_FOFB_PROCESSING_REGS_CH_ACC_GAIN 0x804UL
#define WB_FOFB_PROCESSING_REGS_CH_ACC_GAIN_VAL_MASK 0xffffffffUL
#define WB_FOFB_PROCESSING_REGS_CH_ACC_GAIN_VAL_SHIFT 0

/* fofb processing saturation limits registers (per channel) */
#define WB_FOFB_PROCESSING_REGS_CH_SP_LIMITS 0x820UL
#define WB_FOFB_PROCESSING_REGS_CH_SP_LIMITS_SIZE 8 /* 0x8 */

/* fofb processing maximum saturation value register (per channel) */
#define WB_FOFB_PROCESSING_REGS_CH_SP_LIMITS_MAX 0x820UL
#define WB_FOFB_PROCESSING_REGS_CH_SP_LIMITS_MAX_VAL_MASK 0xffffffffUL
#define WB_FOFB_PROCESSING_REGS_CH_SP_LIMITS_MAX_VAL_SHIFT 0

/* fofb processing minimum saturation value register (per channel) */
#define WB_FOFB_PROCESSING_REGS_CH_SP_LIMITS_MIN 0x824UL
#define WB_FOFB_PROCESSING_REGS_CH_SP_LIMITS_MIN_VAL_MASK 0xffffffffUL
#define WB_FOFB_PROCESSING_REGS_CH_SP_LIMITS_MIN_VAL_SHIFT 0

/* fofb processing setpoints decimation registers (per channel) */
#define WB_FOFB_PROCESSING_REGS_CH_SP_DECIM 0x828UL
#define WB_FOFB_PROCESSING_REGS_CH_SP_DECIM_SIZE 8 /* 0x8 */

/* fofb processing decimated setpoint value register (per channel) */
#define WB_FOFB_PROCESSING_REGS_CH_SP_DECIM_DATA 0x828UL
#define WB_FOFB_PROCESSING_REGS_CH_SP_DECIM_DATA_VAL_MASK 0xffffffffUL
#define WB_FOFB_PROCESSING_REGS_CH_SP_DECIM_DATA_VAL_SHIFT 0

/* fofb processing setpoint decimation ratio register (per channel)
NOTE: if this value is higher than sp_decim_ratio_max, gw will truncate the
      lowest ceil(log2(sp_decim_ratio_max)) bits
 */
#define WB_FOFB_PROCESSING_REGS_CH_SP_DECIM_RATIO 0x82cUL
#define WB_FOFB_PROCESSING_REGS_CH_SP_DECIM_RATIO_VAL_MASK 0xffffffffUL
#define WB_FOFB_PROCESSING_REGS_CH_SP_DECIM_RATIO_VAL_SHIFT 0

struct wb_fofb_processing_regs {
  /* [0x0]: BLOCK fofb processing fixed-point position constants */
  struct fixed_point_pos {
    /* [0x0]: REG (ro) fofb processing coefficients fixed-point position constant */
    uint32_t coeff;

    /* [0x4]: REG (ro) fofb processing accumulators' gains fixed-point position register */
    uint32_t accs_gains;

    /* padding to: 1 words */
    uint32_t __padding_0[14];
  } fixed_point_pos;

  /* [0x40]: BLOCK fofb processing loop interlock registers */
  struct loop_intlk {
    /* [0x0]: REG (rw) fofb processing loop interlock control register */
    uint32_t ctl;

    /* [0x4]: REG (ro) fofb processing loop interlock status register */
    uint32_t sta;

    /* [0x8]: REG (rw) fofb processing loop interlock orbit distortion limit value register */
    uint32_t orb_distort_limit;

    /* [0xc]: REG (rw) fofb processing loop interlock minimum number of packets per timeframe value register */
    uint32_t min_num_pkts;

    /* padding to: 3 words */
    uint32_t __padding_0[12];
  } loop_intlk;

  /* [0x80]: REG (ro) fofb processing maximum setpoint decimation ratio constant */
  uint32_t sp_decim_ratio_max;

  /* padding to: 512 words */
  uint32_t __padding_0[479];

  /* [0x800]: MEMORY fofb processing setpoints ram bank */
  struct sps_ram_bank {
    /* [0x0]: REG (rw) (no description) */
    uint32_t data;
  } sps_ram_bank[512];

  /* [0x1000]: REPEAT (no description) */
  struct ch {
    /* [0x0]: MEMORY fofb processing coefficients ram bank (per channel) */
    struct coeff_ram_bank {
      /* [0x0]: REG (rw) (no description) */
      uint32_t data;
    } coeff_ram_bank[512];

    /* [0x800]: BLOCK fofb processing accumulator registers (per channel) */
    struct acc {
      /* [0x0]: REG (rw) fofb processing accumulator control register (per channel) */
      uint32_t ctl;

      /* [0x4]: REG (rw) fofb processing accumulator gain register (per channel) */
      uint32_t gain;

      /* padding to: 1 words */
      uint32_t __padding_0[6];
    } acc;

    /* [0x820]: BLOCK fofb processing saturation limits registers (per channel) */
    struct sp_limits {
      /* [0x0]: REG (rw) fofb processing maximum saturation value register (per channel) */
      uint32_t max;

      /* [0x4]: REG (rw) fofb processing minimum saturation value register (per channel) */
      uint32_t min;
    } sp_limits;

    /* [0x828]: BLOCK fofb processing setpoints decimation registers (per channel) */
    struct sp_decim {
      /* [0x0]: REG (ro) fofb processing decimated setpoint value register (per channel) */
      uint32_t data;

      /* [0x4]: REG (rw) fofb processing setpoint decimation ratio register (per channel)
NOTE: if this value is higher than sp_decim_ratio_max, gw will truncate the
      lowest ceil(log2(sp_decim_ratio_max)) bits
 */
      uint32_t ratio;
    } sp_decim;

    /* padding to: 522 words */
    uint32_t __padding_0[500];
  } ch[12];
};

#endif /* __CHEBY__WB_FOFB_PROCESSING_REGS__H__ */

#ifndef __CHEBY__FOFB_CC_CSR__H__
#define __CHEBY__FOFB_CC_CSR__H__
#define FOFB_CC_CSR_SIZE 16384 /* 0x4000 = 16KB */

/* FOFB CC configuration register */
#define FOFB_CC_CSR_CFG_VAL 0x0UL

/* FOFB CC control register */
#define FOFB_CC_CSR_CFG_CTL 0x4UL
#define FOFB_CC_CSR_CFG_CTL_READ_RAM 0x1UL

/* FOFB CC RAM for register map */
#define FOFB_CC_CSR_RAM_REG 0x2000UL
#define FOFB_CC_CSR_RAM_REG_SIZE 4 /* 0x4 */

/* None */
#define FOFB_CC_CSR_RAM_REG_DATA 0x0UL

struct fofb_cc_csr {
  /* [0x0]: REG (rw) FOFB CC configuration register */
  uint32_t cfg_val;

  /* [0x4]: REG (rw) FOFB CC control register */
  uint32_t cfg_ctl;

  /* padding to: 2048 words */
  uint32_t __padding_0[2046];

  /* [0x2000]: MEMORY FOFB CC RAM for register map */
  struct ram_reg {
    /* [0x0]: REG (rw) (no description) */
    uint32_t data;
  } ram_reg[2048];
};

#endif /* __CHEBY__FOFB_CC_CSR__H__ */

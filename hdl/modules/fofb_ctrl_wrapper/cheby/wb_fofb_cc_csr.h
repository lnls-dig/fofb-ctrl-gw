#ifndef __CHEBY__FOFB_CC_CSR__H__
#define __CHEBY__FOFB_CC_CSR__H__
#define FOFB_CC_CSR_SIZE 8196 /* 0x2004 */

/* FOFB CC RAM for register map */
#define FOFB_CC_CSR_RAM_REG 0x0UL
#define FOFB_CC_CSR_RAM_REG_SIZE 4 /* 0x4 */

/* None */
#define FOFB_CC_CSR_RAM_REG_DATA 0x0UL

/* FOFB CC configuration register */
#define FOFB_CC_CSR_CFG_VAL 0x2000UL

struct fofb_cc_csr {
  /* [0x0]: MEMORY FOFB CC RAM for register map */
  struct ram_reg {
    /* [0x0]: REG (rw) (no description) */
    uint32_t data;
  } ram_reg[2048];

  /* [0x2000]: REG (rw) FOFB CC configuration register */
  uint32_t cfg_val;
};

#endif /* __CHEBY__FOFB_CC_CSR__H__ */

#ifndef __CHEBY__DOT_PROD_WB__H__
#define __CHEBY__DOT_PROD_WB__H__
#define DOT_PROD_WB_SIZE 12 /* 0xc */

/* None */
#define DOT_PROD_WB_RAM_COEFF_DAT 0x0UL

/* None */
#define DOT_PROD_WB_RAM_COEFF_ADDR 0x4UL

/* None */
#define DOT_PROD_WB_RAM_WRITE 0x8UL
#define DOT_PROD_WB_RAM_WRITE_ENABLE 0x1UL

struct dot_prod_wb {
  /* [0x0]: REG (rw) (no description) */
  uint32_t ram_coeff_dat;

  /* [0x4]: REG (rw) (no description) */
  uint32_t ram_coeff_addr;

  /* [0x8]: REG (rw) (no description) */
  uint32_t ram_write;
};

#endif /* __CHEBY__DOT_PROD_WB__H__ */

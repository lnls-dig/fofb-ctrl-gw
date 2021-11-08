#ifndef __CHEBY__WB_FOFB_PROCESSING_REGS__H__
#define __CHEBY__WB_FOFB_PROCESSING_REGS__H__
#define WB_FOFB_PROCESSING_REGS_SIZE 16 /* 0x10 */

/* None */
#define WB_FOFB_PROCESSING_REGS_RAM_WRITE 0x0UL
#define WB_FOFB_PROCESSING_REGS_RAM_WRITE_ENABLE 0x1UL

/* None */
#define WB_FOFB_PROCESSING_REGS_RAM_DATA_IN 0x4UL

/* None */
#define WB_FOFB_PROCESSING_REGS_RAM_DATA_OUT 0x8UL

/* None */
#define WB_FOFB_PROCESSING_REGS_RAM_ADDR 0xcUL

struct wb_fofb_processing_regs {
  /* [0x0]: REG (rw) (no description) */
  uint32_t ram_write;

  /* [0x4]: REG (rw) (no description) */
  uint32_t ram_data_in;

  /* [0x8]: REG (ro) (no description) */
  uint32_t ram_data_out;

  /* [0xc]: REG (rw) (no description) */
  uint32_t ram_addr;
};

#endif /* __CHEBY__WB_FOFB_PROCESSING_REGS__H__ */

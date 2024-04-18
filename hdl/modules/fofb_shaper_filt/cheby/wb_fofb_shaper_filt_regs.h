#ifndef __CHEBY__WB_FOFB_SHAPER_FILT_REGS__H__
#define __CHEBY__WB_FOFB_SHAPER_FILT_REGS__H__
#define WB_FOFB_SHAPER_FILT_REGS_SIZE 8200 /* 0x2008 */

/* None */
#define WB_FOFB_SHAPER_FILT_REGS_CH 0x0UL
#define WB_FOFB_SHAPER_FILT_REGS_CH_SIZE 512 /* 0x200 */

/* Coefficients for the ceil('max_filt_order'/2) IIR internal
biquads.

Each biquad takes 5 coefficients: b0, b1, b2, a1 and a2 (a0 = 1).
The 'coeffs' array should be populated in the following manner:

  coeffs[0 + 8*{biquad_idx}] = b0 of biquad {biquad_idx}
  coeffs[1 + 8*{biquad_idx}] = b1 of biquad {biquad_idx}
  coeffs[2 + 8*{biquad_idx}] = b2 of biquad {biquad_idx}
  coeffs[3 + 8*{biquad_idx}] = a1 of biquad {biquad_idx}
  coeffs[4 + 8*{biquad_idx}] = a2 of biquad {biquad_idx}
  coeffs[5 + 8*{biquad_idx}] = unused
  coeffs[6 + 8*{biquad_idx}] = unused
  coeffs[7 + 8*{biquad_idx}] = unused

NOTE: This ABI supports up to 20th order filters, but only the
coefficients corresponding to the first 'max_filt_order' filters
are meaningful for the gateware.
 */
#define WB_FOFB_SHAPER_FILT_REGS_CH_COEFFS 0x0UL
#define WB_FOFB_SHAPER_FILT_REGS_CH_COEFFS_SIZE 4 /* 0x4 */

/* Coefficient value using 'coeffs_fp_repr' fixed-point
representation. It should be aligned to the left.
 */
#define WB_FOFB_SHAPER_FILT_REGS_CH_COEFFS_VAL 0x0UL

/* Maximum filter order supported by the gateware.
 */
#define WB_FOFB_SHAPER_FILT_REGS_MAX_FILT_ORDER 0x2000UL

/* Fixed-point signed (2's complement) representation of coefficients.
The coefficients should be aligned to the left. The fixed-point
position is then given by 32 - 'int_width' (i.e. one should divide
this register's content by 2**{32 - 'int_width'} to get the
represented decimal number.
 */
#define WB_FOFB_SHAPER_FILT_REGS_COEFFS_FP_REPR 0x2004UL
#define WB_FOFB_SHAPER_FILT_REGS_COEFFS_FP_REPR_INT_WIDTH_MASK 0x1fUL
#define WB_FOFB_SHAPER_FILT_REGS_COEFFS_FP_REPR_INT_WIDTH_SHIFT 0
#define WB_FOFB_SHAPER_FILT_REGS_COEFFS_FP_REPR_FRAC_WIDTH_MASK 0x3e0UL
#define WB_FOFB_SHAPER_FILT_REGS_COEFFS_FP_REPR_FRAC_WIDTH_SHIFT 5

#ifndef __ASSEMBLER__
struct wb_fofb_shaper_filt_regs {
  /* [0x0]: REPEAT (no description) */
  struct ch {
    /* [0x0]: MEMORY Coefficients for the ceil('max_filt_order'/2) IIR internal
biquads.

Each biquad takes 5 coefficients: b0, b1, b2, a1 and a2 (a0 = 1).
The 'coeffs' array should be populated in the following manner:

  coeffs[0 + 8*{biquad_idx}] = b0 of biquad {biquad_idx}
  coeffs[1 + 8*{biquad_idx}] = b1 of biquad {biquad_idx}
  coeffs[2 + 8*{biquad_idx}] = b2 of biquad {biquad_idx}
  coeffs[3 + 8*{biquad_idx}] = a1 of biquad {biquad_idx}
  coeffs[4 + 8*{biquad_idx}] = a2 of biquad {biquad_idx}
  coeffs[5 + 8*{biquad_idx}] = unused
  coeffs[6 + 8*{biquad_idx}] = unused
  coeffs[7 + 8*{biquad_idx}] = unused

NOTE: This ABI supports up to 20th order filters, but only the
coefficients corresponding to the first 'max_filt_order' filters
are meaningful for the gateware.
 */
    struct coeffs {
      /* [0x0]: REG (rw) Coefficient value using 'coeffs_fp_repr' fixed-point
representation. It should be aligned to the left.
 */
      uint32_t val;
    } coeffs[80];

    /* padding to: 0 words */
    uint32_t __padding_0[48];
  } ch[12];

  /* padding to: 0 words */
  uint32_t __padding_0[512];

  /* [0x2000]: REG (ro) Maximum filter order supported by the gateware.
 */
  uint32_t max_filt_order;

  /* [0x2004]: REG (ro) Fixed-point signed (2's complement) representation of coefficients.
The coefficients should be aligned to the left. The fixed-point
position is then given by 32 - 'int_width' (i.e. one should divide
this register's content by 2**{32 - 'int_width'} to get the
represented decimal number.
 */
  uint32_t coeffs_fp_repr;
};
#endif /* !__ASSEMBLER__*/

#endif /* __CHEBY__WB_FOFB_SHAPER_FILT_REGS__H__ */

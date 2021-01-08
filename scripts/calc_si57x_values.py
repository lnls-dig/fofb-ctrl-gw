#!/usr/bin/env python3

# Based on script from Joao Brito

fout = 156250000
hs_div_opt = {
    4: "0b000",
    5: "0b001",
    6: "0b010",
    7: "0b011",
    9: "0b101",
    11: "0b111"
}
hs_div = 4
N1 = 8  # even number or 1
# 4.85 <= fdco <= 5.67 GHz
fdco = fout*hs_div*N1
fxtal = 114300370
RFREQ = fdco/fxtal
RFREQw = hex(int(RFREQ*2**28))

print("\nSi570 RTM center freq.: {}".format(fout))
print("hs_div: {} bits: {}".format(hs_div, hs_div_opt[hs_div]))
print("N1: {} N1 bits: {}".format(N1, bin(N1-1)))
print("fdco: {} In range: {}".format(fdco, ((fdco>=4.85e9) & (fdco<=5.67e9))))
print("RFREQ: {}".format(RFREQw))

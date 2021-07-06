#!/usr/bin/env python3

import sys
import matplotlib.pyplot as plt
import pandas as pd

try:
    input = sys.argv[1]
except (IndexError):
    print("Invalid or missing filename")
    sys.exit(1)

df = pd.read_csv(input)
ax = df.plot(title="Error counts for {}".format(input))
ax.set_xlabel("Samples")
ax.set_ylabel("Error counts")

plt.show()

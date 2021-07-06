#!/usr/bin/env python3

import sys
import os
import re
import itertools
import pandas as pd

try:
    input = sys.argv[1]
    input_basename = os.path.splitext(input)[0]
except (IndexError):
    print("Invalid or missing filename")
    sys.exit(1)

"""
 stats = {
     # Board
     "1": {
         # Device
         "0": {
             # Stats
             "hard_err_cnt" : [(1, 1, 1, 1), (2, 4, 5, 6), ...]
             "soft_err_cnt" : [(1, 4, 2, 1), (1, 2, 3, 1), ...]
             "frame_err_cnt": [(1, 0, 1, 1), (2, 7, 2, 2), ...]
         }
         "1": {
             "hard_err_cnt" : [(1, 1, 1, 1), (2, 4, 5, 6), ...]
             "soft_err_cnt" : [(1, 4, 2, 1), (1, 2, 3, 1), ...]
             "frame_err_cnt": [(1, 0, 1, 1), (2, 7, 2, 2), ...]
         }
     }
     "2": {
         # Device
         "0": {
             # Stats
             "hard_err_cnt" : [(1, 1, 1, 1), (2, 4, 5, 6), ...]
             "soft_err_cnt" : [(1, 4, 2, 1), (1, 2, 3, 1), ...]
             "frame_err_cnt": [(1, 0, 1, 1), (2, 7, 2, 2), ...]
         }
         "1": {
             "hard_err_cnt" : [(1, 1, 1, 1), (2, 4, 5, 6), ...]
             "soft_err_cnt" : [(1, 4, 2, 1), (1, 2, 3, 1), ...]
             "frame_err_cnt": [(1, 0, 1, 1), (2, 7, 2, 2), ...]
         }
     }

}
"""
stats = {}
skip_line = True
with open(input) as f:
    for line in f:

        # search for "Board XX" header
        match = re.search("Board ([0-9]+)", line)
        if match:
            board = int(match.group(1))
            skip_line = False
            continue

        if skip_line:
            continue

        # stats for board
        match = re.search("halcs: ([0-9]+)", line)
        if match:
            device = int(match.group(1))
        else:
           print("No device number for line: {}".format(line))
           sys.exit(1)

        match = re.search("(hard_err_cnt|soft_err_cnt|frame_err_cnt): ([0-9]+),([0-9]+),([0-9]+),([0-9]+)", line)
        cnt = ""
        if match:
            cnt = match.group(1)
            val = [int(match.group(i)) for i in range(2,6)]
        else:
           print("No counter stats in line: {}".format(line))
           sys.exit(1)

        if board not in stats:
            stats.update({board: {}})

        if device not in stats[board]:
            stats[board].update({device: {}})

        if cnt not in stats[board][device]:
            stats[board][device].update({cnt: []})

        stats[board][device][cnt].append(val)

for board in stats.keys():
    for dev in stats[board].keys():
        with open(input_basename + str(board) + "_" + str(dev) + ".txt", "w") as f:
            df = pd.DataFrame([list(itertools.chain.from_iterable(list(value)))
                        for value in zip((stats[board][device]["hard_err_cnt"]),
                                              (stats[board][device]["soft_err_cnt"]),
                                              (stats[board][device]["frame_err_cnt"]))
                        ], columns = ["hard_err_cnt_1", "hard_err_cnt_2", "hard_err_cnt_3", "hard_err_cnt_4",
                                      "soft_err_cnt_1", "soft_err_cnt_2", "soft_err_cnt_3", "soft_err_cnt_4",
                                      "frame_err_cnt_1", "frame_err_cnt_2", "frame_err_cnt_3", "frame_err_cnt_4"])
            df.to_csv(f, index=False)

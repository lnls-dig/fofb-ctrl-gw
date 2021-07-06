#!/usr/bin/env bash

set -euo pipefail

LOG=$1

trap \
   "{ date | tee -a ${LOG}; exit 0; }" \
   SIGINT SIGTERM ERR

date | tee -a ${LOG}

while true; do
    for board in 2 3 4 5 6 7 8 9 10; do
        ( \
            echo "Board ${board}";
            for halcs in 2 1; do
                for cnt in hard_err_cnt soft_err_cnt frame_err_cnt; do
                    echo -n "halcs: ${halcs}; cnt: ${cnt}: "
                    fofb_ctrl --brokerendp ipc:///tmp/malamute --boardslot ${board} --halcsnumber ${halcs} --${cnt};
                done
            done
        ) | tee -a ${LOG}
    done

    sleep 1;
done

date | tee -a ${LOG}

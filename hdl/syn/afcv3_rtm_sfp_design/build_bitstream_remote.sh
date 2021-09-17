#!/bin/bash

# Exit on error
set -e
# Check for uninitialized variables
set -u

COMMAND="(hdlmake; make cleanremote; time make remote; make sync; date) 2>&1 | tee make_output &"

echo $COMMAND
eval $COMMAND

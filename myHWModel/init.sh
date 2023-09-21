#!/bin/bash

echo "optional parameter. (1) for running vsim"

run=$1

source init_questa

echo "everything is setup. Workspace is clean"

vsim -gui -do resim.tcl 

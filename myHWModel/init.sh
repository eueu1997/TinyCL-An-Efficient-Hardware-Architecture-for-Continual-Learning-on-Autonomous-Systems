#!/bin/bash

echo "optional parameter. (1) for running vsim"

run=$1

source /home/thesis/eugenio.ressa/Desktop/myHWModel/init_questa

echo "everything is setup. Workspace is clean"

vsim -batch -do /home/thesis/eugenio.ressa/Desktop/myHWModel/resim_py.tcl
 

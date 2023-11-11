# This file is public domain, it can be freely copied without restrictions.
# SPDX-License-Identifier: CC0-1.0

PWD=$(shell pwd)

export PYTHONPATH := $(PWD)/model:$(PYTHONPATH)
SIM ?= questa
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES  = /home/thesis/eugenio.ressa/Desktop/myHWModel/src/MAC/adder.sv
VERILOG_SOURCES  = /home/thesis/eugenio.ressa/Desktop/myHWModel/src/MAC/multiplier.sv
VERILOG_SOURCES  = /home/thesis/eugenio.ressa/Desktop/myHWModel/src/MAC/MAC.sv


TOPLEVEL = MAC
MODULE = test_MAC

include $(shell cocotb-config --makefiles)/Makefile.sim

import cocotb
from cocotb.triggers import Timer
from cocotb.binary import BinaryValue
import numpy as np
import random
def fxdPointCnv(x):
    return format(int(x*4096) & 0xFFFF,'04X') #left shift of 8 position 
def twos_complement(hexstr, bits):
    value = int(hexstr, 16)
    if value & (1 << (bits - 1)):
        value -= 1 << bits
    return value

@cocotb.test()
async def adder_randomised_test(dut):
    """Test for adding 2 random numbers multiple times"""
    myMAC=0
    S = BinaryValue()
    for j in range(10):
        myMAC=0
        A = [BinaryValue()]*8
        B = [BinaryValue()]*8
        
        for i in range (8):
            A[i].integer = int(4096/(j+1))#random.randint(0, 2**10-1)
            B[i].integer = int(4096/(j+1))#random.randint(0, 2**10-1)
            myMAC += (A[i].integer/4096)*(B[i].integer/4096)
        for i in range(8):
            dut.featureIn[i] <= A[i].integer
            dut.Kernel[i] <= B[i].integer
        dut.select <= 0
        dut.partialSumIn <= 0
        await Timer(2, units='ns')
        print(f"Iteration {i}. Python value : {myMAC}. Verilog value : {dut.featureOut.value.integer/4096}")
        
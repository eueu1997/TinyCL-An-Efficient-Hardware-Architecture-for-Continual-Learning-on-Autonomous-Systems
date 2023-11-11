echo "resim run"
set workdir /home/thesis/eugenio.ressa/Desktop/myHWModel/src
quit -sim
vlog -reportprogress 300 -work work /home/thesis/eugenio.ressa/Desktop/myHWModel/src/MAC/adder.sv
vlog -reportprogress 300 -work work /home/thesis/eugenio.ressa/Desktop/myHWModel/src/activation/activation.sv
vlog -reportprogress 300 -work work /home/thesis/eugenio.ressa/Desktop/myHWModel/src/MAC/multiplier.sv
vlog -reportprogress 300 -work work /home/thesis/eugenio.ressa/Desktop/myHWModel/src/MAC/MultiOpAdderDadda.sv
vlog -reportprogress 300 -work work /home/thesis/eugenio.ressa/Desktop/myHWModel/src/MAC/MAC.sv
vlog -reportprogress 300 -work work /home/thesis/eugenio.ressa/Desktop/myHWModel/src/FW/featureRegisters.sv
vlog -reportprogress 300 -work work /home/thesis/eugenio.ressa/Desktop/myHWModel/src/FW/kernelsRegisters.sv
vlog -reportprogress 300 -work work /home/thesis/eugenio.ressa/Desktop/myHWModel/src/FW/FWAddrManager.sv
vlog -reportprogress 300 -work work /home/thesis/eugenio.ressa/Desktop/myHWModel/src/memory/SRAM.sv
vlog -reportprogress 300 -work work /home/thesis/eugenio.ressa/Desktop/myHWModel/src/BW/register.sv
vlog -reportprogress 300 -work work /home/thesis/eugenio.ressa/Desktop/myHWModel/src/BW/gradientInRegisterBWDK.sv
vlog -reportprogress 300 -work work /home/thesis/eugenio.ressa/Desktop/myHWModel/src/BW/AddrManagerBWDK.sv
vlog -reportprogress 300 -work work /home/thesis/eugenio.ressa/Desktop/myHWModel/src/BW/AddrManagerBWDX.sv
vlog -reportprogress 300 -work work /home/thesis/eugenio.ressa/Desktop/myHWModel/src/BW/featureRegistersBWDX.sv
vlog -reportprogress 300 -work work /home/thesis/eugenio.ressa/Desktop/myHWModel/src/BW/kernelRegisterBWDX.sv

vlog -reportprogress 300 -work work /home/thesis/eugenio.ressa/Desktop/myHWModel/src/FW_BW_PU.sv
vlog -reportprogress 300 -work work /home/thesis/eugenio.ressa/Desktop/myHWModel/src/NN.sv
vlog -reportprogress 300 -work work /home/thesis/eugenio.ressa/Desktop/myHWModel/tb/NN_tb.sv
#vlog -reportprogress 300 -work work /home/thesis/eugenio.ressa/Desktop/myHWModel/src/GDumb.sv


vsim -t ns -voptargs=+acc work.NN_tb
#add wave -position insertpoint {sim:/NN_tb/uut/FW_BW_PU_i/genblk1[0]/genblk1[0]/MACij/*}
add wave -position insertpoint sim:/NN_tb/uut/*
add wave -position insertpoint sim:/NN_tb/uut/FW_BW_PU_i/*

run 30000 ns
#quit
#add wave -position insertpoint sim:/NN_tb/uut/*
#add wave -position insertpoint sim:/NN_tb/uut/FW_BW_PU_i/*
#add wave *
#run 300000 ns
#quit -sim
#vsim -debugDB -t 1ns work.tb_dadda
#add wave *

#run 100 ns

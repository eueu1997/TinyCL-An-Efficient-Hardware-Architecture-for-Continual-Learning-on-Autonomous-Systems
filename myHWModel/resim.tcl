echo "resim run"
set workdir /home/thesis/eugenio.ressa/Desktop/myHWModel/src
quit -sim

vlog -work work $workdir/FW/featureRegister.v


#vsim -debugDB -t 1ns work.tb_dadda
#add wave *

#run 100 ns

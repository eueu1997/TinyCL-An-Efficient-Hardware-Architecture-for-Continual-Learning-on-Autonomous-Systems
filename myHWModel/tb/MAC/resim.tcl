echo "resim run"
set workdir /home/thesis/eugenio.ressa/Desktop/myHWModel/src
quit -sim

vlog -reportprogress 300 -work work /home/thesis/eugenio.ressa/Desktop/myHWModel/src/MAC/multiplier.sv

vlog -reportprogress 300 -work work /home/thesis/eugenio.ressa/Desktop/myHWModel/tb/MAC/multiplier_tb.sv 
vsim -batch -t ns -voptargs=+acc work.operatorCore_sim
run 600 ns



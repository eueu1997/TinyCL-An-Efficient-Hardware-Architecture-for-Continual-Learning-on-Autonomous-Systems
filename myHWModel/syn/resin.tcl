set power "preserve rtl hier names true"
set designChecked "FW_BW_PU"
analyze -f sverilog -lib WORK /home/thesis/eugenio.ressa/Desktop/myHWModel/syn/src/MAC/adder.sv
analyze -f sverilog -lib WORK /home/thesis/eugenio.ressa/Desktop/myHWModel/syn/src/activation/activation.sv
analyze -f sverilog -lib WORK /home/thesis/eugenio.ressa/Desktop/myHWModel/syn/src/MAC/multiplier.sv
analyze -f sverilog -lib WORK /home/thesis/eugenio.ressa/Desktop/myHWModel/syn/src/MAC/MultiOpAdderDadda.sv
analyze -f sverilog -lib WORK /home/thesis/eugenio.ressa/Desktop/myHWModel/syn/src/MAC/MAC.sv
analyze -f sverilog -lib WORK /home/thesis/eugenio.ressa/Desktop/myHWModel/syn/src/FW/featureRegisters.sv
analyze -f sverilog -lib WORK /home/thesis/eugenio.ressa/Desktop/myHWModel/syn/src/FW/kernelsRegisters.sv
analyze -f sverilog -lib WORK /home/thesis/eugenio.ressa/Desktop/myHWModel/syn/src/FW/FWAddrManager.sv
analyze -f sverilog -lib WORK /home/thesis/eugenio.ressa/Desktop/myHWModel/syn/src/BW/register.sv
analyze -f sverilog -lib WORK /home/thesis/eugenio.ressa/Desktop/myHWModel/syn/src/BW/featureInMngrBWDK.sv
analyze -f sverilog -lib WORK /home/thesis/eugenio.ressa/Desktop/myHWModel/syn/src/BW/AddrManagerBWDK.sv
analyze -f sverilog -lib WORK /home/thesis/eugenio.ressa/Desktop/myHWModel/syn/src/BW/AddrManagerBWDX.sv
analyze -f sverilog -lib WORK /home/thesis/eugenio.ressa/Desktop/myHWModel/syn/src/BW/featureRegistersBWDX.sv
analyze -f sverilog -lib WORK /home/thesis/eugenio.ressa/Desktop/myHWModel/syn/src/BW/kernelRegisterBWDX.sv
analyze -f sverilog -lib WORK /home/thesis/eugenio.ressa/Desktop/myHWModel/syn/src/FW_BW_PU.sv
analyze -f sverilog -lib WORK /home/thesis/eugenio.ressa/Desktop/myHWModel/syn/src/memory/SRAM.sv
analyze -f sverilog -lib WORK /home/thesis/eugenio.ressa/Desktop/myHWModel/syn/src/NN.sv
elaborate $designChecked -lib WORK
create_clock -name MY_CLK -period 0 clk
set_dont_touch_network MY_CLK
link
check_design > /home/thesis/eugenio.ressa/Desktop/myHWModel/syn/report/$designChecked/check_design.txt
compile 
report_clock > /home/thesis/eugenio.ressa/Desktop/myHWModel/syn/report/$designChecked/fp_clock.rpt
report_timing > /home/thesis/eugenio.ressa/Desktop/myHWModel/syn/report/$designChecked/fp_timing.rpt
report_power > /home/thesis/eugenio.ressa/Desktop/myHWModel/syn/report/$designChecked/fp_power.rpt
report_area > /home/thesis/eugenio.ressa/Desktop/myHWModel/syn/report/$designChecked/fp_area.rpt
report_resources > /home/thesis/eugenio.ressa/Desktop/myHWModel/syn/report/$designChecked/fp_resources.rpt
ungroup -all -flatten
change_names -hierarchy -rules verilog
#write_sdf /home/thesis/eugenio.ressa/Desktop/myHWModel/syn/report/$designChecked/netlist/$designChecked.sdf
#write -f verilog -hierarchy -output /home/thesis/eugenio.ressa/Desktop/myHWModel/syn/report/$designChecked/netlist/$designChecked.v
#write_sdc /home/thesis/eugenio.ressa/Desktop/myHWModel/syn/report/$designChecked/netlist/$designChecked.sdc
quit
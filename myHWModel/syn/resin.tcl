set power preserve rtl hier names true
analyze -f sverilog -lib WORK /home/thesis/eugenio.ressa/Desktop/myHWModel/syn/MAC/multiplier.sv
analyze -f sverilog -lib WORK /home/thesis/eugenio.ressa/Desktop/myHWModel/syn/MAC/MultiOpAdderDadda.sv
analyze -f sverilog -lib WORK /home/thesis/eugenio.ressa/Desktop/myHWModel/syn/MAC/MAC.sv
elaborate MAC -lib WORK
link
check_design
compile 
report_clock > /home/thesis/eugenio.ressa/Desktop/myHWModel/syn/fp_clock.rpt
report_timing > /home/thesis/eugenio.ressa/Desktop/myHWModel/syn/fp_timing.rpt
report_power > /home/thesis/eugenio.ressa/Desktop/myHWModel/syn/fp_power.rpt
report_area > /home/thesis/eugenio.ressa/Desktop/myHWModel/syn/fp_area.rpt
report_resources > /home/thesis/eugenio.ressa/Desktop/myHWModel/syn/fp_resources.rpt
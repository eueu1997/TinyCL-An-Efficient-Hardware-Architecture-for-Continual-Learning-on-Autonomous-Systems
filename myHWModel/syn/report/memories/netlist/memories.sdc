###################################################################

# Created by write_sdc on Tue Nov 21 05:48:09 2023

###################################################################
set sdc_version 2.1

set_units -time ns -resistance kOhm -capacitance pF -voltage V -current mA
create_clock [get_ports clk]  -name MY_CLK  -period 0  -waveform {0 0}

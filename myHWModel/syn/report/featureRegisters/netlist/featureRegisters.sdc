###################################################################

# Created by write_sdc on Wed Nov  1 18:20:41 2023

###################################################################
set sdc_version 2.1

set_units -time ns -resistance kOhm -capacitance pF -voltage V -current mA
create_clock [get_ports clk]  -name MY_CLK  -period 0  -waveform {0 0}
set_clock_uncertainty 0.07  [get_clocks MY_CLK]

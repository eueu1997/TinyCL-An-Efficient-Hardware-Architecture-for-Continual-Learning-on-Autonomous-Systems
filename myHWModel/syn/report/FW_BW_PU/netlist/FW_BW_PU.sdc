###################################################################

# Created by write_sdc on Sun Nov 12 10:44:24 2023

###################################################################
set sdc_version 2.1

create_clock [get_ports clk]  -name MY_CLK  -period 0  -waveform {0 0}

# featureInBWMngr: report del gestore feature DK

## Contenuto e utilizzo

[check_design.txt](check_design.txt), [fp_area.rpt](fp_area.rpt),
[fp_clock.rpt](fp_clock.rpt), [fp_power.rpt](fp_power.rpt),
[fp_resources.rpt](fp_resources.rpt), [fp_timing.rpt](fp_timing.rpt) e
[netlist](netlist/) descrivono una sintesi storica del gestore feature backward.
L'area riportata e' 864.360022 nelle unita' della libreria, non una misura nuova.
Leggere controllo design e vincoli prima di usare area/timing; procedura generale
nel [README report](../README.md).

## Possibili bug e limiti rilevati

Check design segnala collegamenti diretti input-output (LINT-29/LINT-31);
potenza segnala clock non definito (PWR-80). Una parte combinatoria puo' avere
collegamenti diretti legittimi: serve interpretazione, non classificazione
automatica come bug. La revisione e le condizioni del report non sono certificate.
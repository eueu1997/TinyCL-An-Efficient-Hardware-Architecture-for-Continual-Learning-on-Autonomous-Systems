# featureRegisters: report della finestra feature

## Contenuto e uso

Contiene check_design e i cinque report area/clock/power/resources/timing,
piu' [netlist](netlist/). Il design dichiarato e' `featureRegister`, singolare,
anche se la cartella e' plurale. [fp_area.rpt](fp_area.rpt) riporta 17607.240187
nelle unita' di libreria. Leggere i file con un editor e correlare con
[RTL FW](../../src/FW/); per riprodurre seguire [syn](../../README.md).

## Possibili bug e limiti rilevati

TIM-134 segnala rete ad alto fanout e ipotesi per i ritardi; PWR-80 indica assenza
di clock definito. Potenza e timing non sono una certificazione di frequenza del
sistema completo. Il report e' storico, non rigenerato durante l'analisi.
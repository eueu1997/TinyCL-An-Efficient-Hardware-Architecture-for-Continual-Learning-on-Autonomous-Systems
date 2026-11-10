# FW_BW_PU: report della PU unificata

## Contenuto e uso

Check_design e report area/clock/power/resources/timing, con
[netlist](netlist/), descrivono una precedente elaborazione della PU FW/DK/DX.
Leggere [fp_clock.rpt](fp_clock.rpt) e [check_design.txt](check_design.txt)
prima di qualsiasi misura: riportano dipendenze irrisolte.
La netlist Verilog e' molto grande ma la dimensione non indica validita'.

Per riprodurre partire dal [flusso syn](../../README.md) in una libreria pulita
e includere tutte le dipendenze del top prima di compilare/reportare.

## Possibili bug e limiti rilevati

UID-341 segnala un riferimento irrisolto; LBR-1 indica che
`gradientInRegisterBWDK` non e' trovato in WORK. L'elenco analyze corrente non
include quel file, pur essendo presente nell'albero. L'area riportata zero non
va interpretata come costo nullo della PU. Sono presenti anche PWR-80, warning
di fanout e molti lint. Risultati non validati con una nuova esecuzione.
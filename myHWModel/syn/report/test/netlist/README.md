# netlist: modulo test

## Contenuto e utilizzo

[test.v](test.v), [test.sdc](test.sdc) e [test.sdf](test.sdf) conservano
Verilog, vincoli e ritardi di una prova minima. Consultare con un editor o
con i tool di sintesi, confrontandoli con [test.sv](../../../src/test.sv).
Non sono netlist dell'intera rete NN o del MAC.

## Possibili bug e limiti rilevati

I [report](../README.md) indicano area zero, porte non collegate e limiti della
libreria gtech per la potenza. Non usarli come prova di implementazione fisica
del sistema; nessuna equivalenza o simulazione post-sintesi eseguita.
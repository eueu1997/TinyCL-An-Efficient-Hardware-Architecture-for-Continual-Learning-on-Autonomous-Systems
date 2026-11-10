# NN: report del top hardware

## Contenuto e uso

Sei file: check_design e report area, clock, potenza, risorse e timing.
Non c'e' una sottodirectory netlist nello snapshot.
[fp_area.rpt](fp_area.rpt) riporta 3830068.818321 nelle unita' della libreria,
ma occorre leggere gli errori degli altri report prima di interpretare il numero.
Il top di riferimento e' [syn/src/NN.sv](../../src/NN.sv).

Per rigenerare selezionare NN in un ambiente Design Compiler configurato e
risolvere interfacce/dipendenze, poi applicare clock e vincoli reali. Lo script
attuale seleziona invece FW_BW_PU e non esegue compile.

## Possibili bug e limiti rilevati

[fp_clock.rpt](fp_clock.rpt) segnala LINK-1 sulla porta `NewFeatureInChAddrFW`
di FW_BW_PU e altri problemi di linking; PWR-80 segnala assenza di clock definito.
Questo indica incompatibilita' nell'esecuzione archiviata, non un top certificato.
Area e potenza non sono stime affidabili del sistema senza risolvere tali limiti.
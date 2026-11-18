# src: copia RTL per sintesi

## Contenuto e uso

[NN.sv](NN.sv), [FW_BW_PU.sv](FW_BW_PU.sv) e [test.sv](test.sv) sono i moduli
di controllo/datapath e una prova locale. I blocchi sono in [FW](FW/), [BW](BW/),
[MAC](MAC/), [activation](activation/) e [memory](memory/).
Questo albero viene letto da [resin.tcl](../resin.tcl); non dal Tcl di simulazione.

Usare Design Compiler configurato secondo il [README syn](../README.md).
La SRAM qui non usa file di stimolo. Analizzare un solo albero per libreria e
scegliere esplicitamente il top; i moduli hanno nomi uguali alla copia simulata.
Confrontare le revisioni prima di trasferire risultati di area/timing al sistema.

## Possibili bug e limiti rilevati

Il confronto dei file rileva differenze in NN, PU, gestione FW/BW, MAC, adder e
SRAM. Non si tratta di un mirror automatico. `test.sv` non e' un testbench del
sistema completo. La presenza dei report non verifica questa revisione, e lo
script di sintesi attuale non esegue compile. Nessuna equivalenza formale eseguita.
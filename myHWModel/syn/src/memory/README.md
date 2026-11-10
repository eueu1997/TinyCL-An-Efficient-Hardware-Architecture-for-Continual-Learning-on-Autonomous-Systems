# memory: SRAM senza I/O su file

## Contenuto e utilizzo

[SRAM.sv](SRAM.sv) contiene un array di parole parametrico e accessi al fronte
negativo. A differenza della [copia simulata](../../../src/memory/README.md),
non ha MEMORY_TYPE ne' `$readmemh`/`$writememh`. E' l'implementazione analizzata
dal flusso di sintesi. PORT_WIDTH indica la larghezza della parola e
MEMORY_WIDHT il numero di parole; CHANNEL_IN/OUT restano parametri dichiarati.

Compilare tramite [resin.tcl](../../resin.tcl) e fornire inizializzazione/stimoli
nel testbench esterno. Un array comportamentale non equivale automaticamente
a una macro SRAM della tecnologia: verificare il mapping e i report risorse.

## Possibili bug e limiti rilevati

L'ingresso rst non e' usato; contenuto e uscita non sono inizializzati da reset.
La semantica di simulazione non replica il caricamento file della versione src.
Con lettura e scrittura simultanee lo stato precedente viene letto. Nessuna
verifica di inferenza RAM o equivalenza post-sintesi eseguita qui.
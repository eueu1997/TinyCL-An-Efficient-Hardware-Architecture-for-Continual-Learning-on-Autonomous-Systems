# activation: copia per sintesi

Contiene [activation.sv](activation.sv), ReLU combinatoria parametrizzata per
larghezza e regola, con pass-through per le altre stringhe. Il sorgente coincide
con la [versione simulata](../../../src/activation/README.md) al confronto degli
hash. Viene analizzato da [resin.tcl](../../resin.tcl) prima della PU.

## Utilizzo

Istanziare con parole fixed-point in complemento a due e NBITS coerente con
il datapath. Non richiede vettori o clock propri; la verifica e' a carico del
testbench chiamante. L'output non include una derivata per il backward.

## Possibili bug e limiti rilevati

La costante zero e' 32 bit anche se NBITS e' parametrico. Regole sconosciute non
generano errori ma bypassano l'attivazione. Nessuna nuova sintesi o verifica
temporale e' stata eseguita; identita' del file non prova equivalenza dell'intero top.
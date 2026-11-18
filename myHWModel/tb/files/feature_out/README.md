# feature_out: feature map hardware

Otto file `0.txt` fino a `7.txt` conservano dump delle memorie FEATURE, uno per
canale. Sono il punto di confronto del forward hardware con la convoluzione
software, non immagini PNG e non dataset ImageFolder.

## Utilizzo

Leggere con un parser compatibile con `$writememh`, separando eventuali header
e parole concatenate. Interpretare scala e ordine secondo il
[README vettori](../README.md). Il produttore e' la
[SRAM](../../../src/memory/SRAM.sv); il consumatore di confronto e'
[convEvaluetor.py](../../convEvaluetor.py). Conservare dati e revisione del run.

## Possibili bug e limiti rilevati

La memoria FEATURE non viene inizializzata da reset ma scaricata: puo' contenere
X per posizioni non scritte. Il parser sostituisce X con zero e puo' nascondere
un calcolo incompleto. Risultati archiviati non rigenerati o certificati.
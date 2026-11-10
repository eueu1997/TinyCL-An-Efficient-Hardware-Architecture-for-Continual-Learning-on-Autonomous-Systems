# gdumbs: ingressi della memoria immagini

Contiene nove file: `0.txt`, `1.txt`, `2.txt`, le tre copie `_float.txt` e i
diagnostici `02`, `12`, `22`. I tre indici corrispondono ai canali di input RGB;
il top li adatta al datapath a otto canali. Non e' un archivio di modelli GDumb.

## Utilizzo

La SRAM di tipo GDUMB legge i `.txt` numerati. Il generatore
[convEvaluetor.py](../../convEvaluetor.py) scrive parole impacchettate per porta,
con conversione fixed-point a 16 bit e scala 4096; i float aiutano il confronto.
Seguire [formato e flusso](../README.md) e preservare ordine dei pixel/lane.

## Possibili bug e limiti rilevati

Gli output diagnostici senza estensione non sono automaticamente input SRAM.
Wraparound della conversione e scala del MAC possono produrre differenze
numeriche. File non verificati con un nuovo run; evitare di mescolare generazioni.
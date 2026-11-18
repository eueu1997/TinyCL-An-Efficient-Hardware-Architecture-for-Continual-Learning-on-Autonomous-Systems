# src: package del mini-progetto MNIST

## Contenuto e ruolo

[__init__.py](__init__.py) rende riconoscibile il package; [feed_forward](feed_forward/)
contiene il motore sequenziale, i layer e le varianti custom.
[__pycache__](__pycache__/) contiene bytecode di precedenti interpreti.
Qui non esiste un secondo entrypoint o un loader dei dataset.

## Utilizzo

Eseguire [main.py](../main.py) da `myModelTestWorking`, affinche' gli import
`src.feed_forward...` risolvano questa directory. Per esperimenti isolati
importare i layer, senza importare il main che legge immediatamente i CSV e
avvia training. Requisiti e preparazione dati nel [README superiore](../README.md).

## Possibili bug e limiti rilevati

Il nome generico `src` puo' entrare in conflitto con altri package nel percorso
Python. Le cache 3.10/3.11 non certificano la compatibilita' delle dipendenze
storiche. I problemi numerici appartengono ai moduli figli, non al marcatore
di package; nessun test di installazione e' incluso qui.
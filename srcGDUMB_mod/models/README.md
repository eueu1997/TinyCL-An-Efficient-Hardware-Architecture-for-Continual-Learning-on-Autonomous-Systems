# models: modelli PyTorch della variante a memoria dinamica

## Contenuto e scopo

[layers.py](layers.py) contiene ConvBlock/FCBlock e blocchi iniziale/finale;
[mnist](mnist/), [cifar](cifar/) e [imagenet](imagenet/) le reti per risoluzione.
[__init__.py](__init__.py) rende importabile il pacchetto; [__pycache__](__pycache__/)
e' bytecode generato. I sorgenti omologhi confrontati sono identici alla base:
la modifica della strategia di memoria e' nel loader e nel main, non qui.

## Utilizzo

Avviare il [trainer locale](../README.md) dalla sua directory. `opt` deve includere
parametri della rete e statistiche aggiunte dal loader. Per contratti NCHW,
normalizzazione e costruzione dei blocchi vedere la
[descrizione condivisa](../../srcGDUMB/models/README.md).
Non importare questa copia insieme a un'altra `models` nello stesso processo.

## Possibili bug e limiti rilevati

Restano il confronto stringa per identita' in `layers.py`, le combinazioni
modello/dataset non validate e le opzioni pooling non compatibili con NIN della
base. Le reti identiche non rendono equivalenti le metriche: l'updater locale
introduce rischi di rimappatura delle etichette e aggiornamento delle statistiche
BN documentati nel README del trainer. Verifica statica, non training eseguito.
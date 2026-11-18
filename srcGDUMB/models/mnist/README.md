# mnist: MLP e Network in Network

## Contenuto

[mlp.py](mlp.py) costruisce `784 -> width -> width -> num_classes`, con blocchi FC
condivisi, flatten dell'input e `dim_out` per sostituire il classificatore.
[nin.py](nin.py) contiene convoluzioni 5x5/1x1, pooling e media adattiva finale.
[__init__.py](__init__.py) esporta `MLP` e `NIN`; [mlp.txt](mlp.txt) e' una
rappresentazione testuale di una rete, non pesi caricabili.
[__pycache__](__pycache__/) non e' necessario all'esecuzione.

## Come usarla

Dal trainer, selezionare `--dataset MNIST --model MLP --width 400` oppure
`--model NIN`, aggiungendo i parametri obbligatori descritti nel
[README principale](../../README.md). Input atteso N x 1 x 28 x 28, output N x C.
Per MLP la larghezza deve essere positiva; il valore predefinito della CLI e' 0.
I parametri si addestrano nel main PyTorch, non eseguendo questi file direttamente.

## Possibili bug e limiti rilevati

NIN non espone l'interfaccia `final`/`dim_out` usata dal ramo di pretraining per
sostituire il classificatore: quel ramo non e' generico per tutti i modelli.
Con BN attiva, un ultimo batch di un solo esempio puo' essere incompatibile con
BatchNorm1d del MLP. Restano i rischi dei [blocchi comuni](../README.md).
Nessuna accuracy e' garantita dal dump testuale.
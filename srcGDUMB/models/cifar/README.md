# cifar: reti per immagini piccole

## Contenuto e architetture

[resnet.py](resnet.py) implementa blocchi residuali basic/bottleneck, proiezioni
di shortcut e average pooling adattivo. Supporta profondita' CIFAR
20/32/44/56/110/1202, 164/1001 e famiglie 18/34/50/101/152 con quattro gruppi.
Lo stem resta 3x3 a stride 1. [densenet.py](densenet.py) concatena feature di
DenseLayer con transition e compressione; `width` indica il growth rate.
[nin.py](nin.py) contiene una Network in Network. [__init__.py](__init__.py)
esporta le tre classi. [ResNet.txt](ResNet.txt) e' un dump dell'architettura;
[__pycache__](__pycache__/) contiene bytecode.

## Utilizzo e contratti

Usare il [trainer](../../README.md), per esempio selezionando CIFAR100, ResNet,
depth 32, oppure DenseNet, depth 100, width 12. Il loader definisce canali e classi.
Input NCHW: 3x32x32 per CIFAR/SVHN, 3x64x64 per TinyImagenet. Le reti restituiscono
un vettore di score per classe; la loss e l'ottimizzatore sono esterni.
Depth e width non sono intercambiabili fra ResNet e DenseNet. Non lanciare
questi file come programmi indipendenti e non trattare il dump come checkpoint.

## Possibili bug e limiti rilevati

- NIN legge `opt.hidden_size`, che non e' definito nel parser ne' dal loader:
  la costruzione tramite la CLI attuale puo' fallire con `AttributeError`.
- ResNet inizializza i parametri BN senza controllare se `affine=False`:
  il flag CLI `--affine_bn`, che disabilita affine, puo' lasciare pesi/bias `None`.
- Il pooling finale DenseNet usa una dimensione fissa e presuppone le risoluzioni
  previste; input arbitrari richiedono un controllo delle forme.
- Valgono i limiti delle opzioni di attivazione/pooling dei
  [blocchi comuni](../README.md). Non sono stati eseguiti test numerici delle reti.
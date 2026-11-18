# cifar: reti PyTorch ereditate

## Contenuto e uso

[resnet.py](resnet.py), [densenet.py](densenet.py), [nin.py](nin.py),
[__init__.py](__init__.py), [ResNet.txt](ResNet.txt) e [__pycache__](__pycache__/)
replicano reti, export, dump architetturale e cache della
[base](../../../srcGDUMB/models/cifar/README.md). I layer ricevono NCHW e producono
score per classe; ResNet32 e DenseNet-100/12 sono configurazioni degli script.

Per training PyTorch usare il [trainer base](../../../srcGDUMB/README.md).
Il main di questa copia resta specializzato su MNIST NumPy: il fatto che il
parser accetti CIFAR non rende compatibile il MLP custom con input RGB.

## Possibili bug e limiti rilevati

NIN legge `hidden_size` non fornito dal parser; ResNet con affine BN disabilitato
puo' inizializzare parametri nulli; DenseNet presuppone risoluzioni specifiche.
Non sono stati verificati training o checkpoint di queste reti in questa variante.
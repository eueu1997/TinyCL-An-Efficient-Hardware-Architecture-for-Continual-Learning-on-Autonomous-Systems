# imagenet: sorgenti PyTorch non integrati nel ramo NumPy

## Contenuto e uso

[__init__.py](__init__.py) esporta ResNet da
[resnet_cifar.py](resnet_cifar.py) e DenseNet da [densenet.py](densenet.py).
[resnet_image.py](resnet_image.py) e' alternativo; [var_cifar](var_cifar) e
[var_image](var_image) sono dump testuali; [__pycache__](__pycache__/) e' cache.
Per dettagli architetturali vedere la [base](../../../srcGDUMB/models/imagenet/README.md),
con cui i sorgenti confrontati coincidono.

Importabili con PyTorch e opzioni complete dalla directory del trainer. Il ramo
NumPy del [main locale](../../main.py) non supporta input ImageNet: usare il
[trainer base](../../../srcGDUMB/README.md) per preparare un esperimento 224x224,
dopo averne letto i limiti. I dump non contengono pesi addestrati.

## Possibili bug e limiti rilevati

Nome del modello e import effettivo possono essere confusi: la ResNet attiva ha
stem CIFAR. La factory alternativa e il pooling DenseNet hanno i limiti descritti
nella base. La presenza dei file non prova che ImageNet sia stato eseguito nel
percorso NumPy; nessuna validazione GPU e' stata svolta.
# cifar: ResNet, DenseNet e NIN locali

## Contenuto e uso

[resnet.py](resnet.py), [densenet.py](densenet.py) e [nin.py](nin.py) sono esportati
da [__init__.py](__init__.py). La cache e' in [__pycache__](__pycache__/).
I sorgenti sono uguali a quelli della [base](../../../srcGDUMB/models/cifar/README.md);
qui manca il dump testuale ResNet presente nell'altra copia.

Avviare il [trainer locale](../../README.md) con CIFAR100, ResNet e depth 32 oppure
DenseNet, depth 100 e width 12. I layer ricevono tensor NCHW e restituiscono score
N x C; `width` e' il growth rate in DenseNet. Il main gestisce loss e ottimizzatore,
mentre l'updater sceglie la memoria. TinyImagenet e' previsto dalle reti ma non
dal costruttore generico usato nell'updater.

## Possibili bug e limiti rilevati

NIN richiede `opt.hidden_size` assente nella CLI. ResNet inizializza pesi BN
anche quando affine e' disabilitato. Pooling DenseNet e opzioni comuni conservano
i limiti della base. Compatibilita' del layer e supporto del trainer per un
dataset sono due verifiche distinte; qui non sono state eseguite campagne GPU.
# imagenet: reti della variante modificata

## Contenuto e uso

[resnet_cifar.py](resnet_cifar.py) e' la ResNet esportata da
[__init__.py](__init__.py); [resnet_image.py](resnet_image.py) e' l'alternativa non
selezionata. [densenet.py](densenet.py) contiene DenseNet;
[var_cifar](var_cifar) e [var_image](var_image) sono dump testuali;
[__pycache__](__pycache__/) contiene prodotti Python storici.

Il codice coincide con la [base](../../../srcGDUMB/models/imagenet/README.md).
Si usa tramite import con opzioni complete o attraverso il
[main locale](../../main.py) quando il loader dichiara input 224. Tuttavia
`TrainLoaderUpdater` non supporta correttamente ImageFolder: non considerare
`--dataset ImageNet` un percorso operativo validato in questa variante.

## Possibili bug e limiti rilevati

L'import attivo usa lo stem CIFAR, non quello del file alternativo; il nome
ResNet18 da solo non identifica l'architettura. Restano pooling DenseNet fisso,
assert con profondita' stringa nella factory alternativa e problemi di resize
del loader. Consultare anche i blocchi e il trainer prima di eseguire esperimenti.
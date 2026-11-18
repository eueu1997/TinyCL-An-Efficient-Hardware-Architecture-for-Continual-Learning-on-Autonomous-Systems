# imagenet: implementazioni alternative per immagini grandi

## Contenuto

[__init__.py](__init__.py) esporta `ResNet` da
[resnet_cifar.py](resnet_cifar.py), non da [resnet_image.py](resnet_image.py).
La prima ha stem 3x3 a stride 1; la seconda definisce `ResNetBase`, uno stem
con max pooling e una factory per varie profondita'. [densenet.py](densenet.py)
fornisce l'altra famiglia esportata. [var_cifar](var_cifar) e
[var_image](var_image) sono descrizioni testuali di strutture, non modelli
serializzati. [__pycache__](__pycache__/) contiene anche bytecode di nomi storici.

## Utilizzo

Il [main](../../main.py) sceglie questo pacchetto quando `inp_size == 224`.
Selezionare `--dataset ImageNet100` oppure `ImageNet`, `--model ResNet --depth 18`
e i parametri obbligatori del [trainer](../../README.md). Preparare ImageFolder
con split `train` e `test`. Input N x 3 x H x W; il loader dovrebbe produrre
batch di dimensione uniforme. La scelta tra le due ResNet non e' un parametro
CLI: dipende dall'import. Annotare questa scelta in ogni confronto sperimentale.

## Possibili bug e limiti rilevati

Non chiamare la rete attiva "ResNet ImageNet standard" senza controllarne lo
stem. Il file alternativo include nomi ResNext/WideResNet non selezionabili nel
parser attuale e un assert finale che confronta la profondita' con stringhe.
DenseNet mantiene ipotesi di pooling a dimensione fissa. Il training con resize
a lato singolo puo' produrre forme diverse fra immagini (problema del loader,
descritto nel README del trainer). Pesi e prestazioni non sono verificati qui.
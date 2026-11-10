# data: dataset locali del trainer

## Contenuto e scopo

Lo snapshot contiene [MNIST](MNIST/) con file IDX compressi e decompressi.
Non contiene qui CIFAR, SVHN o ImageNet; la copia CIFAR10 del simulatore e' in
[myCNNSimulator/data](../myCNNSimulator/data/). I dati non sono sorgenti Python.

## Utilizzo

Passare questa directory come `--data_dir` al [trainer](../srcGDUMB/README.md).
Torchvision puo' scaricare MNIST/CIFAR/SVHN quando richiesto. Per ImageFolder
preparare `<dataset>/train/<classe>/...` e `<dataset>/test/<classe>/...` con stessi
nomi classe nei due split. ImageNet non viene scaricato automaticamente e richiede
accesso legittimo ai dati. Il mini-progetto MNIST CSV usa invece un formato diverso.

## Possibili bug e limiti rilevati

I default del parser puntano ad altri computer: senza percorso esplicito questi
dati potrebbero non essere usati. Non creare README dentro future directory
ImageFolder come se fossero classi; il loader considera le sottodirectory.
Integrita'/checksum dei dataset non verificati, nessun download effettuato.
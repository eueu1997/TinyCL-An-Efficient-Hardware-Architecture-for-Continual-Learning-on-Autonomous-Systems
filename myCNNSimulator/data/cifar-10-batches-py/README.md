# cifar-10-batches-py: batch CIFAR10

## Contenuto e formato

Cinque file `data_batch_1` fino a `data_batch_5`, `test_batch`, `batches.meta` e
[readme.html](readme.html) del dataset. Il formato ufficiale serializza dizionari
Python con pixel RGB 32x32, etichette e metadati; i batch standard contengono
10000 immagini ciascuno. Il meta associa indici ai dieci nomi classe.

## Utilizzo

Da `myCNNSimulator`, usare `torchvision.datasets.CIFAR10(root="./data",
train=True, download=False)`; per test `train=False`. Il loader converte il
layout dei byte e applica le trasformazioni scelte. Leggere il documento HTML
per informazioni originarie sul dataset. Non passare questa directory come
ImageFolder: i file non sono immagini individuali organizzate per classe.

## Possibili bug e limiti rilevati

I file non vanno eseguiti o aperti come testo. Non caricare pickle di provenienza
non attendibile. Non sono stati verificati checksum, conteggi effettivi o
corrispondenza delle etichette nel payload locale.
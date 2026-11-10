# MNIST: cache torchvision

## Contenuto

[raw](raw/) contiene immagini ed etichette IDX dei due split, sia `.gz` sia
decompressi. Le immagini MNIST sono 28x28 a un canale, le etichette identificano
dieci cifre. Non ci sono CSV o pesi di un classificatore in questa directory.

## Utilizzo

Usare `torchvision.datasets.MNIST(root="data", train=True, download=False)` da
MSThesis; `root` e' il genitore di MNIST, non `MNIST/raw`. Il test usa `train=False`.
Nel trainer passare `--data_dir ../data` dalla sua directory. Torchvision gestisce
lettura del formato e trasformazioni; non aprire IDX come file di testo.

## Possibili bug e limiti rilevati

La presenza dei nomi attesi non certifica checksum o completezza dei payload.
Il progetto `myModelTestWorking` richiede CSV e non legge direttamente questi
file. Non rinominare gli split per adattarli a un altro loader; usare una
conversione esplicita e mantenere separati training e test.
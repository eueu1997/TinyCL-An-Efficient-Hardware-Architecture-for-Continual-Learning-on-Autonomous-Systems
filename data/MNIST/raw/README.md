# raw: file IDX MNIST

## Contenuto e formato

Otto file dati: immagini `train-images-idx3-ubyte` e `t10k-images-idx3-ubyte`,
etichette `train-labels-idx1-ubyte` e `t10k-labels-idx1-ubyte`, con una copia gzip
per ciascuno. IDX conserva un'intestazione binaria con tipo/dimensioni, seguita
da byte; non e' una matrice CSV. Il formato standard ha 60000 esempi di training
e 10000 di test; questi conteggi non sono stati ricontrollati sul payload locale.

## Utilizzo

Caricare tramite torchvision come descritto nel [README MNIST](../README.md).
Le copie compresse servono al download/estrazione, quelle senza `.gz` alla cache
leggibile dal dataset. Conservare la coppia immagini-label dello stesso split.
Per validare l'integrita' usare i checksum del distributore, non il nome del file.

## Possibili bug e limiti rilevati

Nessun codice eseguibile; le estensioni apparentemente mancanti non indicano
file danneggiati. Non deserializzare con pickle e non interpretare i byte come
testo. Non e' stata verificata l'identita' tra copie compresse e decompresse.
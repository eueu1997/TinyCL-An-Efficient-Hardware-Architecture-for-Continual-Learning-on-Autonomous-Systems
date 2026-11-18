# ImageNet: confronto delle curve archiviate

## Contenuto e uso

Sei PNG confrontano etichette di esperimenti ResNet/ImageNet: input dichiarato
32 o 224, 128 o 256 passaggi, varianti augmented/no_augmentation e memorie
denominate 10000, 10000C(130000) o 770C. Aprire i file come immagini e cercare la
configurazione nei corrispondenti [log ImageNet](../../logs/), non dedurla dal
solo nome. La directory non contiene modelli, dataset o script per i grafici.

Per riprodurre servono dataset, revisione del loader, import effettivo della
ResNet e percorso di salvataggio del [trainer](../../srcGDUMB/README.md).
Le dimensioni e trasformazioni sono state oggetto di modifiche nel sorgente,
quindi la CLI non descrive necessariamente tutto il preprocessing storico.

## Possibili bug e limiti rilevati

La dicitura no_augmentation non implica CutMix disattivato: nei log associati
compare ancora `regularization='cutmix'`. Le etichette di memoria non sono
sempre uguali a memory_size. Non assumere confrontabilita' di tutte le curve o
la stessa architettura solo perche' compare ResNet18. Dati non rigenerati.
# data: cache CIFAR10 del simulatore

## Contenuto e utilizzo

[cifar-10-batches-py](cifar-10-batches-py/) contiene il dataset nel formato Python
ufficiale. [myCNN.py](../myCNN.py) usa `root='./data'`: avviarlo dalla directory
`myCNNSimulator` per riutilizzare questa cache. Il loader normalizza i tensor RGB
con media e deviazione 0.5. Non contiene checkpoint o risultati di training.

La versione Keras usa il proprio `datasets.cifar10.load_data()` e puo' mantenere
una cache diversa. Non duplicare o spostare i dati soltanto per uniformare i nomi.
Per un controllo manuale usare il loader torchvision con download disabilitato.

## Possibili bug e limiti rilevati

Il percorso dipende dalla directory corrente: un avvio dalla radice usa un'altra
cartella data. Integrita' dei payload non verificata e nessun download eseguito.
Usare soltanto archivi attendibili, poiche' il formato Python comporta
deserializzazione; leggere i dettagli nella sottodirectory.
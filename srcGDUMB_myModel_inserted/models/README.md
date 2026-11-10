# models: reti PyTorch conservate nel prototipo NumPy

## Contenuto e ruolo

[layers.py](layers.py) costruisce blocchi PyTorch configurabili;
[mnist](mnist/), [cifar](cifar/) e [imagenet](imagenet/) sono le famiglie esportate.
[__init__.py](__init__.py) e [__pycache__](__pycache__/) sono rispettivamente il
marcatore del pacchetto e la cache. I sorgenti omologhi coincidono con la
[base](../../srcGDUMB/models/README.md), verificata tramite hash.

## Utilizzo

Il [main locale](../main.py) costruisce ancora una rete da questo pacchetto e un
ottimizzatore PyTorch, ma il ramo attivo allena i layer NumPy separati. Cambiare
`--model` non trasforma il MLP NumPy in ResNet. Per usare davvero queste reti
con autograd consultare il [trainer base](../../srcGDUMB/README.md).
Gli import assoluti richiedono la directory del trainer nel percorso Python.

## Possibili bug e limiti rilevati

I difetti dei blocchi comuni restano: identita' stringa per l'attivazione,
combinazioni CLI non validate e opzioni pooling incoerenti. Il rischio principale
qui e' interpretare i checkpoint o le opzioni di questa rete come pesi e
configurazione della rete NumPy: sono oggetti distinti. Analisi statica.
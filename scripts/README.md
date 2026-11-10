# scripts: campagne sperimentali GDumb

## Scopo e contenuto

Questa directory contiene sequenze Bash di invocazioni del trainer Python. Non
contiene un trainer autonomo: ogni riga esegue `python main.py` nella directory
corrente. Le sigle B1/B2/B3 e le altre formulazioni sono le etichette dei protocolli
richiamati nei commenti originali, non opzioni selezionabili nel parser.

| File | Campagna codificata |
| --- | --- |
| [replicate.sh](replicate.sh) | MNIST con MLP; SVHN e CIFAR10 con ResNet18; CIFAR100 con ResNet32; TinyImagenet con DenseNet-100, crescita 12. Memorie ed epoche cambiano tra le righe. |
| [replicate_supp.sh](replicate_supp.sh) | Esperimenti supplementari con NIN e DenseNet, soprattutto 512 passaggi; confronto con e senza CutMix. |
| [cifar100_formB2.sh](cifar100_formB2.sh) | 19 esecuzioni CIFAR100, da 1 a 19 task di 5 classi, memoria 2000, ResNet32, 256 passaggi. |
| [cifar100_formB3.sh](cifar100_formB3.sh) | 50 esecuzioni con 50 classi di pretraining, da 51 a 100 task di una classe, memoria da 1020 a 2000; pretraining 256 passaggi, training 32. |
| [imagenet100_formB3.sh](imagenet100_formB3.sh) | Analoga campagna su ImageNet100 e ResNet18, pretraining 128 passaggi, training 16. |

## Prerequisiti e utilizzo

Servono Bash (su Windows, per esempio WSL), Python e le dipendenze del trainer
scelto. Consultare [opts.py](../srcGDUMB/opts.py) per gli argomenti effettivi.
Le copie modificate del trainer non sono necessariamente equivalenti alla base.
Il trainer base richiede CUDA nel percorso di training attuale. ImageNet e
TinyImagenet richiedono dati predisposti dall'utente; non sono inclusi qui.

Prima di eseguire una campagna:

1. Configurare i percorsi dati e log nel trainer oppure aggiungere `--data_dir`
   e `--log_dir` a ciascuna invocazione dello script. Gli script non inoltrano
   automaticamente opzioni aggiuntive passate dopo il seed.
2. Controllare i percorsi dei grafici e le anomalie indicate nel README del
   trainer. Una campagna non e' un test rapido: puo' richiedere molte ore/GPU.
3. Eseguire dalla directory del trainer, non da questa cartella:

```bash
cd srcGDUMB
bash ../scripts/replicate.sh 0
```

Questo esempio parte dalla radice di MSThesis e avvia l'intera sequenza. Per un
solo esperimento, scegliere una singola riga e impostare esplicitamente i percorsi.
Per il B2, che non contiene `SEED=$1`, usare invece:

```bash
SEED=0 bash ../scripts/cifar100_formB2.sh
```

Per B3 il seed e' fissato a zero nelle righe. I commenti chiedono di impostare
manualmente l'ordine delle classi secondo il protocollo: lo script da solo non
garantisce tale riproduzione.

## Input e risultati

Gli input sono dataset, configurazione del trainer e seed. Ogni riga imposta un
`--exp_name`; i log vengono scritti sotto `--log_dir/<exp_name>/`. Il pretraining
usa anche `--old_exp_name` per identificare il checkpoint condiviso. Verificare
nel trainer il comportamento di riuso dei pesi prima di confrontare le campagne.
Conservare comando completo, revisione del codice, versioni delle librerie e
ordine delle classi: il nome della cartella non basta a ricostruire un risultato.

## Possibili bug e limiti rilevati

- **Seed B2 mancante:** [cifar100_formB2.sh](cifar100_formB2.sh#L2) usa `$SEED`
  senza inizializzarlo. Senza la variabile d'ambiente, `--seed` resta privo di
  valore e il parser rifiuta il comando. Anche i due script di replica richiedono
  effettivamente il primo argomento, senza un valore predefinito.
- **Dipendenza dalla directory corrente:** l'esecuzione dalla radice o da
  `scripts` non trova il `main.py` previsto. Nessuno script effettua un `cd`.
- **Assenza di arresto controllato:** non e' impostato `set -e` e non si controlla
  l'exit status di Python; dopo un fallimento si possono avviare altre esecuzioni.
- **Configurazione non portabile:** le righe non specificano directory dati/log
  e quindi ereditano i percorsi Linux assoluti del parser.
- **Nomi non sempre fedeli ai parametri:** nel B2 compare `M20` ma la memoria
  totale e' 2000; nella prima riga TinyImagenet di replica il seed e' sempre 1,
  indipendentemente da quello richiesto. Sono rischi di interpretazione dei
  risultati, non prove che le metriche storiche siano errate.

Analisi statica delle cinque sequenze e confronto con il parser; le campagne
complete non sono state eseguite durante la documentazione.
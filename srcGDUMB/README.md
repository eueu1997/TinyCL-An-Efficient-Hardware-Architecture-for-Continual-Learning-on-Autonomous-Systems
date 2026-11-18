# srcGDUMB: trainer PyTorch di riferimento

## Scopo e organizzazione

Implementazione sperimentale di GDumb: seleziona una memoria bilanciata di esempi
e addestra una rete su quella memoria. In questa versione il flusso principale
costruisce una sola memoria per tutte le classi richieste: **non** esegue un ciclo
di arrivo dei task con riaddestramento da zero dopo ciascuno di essi. Il numero di
task determina classi selezionate e maschera per la metrica task-incremental.

| File/directory | Responsabilita' |
| --- | --- |
| [main.py](main.py) | Parsing, seed, costruzione rete, pretraining opzionale, SGD, valutazione, grafico accuracy. |
| [opts.py](opts.py) | Unica interfaccia CLI; valori predefiniti e scelte accettate. |
| [dataloader.py](dataloader.py) | Dataset torchvision/ImageFolder, trasformazioni, rimappatura etichette, memoria e sampler. |
| [utils.py](utils.py) | Logger, medie pesate, metriche, CutMix, checkpoint di pretraining. |
| [models](models/) | Blocchi comuni e famiglie MNIST, CIFAR/TinyImagenet e ImageNet. |
| [experiments.sh](experiments.sh) | Comandi sperimentali storici: leggere le righe attive prima dell'esecuzione. |
| [data_collector.py](data_collector.py) | Estrazione testuale di risultati da log CIFAR in percorsi assoluti. |
| [ImageNet_resize](ImageNet_resize) | Script Python, senza estensione, per ridimensionare immagini ImageNet. |
| [clean.sh](clean.sh) | Eliminazione ricorsiva delle cache Python dalla directory di esecuzione. |
| [dbg](dbg/) | Configurazione di debug locale; nessun test automatico. |
| [__pycache__](__pycache__/) | Bytecode storico, non necessario per installare o eseguire il sorgente. |

## Flusso dei dati e apprendimento

`VisionDataset` aggiunge alle opzioni dimensione input, canali e numero totale di
classi. Raggruppa gli indici per etichetta e seleziona fino a
`memory_size // (num_tasks * num_classes_per_task)` esempi per classe. Gli eventuali
slot residui non vengono distribuiti. La scelta prende i primi indici del gruppo
ottenuto da `argsort`, non un reservoir online. `ReorderTargets` produce etichette
consecutive da zero. CIFAR100 e ImageNet100 usano l'ordine fisso nel main; negli
altri casi vengono rimescolate le classi del prefisso selezionato.

MNIST usa immagini 28x28 a un canale; SVHN/CIFAR 32x32; TinyImagenet 64x64;
ImageNet/ImageNet100 dichiarano 224. Si applicano conversione tensor e
normalizzazione specifica; il training aggiunge crop/flip secondo il dataset.
Per ImageNet il resize con un intero preserva il rapporto d'aspetto: non garantisce
da solo batch di immagini con uguale altezza e larghezza.

La rete viene convertita in FP16 e trasferita su CUDA. Il ciclo usa cross-entropy,
SGD con momentum 0.9, weight decay, clipping dei gradienti e
`CosineAnnealingWarmRestarts`, dopo due epoche di avvio del learning rate.
La variabile sorgente `single_lr` permette un'alternativa fissa, non esposta in CLI.
CutMix e' opzionale. A ogni epoca si valuta l'intero test set delle classi scelte.

`Acc` e `Current accuracy` sono frazioni nell'intervallo 0..1, non percentuali.
`Task Acc` limita la predizione alle classi del task vero tramite una maschera.
Il riepilogo riporta la migliore accuracy sul test lungo le epoche, non
necessariamente quella dell'ultima epoca. Non e' una validazione indipendente.

## Installazione e avvio

Non esiste un ambiente bloccato per questo trainer. Servono Python, NumPy,
PyTorch/torchvision compatibili e Matplotlib; per CUDA scegliere la build di
PyTorch adatta al sistema. La compatibilita' con le release attuali non e'
certificata: vedere in fondo il problema `np.int` prima di abilitare CutMix.

Da PowerShell, nella radice di MSThesis e in un ambiente Python gia' configurato:

```powershell
New-Item -ItemType Directory -Force logs | Out-Null
cd srcGDUMB
python main.py --help
python main.py --dataset MNIST --num_classes_per_task 2 --num_tasks 5 --memory_size 500 --num_passes 2 --model MLP --width 400 --regularization none --workers 0 --exp_name mnist_documentazione --data_dir ../data --log_dir ../logs/
```

Il secondo comando e' un esempio minimo di training, **non un'esecuzione
garantita senza adattamenti**: richiede CUDA e il percorso assoluto del grafico
in `experiment` deve essere sostituito/configurato prima del lancio. Usare un
nome esperimento nuovo per non sovrascrivere i log. `--workers 0` semplifica la
diagnosi su Windows. Anche `--help` importa le dipendenze del main.

Dataset scaricabili dal loader: MNIST, CIFAR10, CIFAR100 e SVHN. Per gli altri,
preparare `<data_dir>/<dataset>/train/<classe>/immagini` e la stessa struttura
sotto `test`, con identica corrispondenza delle classi. La CLI accetta esattamente
`TinyImagenet`, `ImageNet100`, `ImageNet`; non tutte le voci presenti nella tabella
interna delle statistiche sono esposte dal parser.

Opzioni principali:

| Opzione | Significato/default |
| --- | --- |
| `--dataset`, `--num_tasks`, `--num_classes_per_task` | Obbligatorie; il prodotto dei task non deve superare le classi del dataset. |
| `--memory_size`, `--num_passes` | Obbligatorie; esempi complessivi e passaggi sulla memoria. |
| `--model`, `--depth`, `--width` | MLP di default; i moduli effettivamente disponibili dipendono dalla famiglia del dataset. Impostare una larghezza positiva per MLP. |
| `--batch_size`, `--workers` | 16 e 2. |
| `--maxlr`, `--minlr`, `--weight_decay`, `--clip` | 0.05, 0.0005, 1e-6, 10. |
| `--regularization`, `--cutmix_alpha`, `--cutmix_prob` | `none`, 1.0, 0.5. |
| `--num_pretrain_classes`, `--num_pretrain_passes`, `--old_exp_name` | Attivano pretraining e identificano il checkpoint da salvare/caricare. |
| `--bn`, `--affine_bn` | Flag con `store_false`: specificarli **disabilita** rispettivamente BN e affine. |
| `--preact`, `--activetype`, `--normtype` | Ordinamento e tipo dei blocchi. Verificare compatibilita' della rete selezionata. |

## Risultati e strumenti accessori

Il logger crea `<log_dir>/<exp_name>/checkpoint.log` in modalita' sovrascrittura.
La directory superiore dei log deve esistere. I checkpoint contengono `opt` e
`state_dict` e riguardano il solo pretraining; non esiste salvataggio automatico
del miglior modello continual-learning o ripresa dello stato SGD/scheduler.
Il grafico accuracy viene scritto in un percorso Linux codificato nel main.
Usare [scripts](../scripts/README.md) per capire i wrapper delle campagne.

Gli strumenti accessori non sono CLI generiche: prima di avviare
`python data_collector.py` o `python ImageNet_resize`, leggere e adattare percorsi
e criteri di estrazione. Il resize non prepara automaticamente tutto il dataset.
Non eseguire `clean.sh` dalla radice di un albero che non si vuole ripulire.

## Possibili bug e limiti rilevati

- **CutMix su NumPy moderno:** [utils.py](utils.py) usa `np.int` in `rand_bbox`.
  L'alias e' rimosso da NumPy 1.24; il ramo puo' terminare con `AttributeError`.
- **Percorso pretraining:** `save_model`, `load_model` e il controllo nel main
  concatenano `log_dir + old_exp_name` senza separatore. Passare un `log_dir`
  terminante in `/` aggira questo problema; altrimenti il file finisce in un
  percorso diverso da quello creato con `log_dir + '/' + old_exp_name`.
- **Fine training non portabile:** `fig.savefig` usa un percorso assoluto e non
  crea la directory; puo' fallire dopo aver gia' completato le epoche.
- **Batch ImageNet:** `Resize(inp_sz)` nel training conserva proporzioni diverse
  fra immagini. Con originali non quadrati, il collate del DataLoader puo'
  fallire per forme incompatibili. Il test applica invece un center crop.
- **Memoria troppo piccola:** con meno slot che classi, il quoziente intero e'
  zero; non viene verificata una memoria non vuota prima del training.
- **Curve accumulate:** `acc_v` e `lr_v` sono globali e non azzerati fra
  pretraining e training; il grafico puo' mescolare le due fasi.
- **CUDA e FP16 obbligatori:** non c'e' fallback CPU ne' gestione esplicita di
  overflow FP16. Il seed non garantisce determinismo CUDA (`benchmark=True`).
- **Blocchi comuni:** i confronti stringa `is not 'None'` in
  [models/layers.py](models/layers.py) usano identita' invece di uguaglianza;
  la selezione dell'attivazione puo' dipendere da come la stringa e' costruita.
- **Riproducibilita':** la variante ResNet importata per ImageNet e' quella di
  [models/imagenet/resnet_cifar.py](models/imagenet/resnet_cifar.py), non la
  distinta implementazione `resnet_image`. Non dedurre l'architettura dal solo
  nome di un esperimento.

Rilievi da ispezione statica dei sorgenti e dei chiamanti. Nessuna campagna GPU,
download di dataset o modifica al codice e' stata eseguita per questa analisi.
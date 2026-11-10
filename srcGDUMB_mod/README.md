# srcGDUMB_mod: memoria aggiornata durante i task

## Contenuto e differenze

Fork del [trainer base](../srcGDUMB/README.md). [main.py](main.py),
[dataloader.py](dataloader.py) e [opts.py](opts.py) differiscono dalla base;
gli altri sorgenti omologhi Python/Bash confrontati risultano identici.
[utils.py](utils.py) gestisce logger, checkpoint, metriche e CutMix;
[models](models/) contiene le reti; [dbg](dbg/) la configurazione editor;
[__pycache__](__pycache__/) contiene bytecode storico.

Ogni epoca percorre tutti i task. `TrainLoaderUpdater` inizializza la memoria con
le prime classi; per quelle nuove confronta la cross-entropy del modello corrente
con quella di una copia aggiornata con un passo sui gradienti disponibili.
Ordina gli esempi per `post_loss - pre_loss`, poi riduce la quota delle classi gia'
viste per rispettare il budget. Il trainer ripete il training della memoria
`num_iteration` volte per task. Non equivale alla selezione statica della base,
ne' a un benchmark certificato di replay: vedere i limiti sotto.

## Come usarla

Occorrono PyTorch/torchvision, NumPy, Matplotlib e CUDA. Gli input mantengono la
struttura della base. Il percorso dell'updater presuppone in concreto dataset con
`.targets` e costruttore torchvision con `train=True`, come MNIST e CIFAR.
Il numero di iterazioni e' l'opzione aggiuntiva `--num_iteration` nel parser.

Da MSThesis:

```powershell
cd srcGDUMB_mod
python main.py --help
```

Per costruire un comando, usare gli argomenti obbligatori della base e aggiungere
il numero di iterazioni desiderato. Configurare sempre `--data_dir`, `--log_dir`
e `--exp_name`, creare il genitore dei log e adattare `fig.savefig` prima del
training. Non avviare campagne di confronto senza affrontare il disallineamento
delle etichette sotto. Evitare di importare simultaneamente le copie di `models`
o `dataloader`: i loro nomi assoluti coincidono.

## Output e analisi

Il log per esperimento contiene anche il numero di task e la classificazione
degli esempi delle nuove classi. Test e grafico sono calcolati alla fine di ogni
epoca, dopo aver ripercorso tutti i task. L'accuracy e' una frazione 0..1.
Il checkpoint resta riservato al pretraining, non alla memoria selezionata.
[data_collector.py](data_collector.py), [ImageNet_resize](ImageNet_resize),
[experiments.sh](experiments.sh) e [clean.sh](clean.sh) sono copie degli strumenti
storici: non diventano compatibili con questa strategia solo perche' sono qui.

## Possibili bug e limiti rilevati

- **Etichette training/test discordanti:** `gen_cl_mapping` rimappa le etichette
  secondo `cl_class_list`; `TrainLoaderUpdater` ricrea il training senza
  `target_transforms` e seleziona classi numeriche 0,1,... anziche' l'ordine del
  test. Con ordine non identita' si addestra e valuta con significati diversi.
- **Pretraining non aggiornato:** `experiment` accetta `loader`, ma il ramo di
  pretraining passa ancora `train_loader` e `test_loader`: possibile `TypeError`
  prima dell'allenamento quando quel ramo viene percorso.
- **Ultimo batch della selezione:** il ciclo legge sempre 20 score e indici.
  Se una classe ha un numero di esempi non multiplo di 20, l'ultimo batch causa
  accessi fuori limite. Il batch di selezione e' indipendente da `--batch_size`.
- **Dataset non generici:** SVHN usa `.labels` e `split`, ImageFolder un altro
  costruttore; l'updater non conserva queste distinzioni del loader base.
- **Valutazione che aggiorna BatchNorm:** l'updater usa `no_grad` ma lascia il
  modello in training; i forward di scoring possono modificare le statistiche
  BN. `no_grad` non equivale a `eval`.
- **Gradienti e storia:** gli score usano i gradienti rimasti dall'ultimo batch,
  non un nuovo backward sulle immagini candidate; a ogni epoca il task zero
  reinizializza la memoria. Verificare che sia il protocollo desiderato.
- Restano i rischi della base: `np.int` con CutMix, CUDA/FP16 obbligatori,
  concatenazione del percorso checkpoint, grafici assoluti e log sovrascritti.
  Le funzioni per raccogliere gradienti e simulare un passo sono inoltre definite
  due volte nello stesso loader: la seconda definizione sostituisce la prima.

Analisi statica; nessuna riproduzione GPU delle metriche storiche.
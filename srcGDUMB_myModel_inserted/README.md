# srcGDUMB_myModel_inserted: confronto GDumb e MLP NumPy

## Scopo e contenuto

Prototipo che riusa la selezione della memoria GDumb e confronta due reti NumPy
su MNIST. Non e' un sostituto generale del [trainer PyTorch](../srcGDUMB/README.md).
Le scelte generiche della CLI sono rimaste, ma il percorso attivo e' specializzato
per immagini 28x28, dieci classi e batch di 16.

- [main.py](main.py): costruisce un MLP custom e una rete di confronto con
  `NeuralNetwork`, confronta intermedi forward/backward e registra le metriche.
- [myLayers](myLayers/): layer, loss e MLP con backpropagation manuale NumPy.
- [dataloader.py](dataloader.py): stessa selezione bilanciata della base, ma
  maschera delle classi NumPy e rimozione delle chiamate CUDA dalla mappatura.
- [utils.py](utils.py): aggiunge `get_accuracy_NO_CUDA` alle utility storiche.
- [opts.py](opts.py): CLI derivata dalla base; percorsi Windows di un altro utente
  e `maxlr=0.005`. Le opzioni non controllano tutti i valori del modello custom.
- [models](models/): modelli PyTorch ancora costruiti dal main, ma non aggiornati
  nel ramo custom attivo. [test.py](test.py) e' una prova isolata, non una suite.
- [BatchNormalization](BatchNormalization/): directory vuota nello snapshot.
- [dbg](dbg/), [.vscode](.vscode/) e [__pycache__](__pycache__/): configurazioni e
  prodotti locali, non dipendenze del modello.

Gli script [experiments.sh](experiments.sh), [data_collector.py](data_collector.py),
[ImageNet_resize](ImageNet_resize) e [clean.sh](clean.sh) sono rimasti dalla base;
non vanno interpretati come una certificazione dei dataset supportati qui.

## Come usarla

Servono Python, NumPy, PyTorch/torchvision e Matplotlib. Il ramo NumPy lavora
sulla CPU; alcune utility legacy, in particolare caricamento checkpoint e
CutMix, conservano assunzioni CUDA. Non abilitare CutMix per il confronto custom.

Da MSThesis, dopo aver creato la directory dei log e corretto il percorso del
grafico in `experiment`:

```powershell
cd srcGDUMB_myModel_inserted
python main.py --dataset MNIST --num_classes_per_task 2 --num_tasks 5 --memory_size 500 --num_passes 2 --model MLP --width 400 --batch_size 16 --workers 0 --regularization none --data_dir ../data --log_dir ../logs/ --exp_name confronto_numpy
```

Esempio del percorso previsto dal prototipo, non prova di correttezza numerica.
Il learning rate effettivo dei due modelli NumPy e' fissato a `0.0001` nelle
chiamate di training: cambiare `--maxlr` non lo modifica. I batch incompleti del
training vengono scartati. Il modello custom ha larghezza 400 e dieci output
indipendentemente da `--width` e dal numero di classi richiesto dalla CLI.

## Risultati

Il log viene scritto in `<log_dir>/<exp_name>/checkpoint.log` e sovrascritto se
il nome e' riutilizzato. Il grafico `my_accuracy_test_...` ha destinazione Windows
assoluta. Le liste `diffForw`/`diffFb` sono calcolate in memoria per il debug, ma
non sono esportate come rapporto di equivalenza. Non esiste un checkpoint
affidabile dei pesi del MLP NumPy nel flusso attuale.

## Possibili bug e limiti rilevati

- **Valutazione parziale:** l'indentazione di `test` esegue il forward soltanto
  quando `count == 10`; l'accuracy non riguarda tutti i batch del test set.
- **Batch rigido nel test:** il flatten accede sempre a 16 esempi; un batch piu'
  piccolo che entra nel ramo valutato puo' produrre `IndexError`.
- **Migliore accuracy non aggiornata:** `best_myPrec`, `best_prec1` e `best_lr`
  rimangono zero; il riepilogo finale e i valori restituiti non rappresentano
  l'andamento registrato per epoca. `Task Acc` stampa inoltre il meter PyTorch
  non aggiornato anziche' `myTaskAcc`.
- **Pretraining rotto:** `np.ones(opt.num_classes,opt.num_classes)` passa il
  secondo intero come dtype, non come dimensione; dopo questo problema, il
  chiamante prova comunque a spacchettare due valori da una funzione che ne
  restituisce tre.
- **CutMix incoerente:** vengono modificati gli input, ma il modello NumPy usa
  le etichette originali anziche' la loss pesata delle due etichette mescolate.
- **Valutazione BN:** `model.eval()` riguarda il modello PyTorch, non i layer
  NumPy. Le statistiche custom possono essere ricalcolate sui batch di test.
- **Riproducibilita':** la chiamata a `seed_everything` e' commentata; una delle
  reti viene inizializzata globalmente prima del parsing.
- **Confronto insufficiente:** la somma delle differenze puo' annullare errori
  di segno opposto; non e' una verifica di gradienti o un test di equivalenza.
- Percorso del grafico assoluto, concatenazione checkpoint senza separatore e
  assenza di checkpoint custom rendono questo un banco di prova da completare.

Rilievi da sorgente; training e accuratezze non verificati a runtime.
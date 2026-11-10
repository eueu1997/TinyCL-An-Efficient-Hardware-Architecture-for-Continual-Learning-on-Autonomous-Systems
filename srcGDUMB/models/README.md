# models: blocchi e selezione delle reti

## Contenuto e funzionamento

[layers.py](layers.py) definisce `ConvBlock`, `FCBlock`, `InitialBlock` e
`FinalBlock`: costruiscono moduli `torch.nn.Sequential` usando attivazione,
normalizzazione, epsilon, affine e preattivazione delle opzioni. Il blocco finale
ha `opt.num_classes` uscite e disabilita l'attivazione quando non si usa preact.

[mnist](mnist/) espone MLP/NIN per 28x28; [cifar](cifar/) ResNet/DenseNet/NIN per
32x32 o TinyImagenet; [imagenet](imagenet/) ResNet/DenseNet per immagini grandi.
[__init__.py](__init__.py) e' il marcatore del pacchetto;
[__pycache__](__pycache__/) raccoglie compilati Python storici.

## Utilizzo

Le reti sono librerie, non programmi CLI. Avviare il [main](../main.py) dalla
directory del trainer. Il loader completa `opt` con `inp_size`, `in_channels` e
`num_classes`, poi il main seleziona il modulo e chiama `getattr(...)(opt)`.
Un import isolato richiede che questa copia di `models` sia nel percorso Python.
Non mescolare i pacchetti omonimi delle tre varianti. Input convoluzionali NCHW;
output batch per numero classi, da passare alla loss del trainer.

## Possibili bug e limiti rilevati

`opt.activetype is not 'None'` nei due blocchi confronta identita', non valore:
usare la stringa ottenuta dinamicamente puo' attivare un `getattr(nn, 'None')`.
La CLI non valida combinazioni modello/dataset: per esempio MLP non e' esportato
da `cifar`. Le scelte adaptive di `pooltype` sono nomi di funzioni funzionali, non
classi di `torch.nn` con la firma usata da NIN. Nessun test automatico di forme o
equivalenza delle tre copie e' incluso. Rilievi statici, non benchmark eseguiti.
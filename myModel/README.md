# myModel: layer e MLP implementati con NumPy

## Scopo e contenuto

Prototipi di forward, backpropagation e aggiornamento manuale dei parametri,
separati dai moduli `torch.nn` del trainer GDumb. Non sono un pacchetto installabile
con una CLI o una suite di test completa.

| File | Comportamento effettivo |
| --- | --- |
| [FCLayer.py](FCLayer.py) | Matrice input-pesi, bias, gradiente verso l'input e aggiornamento SGD. |
| [BatchNorm1d.py](BatchNorm1d.py) | Media/varianza sul batch per feature, trasformazione affine e backward manuale. |
| [BatchNorm2d.py](BatchNorm2d.py) | Bozza di normalizzazione spaziale, non equivalente a una BN2d PyTorch pronta all'uso. |
| [Conv2dLayer.py](Conv2dLayer.py) | Bozza di convoluzione multicanale e gradienti con cicli espliciti. |
| [ReLU.py](ReLU.py) | ReLU2d e classe ReLU1d che in realta' usa una sigmoide. |
| [CrossEntropyLoss.py](CrossEntropyLoss.py) | Loss binaria elemento per elemento su output sigmoidi; contiene anche SoftmaxLayer sperimentale. |
| [MLPOnMNIST.py](MLPOnMNIST.py) | Classe `MLPOnMIST` (nome esatto), MLP 784-400-400-10 con BN e sigmoidi, batch fisso 60. |
| [ResNetOnCIFAR.py](ResNetOnCIFAR.py) | Segnaposto, non implementazione ResNet utilizzabile. |

## API e utilizzo

Servono NumPy e, per il wrapper MLP, tqdm. I layer mantengono stato: `forward`
scrive tipicamente `.output`; `feedback` legge l'ultimo input, scrive `.dx` e
nei layer parametrici applica gia' l'aggiornamento. Non chiamare due forward prima
del backward se occorrono le cache del primo. Non c'e' autograd.

Esempio limitato al layer FC, da Python avviato nella radice di MSThesis:

```python
import numpy as np
from myModel.FCLayer import FCLayer

layer = FCLayer(4, 3, 2, 1e-6, 0.9)
layer.forward(np.ones((2, 4), dtype=np.float32))
prediction = layer.output.copy()
layer.feedback(np.ones((2, 3), dtype=np.float32), 0.001)
input_gradient = layer.dx
```

Il MLP richiede immagini appiattibili in 784 valori e target one-hot, non etichette
intere nel suo `forward`. `fit` esprime il budget in step e converte a epoche
intere; ritorna una matrice di metriche. **Il suo import attuale e' bloccato** dal
simbolo mancante indicato sotto. Non eseguire direttamente il file MLP: usa
import relativi. I blocchi `__main__` dei layer sono prove storiche, non test CI.

## Possibili bug e limiti rilevati

- **Import MLP:** richiede `CrossEntropyLoss2`, ma
  [CrossEntropyLoss.py](CrossEntropyLoss.py) in questa directory non la definisce.
  L'import del MLP fallisce; la copia in `srcGDUMB_myModel_inserted` e' diversa.
- **Convoluzione incompleta:** usa `np.zero` inesistente, `np.zeros` con dimensioni
  passate come argomenti distinti, uno stride float in `range`, un `pad_matrix`
  non risolto come funzione globale e `oneChannelConv` senza return. Il test in
  fondo chiama inoltre un costruttore senza i parametri richiesti.
- **BN2d:** il backward legge `self.weight` anziche' `self.weights` e la gestione
  di statistiche/forme non e' coerente con una BN per canale.
- **Metriche MLP:** l'accuracy aggrega iterativamente `(precedente + batch)/2`,
  quindi pesa maggiormente gli ultimi batch; la loss restituita e' quella
  dell'ultimo batch completo. Si usa il numero di esempi di training per iterare
  sul test. Un test senza batch completo lascia variabili non inizializzate.
- **Batch rigido:** `fit` accetta un batch_size diverso da quello fissato nei
  layer; l'ultimo batch incompleto puo' provocare accessi fuori limite.
- **Inferenza e ottimizzazione:** BatchNorm1d non distingue train/eval; momentum
  e weight decay sono memorizzati ma non applicati dall'aggiornamento FC letto.
- **Nomi e stabilita':** ReLU1d e' una sigmoide; la loss non e' softmax
  cross-entropy multiclass. La softmax non sottrae il massimo e il suo backward
  pass-through non e' una derivata generale.

Analisi statica, non gradient-check o prova di convergenza; codice lasciato
inalterato. Per le varianti con chiamanti concreti vedere
[myModelTestWorking](../myModelTestWorking/README.md).
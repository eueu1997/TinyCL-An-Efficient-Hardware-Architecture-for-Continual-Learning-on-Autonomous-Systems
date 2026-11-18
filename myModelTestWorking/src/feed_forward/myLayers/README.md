# myLayers: MLP custom floating-point

## Contenuto

[FCLayer.py](FCLayer.py), [BatchNorm1d.py](BatchNorm1d.py), [ReLU.py](ReLU.py) e
[CrossEntropyLoss.py](CrossEntropyLoss.py) sono i blocchi usati da
[MLPOnMNIST.py](MLPOnMNIST.py). [Conv2dLayer.py](Conv2dLayer.py) e
[BatchNorm2d.py](BatchNorm2d.py) sono bozze; [ResNetOnCIFAR.py](ResNetOnCIFAR.py)
e' un segnaposto. [layers.py](layers.py) e [neural_network.py](neural_network.py)
costituiscono un'ulteriore rete di confronto floating-point.
[.vscode](.vscode/) e [__pycache__](__pycache__/) sono configurazione/cache.

## Uso e differenze rispetto alle altre copie

La classe si chiama `MLPOnMIST(inputDataSize, internalSize)`: qui la larghezza e'
configurabile, il batch e' fissato a 60, le classi a 10. Gli input si appiattiscono
in `inputDataSize**2` valori; i target sono one-hot. `forward` restituisce la
lista di attivazioni/loss; `feedback(lr)` aggiorna i parametri e restituisce i
gradienti intermedi. `ReLU1d` e' una sigmoide e la loss e' binaria per componente.

Importare da `src.feed_forward.myLayers.MLPOnMNIST` con directory corrente
`myModelTestWorking`; non eseguire il file direttamente, per gli import relativi.
Servono NumPy e tqdm. Il training custom nel [main](../../../main.py) e' commentato:
il main attivo allena un'altra famiglia di reti intere.

## Possibili bug e limiti rilevati

- `fit` scrive `metrics[epoch, :] = accuracy`: anche la colonna dichiarata loss
  viene riempita con l'accuracy.
- La valutazione fa la media ricorsiva `(accuracy + batch_accuracy)/2`, non una
  media di tutti gli esempi; restituisce soltanto la loss dell'ultimo batch.
  Usa inoltre il numero di esempi di training come limite del test.
- Batch finale incompleto e `batch_size` diverso da 60 non sono gestiti in modo
  generale; la BN custom non distingue inferenza e training.
- Conv2d contiene `np.zero`, stride float in `range` e helper senza return;
  BN2d usa `self.weight` non definito. Sono bozze, non layer collaudati.
- La copia `neural_network.py` importa `myLayers.layers` come package top-level,
  mentre qui il percorso naturale e' `src.feed_forward.myLayers`: l'import puo'
  fallire o risolvere una copia diversa. Non mescolare le varianti nel PYTHONPATH.

Analisi statica; gradienti e convergenza non validati.
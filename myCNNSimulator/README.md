# myCNNSimulator: prototipi CNN software

## Contenuto e scopo

[myCNN.py](myCNN.py) implementa in NumPy MAC, convoluzione/gradienti, ReLU,
classificatore softmax e ciclo CIFAR10. Usa torch/torchvision solo per il loader.
La rete prevista estende RGB a otto canali, poi usa convoluzioni 8->16 e 16->32,
kernel 3, stride 2, attivazioni e classificatore 2048->10.
[myCNN_TF.py](myCNN_TF.py) e' un esperimento TensorFlow/Keras distinto: Conv2D
con 8 filtri 3x3, ReLU, flatten e Dense softmax a dieci uscite.
[data](data/) contiene la copia locale CIFAR10 del percorso torchvision.

## Come usarli

Per il prototipo NumPy servono NumPy, torch e torchvision; per quello Keras
TensorFlow, NumPy e Matplotlib. I due ambienti possono essere separati.
I parametri sono nel sorgente, non in CLI. Dalla radice:

```powershell
cd myCNNSimulator
python myCNN_TF.py
```

Questo comando scarica CIFAR10 tramite Keras se necessario, forza il device CPU
e allena un'epoca sull'intero training set con batch 1, stampando il tempo.
La funzione `getLoader` con memoria bilanciata e `memorySize=10000` e' definita
ma non usata dal percorso attivo. Il dataset Keras non coincide necessariamente
con la cache torchvision sotto questa cartella.

`python myCNN.py` e' l'entrypoint previsto del secondo prototipo, ma e' attualmente
bloccato dai problemi sotto. Il loader torchvision salva in `./data` rispetto
alla directory di esecuzione. Non sono previsti CLI, checkpoint o report
persistenti completi; vengono stampate accuracy di avanzamento.

## Possibili bug e limiti rilevati

- **Input della convoluzione non assegnato:** `Conv3dForward(featureIn)` legge
  `self.featureIn`, ma l'unica assegnazione e' commentata e il costruttore non
  definisce l'attributo. Il primo forward puo' sollevare `AttributeError`.
- **ReLU in-place:** input e output sono alias; il forward azzera i negativi
  nell'input memorizzato. Il backward poi cerca valori `< 0` che non ci sono piu',
  perdendo la maschera delle attivazioni originariamente negative.
- **Test diverso dal training:** il loop di test salta il secondo layer e le
  attivazioni e passa direttamente il primo output al classificatore dimensionato
  per il secondo, con possibile incompatibilita' delle dimensioni.
- **Aggiornamenti incoerenti:** la convoluzione 2 non viene aggiornata nel loop
  attivo; il batch effettivo e' 1 ma gli update dividono per 16.
- **Softmax fragile:** esponenziali senza sottrazione del massimo; il backward
  ritorna al primo gradiente non nullo e non e' generale per target distribuiti.
  Il buffer dE_dw iniziale ha forma input-input anziche' input-output.
- **TensorFlow:** il percorso attivo non esegue la validazione sul test ne' usa
  la memoria GDumb; il tempo stampato non e' un benchmark GPU o hardware.

Analisi statica; nessun download o training e' stato avviato per documentare.
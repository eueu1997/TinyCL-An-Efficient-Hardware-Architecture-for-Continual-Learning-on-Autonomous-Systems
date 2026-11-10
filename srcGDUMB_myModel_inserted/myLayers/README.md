# myLayers: componenti NumPy del confronto GDumb

## Contenuto e architettura

[MLPOnMNIST.py](MLPOnMNIST.py) definisce `MLPOnMIST(28)`, con rete
784-400-400-10 e batch 16. Usa [FCLayer.py](FCLayer.py),
[BatchNorm1d.py](BatchNorm1d.py), [ReLU.py](ReLU.py) (sigmoide nella classe 1d) e
[CrossEntropyLoss.py](CrossEntropyLoss.py) (loss binaria per componente).
Questo ultimo file contiene anche CrossEntropyLoss2 e SoftmaxLayer.
[layers.py](layers.py) e [neural_network.py](neural_network.py) implementano la
rete di confronto con interfacce Layer/ParamLayer e `fit_train`.
[Conv2dLayer.py](Conv2dLayer.py), [BatchNorm2d.py](BatchNorm2d.py) e
[ResNetOnCIFAR.py](ResNetOnCIFAR.py) non costituiscono una CNN completa.
[.vscode](.vscode/) e [__pycache__](__pycache__/) sono supporti locali.

## Utilizzo

Avviare il [main superiore](../README.md) dalla directory del trainer.
`myModel.forward(inputs, labels)` riceve un batch di 16 immagini 28x28 e label
intere, convertite internamente con `ConvToOneHot`. Restituisce una lista di
intermedi; `feedback(lr)` aggiorna i pesi usando l'ultimo forward. I layer salvano
anche `.output` e `.dx`. Il modello non deriva da `nn.Module`, non supporta
`.cuda()`, `.eval()` o `state_dict` PyTorch.

La rete di confronto `NeuralNetwork` ha API diversa; il main confronta le liste
di forward/backward delle due reti. Dipendenze: NumPy e tqdm, oltre alle librerie
del trainer. Non importare copie omonime da altre directory nello stesso processo.

## Possibili bug e limiti rilevati

Batch fisso, dieci classi e larghezza 400 non seguono automaticamente le opzioni
CLI. BN custom calcola statistiche sul batch anche al test; momentum/weight decay
non sono implementati come nell'SGD PyTorch. Conv2d presenta `np.zero`, stride
float e helper incompleti; BN2d legge `self.weight` non definito. Softmax non e'
stabilizzata e il backward pass-through non e' una derivata generale.
Le somme di differenze nel main non costituiscono un gradient-check.
Qui l'import CrossEntropyLoss2 esiste, diversamente dalla copia in `myModel`.
Le metriche e il pretraining hanno ulteriori problemi nel README superiore.
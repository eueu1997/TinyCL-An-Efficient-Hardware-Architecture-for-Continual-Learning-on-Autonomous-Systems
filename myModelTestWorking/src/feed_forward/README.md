# feed_forward: rete sequenziale e aritmetica intera

## Contenuto e flusso

[layers.py](layers.py) definisce le interfacce `Layer`/`ParamLayer`, LinearLayer,
SigmoidLayer, BatchNormLayer, SoftmaxLayer, SqrErrorLayer e CrossEntropyLoss.
[neural_network.py](neural_network.py) orchestra forward, backward inverso,
aggiornamento dei ParamLayer e valutazione. [myLayers](myLayers/) contiene una
seconda famiglia di implementazioni, non intercambiabile automaticamente.
[__pycache__](__pycache__/) e' cache generata.

`NeuralNetwork.fit` rimescola gli esempi, divide in minibatch, accumula le metriche
una volta per epoca e restituisce una matrice `(epoche, 2)` con loss e accuracy.
`predict(..., train=False)` propaga il flag ai layer; BN usa le statistiche
memorizzate, che devono essere inizializzate da un passaggio training.

## Utilizzo

Da `myModelTestWorking`, importare `src.feed_forward.layers` e
`src.feed_forward.neural_network`. LinearLayer richiede dimensioni e `dataType`,
SigmoidLayer richiede il dtype; `fit` ed `evaluate_model` richiedono anch'essi
`dataType`. Input e target sono matrici batch-feature e batch-classi. Il main
usa target scalati al massimo signed del dtype, non one-hot floating-point 0/1.
Seguire il [README del progetto](../../README.md) per dati e dipendenze.

## Possibili bug e limiti rilevati

Sigmoide scalata e backward non corrispondono; lo stesso vale per loss e suo
gradiente. `SoftmaxLayer` divide per la somma senza esponenziale: non implementa
una softmax e puo' dividere per zero. La quantizzazione signed usa limiti unsigned,
con rischio di wraparound; gli accumulatori non sono allargati esplicitamente.
BN puo' modificare per alias la varianza memorizzata aggiungendo epsilon.
Non interpretare le classi come implementazioni di riferimento senza gradient
check e test di saturazione. Nessuna verifica numerica e' stata eseguita qui.
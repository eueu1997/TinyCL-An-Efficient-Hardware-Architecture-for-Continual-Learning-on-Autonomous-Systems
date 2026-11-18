# mnist: MLP/NIN PyTorch di confronto

## Contenuto e uso

[mlp.py](mlp.py) definisce il MLP 784-width-width-C;
[nin.py](nin.py) una rete convoluzionale; [__init__.py](__init__.py) le esporta.
[mlp.txt](mlp.txt) e' un dump, [__pycache__](__pycache__/) e' bytecode.
Questi file coincidono con la [base](../../../srcGDUMB/models/mnist/README.md).
Richiedono PyTorch e opzioni complete; input 1x28x28 per esempio.

Usare gli import dal trainer o la CLI descritta nel [README locale](../../README.md).
Il modello NumPy effettivamente allenato e' invece in
[myLayers](../../myLayers/): non e' la classe MLP di questo pacchetto.

## Possibili bug e limiti rilevati

Width predefinita zero, batch singoli con BN e interfaccia pretraining non
supportata da NIN restano limiti della base. Nel main locale l'ottimizzatore di
questa rete non esegue `step`: non attribuire le metriche custom a questi pesi.
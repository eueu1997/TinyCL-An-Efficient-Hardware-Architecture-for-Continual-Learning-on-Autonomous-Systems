# mnist: reti della variante modificata

## Contenuto e uso

[mlp.py](mlp.py) e [nin.py](nin.py) definiscono MLP e NIN;
[__init__.py](__init__.py) le esporta, [__pycache__](__pycache__/) e' cache.
MLP appiattisce 1x28x28 in 784 ingressi e usa due livelli di larghezza `opt.width`;
NIN usa convoluzioni e pooling globale. Input NCHW, output N x numero classi.
Le implementazioni coincidono con la [base](../../../srcGDUMB/models/mnist/README.md).

Usare il [main locale](../../main.py) con MNIST e `--model MLP --width 400`,
specificando gli altri argomenti del [trainer](../../README.md).
Non e' una rete NumPy e non si esegue direttamente il file del layer.

## Possibili bug e limiti rilevati

La CLI non impone width positiva; il pretraining assume `dim_out`/`final`,
interfaccia non esposta da NIN. Con MLP e BN evitare batch finali singoli.
La memoria dinamica puo' disallineare le etichette anche se i layer sono corretti.
Nessun test di convergenza e' stato eseguito.
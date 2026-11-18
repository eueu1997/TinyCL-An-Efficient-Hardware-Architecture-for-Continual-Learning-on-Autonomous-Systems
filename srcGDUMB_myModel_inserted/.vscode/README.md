# .vscode: lancio del confronto MNIST

## Contenuto e uso

[launch.json](launch.json) imposta MNIST, MLP400, memoria 500, cinque task da
due classi, 128 passaggi e seed 1. Il programma e' tuttavia un percorso assoluto
di un altro computer verso src_my_model_MNIST/main.py.
Per usarlo selezionare l'interprete e sostituire target/cwd con il main di questa
directory; seguire i vincoli del [README](../README.md) e impostare dati/log.

## Possibili bug e limiti rilevati

Il nome Current File non implica esecuzione del file aperto. Target inesistente,
tipo debugger legacy e mancata attivazione automatica delle configurazioni
annidate possono impedire il lancio. Nessun parametro corregge i bug numerici
del prototipo documentati nel README superiore; JSON lasciato intatto.
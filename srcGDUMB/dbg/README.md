# dbg: supporto al debug del trainer base

## Contenuto e utilizzo

Contiene solo [.vscode](.vscode/) con una configurazione di lancio storica; non
ci sono test, dataset o implementazioni alternative. Per il programma effettivo
vedere il [trainer](../README.md). VS Code normalmente legge `.vscode` della
radice aperta, non tutte le directory annidate: questa configurazione non e'
automaticamente attiva quando e' aperta MSThesis.

## Possibili bug e limiti rilevati

Il target punta a un percorso di un altro computer e richiede adattamento.
La configurazione da sola non installa dipendenze, non seleziona CUDA e non
verifica risultati. Leggere il README della sottocartella prima dell'uso.
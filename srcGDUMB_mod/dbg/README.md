# dbg: supporto al debug della variante memoria

## Contenuto e utilizzo

Solo [.vscode](.vscode/) con launch.json storico. Non e' un test della memoria
dinamica. Per avviare il codice usare il [README del trainer](../README.md),
poi adattare una configurazione debugger al suo main, cwd e ambiente.
Una `.vscode` annidata non viene caricata automaticamente dalla workspace radice.

## Possibili bug e limiti rilevati

Il percorso originale non identifica il main di questa copia; un lancio non
corretto puo' eseguire un altro trainer. Nessun dato o dipendenza e' configurato
automaticamente e la validita' del debug non implica correttezza delle metriche.
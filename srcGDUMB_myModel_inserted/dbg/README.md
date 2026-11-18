# dbg: configurazione storica ereditata

## Contenuto e utilizzo

Solo [.vscode](.vscode/) con una configurazione Python. E' un residuo del trainer
base, non un banco di verifica dei layer NumPy. Seguire prima il
[README del prototipo](../README.md) per dataset, batch e percorsi.
VS Code non scopre automaticamente i launch.json di tutte le sottodirectory.

## Possibili bug e limiti rilevati

Il programma indicato e' esterno a questa workspace e gli argomenti non
descrivono il confronto custom attuale. Adattare esplicitamente main/interprete
e directory corrente; nessun avvio debugger e' stato eseguito.
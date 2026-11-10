# .vscode: configurazione Python della variante

[launch.json](launch.json) e' una copia del lancio storico MNIST con memoria
1000, 10 passaggi e MLP. Per utilizzarlo adattare programma, cwd, interprete e
argomenti al [trainer modificato](../../README.md), incluso num_iteration se
necessario. VS Code usa la configurazione della cartella aperta, non tutte le
`.vscode` annidate.

## Possibili bug e limiti rilevati

Program punta a un vecchio main esterno, non a questa variante; width manca.
La forma abbreviata `--num_task` dipende dall'abbreviazione argparse. Tipo python
legacy e percorsi non portabili richiedono revisione. Nessun lancio verificato.
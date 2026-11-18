# .vscode: configurazione MLP storica

[launch.json](launch.json) conserva un programma assoluto sotto una vecchia
cartella layers. Non e' il main del mini-progetto. Per usare il debugger aprire
myModelTestWorking, impostare interprete e cwd, e lanciare il chiamante dei
[layer](../README.md) dopo aver preparato i CSV richiesti dal progetto.

## Possibili bug e limiti rilevati

Il target non esiste in questa workspace; gli import relativi impediscono un
lancio indiscriminato del file come script. Tipo debugger legacy e annidamento
richiedono adattamenti. Non si installano dipendenze o dati da questa directory.
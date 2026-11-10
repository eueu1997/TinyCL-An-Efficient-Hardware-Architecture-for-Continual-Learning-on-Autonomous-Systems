# .vscode: prova di lancio MLP

[launch.json](launch.json) punta a un vecchio layers/MLPOnMNIST.py assoluto,
non al file locale. Per debug dei [layer](../README.md), partire dal main del
trainer con cwd corretta e breakpoint nel layer, in un ambiente NumPy/PyTorch
configurato. La directory non contiene test o dati.

## Possibili bug e limiti rilevati

Eseguire direttamente MLPOnMNIST.py puo' fallire per import relativi e non
avvia comunque un trainer completo. Program inesistente qui, tipo python legacy
e configurazione annidata non automaticamente attiva. Nessun debug eseguito.
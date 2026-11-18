# .vscode: lancio MNIST storico

[launch.json](launch.json) imposta main assoluto sotto un'altra directory GDumb,
MNIST, una classe per task, memoria 1000, 10 passaggi e MLP. Non contiene codice
di training. Per usarlo selezionare interprete, program e cwd del
[trainer locale](../../README.md), specificare percorsi validi e larghezza MLP.

## Possibili bug e limiti rilevati

Il percorso non esiste qui; `--num_task` e' un'abbreviazione di `--num_tasks`
eventualmente accettata da argparse, non il nome completo documentato. Width
manca e resta zero. Il tipo debugger python e' legacy. La configurazione non e'
attiva automaticamente dalla radice MSThesis e non e' stata eseguita.
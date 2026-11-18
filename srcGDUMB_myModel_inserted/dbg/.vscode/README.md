# .vscode: debug ereditato dal trainer base

[launch.json](launch.json) descrive un lancio MNIST MLP con memoria 1000 e
10 passaggi su un vecchio percorso assoluto. Non verifica la rete NumPy.
Adattare program/cwd e interprete secondo il [README locale](../../README.md),
con batch 16 e la configurazione custom effettivamente supportata.

## Possibili bug e limiti rilevati

Il percorso non e' quello della workspace; manca width e `--num_task` e' solo
un'abbreviazione potenzialmente accettata. La configurazione annidata non e'
automaticamente attiva e il debugger python e' legacy. Non eseguita qui.
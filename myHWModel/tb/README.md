# tb: testbench e confronto software/hardware

## Contenuto e flusso

[NN_tb.sv](NN_tb.sv) e' il top usato dalla simulazione principale: fornisce
clock/reset, istanzia NN e memorie degli input. [FW_BW_tb.sv](FW_BW_tb.sv) esercita
la PU unificata separatamente. [FW](FW/), [BW](BW/), [MAC](MAC/) e [memory](memory/)
contengono prove dei sottoblocchi. [files](files/) raccoglie stimoli, dump e diff;
[work](work/) e' libreria compilata. La directory
[Carry-Lookahead-Adder-Cocotb](Carry-Lookahead-Adder-Cocotb/) e' vuota.

[convEvaluetor.py](convEvaluetor.py) genera vettori fixed-point, usa un modello
NumPy di convoluzione, avvia lo script Questa e legge output per confronti FW,
kernel e gradienti. [MAC.py](MAC.py) e' una prova di complemento a due/aritmetica.
LogConv, transcript e waveform sono artefatti, non sorgenti del risultato.

## Utilizzo

Per il sistema completo seguire [myHWModel](../README.md) ed elaborare `NN_tb`.
Per una prova locale compilare dipendenze e il testbench scelto, poi usare il
nome del modulo dichiarato nel file, che non coincide sempre con il nome file.
Verificare reset, durata e criteri pass/fail prima di interpretare una waveform.

Il valutatore Python richiede NumPy, torch/torchvision, dati CIFAR10 e Questa
configurato; non e' un test leggero. Prima di `python convEvaluetor.py` adattare
tutti i percorsi e conservare [files](files/): il programma scrive stimoli e diff
e avvia un processo esterno. Non eseguirlo per consultare i risultati archiviati.
Controllare sia l'exit status del simulatore sia contenuto e data dei dump.

## Possibili bug e limiti rilevati

Il test principale termina secondo il tempo del Tcl, non per una certificazione
di tutte le fasi. I test unitari possono usare interfacce precedenti e molti
stampano soltanto messaggi. Il valutatore ha percorsi assoluti e formati/output
con indici codificati; alcuni diff sono salvati come interi perdendo frazioni.
La ReLU del modello NumPy modifica l'input in-place, con rischio di perdere la
maschera negativa per il backward. I risultati storici non sono stati rigenerati.
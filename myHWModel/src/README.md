# src: RTL della simulazione

## Contenuto e architettura

[NN.sv](NN.sv) coordina layer, canali, prefetch e memoria e alterna le fasi
`bw=0` forward, `bw=1` DK e `bw=2` DX. [FW_BW_PU.sv](FW_BW_PU.sv) collega griglia
MAC, riduzione, registri e generatori di indirizzo.
[GDumb.sv](GDumb.sv) e' una bozza non compilata nel flusso principale.

I sottoblocchi sono in [MAC](MAC/), [FW](FW/), [BW](BW/),
[activation](activation/) e [memory](memory/). Configurazione tipica dichiarata:
griglia 3x3, kernel 3, otto canali elaborati per gruppo e parole di 16 bit.
Le dimensioni per layer sono array di parametri; non tutti i valori alternativi
sono realmente supportati dal codice.

## Utilizzo

Compilare nell'ordine di [resim_py.tcl](../resim_py.tcl), poi elaborare
[NN_tb](../tb/NN_tb.sv). I moduli non sono programmi autonomi. Il testbench
fornisce clock/reset e ingressi della memoria GDumb; SRAM carica e scarica vettori
su file. Consultare il [README superiore](../README.md) prima di lanciare Questa.
Per la sintesi esiste una [copia diversa](../syn/src/): non compilare entrambe
nella medesima libreria perche' definiscono moduli con gli stessi nomi.

## Possibili bug e limiti rilevati

NN fissa `stride=1`, usa larghezze e gruppi di otto in piu' punti e dichiara
indici con `$clog2(NLAYER)` anche con NLAYER=1: verificare gli intervalli elaborati.
Il clock della PU e' filtrato combinatoriamente, con rischio di glitch.
I TODO segnalano timing del prefetch, aggiornamento DK e derivata ReLU incompleta;
richiedono test, non sono prove di funzionamento. MAC e SRAM hanno ulteriori
limiti nei rispettivi README. Nessuna simulazione e' stata rilanciata.
# netlist: registri kernel

## Contenuto e utilizzo

[kernelsRegisters.v](kernelsRegisters.v) conserva la rete sintetizzata;
[kernelsRegisters.sdc](kernelsRegisters.sdc) i vincoli;
[kernelsRegisters.sdf](kernelsRegisters.sdf) i ritardi. Caricare nei tool EDA
con modelli della stessa tecnologia, verificando nome del modulo e gerarchia.
Consultare i [report superiori](../README.md) prima di usare i dati per confronti.

## Possibili bug e limiti rilevati

Fanout elevato e clock non definito nei report limitano interpretazione di
timing/potenza. File generati non garantiscono equivalenza con la copia RTL
simulata corrente. Nessuna simulazione gate-level o rigenerazione effettuata.
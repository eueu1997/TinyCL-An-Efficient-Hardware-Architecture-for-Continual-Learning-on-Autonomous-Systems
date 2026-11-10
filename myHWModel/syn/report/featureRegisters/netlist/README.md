# netlist: registri feature

## Contenuto e utilizzo

[featureRegisters.v](featureRegisters.v), [featureRegisters.sdc](featureRegisters.sdc)
e [featureRegisters.sdf](featureRegisters.sdf) sono rispettivamente circuito
generato, vincoli e ritardi. Per simulazione post-sintesi servono libreria di
celle, top/gerarchia corretti e annotazione SDF. Per modifiche funzionali partire
dall'RTL e rigenerare, non editare i prodotti generati a mano.

## Possibili bug e limiti rilevati

I [report](../README.md) citano fanout elevato e clock non definito. Il nome file
plurale non garantisce il nome del modulo (report: featureRegister). Questi
artefatti non sono stati rielaborati ne' confrontati formalmente con il sorgente.
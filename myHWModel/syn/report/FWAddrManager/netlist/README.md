# netlist: FWAddrManager

## Contenuto e utilizzo

[FWAddrManager.v](FWAddrManager.v), [FWAddrManager.sdc](FWAddrManager.sdc) e
[FWAddrManager.sdf](FWAddrManager.sdf) sono un archivio Verilog/vincoli/ritardi.
Per riuso servono le librerie EDA e la corrispondenza con il sorgente e il top;
ricostruire il flusso descritto in [syn](../../../README.md).

## Possibili bug e limiti rilevati

I [report fratelli](../README.md) contengono UID-4 (design corrente non definito).
La presenza di questi tre file non risolve quell'errore: potrebbero provenire da
un'altra esecuzione. Non usarli come output certificato del run fallito. Integrita'
logica e corrispondenza temporale non verificate.
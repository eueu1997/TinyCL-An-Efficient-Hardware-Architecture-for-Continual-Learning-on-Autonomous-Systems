# netlist: featureInBWMngr

## Contenuto e utilizzo

[featureInBWMngr.v](featureInBWMngr.v) e' il Verilog generato;
[featureInBWMngr.sdc](featureInBWMngr.sdc) contiene vincoli e
[featureInBWMngr.sdf](featureInBWMngr.sdf) ritardi. Usare con Design Compiler/STA
o simulatore gate-level, includendo i modelli delle celle della libreria originaria.
Non sostituire automaticamente il sorgente RTL con questa netlist.

## Possibili bug e limiti rilevati

I [report associati](../README.md) segnalano collegamenti diretti e clock non
definito; i file non dimostrano timing/potenza validati. Prima di annotare SDF
verificare gerarchia e corrispondenza della netlist. Nessuna equivalenza eseguita.
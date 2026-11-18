# netlist: MAC

## Contenuto e utilizzo

[MAC.v](MAC.v) contiene la netlist, [MAC.sdc](MAC.sdc) i vincoli,
[MAC.sdf](MAC.sdf) i ritardi annotabili. Usare con la libreria di celle originale
per elaborazione gate-level o analisi statica; preservare gerarchia e revisione.
Per il significato dei report e la differenza tra MAC simulato/sintetizzato
vedere il [README del blocco](../README.md).

## Possibili bug e limiti rilevati

Porte/bit inutilizzati nei report possono derivare da troncamenti e vanno
interpretati con la scala fixed-point. Mancano evidenze di equivalenza numerica
e clock vincolato. Dimensione dei file e assenza di errori testuali nella netlist
non dimostrano correttezza aritmetica. Non rigenerata qui.
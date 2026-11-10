# MAC: report del blocco aritmetico

## Contenuto e uso

Check_design, report area/clock/power/resources/timing e [netlist](netlist/)
conservano una sintesi del MAC. [fp_area.rpt](fp_area.rpt) riporta 41375.519933
nelle unita' della libreria. Confrontare con [syn/src/MAC](../../src/MAC/),
non automaticamente con il MAC simulato: le copie differiscono.

Leggere i warning, i vincoli e la configurazione prima di confrontare varianti
aritmetiche. La netlist richiede modelli delle celle per simulazione gate-level;
SDC/SDF non sono risultati di accuratezza numerica.

## Possibili bug e limiti rilevati

Check_design contiene LINT-2 e altri avvisi su connessioni/bit inutilizzati,
potenzialmente legati ai troncamenti. PWR-80 indica assenza di clock definito.
Non dedurre saturazione corretta o frequenza del sistema dall'area del blocco.
Nessuna nuova sintesi o equivalenza e' stata verificata.
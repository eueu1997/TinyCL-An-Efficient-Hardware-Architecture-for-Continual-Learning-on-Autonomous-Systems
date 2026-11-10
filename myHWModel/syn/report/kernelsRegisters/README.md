# kernelsRegisters: report dei registri kernel

## Contenuto e uso

Check design e report area, clock, potenza, risorse e timing accompagnano la
[netlist](netlist/). Il design nel testo e' `kernelRegisters`.
[fp_area.rpt](fp_area.rpt) riporta 11862.359922 nelle unita' della libreria.
Consultare prima i vincoli e i warning; gli RTL sono nella copia
[syn/src/FW](../../src/FW/). Non usare i report come input al trainer Python.

## Possibili bug e limiti rilevati

TIM-134 segnala due reti ad alto fanout e PWR-80 un clock non definito.
Queste condizioni limitano confronti di consumo/prestazioni. Il flusso corrente
non rigenera automaticamente gli artefatti; nessuna equivalenza o sintesi nuova.
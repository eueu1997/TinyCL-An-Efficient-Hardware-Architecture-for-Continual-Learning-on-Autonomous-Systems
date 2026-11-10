# test: report del modulo di prova

## Contenuto e uso

Check_design, i cinque report standard e [netlist](netlist/) appartengono al
piccolo [test.sv](../../src/test.sv), non al sistema NN. L'area riportata e' zero.
Servono come traccia di prove del flusso: leggere prima design e libreria nei
report, poi confrontare con il sorgente e i vincoli. Non usarli per stimare il MAC.

## Possibili bug e limiti rilevati

LINT-28 segnala porte come clk non collegate; PWR-424 segnala unita' di leakage
non disponibili nella libreria gtech e PWR-80 clock non definito. Area zero puo'
riflettere ottimizzazioni o un design generico, non hardware completo gratuito.
Nessuna nuova sintesi eseguita; procedura generale nel [README report](../README.md).
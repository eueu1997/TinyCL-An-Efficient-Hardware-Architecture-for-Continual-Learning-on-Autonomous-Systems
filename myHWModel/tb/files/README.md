# files: stimoli, dump e differenze del confronto hardware

## Contenuto e formato

[gdumbs](gdumbs/) conserva input RGB, [kernels_in](kernels_in/) coefficienti,
[gradients_in](gradients_in/) gradienti dy. [feature_out](feature_out/),
[kernels_out](kernels_out/) e [gradients_out](gradients_out/) sono dump della SRAM.
Al livello corrente ci sono 23 file numerici di confronto: diffGradient,
diffKernel, Kernel/OptiKernel, gradientOut/optiGradientOut, featureOut e file
di appoggio `featureErrRel` e `pp`.

## Utilizzo

[convEvaluetor.py](../convEvaluetor.py) genera e confronta i dati;
[SRAM.sv](../../src/memory/SRAM.sv) li legge/scrive tramite percorsi assoluti.
Il convertitore Python usa `int(x*4096) & 0xFFFF`: parole a 16 bit, scala 4096 e
wraparound, non saturazione. Le righe di porta possono concatenare otto parole;
ordine dei lane e complemento a due vanno conservati. I file float e i diff
non sono tutti intercambiabili con `$readmemh`.

Prima di rigenerare conservare l'intero set coerente di input/output. Per leggere
le differenze usare un parser numerico e controllare scala, forma e canale.
Non passare tutti i file indistintamente alla memoria del simulatore.

## Possibili bug e limiti rilevati

Il converter elimina un numero fisso di righe iniziali e sostituisce `x` con
zero: puo' mascherare stati HDL sconosciuti. Alcuni diff sono esportati con
`fmt='%d'`, perdendo errori frazionari. I file nominati canale zero non sempre
usano lo stesso indice nel codice di confronto. Non ci sono checksum o manifest
che leghino tutti i dump a una singola simulazione; nessuna rigenerazione svolta.
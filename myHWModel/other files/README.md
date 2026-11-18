# other files: prototipi e appunti hardware

## Contenuto e uso

[enableManager.v](enableManager.v) e [top_PU_old.sv](top_PU_old.sv) conservano
varianti precedenti del controllo/top di processing unit.
[KERNEL_FEATURE_SWAP.xlsx](KERNEL_FEATURE_SWAP.xlsx) e' un foglio di lavoro per
lo scambio di kernel e feature, non RTL eseguibile.

Consultare i sorgenti come confronto storico e aprire il foglio in un lettore
compatibile senza eseguire contenuti attivi. Non aggiungere automaticamente
questi moduli alla compilazione: [resim_py.tcl](../resim_py.tcl) usa l'albero
[src](../src/). Per un riuso occorre confrontare porte, reset, larghezze e layout
con la versione attiva. Non sono dipendenze necessarie del flusso principale.

## Possibili bug e limiti rilevati

La compatibilita' dei prototipi con NN/FW_BW_PU attuali non e' verificata. Il
foglio non e' stato validato come specifica formale e non sostituisce test di
indirizzamento. Nomi simili e versioni vecchie possono causare duplicazioni di
moduli se compilati indiscriminatamente.
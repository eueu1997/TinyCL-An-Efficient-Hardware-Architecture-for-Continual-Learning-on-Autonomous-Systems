# FW: test unitari del percorso forward

## Contenuto e uso

[featureRegister_tb.sv](featureRegister_tb.sv) verifica lo scorrimento delle
feature; [kernelRegister_tb.sv](kernelRegister_tb.sv) il registro kernel;
[FWAddrManager_tb.sv](FWAddrManager_tb.sv) le coordinate;
[FW_PU_tb.sv](FW_PU_tb.sv) la PU forward separata.
Compilare prima i corrispondenti moduli in [src/FW](../../src/FW/README.md) e le
dipendenze MAC, poi il testbench. Elaborare il modulo `tb_...` dichiarato nel
file e osservare segnali, reset e messaggi in console.

Non sono i test lanciati automaticamente dal Tcl principale, che usa NN_tb.
Le prove documentano una configurazione specifica di canali e geometria, non
tutte le combinazioni dei parametri.

## Possibili bug e limiti rilevati

Alcuni assert riportano soltanto `$display("Test ... failed")`: un processo con
exit code zero puo' contenere fallimenti. Confrontare le porte dei test storici
con i moduli attuali prima di compilare. Nessuna esecuzione Questa svolta qui.
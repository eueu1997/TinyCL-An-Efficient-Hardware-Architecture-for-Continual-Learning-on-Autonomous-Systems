# FW: indirizzi e finestre del forward

## Contenuto

[FWAddrManager.sv](FWAddrManager.sv) genera coordinate/canali e anticipazioni
necessarie alla scansione; [featureRegisters.sv](featureRegisters.sv) mantiene
la finestra di feature, [kernelsRegisters.sv](kernelsRegisters.sv) i coefficienti.
[FW_PU.sv](FW_PU.sv) e' una PU forward separata, non la top-level compilata dal
flusso corrente, che usa [FW_BW_PU](../FW_BW_PU.sv).

## Utilizzo

Compilare i tre blocchi di gestione insieme a MAC e PU seguendo
[resim_py.tcl](../../resim_py.tcl). Per studiare scorrimento e reset usare i
[testbench FW](../../tb/FW/). Parametri di parola, canali e geometria devono
essere coerenti con il top; un cambio di stride modifica anche la logica di
prefetch e il layout dei dati in memoria. Gli output sono segnali hardware,
non file: i dump sono prodotti dai modelli di memoria del testbench.

## Possibili bug e limiti rilevati

La presenza di parametri non garantisce supporto a finestre/gruppi arbitrari:
il top mantiene stride e gruppi fissi. Il file FW_PU e i suoi test possono essere
anteriori all'interfaccia unificata; verificarne porte e nomi dei moduli prima
di elaborare. La copia di sintesi differisce nei registri/indirizzi: non assumere
equivalenza sulla base del nome. Nessuna regressione Questa eseguita.
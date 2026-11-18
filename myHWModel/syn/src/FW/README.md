# FW: registri e indirizzi della copia di sintesi

## Contenuto e utilizzo

[featureRegisters.sv](featureRegisters.sv), [kernelsRegisters.sv](kernelsRegisters.sv),
[FWAddrManager.sv](FWAddrManager.sv) e [FW_PU.sv](FW_PU.sv) gestiscono finestre,
coefficienti, scansione e una PU dedicata. Lo script
[resin.tcl](../../resin.tcl) analizza i blocchi usati dalla PU unificata.
Impostare parametri coerenti con il top e usare la toolchain descritta in
[syn](../../README.md), non eseguire questi file come test autonomi.

## Possibili bug e limiti rilevati

Registri e address manager differiscono dalla [copia simulata](../../../src/FW/README.md).
Le prove in tb/FW possono avere porte/configurazioni di un'altra revisione.
Report storici separati per registri e manager non dimostrano timing della catena
completa. Nessuna equivalenza fra gli alberi o simulazione post-sintesi eseguita.
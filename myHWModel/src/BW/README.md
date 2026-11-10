# BW: gradienti dei pesi e degli input

## Contenuto e responsabilita'

- [AddrManagerBWDK.sv](AddrManagerBWDK.sv): modulo `BWDKAddrManager`, scansione DK.
- [gradientInRegisterBWDK.sv](gradientInRegisterBWDK.sv): staging del gradiente dy.
- [AddrManagerBWDX.sv](AddrManagerBWDX.sv): indirizzi per propagazione DX.
- [featureRegistersBWDX.sv](featureRegistersBWDX.sv) e
  [kernelRegisterBWDX.sv](kernelRegisterBWDX.sv): finestre di gradienti/kernel.
- [register.sv](register.sv): primitiva di registro parametrico.
- [featureInMngrBWDK.sv](featureInMngrBWDK.sv) e [BW_PU.sv](BW_PU.sv): altre
  implementazioni/prototipi, non entrambi inclusi nella ricetta principale.

## Utilizzo

Il flusso attivo compila i blocchi scelti da
[resim_py.tcl](../../resim_py.tcl) e li collega nella PU unificata. DK riusa
feature originali e gradienti d'uscita; DX combina dy con kernel per propagare
il gradiente al livello precedente. I [testbench](../../tb/BW/) permettono
osservazione locale di coordinate e registri, ma non costituiscono una suite
completa dei gradienti. Mantenere coerenti numero lane, dimensioni e reset.

## Possibili bug e limiti rilevati

Nome del file e nome del modulo non sempre coincidono; non dedurre la top di
simulazione dal nome del file. Il top conserva TODO su stall, aggiornamento DK e
derivata ReLU in DX, quindi la catena backward non e' certificata end-to-end.
Più file differiscono dalla copia di sintesi. Per nuove geometrie verificare
confini, padding, valid e ultimo pixel/canale; nessuna simulazione eseguita qui.
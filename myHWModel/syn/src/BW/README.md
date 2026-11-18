# BW: controllo e finestre backward per sintesi

## Contenuto e uso

Contiene [AddrManagerBWDK.sv](AddrManagerBWDK.sv),
[AddrManagerBWDX.sv](AddrManagerBWDX.sv), [BW_PU.sv](BW_PU.sv),
[featureInMngrBWDK.sv](featureInMngrBWDK.sv),
[featureRegistersBWDX.sv](featureRegistersBWDX.sv),
[gradientInRegisterBWDK.sv](gradientInRegisterBWDK.sv),
[kernelRegisterBWDX.sv](kernelRegisterBWDX.sv) e [register.sv](register.sv).
Sono gestione indirizzi/registri per DK e DX e una PU sperimentale separata.

Usare la lista analyze del [flusso syn](../../resin.tcl), controllando dipendenze
del top e moduli realmente elaborati. Non compilare contemporaneamente la copia
di simulazione. Mantenere coerenti geometria, canali, reset e protocollo valid.

## Possibili bug e limiti rilevati

Manager, finestre DX e registro differiscono dal corrispondente albero simulato.
La presenza di gradientInRegisterBWDK non ne implica l'analisi: non e' elencato
nella ricetta corrente. Vecchi prodotti WORK possono mascherare dipendenze
mancanti. Non e' stata verificata la correttezza numerica dei gradienti.
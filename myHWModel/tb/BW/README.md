# BW: test dei sottoblocchi backward

## Contenuto e uso

Sette testbench: [AddrManagerBWDX_tb.sv](AddrManagerBWDX_tb.sv),
[BWAddrManager_tb.sv](BWAddrManager_tb.sv), [BW_PU_tb.sv](BW_PU_tb.sv),
[featureInBWMngr_tb.sv](featureInBWMngr_tb.sv),
[featureRegisterBWDX_tb.sv](featureRegisterBWDX_tb.sv),
[gradientRegisterBWDK_tb.sv](gradientRegisterBWDK_tb.sv) e
[kernelRegisterBWDX_tb.sv](kernelRegisterBWDX_tb.sv).
Esercitano indirizzi DK/DX, finestre, registri e PU separata.

Compilare dipendenze in [src/BW](../../src/BW/README.md), poi il test desiderato;
scegliere come top il modulo dichiarato, non dedurlo dal nome del file.
I parametri e gli stimoli sono nel sorgente, non in CLI. Consultare i segnali
valid, reset e coordinate nelle waveform per capire il protocollo atteso.

## Possibili bug e limiti rilevati

Test storici e PU unificata possono avere interfacce diverse. La simulazione
di un registro non certifica gradienti, aggiornamento pesi o timing dell'intera
rete. Non esiste qui una regressione automatica unica con soglie numeriche e
coverage; nessun test e' stato rilanciato.
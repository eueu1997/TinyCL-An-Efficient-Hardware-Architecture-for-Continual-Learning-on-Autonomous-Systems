# netlist: PU forward/backward

## Contenuto e utilizzo

[FW_BW_PU.v](FW_BW_PU.v), [FW_BW_PU.sdc](FW_BW_PU.sdc) e
[FW_BW_PU.sdf](FW_BW_PU.sdf) sono prodotti generati. Per aprirli in tool EDA
servono librerie delle celle e risoluzione di tutte le istanze. Non sono un
bitstream FPGA ne' codice da eseguire in Python. Riproduzione nel
[README syn](../../../README.md).

## Possibili bug e limiti rilevati

I [report](../README.md) indicano `gradientInRegisterBWDK` irrisolto e area zero.
La netlist di circa 35 MB non dimostra un mapping completo. Verificare black box,
vincoli e corrispondenza SDF prima di simulare; nessuna verifica EDA nuova.
# report: archivio dei risultati Design Compiler

## Contenuto e lettura

Otto cartelle di design: [featureInBWMngr](featureInBWMngr/),
[featureRegisters](featureRegisters/), [FWAddrManager](FWAddrManager/),
[kernelsRegisters](kernelsRegisters/), [MAC](MAC/), [FW_BW_PU](FW_BW_PU/),
[NN](NN/) e [test](test/). Ogni cartella conserva `check_design.txt` e
cinque report `fp_area`, `fp_clock`, `fp_power`, `fp_resources`, `fp_timing`.
Sette hanno anche una directory netlist; NN non la contiene nello snapshot.

Aprire prima check_design e i warning, poi risorse/area, vincoli clock e timing,
infine potenza. SDC contiene vincoli, SDF ritardi, Verilog la netlist. Per riprodurre
serve la [toolchain syn](../README.md) con revisione RTL, libreria/corner e vincoli
originali. Le unita' dell'area dipendono dalla libreria: non interpretare i numeri
come misure fisiche universali. La ricetta attuale non rigenera questi report.

## Possibili bug e limiti rilevati

Sono presenti errori reali nei testi archiviati: UID-4 per FWAddrManager,
UID-341/LBR-1 per FW_BW_PU, LINK-1/LINK-25 per NN. Molti report di potenza
segnalano PWR-80 (nessun clock definito). Un file presente o una netlist grande
non provano sintesi valida. Rilievi sull'archivio, non nuove esecuzioni EDA.
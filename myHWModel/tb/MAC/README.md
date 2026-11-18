# MAC: prove aritmetiche SystemVerilog e Cocotb

## Contenuto

[MAC_tb.sv](MAC_tb.sv), [dadda_tb.sv](dadda_tb.sv) e
[multiplier_tb.sv](multiplier_tb.sv) sono testbench RTL.
[test_MAC.py](test_MAC.py) e [Makefile](Makefile) costituiscono la prova Cocotb;
[multTb.py](multTb.py) genera vettori per il moltiplicatore, avvia Questa e legge
il risultato. [init.sh](init.sh), [resim.tcl](resim.tcl) e
[modelsim.ini](modelsim.ini) configurano il flusso locale.
[featureIn1.txt](featureIn1.txt), [kernel.txt](kernel.txt) e [result.txt](result.txt)
sono input/output; [results.xml](results.xml) e transcript sono risultati storici.
[sim_build](sim_build/) e [__pycache__](__pycache__/) sono prodotti generati.

## Utilizzo

Per Cocotb servono Python, NumPy, Cocotb compatibile con `BinaryValue`, GNU make
e Questa sul PATH. Dopo aver adattato i percorsi e risolto l'elenco sorgenti del
Makefile, eseguire `make SIM=questa` da questa directory in Bash/Linux.
Per i test SV scegliere il modulo dichiarato e compilare prima adder/multiplier/
MAC o Dadda. Per `multTb.py` conservare i vettori: lo script li sovrascrive e
avvia processi esterni. Consultare prima la [scala del MAC](../../src/MAC/README.md).

## Possibili bug e limiti rilevati

- `VERILOG_SOURCES = ...` e' ripetuto tre volte: solo MAC resta nella variabile,
  mentre adder e multiplier necessari possono mancare in una build pulita.
- Il test Cocotb stampa valori ma non contiene un assert numerico. L'XML
  archiviato ha un testcase senza failure: non dimostra l'equivalenza aritmetica.
- `[BinaryValue()]*8` condivide un oggetto tra tutti gli elementi di ciascuna
  lista; stimoli diversi per lane non resterebbero indipendenti.
- Il riferimento usa scala 4096 e il MAC corrente slice `[19:4]`: non assumere
  stesso punto binario. `cocotb.binary.BinaryValue` e assegnazioni legacy richiedono
  inoltre una versione dell'API compatibile, non installazioni moderne arbitrarie.

Nessun test hardware e' stato eseguito per la documentazione.
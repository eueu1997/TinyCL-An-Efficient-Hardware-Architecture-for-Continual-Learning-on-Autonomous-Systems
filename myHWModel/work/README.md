# work: libreria Questa generata

## Contenuto e scopo

Directory di compilazione/elaborazione del simulatore, con database `_lib*.qdb`,
indici `_info`, `_vmake`, pagine/intermedi e cartelle `@_opt*`. I sottoalberi
contengono immagini ottimizzate di precedenti elaborazioni e dati interni del
tool, non sorgenti HDL, dataset o checkpoint del trainer Python.

## Utilizzo e rigenerazione

Usarla solo attraverso Questa/ModelSim della versione compatibile. Le forme
d'onda si aprono dai file WLF, non interpretando manualmente i database.
Per una build riproducibile usare [src](../src/) e
[resim_py.tcl](../resim_py.tcl) con libreria pulita e mappata; prima adattare
percorsi, licenza e vettori come descritto nel [README](../README.md).
Non modificare o cancellare i database mentre il simulatore e' aperto.

## Possibili bug e limiti rilevati

Prodotti compilati obsoleti possono mascherare moduli mancanti e non dimostrano
che il sorgente attuale compili. Formato binario dipendente dal tool: non ne e'
stata verificata integrita', compatibilita' o corrispondenza all'RTL. I README
aggiunti documentano l'archivio e non sono richiesti dal simulatore.
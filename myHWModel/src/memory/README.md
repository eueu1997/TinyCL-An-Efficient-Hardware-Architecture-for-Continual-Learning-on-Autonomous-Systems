# memory: SRAM comportamentale con file di stimolo

## Contenuto e contratto

[SRAM.sv](SRAM.sv) memorizza `MEMORY_WIDHT` parole di `PORT_WIDTH` bit
(il nome WIDHT e' quello effettivo del parametro). Letture e scritture avvengono
al fronte negativo del clock, controllate da readEn/writeEn. Con entrambi attivi
sullo stesso indirizzo, le assegnazioni non bloccanti leggono il valore precedente.

In reset, `MEMORY_TYPE` seleziona i file in [tb/files](../../tb/files/): KERNEL
scarica e ricarica coefficienti, GRADIENT scarica/ricarica gradienti, GDUMB legge
gli input e FEATURE scrive output. CHANNEL_IN/OUT determinano i nomi dei file.

## Utilizzo

Istanziare nel testbench o in NN con tipo esplicito, parametri di porta coerenti
e file esadecimali nel layout previsto. Adattare i percorsi assoluti prima di
simulare. Il reset ha effetti su disco e puo' sovrascrivere risultati; conservarne
una copia prima delle prove. Per sintesi usare la
[SRAM distinta](../../syn/src/memory/), priva di I/O su file.

## Possibili bug e limiti rilevati

Il default `GDUMB_MEM` non e' riconosciuto e porta a `$finish`. Scrivere il dump
prima dell'inizializzazione puo' produrre X; mantenere reset alto per piu' fronti
ripete tutte le operazioni su disco. FEATURE non inizializza la memoria e il
registro readValue non e' azzerato esplicitamente. Non c'e' verifica dell'esistenza
o della lunghezza corretta dei file nel sorgente. Nessun test EDA eseguito.
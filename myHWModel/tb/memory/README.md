# memory: test del modello SRAM

## Contenuto e utilizzo

[SRAM_tb.sv](SRAM_tb.sv) contiene clock, reset e operazioni di lettura/scrittura
per il modulo SRAM. Compilare la [SRAM simulata](../../src/memory/SRAM.sv) e
il testbench, quindi elaborare `tb_SRAM` in Questa. Verificare che parametri e
MEMORY_TYPE del banco siano compatibili con la versione scelta; per tipi con
file servono i vettori sotto tb/files e percorsi corretti.

Lettura e scrittura del modello sono al fronte negativo: osservare l'uscita
dopo quel fronte, tenendo conto delle assegnazioni non bloccanti.

## Possibili bug e limiti rilevati

Il valore predefinito MEMORY_TYPE della SRAM corrente non e' riconosciuto;
un test che non lo sovrascrive puo' terminare al reset prima delle verifiche.
La copia di sintesi ha interfaccia e reset differenti. Una prova storica non
certifica entrambe le versioni; simulazione non eseguita durante l'analisi.
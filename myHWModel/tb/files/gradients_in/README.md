# gradients_in: stimoli dy

Contiene 24 file, tre per ciascuno degli otto canali: `.txt` impacchettato,
`_2.txt` diagnostico e `_float.txt`. Provengono dal backward del riferimento
software e alimentano la SRAM GRADIENT per le fasi DK/DX.

## Utilizzo

La memoria legge il `.txt` numerato secondo CHANNEL_IN. Le altre copie servono
all'ispezione del packing o del valore floating-point. Consultare
[convEvaluetor.py](../../convEvaluetor.py) e il [formato comune](../README.md)
prima di cambiare geometria, canali o punto binario. Non rigenerare dy separato
da feature/kernel se si vuole confrontare la stessa convoluzione.

## Possibili bug e limiti rilevati

La conversione a 16 bit tronca e maschera senza saturare; grandi gradienti
possono andare in wraparound. I file archiviati non hanno un manifest del run.
Non e' stata verificata una nuova simulazione o la scala end-to-end.
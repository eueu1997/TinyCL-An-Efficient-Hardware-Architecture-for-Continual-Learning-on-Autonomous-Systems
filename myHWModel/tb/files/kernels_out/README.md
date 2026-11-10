# kernels_out: dump dei coefficienti hardware

Contiene 64 file `.txt`, una matrice 8x8 di coppie canale out/in da `0_0` a `7_7`.
Sono scritti da `$writememh` per SRAM KERNEL e usati dal valutatore per confrontare
i pesi dopo il percorso DK con il modello software.

## Utilizzo

Eseguire la [simulazione](../../../README.md) con input corrispondenti, poi leggere
i dump rispettando header, ordine delle parole, segno e scala del
[formato comune](../README.md). Non sono checkpoint Python. Confrontare lo stesso
canale e la stessa fase del reset, non soltanto il nome del file.

## Possibili bug e limiti rilevati

La SRAM scrive al reset prima di ricaricare: il primo dump puo' contenere X o
valori precedenti. Il converter che trasforma X in zero puo' nasconderli.
Nessuna integrita' o correttezza dei gradienti e' stata verificata a runtime.
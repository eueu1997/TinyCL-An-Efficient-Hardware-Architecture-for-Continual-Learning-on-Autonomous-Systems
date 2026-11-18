# kernels_in: coefficienti di convoluzione

Contiene 128 file: 64 coppie canale uscita/ingresso `0_0` fino a `7_7`, ciascuna
con `.txt` per memoria e variante `_float`. I kernel sono generati dal modello
software e letti dalla SRAM di tipo KERNEL in reset.

## Utilizzo

Conservare la convenzione `<canale_out>_<canale_in>` e l'ordine degli elementi
del kernel. I `.txt` sono parole esadecimali fixed-point; leggere i dettagli nel
[README vettori](../README.md). Il suffisso `_float` e' storico: il generatore
osservato applica anche a questi file la funzione di conversione esadecimale,
quindi controllarne il contenuto prima di interpretarli come decimali.

## Possibili bug e limiti rilevati

Il nome float non garantisce il formato. La scala di conversione deve coincidere
con il MAC; non e' stata certificata l'equivalenza con i dump di output. La
rigenerazione sovrascrive i coefficienti; conservare un insieme coerente di dati.
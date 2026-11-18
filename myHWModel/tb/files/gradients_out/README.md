# gradients_out: gradienti scaricati dalla SRAM

Otto dump esadecimali `0.txt` fino a `7.txt`, selezionati tramite CHANNEL_OUT.
Sono output della memoria GRADIENT, confrontati dal valutatore con DX software.
Non sono target di training o vettori di input da copiare senza conversione.

## Utilizzo

Aprire come testo per ispezione; per valori numerici interpretare packing,
complemento a due e scala come nel [README vettori](../README.md). Associare
sempre gli output agli input della stessa esecuzione. Il reset del modello
scrive i dati prima di ricaricare gli stimoli e puo' sovrascrivere questi file.

## Possibili bug e limiti rilevati

X iniziali, dump obsoleti e sostituzione delle X con zero nel parser possono
falsare il confronto. Non assumere che la presenza di otto file equivalga al
completamento corretto del backward; nessun controllo numerico rieseguito.
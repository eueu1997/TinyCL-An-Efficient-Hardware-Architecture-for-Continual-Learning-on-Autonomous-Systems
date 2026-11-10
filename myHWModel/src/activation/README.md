# activation: ReLU combinatoria

## Contenuto e utilizzo

[activation.sv](activation.sv) definisce il modulo `activation`, parametrizzato
da `NBITS` (16) e stringa `act_rule` (`RELU`). Con ReLU, il bit piu' significativo
determina il segno: valori negativi diventano zero, gli altri passano invariati.
Ogni altra stringa abilita il pass-through. Non ha clock, stato o handshake.

Viene compilato da [resim_py.tcl](../../resim_py.tcl) e istanziato nel datapath
di [NN](../NN.sv). Usare parole in complemento a due e la stessa scala fixed-point
dei blocchi circostanti. Per attivazione disabilitata il top usa `NONE`.

## Possibili bug e limiti rilevati

I valori sono vettori non dichiarati signed, ma il segno viene letto direttamente:
non usarli come unsigned senza cambiare la semantica. Lo zero e' scritto come
costante 32 bit nonostante NBITS sia parametrico, normalmente ridimensionata
dall'assegnazione. Non implementa la derivata ReLU per DX; tale funzione va
verificata nel controllo backward. Nessun test automatico locale dedicato.
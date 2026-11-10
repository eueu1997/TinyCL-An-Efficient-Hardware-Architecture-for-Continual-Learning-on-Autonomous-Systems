# graphs: grafici degli esperimenti

## Contenuto

Quindici PNG al livello corrente: curve accuracy con varie memorie/passaggi,
una curva learning rate `lr_test_5k_1k.png` e tre curve custom MNIST. I sei grafici
ImageNet sono nella [sottodirectory dedicata](ImageNet/). I nomi sono etichette
storiche, non manifest rigorosi: alcune configurazioni non sono interamente
codificate nel filename.

## Utilizzo e rigenerazione

Aprire le immagini in VS Code o in un visualizzatore; confrontarle con i
[log](../logs/) usando dataset, memoria, epoche e modello. Le ordinate dei log
GDumb sono frazioni 0..1. Per rigenerare una figura ricostruire la serie dal log
o rilanciare il trainer dopo aver corretto il percorso `fig.savefig`; i main
attuali non usano automaticamente questa directory relativa. Non sovrascrivere
figure storiche con esperimenti di prova.

## Possibili bug e limiti rilevati

I grafici non contengono dati numerici completi, revisione codice, seed e ambiente.
L'accumulo delle liste globali nei trainer puo' unire pretraining e training.
Le curve custom dipendono da metriche con limiti documentati nei relativi README.
Nessuna rigenerazione o verifica pixel-per-pixel delle metriche e' stata svolta.
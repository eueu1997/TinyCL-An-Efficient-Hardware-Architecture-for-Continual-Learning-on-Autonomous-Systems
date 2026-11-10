# FWAddrManager: archivio con report falliti

## Contenuto e uso

Contiene check_design, i cinque report standard e una [netlist](netlist/) con
Verilog/SDC/SDF. I report di questo livello riportano
`Error: Current design is not defined. (UID-4)`, non statistiche valide del
manager. Aprire [check_design.txt](check_design.txt) per il riscontro.

Per riprodurre occorre selezionare ed elaborare il design corretto in
Design Compiler, collegare dipendenze/librerie e applicare vincoli secondo
[syn](../../README.md). Conservare l'archivio come evidenza dell'esecuzione
fallita; non sostituirlo con numeri dedotti da altre cartelle.

## Possibili bug e limiti rilevati

La netlist presente puo' appartenere a un'altra esecuzione: report falliti e
file netlist esistenti non provano corrispondenza. Non ricavare area o frequenza
da questi report. Errore osservato nell'archivio, non riprodotto con il tool.
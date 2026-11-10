# MAC: copia aritmetica per Design Compiler

## Contenuto e uso

[MAC.sv](MAC.sv), [adder.sv](adder.sv), [multiplier.sv](multiplier.sv) e
[MultiOpAdderDadda.sv](MultiOpAdderDadda.sv) costituiscono prodotti, accumuli e
riduzione del datapath. Compilarli nell'ordine di
[resin.tcl](../../resin.tcl), con librerie e vincoli del flusso syn.
I rapporti storici del blocco sono in [report/MAC](../../report/MAC/).

MAC e adder differiscono dai file nella [copia simulata](../../../src/MAC/README.md);
multiplier e Dadda confrontati coincidono. Non scambiare i due alberi assumendo
stessa quantizzazione o stessa area. Per un confronto numerico serve la stessa
convenzione fixed-point e un testbench associato alla revisione sintetizzata.

## Possibili bug e limiti rilevati

Verificare larghezze, segno, troncamenti e overflow prima di cambiare parametri.
Il test Cocotb presente si riferisce ai percorsi `src`, non certifica questa
copia. Il flusso corrente non rigenera il report MAC e non e' stato eseguito qui.
# MAC: aritmetica fixed-point

## Contenuto e funzionamento

[MAC.sv](MAC.sv) istanzia moltiplicatori e sommatori: `select=0` riduce otto
prodotti in un valore FW/DX; `select=1` aggiorna otto somme parziali DK distinte.
[multiplier.sv](multiplier.sv) definisce `fixed_multi`,
[adder.sv](adder.sv) `fixed_add`, e [MultiOpAdderDadda.sv](MultiOpAdderDadda.sv)
la riduzione `dadda_top`. Il MAC e' combinatorio; clock e registrazione si trovano
nei chiamanti. Prodotto intermedio e somme sono larghi 32 bit nel percorso attuale.

## Utilizzo

Compilare adder, multiplier, Dadda e MAC prima della PU tramite lo
[script principale](../../resim_py.tcl). I test di unita' sono in
[tb/MAC](../../tb/MAC/). Documentare scala, complemento a due, ordine dei lane e
troncamento prima di confrontare con floating-point. I segnali overflow e
precisionLost del moltiplicatore non vengono consumati dal MAC.

## Possibili bug e limiti rilevati

Gli indici 0..7 sono espliciti nonostante `NOperands` sia un parametro; sommatori
32 bit e slice `[19:4]` vincolano anche `NBit`. Non c'e' saturazione generale.
Nel ramo DK le somme parziali 16 bit sono assegnate a operandi 32 bit senza una
conversione signed/scala esplicita: verificare estensione del segno e allineamento
del punto binario con vettori negativi. Il test Cocotb usa scala 4096, da
riconciliare con la slice corrente. Nessun gradient/arithmetic test eseguito qui.
# syn: flusso Synopsys Design Compiler

## Contenuto

[resin.tcl](resin.tcl) contiene analyze/elaborate e comandi di sintesi/report
attualmente commentati. [resyn.bash](resyn.bash) e [init_syn.sh](init_syn.sh)
sono wrapper; [init_design_vision](init_design_vision) e
[.synopsys_dc.setup](.synopsys_dc.setup) configurano ambiente e librerie.
[src](src/) e' una copia RTL specifica, [report](report/) conserva risultati,
[work](work/) e' area di lavoro. Command log, mylogFile, mylogFileNN e default.svf
sono prodotti storici; il file con suffisso tilde e' un backup, non l'entrypoint.

## Come usarla

Occorrono Design Compiler/Design Vision, licenza e librerie tecnologiche del
flusso; non sono inclusi nel repository. Dalla directory `syn`, adattare setup,
percorsi e top. Lo script seleziona oggi `designChecked="FW_BW_PU"`. Eseguire
`source resin.tcl` **nella console Tcl di Design Compiler**, non in una shell
PowerShell/Bash ordinaria. Leggere il wrapper prima di lanciarlo: prepara/pulisce
la directory work e puo' rimuovere risultati di lavoro.

Per una sintesi completa occorre definire clock/vincoli realistici, collegare
le librerie, controllare il design, compilare e generare report/netlist. Questi
passi sono presenti come commenti, non vengono eseguiti nello stato corrente.
Registrare versione tool, corner, libreria, vincoli e revisione RTL con gli output.

## Possibili bug e limiti rilevati

- La ricetta attuale elabora soltanto: non rigenera i report gia' presenti.
- Il comando clock commentato ha periodo zero: non riattivarlo come vincolo
  fisico valido senza scegliere il periodo richiesto.
- La lista analyze include `featureInMngrBWDK` ma non
  `gradientInRegisterBWDK`: verificare le istanze effettive prima dell'elaborazione
  in una libreria pulita, senza affidarsi a vecchi compilati.
- Molti file della copia RTL differiscono dalla simulazione; non si assume
  equivalenza logica. I percorsi di laboratorio sono assoluti.
- Rapporti senza clock o con porte non vincolate non dimostrano frequenza,
  consumo o correttezza del sistema completo. Nessuna sintesi e' stata rilanciata.
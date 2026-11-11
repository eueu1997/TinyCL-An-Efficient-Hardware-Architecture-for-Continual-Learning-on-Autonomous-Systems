# Concorrenti e riferimenti per un coprocessore MAC

Data di consultazione: 2026-11-10.

## 1. Perimetro e metodo

Questa ricerca riguarda l'idea discussa nel [diario](conversazione.md): una CPU, potenzialmente RISC-V, che demanda a un coprocessore operazioni riconducibili a prodotti e accumuli, passando operandi o puntatori e configurazione. Il blocco convoluzionale `3x3x8` resta un'ipotesi di partenza, non un vincolo architetturale definitivo.

Sono pertinenti prodotti scalari, GEMV, GEMM, convoluzioni e le loro componenti di backward basate su MAC. Non vengono confrontati softmax, attivazioni, loss o intere reti come se fossero costituiti soltanto da MAC. Il supporto a GEMM non dimostra, da solo, un sistema completo di training.

La ricerca combina interrogazioni web e consultazione diretta di repository ufficiali, documentazione tecnica, pagine dei produttori e abstract di pubblicazioni degli autori. Le fonti sono collegate nelle singole schede. Si distinguono:

- **Concorrenti architetturali:** implementazioni che risolvono un problema hardware molto simile.
- **Alternative commerciali:** IP o dispositivi che un utilizzatore potrebbe adottare al posto di un nuovo progetto.
- **Infrastrutture riutilizzabili:** framework utili anche per sviluppare il coprocessore, non necessariamente prodotti concorrenti.
- **Alternative ISA:** istruzioni vettoriali o matriciali gia' disponibili che riducono la necessita' di una nuova estensione.

Non sono stati clonati, compilati o simulati i progetti. L'approfondimento sui prezzi pubblici e' nella sezione 9; non sono stati richiesti preventivi, verificati contratti commerciali o provate le dipendenze. Non e' un censimento esaustivo del mercato, una revisione sistematica di tutta la letteratura o una ricerca brevettuale. Le pagine su rami mobili possono cambiare; un eventuale confronto sperimentale richiedera' revisioni fissate.

## 2. Risultato principale

**L'idea generale "istruzioni CPU + puntatori ai tensori + acceleratore MAC autonomo" ha precedenti molto vicini. RedMulE e Gemmini sono i primi due riferimenti da studiare.**

OpenGeMM/SNAX aggiunge un confronto particolarmente pertinente su controllo RISC-V leggero, memoria locale e generazione degli indirizzi. NE16 e NEureka sono piu' vicini alla specializzazione convoluzionale del datapath attuale. Sul mercato, SiFive XM e' molto vicino alla direzione CPU con istruzioni matriciali; Arm Ethos-U85 e Cadence Neo sono alternative NPU embedded.

Questo non dimostra che una specifica microarchitettura nuova sia priva di originalita'. Dimostra invece che il contributo non puo' essere identificato soltanto con l'aggiunta di un'istruzione di convoluzione, con il passaggio di indirizzi, con il riuso dei dati o con l'intenzione di accelerare anche il training.

## 3. Progetti aperti

"Training ND" significa non documentato nelle fonti consultate, non impossibilita' matematica o impossibilita' di estensione.

| Progetto | Operazioni e numerica documentate | Collegamento e memoria | Evidenza sul training | Pertinenza |
| --- | --- | --- | --- | --- |
| RedMulE | GEMM; ingressi/uscite FP8 e FP16, calcolo interno FP16 nella configurazione descritta | CV-X-IF con istruzioni custom oppure HWPE memory-mapped; tiler autonomo | Obiettivo esplicito nella pubblicazione TinyML | Molto alta per ISA, autonomia e training |
| Gemmini | GEMM e convoluzioni; default INT8 e accumulo INT32, generatore configurabile | RoCC, istruzioni custom, DMA, scratchpad, TLB | Pipeline completa di training ND nel README consultato | Molto alta per integrazione completa |
| OpenGeMM / SNAX-GEMM | GEMM intera, esempi e test INT8 con risultati INT32 | Snitch, CSR, streamer, memoria TCDM; accessi a stride | Training ND | Molto alta per controllo e movimento dati |
| NE16 / NEureka | Convoluzioni 1x1, 3x3, depthwise; pesi 2-8 bit | HWPE/HCI in cluster PULP | Training ND | Molto alta per convoluzioni quantizzate |
| CFU Playground | Operazioni custom scelte dal progettista, inclusi dot product | VexRiscv; interfaccia a operandi/risultati nei registri | Flusso documentato di inferenza TFLM | Alta come piattaforma di prototipazione |
| Ara | Operazioni vettoriali, esempi di matmul e convoluzione | Coprocessore CVA6 con RVV 1.0 | Training completo ND nelle fonti consultate | Alternativa ISA generalista |
| VTA | GEMM e ISA tensoriale; tipicamente ingressi interi a bassa precisione e accumuli 32 bit | Registri memory-mapped, stream di istruzioni, DMA, SRAM locali | Training ND | Riferimento per compiler e runtime |
| FINN | Inferenza di reti quantizzate su FPGA | Dataflow generato per la rete | Inferenza, non training on-device nel flusso descritto | Alternativa alla programmabilita' runtime |
| NVDLA | Convoluzioni per inferenza; ramo nvdlav1 con INT8 e operazioni a 16 bit | Acceleratore integrabile in SoC; dettagli di interfaccia non verificati qui | Esplicitamente inferenza | Riferimento RTL convoluzionale |

### 3.1 RedMulE: il precedente piu' vicino al modello di comando

Fonti: [repository ufficiale](https://github.com/pulp-platform/redmule), [pubblicazione, abstract e riferimenti](https://arxiv.org/abs/2301.03904), [DOI della pubblicazione su rivista](https://doi.org/10.1016/j.future.2023.07.002).

RedMulE e' un acceleratore SystemVerilog di operazioni matriciali. Un array bidimensionale di elementi di calcolo comprende unita' FMA. Il progetto documenta sia l'integrazione HWPE con controllo memory-mapped, sia un coprocessore tensoriale associato a CV32E40X tramite CORE-V eXtension Interface, CV-X-IF.

Il modello ISA e' particolarmente pertinente:

- `mcnfig` comunica le dimensioni delle matrici usando registri della CPU.
- `marith` comunica tre puntatori, X, W e Z, oltre a formato e operazione.
- Un tiler hardware determina autonomamente la suddivisione del lavoro.
- La variante memory-mapped trasmette sostanzialmente la stessa configurazione mediante registri.

La conseguenza per la discussione sui "due indirizzi" e' concreta: due indirizzi possono descrivere i due ingressi, ma occorre anche stabilire la destinazione del risultato e l'eventuale accumulo. RedMulE fornisce un precedente esplicito con tre puntatori; non implica che il nostro encoding debba essere uguale.

Gli ingressi e le uscite possono essere FP8 o FP16. Il README descrive calcolo e accumuli intermedi in IEEE FP16, anche per la modalita' di ingresso BF16 tramite formato custom. Non va descritto come un motore con accumulo FP32 senza verificare una diversa configurazione.

La pubblicazione tratta esplicitamente TinyML training e integrazione con un cluster PULP a otto core e memoria dati strettamente accoppiata. Questo e' un precedente sul training, ma non equivale alla verifica di un prodotto pronto che implementi autonomamente ogni loss, backward e optimizer.

**Cosa studiare:** encoding, tiler, transazioni verso la memoria, completamento e HAL. **Differenza da non perdere:** e' un motore matriciale; non e' automaticamente equivalente al nostro scorrimento diretto di finestre convoluzionali.

Licenze dichiarate: hardware Solderpad 0.51; software Apache 2.0, salvo eccezioni locali. Sono disponibili golden model e flussi di simulazione Verilator/Questa.

### 3.2 Gemmini: il riferimento di sistema

Fonti: [repository e specifica ISA](https://github.com/ucb-bar/gemmini), [licenza](https://raw.githubusercontent.com/ucb-bar/gemmini/master/LICENSE).

Gemmini e' un generatore Chisel nell'ecosistema Chipyard. Si collega a Rocket o BOOM tramite RoCC e istruzioni RISC-V non standard. Il default descritto usa un array sistolico 16x16, ingressi INT8 e memoria di accumulo INT32; questi valori non sono limiti universali del generatore.

Caratteristiche rilevanti:

- Dataflow weight-stationary e output-stationary, selezionabili o fissabili in configurazione.
- Scratchpad SRAM a banchi e memoria separata per gli accumulatori.
- Controllori distinti per load, store ed execute, con code e gestione delle dipendenze.
- DMA che opera su indirizzi virtuali, con TLB e accesso al page-table walker condiviso con la CPU.
- Istruzioni per caricamento, scaricamento, configurazione, preload e calcolo.
- Comandi di livello superiore per matmul e convoluzioni, con tiling e double buffering.

Le operazioni grandi non sono prive di limiti: i loop hardware sono soggetti alla capacita' della memoria locale e possono richiedere tiling esterno. Inoltre i comandi complessi sono sequenze di istruzioni custom, non necessariamente una singola parola macchina che contiene tutti i parametri.

Il valore del confronto e' nel sistema completo: libreria C, test, simulazione funzionale e cycle-accurate, esecuzione bare-metal/Linux e integrazione ONNX. La presenza di trasposizioni e convoluzioni trasposte non dimostra da sola un training end-to-end.

**Cosa studiare:** costo di avvio, movimentazione, accumulo, code e software. La scelta di indirizzi fisici nel nostro progetto sarebbe una differenza d'integrazione rispetto al percorso virtuale documentato, non automaticamente un vantaggio prestazionale.

La licenza consultata e' permissiva di tipo BSD a tre condizioni, con disclaimer University of California. Le dipendenze richiedono comunque una verifica separata.

### 3.3 OpenGeMM e SNAX: controllo leggero e memoria

Fonti: [SNAX Cluster](https://github.com/KULeuven-MICAS/snax_cluster), [SNAX-GEMM](https://github.com/KULeuven-MICAS/snax-gemm), [OpenGeMM, pubblicazione](https://arxiv.org/abs/2411.09543).

SNAX e' una piattaforma per integrare acceleratori con core Snitch, non il nome di un singolo datapath. Comprende un CSR manager, data streamer, generatori, esempi software e ambienti di simulazione. OpenGeMM e' il riferimento pubblicato per un sistema GEMM con controllo RISC-V leggero e scratchpad multibanco; SNAX-GEMM rende disponibile un generatore Chisel pertinente a questa linea di lavoro. Non si presume identita' fra ogni revisione corrente e la configurazione del paper.

SNAX-GEMM documenta Base GEMM, Block GEMM e Batch Stride GEMM. Gli esempi usano ingressi INT8 e uscite INT32; larghezze e geometria sono parametriche, ma il README precisa che i test descritti coprono INT8/INT32 con una dimensione fissata dell'array.

Indirizzi, dimensioni, stride, stato e contatori vengono configurati tramite CSR. Gli accessi a memoria sono parte essenziale del progetto. Layout e ordine di memorizzazione hanno vincoli espliciti: non bisogna assumere che qualunque matrice contigua venga utilizzata senza preparazione.

La pubblicazione OpenGeMM propone precaricamento della configurazione, prefetch degli ingressi, buffering delle uscite e accessi a stride. Gli autori riportano anche confronti con Gemmini. Non vengono riprodotti qui come una graduatoria universale: occorre controllare configurazioni, normalizzazione e workload prima di trasferire quei risultati al nostro caso.

**Cosa studiare:** overhead del controllo, configurazione degli indirizzi e sfruttamento della memoria locale. E' un concorrente importante proprio perche' lavora sui costi esterni all'array di MAC.

Licenze verificate: [SNAX Cluster](https://raw.githubusercontent.com/KULeuven-MICAS/snax_cluster/main/LICENSE), Apache 2.0 a livello principale; [SNAX-GEMM](https://raw.githubusercontent.com/KULeuven-MICAS/snax-gemm/main/LICENSE), Solderpad 2.1 con opzione Apache 2.0. Non si estende automaticamente questa classificazione a tutti i componenti importati.

### 3.4 NE16 e NEureka: i confronti convoluzionali

Fonti: [NE16](https://github.com/pulp-platform/ne16), [NEureka](https://github.com/pulp-platform/neureka).

NE16 e' un motore per cluster PULP basato su HWPE e HCI. Supporta filtri 1x1, 3x3, depthwise e linear, ingressi di attivazione a 8/16 bit, pesi da 2 a 8 bit e uscite a 8/16/32 bit. Sono documentati numeri arbitrari di canali in ingresso e uscita.

NEureka e' un derivato di NE16: documenta 1x1, 3x3 e depthwise, attivazioni in ingresso a 8 bit, pesi 2-8 bit e uscite a 8/32 bit. Il repository include generazione degli stimoli, simulazione Questa e regressioni. Questi formati di uscita non devono essere confusi con una specifica completa della precisione di ogni accumulatore interno.

**Cosa studiare:** disposizione dei MAC, organizzazione dei dati per canali e finestre, controllo degli accessi e gestione dei casi 1x1/3x3/depthwise. Il mero supporto 3x3 o il riuso fra finestre non basta a differenziarsi. La capacita' di calcolare gradienti e un flusso completo di training non sono dimostrati dai README consultati.

Per entrambi: hardware Solderpad 0.51 e software Apache 2.0. Il finanziamento GreenWaves dichiarato da NE16 non viene usato come prova che questo repository coincida con una particolare revisione di un chip commerciale.

### 3.5 CFU Playground: una piattaforma per provare le istruzioni

Fonti: [repository](https://github.com/google/CFU-Playground), [interfaccia CPU-CFU](https://cfu-playground.readthedocs.io/en/latest/interface.html).

Il framework usa VexRiscv, LiteX e unita' custom in Verilog/Amaranth per accelerare kernel TensorFlow Lite Micro. Il flusso documentato misura i cicli dei layer, sostituisce sequenze software con operazioni custom e rivaluta i risultati.

L'interfaccia descritta trasporta due operandi e un risultato, con modalita' multicycle, split-phase, polling e accumulo. Nell'esempio di dot product, un ciclo software carica i dati e li invia alla CFU. **Non e' quindi, per definizione, un motore che riceve due puntatori e legge autonomamente tutti i tensori:** tale capacita' richiederebbe un'estensione del percorso dati/memoria.

E' interessante come infrastruttura per il nostro esperimento e come alternativa di accelerazione fine-grained. Non e' un NPU commerciale pronto. Licenza Apache 2.0; il repository dichiara che non e' un progetto Google ufficialmente supportato e che il flusso host supportato e' Linux.

### 3.6 Ara: la domanda "perche' non RVV?"

Fonte: [repository Ara](https://github.com/pulp-platform/ara).

Ara e' un coprocessore vettoriale per CVA6 che supporta RVV 1.0. Include applicazioni di moltiplicazione matriciale e convoluzione, simulazione e un flusso FPGA/Linux.

Non offre per questo una singola istruzione che completi una convoluzione arbitraria. Offre invece programmabilita' tramite istruzioni vettoriali, sulla quale costruire kernel MAC. E' una baseline importante per giustificare il costo di un'estensione piu' specializzata. Le precise istruzioni e precisioni abilitate vanno controllate per la configurazione scelta; non sono inventariate in questa ricerca.

### 3.7 VTA: ISA tensoriale e compilazione

Fonti: [repository VTA](https://github.com/apache/tvm-vta), [guida hardware nella revisione TVM v0.13.0](https://raw.githubusercontent.com/apache/tvm/v0.13.0/docs/topic/vta/dev/hardware.rst).

La guida descrive un acceleratore con load, compute e store disaccoppiati; ISA con `LOAD`, `GEMM`, `ALU`, `STORE`; micro-operazioni e memorie locali. La CPU prepara uno stream di istruzioni in memoria fisicamente contigua e ne comunica indirizzo fisico, lunghezza e avvio mediante registri memory-mapped.

**Distinzione importante:** VTA ha una propria ISA, ma questa non e' automaticamente un'estensione dell'ISA della CPU host. Il motore preleva il proprio programma tramite DMA. E' quindi un confronto utile per la granularita' del comando e per l'autonomia, anche se diverso dall'offload di ogni istruzione CPU.

Il progetto include compilatore basato su TVM, runtime e simulatori. La licenza principale e' Apache 2.0. La guida usata e' versionata e storica: non costituisce una verifica di compatibilita' con le versioni attuali di TVM o dei tool FPGA.

### 3.8 FINN: specializzare l'hardware per la rete

Fonte: [repository FINN](https://github.com/Xilinx/finn).

FINN e' un framework sperimentale AMD Research per inferenza di reti quantizzate su FPGA. Genera architetture dataflow personalizzate per una rete invece di imporre un unico coprocessore riutilizzabile a runtime.

E' una strategia concorrente quando la rete cambia poco: il confronto riguarda il compromesso tra efficienza della specializzazione e flessibilita'. Non e' un'estensione ISA pronta e non documenta training sullo stesso acceleratore nel flusso descritto. Licenza principale BSD-3-Clause; il toolflow dipende anche dagli strumenti FPGA e supporta esecuzione Docker.

### 3.9 NVDLA: riferimento aperto per inferenza

Fonte: [repository hardware NVDLA](https://github.com/nvdla/hw).

NVDLA e' esplicitamente un'architettura per acceleratori di inferenza. Il ramo `nvdlav1` consultato contiene una configurazione fissa: 2048 MAC a 8 bit oppure 1024 MAC a 16 bit fixed/floating-point, secondo il README. Non si deve confondere la configurabilita' della famiglia con quella di questo ramo.

Sono disponibili RTL, C-model, testbench e script di sintesi. Il ramo e' descritto come sustaining release senza nuove funzionalita' RTL previste. Rimane utile per studiare un acceleratore convoluzionale piu' completo; non viene presentato come un'estensione ISA della CPU. La documentazione architetturale esterna non e' stata recuperata correttamente, quindi qui non si attribuiscono dettagli di bus o coerenza non verificati.

## 4. Prodotti e IP commerciali

Una IP integrabile in un SoC non e' una scheda da collegare a un PC. Allo stesso modo, un SDK aperto non rende aperto l'RTL del processore. Le prestazioni pubblicitarie non vengono usate per ordinare questi prodotti.

| Soluzione | Categoria | Perche' compete | Differenza rispetto al progetto |
| --- | --- | --- | --- |
| SiFive Intelligence XM | IP scalare/vettoriale/matriciale | Istruzioni matriciali integrate con core RISC-V | Operandi dai registri vettoriali, non un generico comando con puntatori a un layer |
| Arm Ethos-U85 | IP NPU embedded | Accelerazione di CNN e Transformer con ecosistema software | NPU di sistema, non RTL aperto o estensione RISC-V personalizzabile |
| Cadence Neo | IP NPU configurabile | Ampia gamma di MAC, formati e memoria locale, SDK | Integrazione AXI e flusso orientato all'inferenza |
| ARC NPX6 | IP NPU, originariamente Synopsys | Array MAC scalabili e toolchain per reti | Famiglia commerciale; verificare catalogo corrente dopo il passaggio a GF/MIPS |
| Tenstorrent | Chip e piattaforme programmabili | Motori matriciali, runtime e framework anche per training | Scala e integrazione diverse da una piccola unita' embedded |

### 4.1 SiFive Intelligence XM

Fonte: [pagina ufficiale XM Series](https://www.sifive.com/cores/intelligence-xm-series).

La pagina consultata descrive XM Gen 2: quattro core X300, motore matriciale basato su outer product e integrazione stretta con le unita' vettoriali. Documenta istruzioni matriciali prelevate dall'unita' scalare, operandi provenienti dai registri vettoriali e destinazioni negli accumulatori matriciali.

Sono descritti percorsi di memoria cached coerenti tra i quattro core interni e porte dedicate ad alta banda uncached. Non si estende questa affermazione a una coerenza universale con qualsiasi host esterno.

**Pertinenza molto alta per la direzione CPU+ISA matriciale.** E' pero' una IP commerciale, non un repository RTL da scaricare. L'apertura della kernel library citata dal produttore non implica apertura del motore hardware. Il supporto completo al training non viene dedotto dalla sola presenza di BF16.

### 4.2 Arm Ethos-U85

Fonte: [pagina ufficiale Ethos-U85](https://www.arm.com/products/silicon-ip-cpu/ethos/ethos-u85).

La pagina documenta configurazioni da 128 a 2048 MAC, supporto CNN/Transformer, TOSA ed ecosistema Ethos-U; cita l'integrazione con Cortex-M/A e il sottosistema Corstone-320. Il vantaggio competitivo comprende strumenti e integrazione, non soltanto il datapath.

Non e' stata verificata una pipeline completa di training on-device. La parola "training" nelle sezioni di supporto commerciale riguarda anche corsi per sviluppatori e non costituisce tale evidenza. Condizioni di licenza, prezzi e dettagli quantitativi di memoria restano da verificare.

### 4.3 Cadence Neo NPU

Fonte: [pagina ufficiale Neo](https://www.cadence.com/en_US/home/tools/silicon-solutions/ai-ip-platform/neo-npu.html).

Il produttore presenta esplicitamente accelerazione di inferenza. Le opzioni pubblicate includono 256-32k MAC, memoria locale UBUF da 16 kB a 32 MB, INT4/INT8/INT16/FP16/BF16 e interfacce AXI da 128/256/512 bit. Sono opzioni della famiglia, non una promessa che ogni combinazione sia disponibile o abbia le stesse prestazioni.

Supporta diverse famiglie di reti e applicazioni audio, voce, sensori e visione; NeuroWeave copre compilazione, quantizzazione, analisi e deployment. E' un concorrente al prodotto NPU embedded generalizzabile, non una prova che sia gia' risolta ogni forma di backward richiesta dal nostro caso.

### 4.4 ARC NPX6 e stato del fornitore

Fonti: [annuncio tecnico NPX6 del 2022, con avviso aggiornato](https://news.synopsys.com/2022-04-19-Synopsys-Introduces-Industrys-Highest-Performance-Neural-Processor-IP), [annuncio di cessione del gennaio 2026](https://news.synopsys.com/2026-01-14-Synopsys-Enters-Definitive-Agreement-with-GlobalFoundries-For-Sale-of-Processor-IP-Solutions-Business).

L'annuncio NPX6 descrive configurazioni da 4k a 96k MAC, FP16 opzionale, sparsita', scalabilita' multiistanza e ambiente MetaWare MX. E' un riferimento di famiglia commerciale, non una misura confrontabile con il nostro RTL.

La pagina tecnica consultata contiene un avviso secondo cui GlobalFoundries ha acquisito il business Processor Solutions il 1 giugno 2026, con rinvio a MIPS. L'annuncio di gennaio descriveva ancora una transazione futura: non va usato per negare l'avviso successivo. Non si assume che prezzi, marchio commerciale e disponibilita' corrente coincidano con quelli del lancio del 2022.

### 4.5 Tenstorrent

Fonti: [TT-Metal](https://github.com/tenstorrent/tt-metal), [TT-Train](https://github.com/tenstorrent/tt-metal/tree/main/tt-train).

TT-Metalium espone un modello di programmazione di basso livello per kernel e movimento dati; TT-NN offre operatori Python/C++. Sono documentati matmul multicore, riuso, multicast e supporto alle piattaforme Wormhole/Blackhole.

TT-Train documenta esplicitamente un framework di training con esempi MNIST e NanoGPT. Qui l'evidenza va oltre la semplice presenza di MAC: esiste un percorso software dichiarato di training. Non e' stato eseguito o verificato in questa ricerca.

Il software TT-Metalium/TT-NN e' Apache 2.0. Questo non significa che il chip sia disponibile come RTL sintetizzabile aperto. E' un concorrente funzionale per sistemi AI programmabili, ma non una baseline equa di area o consumo per un piccolo coprocessore embedded.

## 5. Alternative ISA e GPU

### 5.1 Intel AMX

Fonte: [guida Intel per Xeon Scalable di quarta generazione](https://www.intel.com/content/www/us/en/developer/articles/technical/tuning-guide-for-ai-on-the-4th-generation.html).

La guida documenta AMX-TILE, AMX-INT8 e AMX-BF16: otto registri bidimensionali TMM, ciascuno fino a 1 KiB, con caricamento, memorizzazione e operazioni TMUL. Sono presenti istruzioni quali `TILELOADD`, `TILESTORED` e `TDPBF16PS`.

E' un precedente commerciale molto netto per "aggiungere all'ISA operazioni matriciali accelerate". Lavora su tile, non completa automaticamente un layer arbitrario a partire da due indirizzi. La guida include flussi software per inferenza e training mixed precision. La configurazione descritta riguarda quella generazione Xeon e non esaurisce tutte le successive estensioni AMX.

### 5.2 Arm SME e SME2

Fonte: [guida Arm all'outer product con SME](https://learn.arm.com/learning-paths/cross-platform/multiplying-matrices-with-sme2/5-outer-product/).

La documentazione spiega come `FMOPA` accumuli l'outer product di due vettori in un tile dello storage ZA. Il programma costruisce la moltiplicazione matriciale mediante questi passi, con gestione di layout e caricamenti.

SME/SME2 sono estensioni architetturali: non sono un unico prodotto con una dimensione fisica fissa. Sono pertinenti per il modello di programmazione e per il riuso degli operandi. La disponibilita' e le prestazioni dipendono dalla CPU concreta; non si presume che qualunque processore Arm le supporti.

### 5.3 NVIDIA Tensor Cores e CUTLASS

Fonte: [repository ufficiale CUTLASS](https://github.com/NVIDIA/cutlass).

CUTLASS espone kernel GEMM e convoluzione, tiling, movimento dati e operazioni Tensor Core tramite istruzioni come MMA/WGMMA nelle architetture appropriate. Sono documentati diversi formati numerici e kernel con FP16 in ingresso e accumulo FP32; disponibilita' e combinazioni dipendono dalla generazione GPU.

Il repository rimanda anche a lavoro sull'accelerazione dei gradienti backward. E' quindi scorretto considerare il mondo dei motori matriciali commerciali come esclusivamente inferenziale.

CUTLASS e' software aperto, con licenza principale BSD-3-Clause, non il progetto RTL aperto dei Tensor Cores. Le GPU sono alternative d'impiego e riferimenti software, ma non un confronto diretto di costo/area con un piccolo blocco RISC-V. Il loro modello di lancio e di esecuzione va distinto dall'offload di un'istruzione della CPU host.

## 6. Cosa cambia per il nostro progetto

### 6.1 Novita' che non si possono rivendicare da sole

| Idea | Precedenti pertinenti |
| --- | --- |
| Nuove istruzioni CPU per calcolo matriciale | RedMulE, Gemmini, Intel AMX, Arm SME, SiFive XM |
| Passare indirizzi e lasciare eseguire il motore | RedMulE, SNAX-GEMM; VTA con programma autonomo |
| Usare memoria locale esplicita | Gemmini, OpenGeMM, VTA |
| Separare trasferimenti e calcolo | Gemmini, VTA, SNAX |
| Supportare convoluzioni 3x3 e canali multipli | NE16, NEureka, NVDLA, Gemmini |
| Impiegare MAC anche nel training | RedMulE; piattaforme Intel, NVIDIA e Tenstorrent |
| Servire visione, audio e altre modalita' | Motori GEMM generalisti e NPU commerciali multimodali |

Un'implementazione didattica o una piattaforma aperta ben verificata puo' avere valore anche senza inventare una nuova classe di acceleratori. Una tesi di ricerca o un prodotto competitivo richiede invece una differenza identificabile e misurabile.

### 6.2 Spazi da verificare, non vantaggi gia' dimostrati

- **Latenza su lavori piccoli e batch 1:** un controllo leggero potrebbe costare meno dell'avvio e del riempimento di un motore piu' grande; va verificato includendo trasferimenti e sincronizzazione.
- **Convoluzione diretta e dati non materializzati:** verificare il traffico evitato rispetto a un mapping che espande le patch. Non assumere che tutti i concorrenti GEMM materializzino necessariamente `im2col` in memoria esterna.
- **Datapath condiviso FW/DK/DX:** valutare se le modalita' esistenti consentano meno memoria o meno trasformazioni. La presenza delle modalita' non certifica un training funzionante, ne' costituisce da sola una novita'.
- **Convoluzione e GEMM nello stesso blocco piccolo:** studiare il costo di flessibilita' in indirizzamento, registri e controllo. Una rete di MAC comune non garantisce identica efficienza per i due dataflow.
- **Precisione di accumulo:** distinguere bit di ingresso, prodotto, somma parziale, uscita e arrotondamento; particolarmente importante per gradienti e aggiornamenti piccoli.
- **Integrazione riproducibile:** ISA/HAL, test automatici, gestione degli errori e toolchain possono rendere il progetto utilizzabile. Non sono sostituibili con una dimostrazione isolata del MAC.

Il riuso fra finestre adiacenti e' una proprieta' importante del nostro percorso convoluzionale, ma il suo valore competitivo dipende da quanti accessi vengono realmente evitati, da quanta memoria serve e dalla frequenza ottenibile.

### 6.3 Memoria e controllo

Occorre separare tre piani che le fonti trattano in modi diversi:

1. **Comando:** singola istruzione, sequenza di istruzioni, CSR, registri memory-mapped o stream di comandi.
2. **Operandi:** registri CPU/vettoriali, tile residenti, puntatori ai tensori o buffer locali pre-caricati.
3. **Movimento dati:** load della CPU, DMA, streamer, cache, scratchpad e relativo modello di coerenza/protezione.

Indirizzi fisici non eliminano i problemi di autorizzazione degli accessi, coerenza con la CPU, ordinamento e completamento. Una SRAM esplicitamente gestita non e' una cache soltanto perche' conserva dati riusati.

La presenza di un'istruzione dedicata, da sola, non dimostra un overhead minore rispetto a un comando memory-mapped. La granularita' del lavoro e il percorso effettivo dei dati sono determinanti.

## 7. Priorita' consigliate e confronto futuro

| Priorita' | Riferimento | Domanda da chiarire leggendo il progetto |
| --- | --- | --- |
| 1 | RedMulE | Quanto del nostro modello ISA/puntatori/autonomia e' gia' implementato? |
| 2 | Gemmini | Quali costi e servizi richiede un acceleratore realmente utilizzabile dal software? |
| 3 | OpenGeMM/SNAX | Quanto contano controllo, stride e memoria rispetto al numero di MAC? |
| 4 | NE16/NEureka | Quali differenze reali ha il nostro percorso convoluzionale? |
| 5 | Ara, AMX, SME | Quando una nuova estensione conviene rispetto a istruzioni gia' disponibili? |
| 6 | SiFive XM, Ethos-U85, Neo | Quale utilizzatore avrebbe una ragione concreta per scegliere una nuova IP? |

Non vengono avviati ora modelli architetturali o benchmark. Per un eventuale confronto successivo servirebbero almeno:

- Stesse forme dei tensori, batch, layout, stride, padding e gruppi.
- Stessa precisione degli ingressi e degli accumuli, con controllo dell'errore numerico.
- Misure separate di solo calcolo e tempo end-to-end, comprendendo packing, trasferimenti e attese.
- Area totale inclusa memoria, frequenza, tecnologia oppure risorse FPGA comparabili.
- Traffico verso ogni livello di memoria e utilizzo effettivo delle unita' MAC.
- Per il training, FW/DK/DX distinti e costo delle trasformazioni; optimizer e loss contabilizzati a parte se fuori dal coprocessore.
- Unita' esplicite: spesso un MAC viene contato come due operazioni nei valori TOPS, ma la convenzione va verificata per ciascuna fonte.
- Versioni fissate di RTL, software e strumenti, senza confrontare risultati di configurazioni diverse sotto lo stesso nome commerciale.

## 8. Conclusione

Il riferimento immediato non e' soltanto una grande GPU: esistono progetti aperti piccoli o configurabili molto vicini all'integrazione immaginata. **RedMulE, Gemmini e OpenGeMM/SNAX sono la shortlist principale; NE16/NEureka completa il confronto sul datapath convoluzionale.**

Una direzione plausibile da investigare e' un coprocessore MAC compatto e verificabile, con basso costo di controllo e movimento dati per un insieme ben definito di convoluzioni e prodotti matriciali, eventualmente includendo i gradienti. Rimane un'ipotesi di posizionamento: questa ricerca non dimostra ne' superiorita' prestazionale del progetto attuale, ne' una nicchia commerciale libera.

## 9. Prezzi commerciali

Approfondimento del 2026-11-10. Importi in USD come riportati nelle fonti, senza conversione valutaria. Non sono preventivi consegnati in Italia: IVA, eventuali dazi, spedizione, configurazione, disponibilita' e condizioni del rivenditore possono cambiare il totale.

### 9.1 IP da integrare in un SoC

| IP | Prezzo pubblico verificato | Fonte e percorso commerciale |
| --- | --- | --- |
| SiFive Intelligence XM | Non trovato; da richiedere su preventivo | [Pagina XM con Contact Sales](https://www.sifive.com/cores/intelligence-xm-series) |
| Arm Ethos-U85 | Non trovato; condizioni da concordare con Arm | [Pagina Ethos-U85 con contatto commerciale e richiamo a Flexible Access](https://www.arm.com/products/silicon-ip-cpu/ethos/ethos-u85) |
| Cadence Neo | Non trovato; da richiedere su preventivo | [Pagina Neo e Contact Us](https://www.cadence.com/en_US/home/tools/silicon-solutions/ai-ip-platform/neo-npu.html) |
| MIPS ARC NPX6 | Non trovato; da richiedere al fornitore | [Pagina corrente della famiglia NPX](https://mips.com/processor-solutions/arc-npx-family/) |

Non sono componenti acquistabili al dettaglio con un unico prezzo per scheda. Un'offerta IP deve chiarire configurazione, diritti di utilizzo, numero di progetti, supporto, strumenti inclusi ed eventuali royalty. Non sono state ottenute le condizioni contrattuali specifiche di questi prodotti: non si attribuiscono loro cifre o modelli tariffari non pubblicati.

Il costo della licenza non include automaticamente progettazione del SoC, verifica, strumenti EDA, produzione, packaging e collaudo. Un programma di accesso per valutazione o prototipazione non equivale necessariamente a una licenza di produzione senza ulteriori costi.

### 9.2 Schede e CPU con prezzi pubblicati

| Prodotto | Prezzo pubblicato in USD | Cosa comprende il riferimento |
| --- | --- | --- |
| Tenstorrent Blackhole p100a | 999 | Scheda PCIe con 28 GB GDDR6 e raffreddamento attivo; host escluso |
| Tenstorrent Blackhole p150a / p150b | 1.399 ciascuna | Scheda PCIe con 32 GB GDDR6; attiva / passiva; host escluso |
| Tenstorrent Wormhole n150s / n150d | 999 / 1.099 | Scheda PCIe; raffreddamento passivo / attivo; host escluso |
| Tenstorrent Wormhole n300s / n300d | 1.399 / 1.449 | Scheda PCIe; raffreddamento passivo / attivo; host escluso |
| NVIDIA GeForce RTX 5090 | A partire da 1.999 | Prezzo iniziale indicato dalla pagina USA, non garanzia del prezzo del rivenditore; PC escluso |
| Intel Xeon Silver 4410Y, con AMX | 676-686 | Recommended Customer Price del solo processore; non un server completo o un'offerta di vendita |

Fonti primarie: [catalogo Tenstorrent](https://tenstorrent.com/hardware/cards), [pagina NVIDIA RTX 5090](https://www.nvidia.com/en-us/geforce/graphics-cards/50-series/rtx-5090/), [specifiche Intel Xeon Silver 4410Y](https://www.intel.com/content/www/us/en/products/sku/232376/intel-xeon-silver-4410y-processor-30m-cache-2-00-ghz/specifications.html).

Il catalogo Tenstorrent consultato indica schede disponibili con spedizione in circa due settimane e transito di 2-5 settimane; non e' stata verificata la consegna verso uno specifico indirizzo italiano. Il raffreddamento passivo richiede un flusso d'aria adeguato nel sistema. Non sono stati effettuati acquisti o richiesti preventivi.

AMX e SME non hanno un prezzo al dettaglio autonomo: sono capacita' del processore. Il 4410Y e' un esempio verificato di CPU con AMX, non la dimostrazione che sia l'opzione piu' economica o piu' appropriata. Il costo di piattaforma comprende anche scheda madre, RAM, alimentazione e raffreddamento.

### 9.3 Un riferimento embedded, con prezzo storico

L'[annuncio NVIDIA del 17 dicembre 2024](https://blogs.nvidia.com/blog/jetson-generative-ai-supercomputer/) indica **249 USD** per Jetson Orin Nano Super Developer Kit, comprendente SoM da 8 GB e carrier board. E' un ulteriore riferimento embedded, non una IP RTL riutilizzabile.

Il prezzo e' verificato nell'annuncio, non come offerta acquistabile oggi in Italia. Il percorso corrente di acquisto ha reindirizzato a un marketplace senza che questa ricerca ne verificasse un prezzo finale. Non si presume quindi che 249 USD sia il costo attuale comprensivo di imposte, consegna e accessori.

### 9.4 Lettura economica

I dati disponibili consentono di confrontare prezzi pubblicati di schede e processori; non consentono di stimare il costo industriale delle IP concorrenti. Per il nostro progetto occorre distinguere l'eventuale vendita di una scheda, confrontabile con altre schede a parita' di sistema, dalla concessione in licenza del blocco hardware, confrontabile con IP e relativi costi d'integrazione.
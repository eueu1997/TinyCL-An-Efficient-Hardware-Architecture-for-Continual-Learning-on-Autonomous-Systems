# myHWModel

## Guida allo snapshot

Workspace sperimentale di accelerazione convoluzionale: percorso forward (FW),
gradiente dei pesi (DK) e gradiente degli input (DX), memorie e aritmetica
fixed-point. Non e' un acceleratore GDumb completo certificato: il modulo
`GDumb` e' sperimentale e non fa parte del flusso di simulazione principale.

Guide locali dettagliate: [RTL](src/README.md), [testbench](tb/README.md),
[sintesi](syn/README.md), [archivio](other%20files/README.md) e
[libreria Questa](work/README.md). Ogni sottocartella documenta anche prodotti
generati, input/output e limiti. La guida inglese originaria qui sotto resta
come contesto; le precisazioni finali descrivono lo stato effettivo dei sorgenti.

Per simulare occorrono Questa/ModelSim SystemVerilog e licenza valida; per la
sintesi Design Compiler e librerie tecnologiche compatibili. WSL da solo non
fornisce questi strumenti. Configurare installazione/licenza senza pubblicare
credenziali, adattare i percorsi assoluti in script e SRAM e lavorare da questa
directory. In una sessione Questa configurata, creare/mappare `work` se manca:

```tcl
vlib work
vmap work work
do resim_py.tcl
```

La ricetta batch esegue `NN_tb` per 245785 ns e termina il simulatore. Gli output
sono transcript, waveform e dump di memoria; non sono automaticamente un
resoconto pass/fail. Prima di rigenerarli conservare i risultati storici utili.
Le directory `work` sono rigenerabili **con tool e sorgenti adeguati**, ma non
vanno cancellate mentre Questa le usa. Non sono state eseguite simulazioni o
sintesi durante questa documentazione.

SystemVerilog hardware model + simulation + synthesis workspace.

At a high level, this folder contains:

- **RTL** for a convolution-like processing block (forward + backward paths) built around a grid of MACs and a behavioral SRAM model.
- **Questa/ModelSim simulation scripts** (`*.tcl`, `init*.sh`) to compile and run the main testbench.
- **Testbenches and vectors** under `tb/` (including file-based hex vectors used by the SRAM model).
- **Synthesis scripts/artifacts** under `syn/` (Synopsys Design Compiler flow).

> Important portability note
>
> Many scripts and the behavioral SRAM model contain **hardcoded absolute Linux paths** like `/home/thesis/eugenio.ressa/Desktop/myHWModel/...`.
> On Windows, you’ll typically run these flows via **WSL/Linux**, or you’ll need to edit paths to be relative.

---

## Folder map (what’s where)

### `src/` — RTL (SystemVerilog)
This is the main hardware implementation.

Key top-level modules:

- `src/NN.sv`
  - **Top module** instantiated by the main testbench.
  - Orchestrates forward + backward phases, with control/stall logic.
  - Instantiates the main processing unit (`FW_BW_PU`).

- `src/FW_BW_PU.sv`
  - **Processing unit** that wires together address managers, register banks, and the MAC grid.
  - Contains the datapath selection/muxing between forward and backward sub-modes.
  - Uses a multi-operand adder (Dadda tree) for reduction.

Subfolders:

- `src/MAC/`
  - `MAC.sv`: fixed-point multiply-accumulate element (supports different “select” modes for FW/DX vs DK-style accumulation).
  - `MultiOpAdderDadda.sv`: `dadda_top` compressor/reduction tree used by the PU.
  - (Also compiled by the sim scripts: `adder.sv`, `multiplier.sv`.)

- `src/FW/`
  - Forward-path building blocks:
    - `FWAddrManager.sv`: generates address patterns (including snake-scan style traversal).
    - `featureRegisters.sv`: feature map shift/register handling.
    - `kernelsRegisters.sv`: kernel window register handling.

- `src/BW/`
  - Backward-path building blocks:
    - `AddrManagerBWDK.sv`: address/control for DK-like iteration.
    - `gradientInRegisterBWDK.sv`: pipeline/register staging for gradient (dy) values.
    - `AddrManagerBWDX.sv`, `featureRegistersBWDX.sv`, `kernelRegisterBWDX.sv`: support for DX/backward data movement.
    - `register.sv`: generic register primitive.

- `src/memory/`
  - `SRAM.sv`: **behavioral SRAM** model.
    - Uses `$readmemh`/`$writememh` to load/store vectors.
    - Supports different modes via `MEMORY_TYPE` (e.g., used as “GDUMB” memory in `NN_tb.sv`).
    - **Hardcoded absolute Linux paths** point into `tb/files/...`.

- `src/activation/`
  - `activation.sv`: activation function block (compiled by the sim scripts).

- `src/GDumb.sv`
  - Appears to be an experimental/partial module related to “GDumb” ideas.
  - Not compiled by default in the main `resim*.tcl` flows (it’s commented out there).

---

### `tb/` — testbenches + vector generation/validation
Primary purpose: drive simulation, provide/consume file-based stimuli, and validate arithmetic.

Key files:

- `tb/NN_tb.sv`
  - **Main testbench** used by `resim_py.tcl` / `resim.tcl`.
  - Instantiates `NN` and SRAM instances configured as GDumb-like memory channels.
  - Provides clock/reset stimulus and runs for ~245.78 µs (as specified in TCL scripts).

- `tb/FW_BW_tb.sv`
  - Older / more detailed unit-level testbench for `FW_BW_PU`.
  - Uses `$readmemh/$writememh` for kernels/feature/gradient vectors.
  - (May require cleanup/updates to run depending on current RTL changes.)

- `tb/MAC.py`
  - Python helper to sanity-check fixed-point / two’s complement MAC arithmetic.

- `tb/convEvaluetor.py`
  - Python script to evaluate/compare convolution forward/backward behavior against expected/reference computations.
  - Also contains Linux-path assumptions for logging/output.

- `tb/files/`
  - **Simulation vectors and dumps** used by `SRAM.sv` and/or testbenches.
  - Structure highlights:
    - `tb/files/kernels_in/`: kernel windows used as inputs (many `X_Y.txt` plus “_float” variants).
    - `tb/files/kernels_out/`: kernel dumps/outputs.
    - `tb/files/gradients_in/`: gradient inputs (dy), including “_float” and “_2” variants.
    - `tb/files/gradients_out/`: gradient outputs.
    - `tb/files/gdumbs/`: GDumb memory contents (e.g., `0.txt`, `1.txt`, `2.txt` + float variants).
    - `tb/files/feature_out/`: feature output dumps (`0.txt`…`7.txt`).
    - Various diff/compare artifacts like `diffKernel*.txt`, `diffGradient*.txt`, `featureOutDiff0.txt`, etc.

- `tb/Carry-Lookahead-Adder-Cocotb/`
  - Present but currently empty in this workspace snapshot.

---

### `syn/` — synthesis (Design Compiler) flow + reports
Contains scripts and artifacts for synthesis.

- `syn/init_syn.sh`
  - Sources a Design Vision / DC environment init script (hardcoded Linux path), cleans/creates `syn/work`, and runs DC.

- `syn/resyn.bash`
  - Small wrapper that sources `syn/resin.tcl`.

- `syn/resin.tcl`
  - Main synthesis script (DC TCL) used by the wrapper.

- `syn/work/`, `syn/report/`, and other generated outputs
  - Placeholders for DC run products and reports.

---

### `work/` — simulator work library (generated)
Questa/ModelSim compilation outputs (e.g., `work` library, intermediate compile products). Safe to delete and re-generate.

---

## How simulation is wired

### Main compile+run scripts

- `init.sh`
  - Bash wrapper that sources `init_questa` then runs Questa in batch:
    - `vsim -batch -do .../resim_py.tcl`

- `init_questa`
  - Exports Questa install path + license variables and sources a vendor setup script.
  - As written, it assumes a university/EDA lab Linux environment.

- `resim_py.tcl`
  - Batch simulation recipe:
    - `vlog` compiles a fixed list of RTL files (MAC, activation, FW, memory, BW, then `FW_BW_PU.sv`, `NN.sv`, `tb/NN_tb.sv`).
    - Launches `vsim work.NN_tb` and runs `245785 ns`.
    - Exits.

- `resim.tcl`
  - Similar to `resim_py.tcl` but adds waves for interactive debug and runs `245775 ns`.

### Where vectors come from
The behavioral SRAM model (`src/memory/SRAM.sv`) uses `$readmemh`/`$writememh` with hardcoded paths into `tb/files/...`.

If you move the repo, or you are on Windows, you’ll need to either:

- run in a Linux-like environment where those paths exist, or
- edit `SRAM.sv` (and possibly the TCL scripts) to use relative paths.

---

## Running it (practical notes)

### Option A: Run in the original intended environment (Linux + Questa)
1. Ensure Questa/ModelSim is installed and licensed.
2. Update `init_questa` to match your install + license server.
3. From `myHWModel/`, run:
   - `bash init.sh`

### Option B: Windows developer workflow
Most of this hardware flow is **Bash/TCL + Linux-path-based**.

Common workable setups:

- **WSL2 (Ubuntu) + Questa Linux install** (if you have access)
- A Linux VM
- A remote Linux server (campus EDA machine)

If you want this to run natively on Windows, the fastest path is usually:

- Convert absolute `/home/thesis/.../myHWModel/...` references in:
  - `init.sh`, `resim_py.tcl`, `resim.tcl`, `syn/init_syn.sh`, and `src/memory/SRAM.sv`
  - into **relative paths** rooted at the repo.

---

## Suggested reading order (if you’re new here)

1. `tb/NN_tb.sv` (what gets instantiated and what memories exist)
2. `src/NN.sv` (top-level control)
3. `src/FW_BW_PU.sv` (datapath wiring)
4. `src/MAC/MAC.sv` + `src/MAC/MultiOpAdderDadda.sv` (compute core)
5. `src/memory/SRAM.sv` (how vectors are loaded/dumped)
6. `resim_py.tcl` (the authoritative compile order)

---

## Known “sharp edges”

- Hardcoded Linux paths are pervasive (scripts + SRAM + some Python utilities).
- `src/GDumb.sv` is not part of the default compile flow and appears experimental.
- Some testbenches/utilities may be older than the current RTL and might require minor fixes if you try to run them.

## Possibili bug e limiti rilevati

- **RTL non unico:** `src` e `syn/src` differiscono in controllo, registri,
  MAC e SRAM. Un report di sintesi non certifica l'RTL simulato corrente.
- **Sintesi incompleta nello script:** [resin.tcl](syn/resin.tcl) seleziona
  `FW_BW_PU` ed elabora; clock, link, compile, report ed export sono commentati.
- **Parametrizzazione parziale:** MAC accede esplicitamente agli operandi 0..7,
  usa sommatori a 32 bit e slice `[19:4]`; cambiare `NOperands`/`NBit` non rende
  automaticamente coerente il circuito. Anche NN contiene dimensioni fisse.
- **Clock e controllo:** NN genera `clk_stalled` con logica combinatoria; il
  rischio di glitch/timing va verificato con vincoli e metodologia di clock
  gating appropriati. I TODO del sorgente segnalano ancora stride, prefetch,
  stall durante DK e derivata ReLU nel backward: non sono funzionalita' validate.
- **SRAM:** default `MEMORY_TYPE="GDUMB_MEM"` non gestito dal modello, che
  accetta `GDUMB`, `KERNEL`, `GRADIENT`, `FEATURE`; con default termina. Il reset
  puo' scrivere dump prima di caricare la memoria, includendo stati sconosciuti.
- **Cocotb:** [Makefile](tb/MAC/Makefile) riassegna tre volte `VERILOG_SOURCES`
  anziche' accumulare i file. [test_MAC.py](tb/MAC/test_MAC.py) non confronta con
  assert i risultati e crea liste con oggetti BinaryValue condivisi.
- **Scale numeriche:** il test Cocotb usa scala 4096, mentre il MAC corrente
  seleziona bit `[19:4]`; la convenzione fixed-point va riconciliata prima di
  interpretare i confronti. Overflow e perdita di precisione non sono gestiti
  come errori nel datapath letto.
- Percorsi assoluti e durate fisse rendono i flussi dipendenti dall'ambiente e
  dalla configurazione. Il solo exit del simulatore non prova il completamento
  corretto di tutte le fasi. Rilievi statici; nessun esito EDA nuovo e' dichiarato.

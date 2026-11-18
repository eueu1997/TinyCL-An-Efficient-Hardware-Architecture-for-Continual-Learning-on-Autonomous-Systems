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

---

## NN hierarchy syntax and compilation analysis (2026-11-11)

### Verdict

**The default NN hierarchy passes SystemVerilog parsing and elaboration, but it is not free of design problems.** Compilation errors were also confirmed when increasing `NLAYER` without supplying matching parameter arrays.

Rather than only inspecting the text, an isolated **slang 12.1.0 compiler frontend** was installed to check [NN.sv](src/NN.sv), its dependencies, and [NN_tb.sv](tb/NN_tb.sv), using the source list from [resim.tcl](resim.tcl). **No RTL was modified.**

This validates syntax, name resolution, parameter evaluation, port connections, and hierarchy elaboration. It **does not execute clock cycles or certify numerical correctness**, and it is not a Questa/ModelSim run. Earlier statements in this README about no new EDA results describe the documentation work preceding this analysis; this section records the subsequent slang checks only.

#### Compilation results

| Configuration | Errors | Result |
|---|---:|---|
| Default NN | **0** | Parses and elaborates; 369 non-error frontend diagnostics |
| Default main testbench | **0** | Parses and elaborates; 374 non-error frontend diagnostics |
| `NLAYER=2`, other parameters unchanged | **6** | Fails: parameter-array lengths do not match |
| `NBITS=8` | **0** | Elaborates, but introduces serious port-width mismatches |
| `N_FEATURE_READ=4`, `N_OF_CH_READ=4` | **0** | Elaborates with **152 out-of-bounds index** and **120 out-of-bounds range** diagnostics |

The diagnostic counts are not counts of independent bugs: many are repeated width, signedness, and arithmetic warnings.

### Hierarchy checked

The elaborated default design contains:

- One [FW_BW_PU](src/FW_BW_PU.sv#L1), containing:
  - FW, DK, and DX address managers.
  - Feature/kernel register banks and the gradient staging block.
  - **9 MACs**, containing **72 multipliers and 72 adders** in total.
  - **9 partial-sum registers** and one Dadda reduction block.
- **80 SRAM instances** inside NN: 64 kernel, 8 feature, and 8 gradient memories.
- One activation block.
- The testbench adds **3 external GDumb SRAMs**.

There were **no unresolved module names or invalid named-port connections** in the checked default hierarchy.

### Important findings

#### 1. Confirmed compilation failure with `NLAYER=2`

At [NN.sv:30](src/NN.sv#L30), the six feature-size arrays have only one initializer element:

```systemverilog
parameter int FEATURE_IN_ROW_SIZE [0:(NLAYER-1)] = {32};
```

Changing only `NLAYER` to 2 produces:

```text
error: array concatenation for 'int$[2]' requires 2 elements
       but 1 were provided
```

**Correction:** supply all six arrays with one value per layer, or use assignment-pattern defaults if identical layer sizes are intended:

```systemverilog
parameter int FEATURE_IN_ROW_SIZE [0:NLAYER-1] = '{default:32};
```

That resolves the initializer problem, not the other multi-layer limitations below.

#### 2. Incorrect kernel SRAM write-data connection - high-confidence wiring bug

At [NN.sv:848](src/NN.sv#L848):

```systemverilog
.writeValue(kernelWriteValue_r[i][j]),
```

Here, `i` is the **layer**, `j` is the **output channel**, and `k` is the **input channel**. However, the write buffer is declared as:

```text
kernelWriteValue_r[output_channel][input_channel]
```

The connection therefore selects the wrong dimensions and ignores `k`. With one layer, all input-channel SRAMs for a given output channel receive the same selected value.

**The corresponding connection should be:**

```systemverilog
.writeValue(kernelWriteValue_r[j][k]),
```

This is legal syntax, so compilation does not catch it.

#### 3. Kernel prefetch selects the next output channel even during initial loading

At [NN.sv:484](src/NN.sv#L484), initial `LOAD_KERNEL` with the default channel addresses selects:

```systemverilog
NewFeatureOutChAddrPreFetch = featureOutChAddrFW + 1;
```

With input-channel address 0 and output-channel address 0, this prefetches **output-channel 1's kernels**, while the output address is still 0.

Also, [NN.sv:481](src/NN.sv#L481) computes `actLayer + 1` without a last-layer guard. With `NLAYER=1`, layer index 1 is outside the kernel-memory layer range.

**Initial loading and terminal-layer transitions need explicit handling.**

#### 4. The advertised parameters do not propagate through the hierarchy

Several child modules in [FW_BW_PU.sv:122](src/FW_BW_PU.sv#L122) and [FW_BW_PU.sv:185](src/FW_BW_PU.sv#L185) are instantiated with their defaults rather than the parent's parameters.

Examples:

- MACs remain **16-bit, 8-operand** blocks.
- Partial-sum registers are explicitly **128 bits**.
- Feature/kernel banks retain their default widths.
- The activation instance at [NN.sv:1131](src/NN.sv#L1131) does not pass `NBITS`.

The eight-bit check confirmed truncation and expansion across these ports. The four-lane check confirmed extensive illegal selections because much of the logic explicitly accesses lanes 0-7.

**Current parameter declarations should not be interpreted as general configuration support.**

#### 5. Procedural constructs need correction before synthesis sign-off

| Location | Finding |
|---|---|
| [NN.sv:327](src/NN.sv#L327) | Next-state combinational logic is labeled `always_ff @(*)`. Slang accepts it, but it does not describe edge-triggered storage. Use an appropriate combinational process with complete assignments. |
| [NN.sv:1527](src/NN.sv#L1527) | `gradientInReadAddr_r` is written by two separate combinational processes, with blocking assignments in one and nonblocking assignments in the other. Consolidate into one driver. |
| [FW_BW_PU.sv:202](src/FW_BW_PU.sv#L202) | `regRst` is assigned only in DK mode, and `dxBWDX` is not assigned in the DK branch. These signals retain previous values. |
| [NN.sv:1479](src/NN.sv#L1479) | `dk_r` retains data whenever `valid` is low. This is latch-style storage, not an edge-triggered capture. Verify that this is intentional. |

These are **not reported as default compilation errors**; they are storage, scheduling, and synthesis concerns.

#### 6. Combinational clock gating can create unintended edges

At [NN.sv:208](src/NN.sv#L208), `clk_stalled` is generated combinationally from `clk` and `stall`.

If `stall` changes while `clk` is high, this can create an additional edge or shorten a pulse. Nonblocking assignments add delta-cycle scheduling effects.

**Prefer clock enables, or a proper glitch-free clock-gating structure.** Compilation alone cannot establish safe timing here.

#### 7. SRAM file access prevents a portable Windows simulation

[SRAM.sv:28](src/memory/SRAM.sv#L28) uses hardcoded Linux paths for `$readmemh` and `$writememh`.

These are not syntax errors, but memory initialization will fail unless those paths resolve. Failed reads can leave memory unknown, and the model has no explicit reset assignment for `readValue`.

#### 8. Single-layer counter width is legal but misleading

At [NN.sv:136](src/NN.sv#L136), `NLAYER=1` creates:

```systemverilog
reg [0:-1] actLayer;
```

This is a **legal two-bit range**, not a zero-width signal. Use a guarded width such as `max(1, $clog2(NLAYER))` and prevent invalid layer values.

### Saved compiler evidence

The following logs are session-local evidence outside the repository. Their links are specific to the machine where this analysis was performed and are not portable repository resources.

- [Default NN diagnostics](file:///C:/Users/Ressa/.copilot/session-state/af61486e-1985-4990-8cc3-6116fd7aa007/files/NN-diagnostics.txt)
- [Main testbench diagnostics](file:///C:/Users/Ressa/.copilot/session-state/af61486e-1985-4990-8cc3-6116fd7aa007/files/NN_tb-diagnostics.txt)
- [Confirmed two-layer compilation errors](file:///C:/Users/Ressa/.copilot/session-state/af61486e-1985-4990-8cc3-6116fd7aa007/files/NN-nlayer2-diagnostics.txt)

**Bottom line:** the default hierarchy is syntactically elaboratable with slang, but the kernel write connection and prefetch selection require attention before trusting results. Parameter overrides, inferred storage, clock gating, and file initialization also prevent a functional or synthesis "clean bill of health."

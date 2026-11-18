# MSThesis

This folder is a snapshot of code + experiment artifacts used during my MSc thesis work.
It contains:

- A PyTorch implementation/variant of the **GDumb** continual learning baseline (and two modified copies).
- Multiple experiment scripts and many saved logs from prior runs.
- A separate “from-scratch” (NumPy) neural-network implementation (layers like Conv/BN/ReLU/FC).
- Prototype CNN simulators and a hardware (SystemVerilog/Questa/Synopsys) model workspace.

For further information about the architecture, you can refer to this link https://arxiv.org/abs/2402.09780 , where you can find the article of the research.
---

## Repository map

### Core continual-learning code (GDumb)

- `srcGDUMB/`
  - Main PyTorch training entrypoint: `main.py`
  - Argument parser / experiment config: `opts.py`
  - Data pipeline and memory sampling (class-balanced greedy memory): `dataloader.py`
  - Utilities: logging, accuracy computation, CutMix augmentation, seeding: `utils.py`
  - Model definitions under `models/` (MNIST/CIFAR/ImageNet-style)
  - `experiments.sh`: example commands for running benchmark sweeps
  - `clean.sh`: deletes `__pycache__` folders

- `srcGDUMB_mod/`
  - A modified copy of `srcGDUMB` (contains its own `main.py`, `opts.py`, etc.).

- `srcGDUMB_myModel_inserted/`
  - Another modified copy of `srcGDUMB` (apparently used to integrate experiments with the custom model code).

### Experiment wrappers

- `scripts/`
  - Bash scripts to run sweeps for CIFAR100/ImageNet100 and replication runs.
  - These expect a bash environment (WSL or Git Bash on Windows).

### Data / outputs

- `data/`
  - Local dataset storage.
  - For torchvision datasets (MNIST/CIFAR/SVHN…), PyTorch can download into this folder.
  - For ImageFolder datasets (e.g. ImageNet-style), the expected structure is:

    ```text
    data/<DatasetName>/train/<class_name>/*.jpg
    data/<DatasetName>/test/<class_name>/*.jpg
    ```

- `logs/`
  - Saved experiment logs from past runs (many folders).
  - The training code writes `checkpoint.log` inside `--log_dir/<exp_name>/`.
  - If pretraining is enabled, it writes a `pretrained_model.pth.tar` under `--log_dir/<old_exp_name>/`.

- `graphs/`
  - Plot outputs (accuracy curves, etc.).
  - Caveat: some code currently saves plots to a hardcoded Linux path.

### Custom model code (NumPy)

- `myModel/`
  - From-scratch building blocks and small models:
    - `BatchNorm1d.py`, `BatchNorm2d.py`
    - `Conv2dLayer.py`, `FCLayer.py`, `ReLU.py`
    - `CrossEntropyLoss.py`
    - `MLPOnMNIST.py` (manual forward/backprop training loop)
    - `ResNetOnCIFAR.py` (placeholder/comment)

- `myModelTestWorking/`
  - A separate, self-contained mini-project focused on BatchNorm (NumPy) and reproducing MNIST results.
  - See its own README: `myModelTestWorking/README.md`
  - Has its own `requirements.txt`.

### Simulation / hardware

- `myCNNSimulator/`
  - Prototypes for CNN/MAC simulation:
    - `myCNN.py` (NumPy-based conv/backprop experiments; also uses torch/torchvision for CIFAR10 loading)
    - `myCNN_TF.py` (TensorFlow/Keras experiment script)

- `myHWModel/`
  - Hardware-model workspace (SystemVerilog + ModelSim/Questa + Synopsys DC scripts).
  - Contains `init.sh`, various `.tcl` scripts, `src/`, `tb/`, `syn/`, and simulator work products.
  - Many scripts reference hardcoded Linux paths.

---

## How to run the GDumb training code

### 1) Environment (Python)

There is no single pinned requirements file for the GDumb code in this repo, but `srcGDUMB/main.py` imports at least:

- `torch`, `torchvision`
- `numpy`
- `matplotlib`

Suggested setup (Windows PowerShell):

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -U pip
python -m pip install torch torchvision numpy matplotlib tqdm
```

> If you want GPU acceleration, install the correct CUDA-enabled PyTorch build for your system (follow PyTorch’s official install command).

### 2) Important runtime caveats

- **CUDA is assumed in the training loop**: `srcGDUMB/main.py` does `model = model.half().cuda()`.
  - If you run without an NVIDIA GPU/CUDA, you’ll need to modify the code to support CPU (or remove `.cuda()` / `.half()`).

- **Default paths are Linux-specific** in `opts.py` (e.g. `/home/thesis/...`).
  - On Windows, always pass `--data_dir` and `--log_dir`.

### 3) Run a minimal example

From the repo root:

```powershell
cd srcGDUMB
python main.py --dataset CIFAR100 --num_classes_per_task 5 --num_tasks 20 --memory_size 2000 --num_passes 256 --regularization cutmix --model ResNet --depth 32 --exp_name CIFAR100_test --data_dir ..\data --log_dir ..\logs
```

This will:

- Download CIFAR100 into `data/` (if missing)
- Create a log folder at `logs/CIFAR100_test/`
- Write training/test progress to `logs/CIFAR100_test/checkpoint.log`

### 4) Running the provided bash scripts

Many sweeps are encoded as bash scripts such as:

- `srcGDUMB/experiments.sh`
- `scripts/replicate.sh`
- `scripts/cifar100_formB2.sh`, `scripts/cifar100_formB3.sh`
- `scripts/imagenet100_formB3.sh`

On Windows you can run them via **WSL**:

```bash
cd srcGDUMB
bash experiments.sh 0
```

(Those scripts expect a positional `SEED` argument.)

---

## Notes on results/artifacts

- The `logs/` folder currently contains many historical runs; treat it as an experiment archive.
- Plot saving in `srcGDUMB/main.py` uses a hardcoded absolute Linux path. If you want plots to be saved inside this repo, update that `fig.savefig(...)` path to something under `graphs/`.

---


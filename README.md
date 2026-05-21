# 🚀 Jetson Orin Nano — Dev Environment Setup

A one-stop interactive Bash script that installs and validates a full deep learning stack on Jetson Orin Nano.

> 🌐 [繁體中文版](./README_zh-TW.md)

- **Target**: JetPack 6.2 / L4T R36.4.x / R36.5.x
- **Python**: 3.10 (Miniconda, isolated conda env)
- **Last updated**: 2026-05-20

---

## 📋 Requirements

| Item | Requirement |
|------|-------------|
| JetPack | 6.2 (L4T R36.4.x / R36.5.x) |
| Swap space | ≥ 8 GB (required for OpenCV CUDA build) |
| Free disk | ≥ 20 GB recommended |
| Network | Required for apt, wget, pip |

---

## 📦 Required Wheel Files

Download these Jetson-specific `.whl` files and place them in `~/packages/jetson_wheels/` before running the script.

| Package | Source | Filename pattern |
|---------|--------|-----------------|
| PyTorch | [Jetson AI Lab](https://pypi.jetson-ai-lab.io/jp6/cu126) | `torch-*-cp310-cp310-manylinux*_aarch64.whl` |
| Torchvision | [Jetson AI Lab](https://pypi.jetson-ai-lab.io/jp6/cu126) | `torchvision-*-cp310-cp310-manylinux*_aarch64.whl` |
| Torchaudio | [Jetson AI Lab](https://pypi.jetson-ai-lab.io/jp6/cu126) | `torchaudio-*-cp310-cp310-manylinux*_aarch64.whl` |
| ONNX Runtime GPU | [Jetson AI Lab](https://pypi.jetson-ai-lab.io/jp6/cu126) | `onnxruntime_gpu-*-cp310-cp310-linux_aarch64.whl` |
| CUDA Python | [Jetson AI Lab](https://pypi.jetson-ai-lab.io/jp6/cu126) | `cuda_python-*-cp310-cp310-linux_aarch64.whl` |
| CuPy (CUDA 12x) | [Jetson AI Lab](https://pypi.jetson-ai-lab.io/jp6/cu126) | `cupy_cuda12x-*-cp310-cp310-manylinux*_aarch64.whl` |

> **Note**: `cv2` and `tensorrt` are **not** installed via pip. The script links them from the system `/usr/lib/python3.10/dist-packages/` using symlinks.

Pre-downloaded wheels are available in the shared Google Drive folder:
📁 [Google Drive — Jetson Wheels](https://drive.google.com/drive/folders/1zOi0G1CkETV6aR9FI9y4iTQOurEH2T1v?usp=sharing)

---

## 🚀 Quick Start

```bash
# 1. Clone or download the script
chmod +x jetson_setup.sh

# 2. (Optional) Set a custom conda env name — default is "tools"
export CONDA_ENV=tools

# 3. (Optional) Set OpenCV script SHA256 for supply chain safety
export OPENCV_SCRIPT_SHA256=<sha256_hash>

# 4. Run
bash jetson_setup.sh
```

---

## 🛠 Menu Options

```
🛠  Jetson Orin Nano - Setup Menu
p) 🔍 Preflight check  (wheels / swap / disk)
1) 🔧 System base      (snap fix + Chinese input)
2) 🔄 System update    (apt update + jtop fix)
3) 📷 OpenCV CUDA      (full rebuild, takes ~2hr)
4) 🐍 Conda env        (create env + symlinks)
5) 📦 Package install  (wheels + pip packages)
v) ✅ Validate         (check all packages + GPU)
a) ⚡ Run all          (p -> 1 -> 2 -> 3 -> 4 -> 5 -> v)
q) 👋 Quit
```

**Recommended order for a fresh device**: `p` → `a`

Run `p` first to catch missing wheels or insufficient swap before committing to the full install.

---

## 🔍 Step Details

### `p` — Preflight Check
Validates the environment before any install begins. Checks:
- All 6 required `.whl` files are present in `PACKAGES_DIR`
- Swap space ≥ 8 GB (hard requirement for OpenCV build)
- `OPENCV_SCRIPT_SHA256` is set (optional but recommended)
- Free disk ≥ 20 GB

The `a` (run all) flow will **abort** if preflight fails.

---

### `1` — System Base
- Pins Snap to revision 24724 and holds it from auto-updating
- Installs `ibus-pinyin` and `ibus-chewing` for Chinese input

---

### `2` — System Update & jtop Fix
- Runs `apt update`
- Installs `jetson-stats` (`jtop`)
- Patches `jetson_variables.py` to add missing JetPack version mappings for L4T R36.4.x:

  | L4T | JetPack |
  |-----|---------|
  | 36.4.0 | 6.2 |
  | 36.4.3 | 6.2 |
  | 36.4.4 | 6.2.1 |
  | 36.4.7 | 6.2.1 |

---

### `3` — OpenCV CUDA Build (~2 hours)
- Removes existing `libopencv*` packages
- Downloads the [Qengineering OpenCV 4.11 build script](https://github.com/Qengineering/Install-OpenCV-Jetson-Nano)
- Verifies SHA256 checksum if `OPENCV_SCRIPT_SHA256` is set
- Runs the full CMake + make build
- Auto-verifies CUDA and cuDNN are enabled after build

> ⚠️ Requires ≥ 8 GB swap. Create swap if needed:
> ```bash
> sudo fallocate -l 8G /swapfile && sudo chmod 600 /swapfile
> sudo mkswap /swapfile && sudo swapon /swapfile
> ```

---

### `4` — Conda Environment & Symlinks
- Installs Miniconda3 (aarch64) if not present
- Creates conda env `tools` with Python 3.10
- Creates symlinks into the conda `site-packages`:

  | Package | Source | Method |
  |---------|--------|--------|
  | `cv2` | `/usr/lib/python3.10/dist-packages/cv2` | symlink |
  | `tensorrt` | `/usr/lib/python3.10/dist-packages/tensorrt*` | symlink |
  | `cupy` | `/usr/lib/python3.10/dist-packages/cupy*` | symlink (if present) |

- Verifies each symlink with a live `import` test after creation

---

### `5` — Package Install

Installs packages in a strict order to avoid dependency conflicts:

| Stage | What | How |
|-------|------|-----|
| 1/6 | `numpy==1.23.5` | pip (pinned) |
| 2/6 | torch, torchvision, torchaudio, onnxruntime_gpu, cuda_python, cupy_cuda12x | local `.whl` with `--no-deps` |
| 3/6 | scikit-learn, ultralytics, easyocr | pip (`--no-deps` for ultralytics/easyocr) |
| 4/6 | Pillow, pyyaml, psutil, matplotlib, polars | pip |
| 5/6 | `numpy==1.23.5` | `--force-reinstall` (re-pin after above) |
| 6/6 | NumPy warning suppression | `activate.d/env_vars.sh` |

> `ultralytics` and `easyocr` are installed with `--no-deps` to prevent pip from overwriting the system `cv2` symlink.

---

### `v` — Environment Validation

Runs three checks after activating the conda env:

**Package versions** — imports each package and prints version or error:
```
  OK  torch          2.8.0
  OK  cv2            4.11.0
  OK  tensorrt       10.x.x
  NG  pycuda         not found    ← red, missing core package
  --  easyocr        not found    ← yellow, optional
```

**CUDA / GPU status**
```
  OK  CUDA Available   True
      GPU Name         Jetson Orin Nano
      GPU Memory       8.0 GB
```

**Functional tests**
```
  OK  NumPy array ops
  OK  cv2 CUDA backend
  OK  torch CUDA tensor
  OK  torch autocast
```

**ONNX Runtime GPU provider**
```
  onnxruntime: 1.24.0
  providers: ['TensorrtExecutionProvider', 'CUDAExecutionProvider', 'CPUExecutionProvider']
  OK  ONNX Runtime GPU provider available
```

---

## ⚙️ Configuration

All config variables are at the top of the script and can be overridden with `export` before running:

| Variable | Default | Description |
|----------|---------|-------------|
| `CONDA_ENV` | `tools` | Conda environment name |
| `PACKAGES_DIR` | `~/packages/jetson_wheels` | Directory containing `.whl` files |
| `PYTHON_VER` | `3.10` | Python version for conda env |
| `OPENCV_SCRIPT_SHA256` | _(empty)_ | Expected SHA256 of OpenCV build script |

```bash
# Example: use a different env name and wheel directory
export CONDA_ENV=myenv
export PACKAGES_DIR=/mnt/usb/wheels
bash jetson_setup.sh
```

---

## 🔑 Key Design Rules

- **`cv2` and `tensorrt` must never be pip-installed** on Jetson. The CUDA-enabled versions only exist in the system packages. The script enforces this by using symlinks instead of pip.
- **`numpy==1.23.5` is pinned** and re-applied at the end of install to prevent any upstream package from silently upgrading it.
- **`ultralytics` and `easyocr` use `--no-deps`** to avoid pulling in a pip-built `opencv-python` that would shadow the system cv2 symlink.
- **`conda activate` requires `eval "$(conda shell.bash hook)"`** inside Bash scripts — plain `conda activate` does not propagate to the current shell in a non-interactive script.

---

## 🐛 Troubleshooting

**`cv2` imports system version instead of CUDA build**
```bash
python -c "import cv2; print(cv2.__file__)"
# Should point to: /usr/lib/python3.10/dist-packages/cv2/...
# NOT: .../envs/tools/lib/...
```
If wrong, re-run step 4 to recreate the symlink.

**`tensorrt` import fails**
```bash
# Check the .so file exists
ls /usr/lib/aarch64-linux-gnu/libnvinfer.so*
# Add to LD_LIBRARY_PATH if missing from linker path
export LD_LIBRARY_PATH=/usr/lib/aarch64-linux-gnu:$LD_LIBRARY_PATH
```

**ONNX Runtime shows CPU provider only**

This usually means `onnxruntime_gpu` was not installed (only the CPU version). Confirm the correct wheel was placed in `PACKAGES_DIR` and re-run step 5.

**OpenCV build OOM / killed**
```bash
# Check swap
free -h
# Add 8GB swap if needed
sudo fallocate -l 8G /swapfile && sudo chmod 600 /swapfile
sudo mkswap /swapfile && sudo swapon /swapfile
```
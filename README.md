# 🚀 Jetson Orin Nano — Dev Environment Setup

> 🌐 [繁體中文](./README_zh-TW.md)

Interactive Bash installer for setting up a deep learning development environment on **NVIDIA Jetson Orin Nano**.

- **Target:** JetPack 6.2 / L4T R36.4.x / R36.5.x
- **Python:** 3.10
- **Environment:** Miniforge + Conda
- **CUDA:** JetPack-provided CUDA stack

---

## 📋 Requirements

| Item | Requirement |
|---|---|
| JetPack | 6.2 (L4T R36.4.x / R36.5.x) |
| Free disk space | ≥ 20 GB |
| Swap | ≥ 8 GB for OpenCV CUDA build |
| Internet | Required for first-run downloads |

When option `a` is selected, the installer automatically creates an additional **8 GB** swapfile at `/swapfile8` if total swap is below the required amount.

---

## 🚀 Quick Start

```bash
chmod +x jetson_setup.sh
bash jetson_setup.sh
```

For a fresh device, select:

```text
a
```

Option `a` runs the complete setup flow:

```text
auto-create swap if needed
→ auto-download and validate Jetson wheels
→ preflight check
→ system base setup
→ system update
→ OpenCV CUDA build
→ Miniforge / Conda environment
→ install Jetson wheels + cuda-python
→ environment validation
```

No separate `p` step or manual wheel / swap preparation is required.

> Destructive or security-sensitive operations still require confirmation, such as rebuilding OpenCV or running an OpenCV build script without a configured SHA256.

---

## 🛠 Setup Menu

```text
p) 🔍 Preflight check   (auto-download wheels / swap / disk)
1) 🔧 System base       (snap fix + Chinese input)
2) 🔄 System update     (apt update + jtop)
3) 📷 OpenCV CUDA       (full rebuild, ~2 hr)
4) 🐍 Conda env         (Miniforge + env + symlinks)
5) 📦 Package install   (validated wheels + pip)
v) ✅ Validate          (check packages + GPU)
a) ⚡ Run all           (auto-prepare → p → 1 → 2 → 3 → 4 → 5 → v)
q) 👋 Quit
```

---

## 📦 Jetson Wheels

The installer automatically downloads the curated **JetPack 6.2 / CUDA 12.6** wheel bundle from Google Drive when required wheels are missing.

📁 [Jetson Wheels](https://drive.google.com/drive/folders/1zOi0G1CkETV6aR9FI9y4iTQOurEH2T1v?usp=sharing)

Required wheel bundle:

- PyTorch
- Torchvision
- ONNX Runtime GPU
- CuPy CUDA 12x

`cuda-python` is installed separately from PyPI:

```text
cuda-python==12.6.2
```

Downloaded wheels are stored under:

```text
~/packages/jetson_wheels/
```

The preflight check:

- accepts Python 3.10 (`cp310`) aarch64 wheels
- accepts `linux_aarch64` and `manylinux*_aarch64` tags
- reads wheel metadata and reports package versions
- validates PyTorch / Torchvision compatibility when an exact dependency is available
- rejects ambiguous duplicate wheel versions

`gdown` is installed automatically only when a Google Drive download is required.

If system Python does not provide `pip`, an isolated environment is created at:

```text
~/.cache/jetson-setup/gdown
```

> `cv2` and `tensorrt` are not downloaded as wheels. The installer links the Jetson system packages into the Conda environment.

---

## 🐍 Miniforge / Conda

The installer uses **Miniforge** instead of Miniconda so the environment can be created directly from `conda-forge` without requiring Anaconda repository Terms of Service acceptance.

Pinned installer:

```text
Miniforge 26.5.3-0
Linux aarch64
~/miniforge3
```

The installer verifies the official SHA256 before installation and creates the `tools` environment with:

```bash
conda create -n tools --override-channels -c conda-forge python=3.10 -y
```

If an older `~/miniconda3` directory exists, it is left untouched. The setup script uses `~/miniforge3` by default.

---

## ⚙️ Configuration

| Variable | Default | Description |
|---|---|---|
| `CONDA_ENV` | `tools` | Conda environment name |
| `CONDA_HOME` | `~/miniforge3` | Miniforge installation root |
| `MINIFORGE_VERSION` | `26.5.3-0` | Pinned Miniforge release |
| `PACKAGES_DIR` | `~/packages/jetson_wheels` | Jetson wheel directory |
| `AUTO_DOWNLOAD_WHEELS` | `1` | Automatically download missing wheels |
| `GDRIVE_WHEELS_URL` | bundled Drive folder | Override the Google Drive wheel source |
| `GDOWN_VERSION` | `6.1.0` | `gdown` version |
| `CUDA_PYTHON_VERSION` | `12.6.2` | `cuda-python` version installed from PyPI |
| `AUTO_CREATE_SWAP` | `1` | Automatically add swap when required |
| `SWAPFILE_PATH` | `/swapfile8` | Auto-created swapfile path |
| `SWAPFILE_SIZE_GB` | `8` | Auto-created swapfile size |
| `OPENCV_SCRIPT_SHA256` | _(empty)_ | Optional OpenCV build-script SHA256 |

Disable automatic wheel download or swap creation if needed:

```bash
export AUTO_DOWNLOAD_WHEELS=0
export AUTO_CREATE_SWAP=0
```

---

## 📷 Basler pylon

### Download

Official Basler software download page:

📁 [Basler pylon downloads](https://www.baslerweb.com/en-us/downloads/software/)

Google Drive:

📁 [Google Drive](https://drive.google.com/drive/folders/1zOi0G1CkETV6aR9FI9y4iTQOurEH2T1v?usp=sharing)

### Install pylon 25.10.2 ARM64

Assuming the package is located in `~/Downloads`:

```bash
cd ~/Downloads

tar -xzf pylon-25.10.2_linux-aarch64_debs.tar.gz

sudo apt update

sudo apt install   ./codemeter-lite_8.20.6558.501_arm64.deb   ./pylon_25.10.2-deb0_arm64.deb
```

Verify installation:

```bash
dpkg -l | grep -Ei "pylon|codemeter"
```

---

## 🐛 Troubleshooting

### Google Drive download fails

Remove the isolated downloader environment and run option `a` again:

```bash
rm -rf ~/.cache/jetson-setup/gdown
```

The installer recreates it automatically if required.

### Legacy Miniconda exists

The installer does not remove it automatically.

Inspect both installations before deleting anything:

```bash
ls -ld ~/miniconda3 ~/miniforge3
```

### Multiple wheel versions are found

Keep exactly one compatible wheel for each required package under:

```text
~/packages/jetson_wheels/
```

Then run the installer again.

### Existing `/swapfile8` cannot be activated

The installer intentionally refuses to overwrite an existing non-swap file.

Inspect it before deleting or replacing it.

### `cv2` has no CUDA support

Check the imported OpenCV path:

```bash
python -c "import cv2; print(cv2.__file__)"
```

It should point to the Jetson system OpenCV package. If not, re-run step 4.

### `tensorrt` import fails

Set the Jetson library path:

```bash
export LD_LIBRARY_PATH=/usr/lib/aarch64-linux-gnu:$LD_LIBRARY_PATH
```

---

## 🔒 Environment Freeze

After completing the Jetson environment setup, it is recommended to freeze critical NVIDIA, CUDA, TensorRT, and Basler packages to reduce the risk of compatibility issues caused by automatic system updates.

📄 [Jetson Environment Freeze Guide](./Envfreeze.md)

---

## ⚠️ Safety Notes

The installer may perform system-level changes such as:

- creating swap space
- installing system packages
- rebuilding OpenCV
- modifying the Conda shell configuration
- linking Jetson system Python packages into the Conda environment

Review prompts carefully before confirming destructive operations.

# 🚀 Jetson Orin Nano — Dev Environment Setup

> 🌐 [繁體中文](./README_zh-TW.md)

An interactive Bash script for setting up a full deep learning stack on Jetson Orin Nano.

- **Target**: JetPack 6.2 / L4T R36.4.x / R36.5.x
- **Python**: 3.10 (Miniconda, conda env)

---

## 📋 Requirements

| Item | Requirement |
|------|-------------|
| JetPack | 6.2 (L4T R36.4.x / R36.5.x) |
| Free disk | ≥ 20 GB |
| Internet | Required for first-run wheel download |

Swap ≥ 8 GB is required for the OpenCV CUDA build. When option `a` is selected, the installer automatically adds an extra 8 GB swapfile at `/swapfile8` if total swap is too low.

---

## 📦 Jetson Wheels

The installer automatically downloads the curated JetPack 6.2 / CUDA 12.6 wheel bundle from Google Drive when required wheels are missing.

📁 [Jetson Wheels](https://drive.google.com/drive/folders/1zOi0G1CkETV6aR9FI9y4iTQOurEH2T1v?usp=sharing)

Required packages:

- PyTorch
- Torchvision
- ONNX Runtime GPU
- CUDA Python
- CuPy (CUDA 12x)

Downloaded wheels are stored under:

```text
~/packages/jetson_wheels/
```

The preflight check accepts Python 3.10 (`cp310`) aarch64 wheels using either `linux_aarch64` or `manylinux*_aarch64` tags. It reads each wheel's metadata, prints the actual package version, and verifies the PyTorch/Torchvision dependency before installation. Exactly one matching wheel per required package must be present; ambiguous multiple versions are rejected.

`gdown` is installed automatically only when a Google Drive download is required.

> `cv2` and `tensorrt` are not downloaded as wheels. The installer links the Jetson system packages into the conda environment.

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

Option `a` performs the complete bootstrap and installation flow:

```text
auto-create swap if needed
→ auto-download and validate wheels
→ preflight
→ system base
→ system update
→ OpenCV CUDA
→ conda environment
→ package install
→ validation
```

No separate `p` step or manual wheel preparation is required.

> Destructive or security-sensitive operations still request confirmation, such as rebuilding OpenCV or running the OpenCV build script without a configured SHA256.

---

## 🛠 Menu

```text
p) 🔍 Preflight check  (auto-download wheels / swap / disk)
1) 🔧 System base      (snap fix + Chinese input)
2) 🔄 System update    (apt update + jtop fix)
3) 📷 OpenCV CUDA      (full rebuild, ~2hr)
4) 🐍 Conda env        (create env + symlinks)
5) 📦 Package install  (validated wheels + pip)
v) ✅ Validate         (check packages + GPU)
a) ⚡ Run all          (auto-prepare → p → 1 → 2 → 3 → 4 → 5 → v)
q) 👋 Quit
```

---

## ⚙️ Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `CONDA_ENV` | `tools` | Conda environment name |
| `PACKAGES_DIR` | `~/packages/jetson_wheels` | Wheel directory |
| `AUTO_DOWNLOAD_WHEELS` | `1` | Automatically download missing wheels from Google Drive |
| `GDRIVE_WHEELS_URL` | bundled Drive folder | Override the Google Drive wheel folder |
| `GDOWN_VERSION` | `6.1.0` | gdown version used for automatic downloads |
| `AUTO_CREATE_SWAP` | `1` | Let option `a` automatically add swap when total swap is below 8 GB |
| `SWAPFILE_PATH` | `/swapfile8` | Auto-created swapfile path |
| `SWAPFILE_SIZE_GB` | `8` | Auto-created swapfile size in GB |
| `OPENCV_SCRIPT_SHA256` | _(empty)_ | Optional SHA256 of the OpenCV build script |

Disable automatic wheel download or automatic swap creation if needed:

```bash
export AUTO_DOWNLOAD_WHEELS=0
export AUTO_CREATE_SWAP=0
```

---

## 🐛 Troubleshooting

**Google Drive download fails**

```bash
rm -rf ~/.cache/jetson-setup/gdown
python3 -m pip install --user gdown==6.1.0
```

Then run the installer and select `a` again.

**Multiple wheel versions are found**

Keep exactly one compatible wheel for each required package under `~/packages/jetson_wheels/`, then select `a` again.

**Existing `/swapfile8` cannot be activated**

The installer intentionally refuses to overwrite an existing non-swap file. Inspect it manually before deleting or replacing it.

**cv2 has no CUDA support**

```bash
python -c "import cv2; print(cv2.__file__)"
```

It should point to the Jetson system OpenCV package. If not, re-run step 4.

**tensorrt import fails**

```bash
export LD_LIBRARY_PATH=/usr/lib/aarch64-linux-gnu:$LD_LIBRARY_PATH
```

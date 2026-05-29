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
| Swap | ≥ 8 GB (required for OpenCV CUDA build) |
| Free disk | ≥ 20 GB |

---

## 📦 Wheel Files

Download the following `.whl` files from [Jetson AI Lab](https://pypi.jetson-ai-lab.io/jp6/cu126) and place them in `~/packages/jetson_wheels/`.

Or download directly from Google Drive: 📁 [Jetson Wheels](https://drive.google.com/drive/folders/1zOi0G1CkETV6aR9FI9y4iTQOurEH2T1v?usp=sharing)

- PyTorch
- Torchvision
- ONNX Runtime GPU
- CUDA Python
- CuPy (CUDA 12x)

> `cv2` and `tensorrt` do not need to be downloaded. The script automatically creates symlinks from the system path.

---

## 🚀 Quick Start

```bash
chmod +x jetson_setup.sh

# Optional: set a custom conda env name (default: tools)
export CONDA_ENV=tools

bash jetson_setup.sh
```

---

## 🛠 Menu

```
p) 🔍 Preflight check  (wheels / swap / disk)
1) 🔧 System base      (snap fix + Chinese input)
2) 🔄 System update    (apt update + jtop fix)
3) 📷 OpenCV CUDA      (full rebuild, ~2hr)
4) 🐍 Conda env        (create env + symlinks)
5) 📦 Package install  (wheels + pip)
v) ✅ Validate         (check packages + GPU)
a) ⚡ Run all          (p → 1 → 2 → 3 → 4 → 5 → v)
q) 👋 Quit
```

**Recommended for a fresh device**: run `p` first to verify the environment, then `a` for full install.

---

## ⚙️ Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `CONDA_ENV` | `tools` | Conda environment name |
| `PACKAGES_DIR` | `~/packages/jetson_wheels` | Wheel directory |
| `OPENCV_SCRIPT_SHA256` | _(empty)_ | SHA256 of the OpenCV build script |

---

## 🐛 Troubleshooting

**cv2 has no CUDA support**
```bash
python -c "import cv2; print(cv2.__file__)"
# Should point to /usr/lib/python3.10/dist-packages/cv2/...
# If not, re-run step 4
```

**tensorrt import fails**
```bash
export LD_LIBRARY_PATH=/usr/lib/aarch64-linux-gnu:$LD_LIBRARY_PATH
```
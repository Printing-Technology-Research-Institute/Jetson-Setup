# 🚀 Jetson Orin Nano — Dev Environment Setup

> 🌐 [English](./README.md)

互動式 Bash 腳本，一鍵安裝 Jetson Orin Nano 深度學習環境。

- **Target**: JetPack 6.2 / L4T R36.4.x / R36.5.x
- **Python**: 3.10 (Miniconda, conda env)

---

## 📋 環境需求

| 項目 | 需求 |
|------|------|
| JetPack | 6.2 (L4T R36.4.x / R36.5.x) |
| Swap | ≥ 8 GB（OpenCV CUDA build 必要） |
| 磁碟空間 | ≥ 20 GB |

---

## 📦 Wheel 檔案

從 [Jetson AI Lab](https://pypi.jetson-ai-lab.io/jp6/cu126) 下載以下 `.whl`，放入 `~/packages/jetson_wheels/`。

或直接從 Google Drive 下載：📁 [Jetson Wheels](https://drive.google.com/drive/folders/1zOi0G1CkETV6aR9FI9y4iTQOurEH2T1v?usp=sharing)

- PyTorch
- Torchvision
- ONNX Runtime GPU
- CUDA Python
- CuPy (CUDA 12x)

> `cv2` 和 `tensorrt` 不需下載，腳本會自動從系統路徑建立 symlink。

---

## 🚀 快速開始

```bash
chmod +x jetson_setup.sh

# 選填：自訂 conda env 名稱（預設 tools）
export CONDA_ENV=tools

bash jetson_setup.sh
```

---

## 🛠 選單

```
p) 🔍 Preflight check  (wheels / swap / disk)
1) 🔧 System base      (snap fix + 中文輸入)
2) 🔄 System update    (apt update + jtop fix)
3) 📷 OpenCV CUDA      (full rebuild, ~2hr)
4) 🐍 Conda env        (建立環境 + symlinks)
5) 📦 Package install  (wheels + pip)
v) ✅ Validate         (檢查套件 + GPU)
a) ⚡ Run all          (p → 1 → 2 → 3 → 4 → 5 → v)
q) 👋 Quit
```

**全新設備建議順序**：先跑 `p` 確認環境，再跑 `a` 全部安裝。

---

## ⚙️ 設定變數

| 變數 | 預設值 | 說明 |
|------|--------|------|
| `CONDA_ENV` | `tools` | Conda 環境名稱 |
| `PACKAGES_DIR` | `~/packages/jetson_wheels` | Wheel 目錄 |
| `OPENCV_SCRIPT_SHA256` | 空 | OpenCV build script 的 SHA256 |

---

## 🐛 常見問題

**cv2 沒有 CUDA**
```bash
python -c "import cv2; print(cv2.__file__)"
# 應指向 /usr/lib/python3.10/dist-packages/cv2/...
# 如果不對，重跑 step 4
```

**tensorrt import 失敗**
```bash
export LD_LIBRARY_PATH=/usr/lib/aarch64-linux-gnu:$LD_LIBRARY_PATH
```
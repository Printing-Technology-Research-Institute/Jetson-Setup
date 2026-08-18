# 🚀 Jetson Orin Nano — 開發環境安裝

> 🌐 [English](./README.md)

互動式 Bash 腳本，一鍵安裝 Jetson Orin Nano 深度學習環境。

- **目標環境**：JetPack 6.2 / L4T R36.4.x / R36.5.x
- **Python**：3.10（Miniconda、conda 環境）

---

## 📋 環境需求

| 項目 | 需求 |
|------|------|
| JetPack | 6.2（L4T R36.4.x / R36.5.x） |
| Swap | ≥ 8 GB（編譯 OpenCV CUDA 必要） |
| 可用磁碟空間 | ≥ 20 GB |

---

## 📦 Wheel 檔案

從 [Jetson AI Lab](https://pypi.jetson-ai-lab.io/jp6/cu126) 下載以下 `.whl`，放入 `~/packages/jetson_wheels/`。

或直接從 Google Drive 下載：📁 [Jetson Wheels](https://drive.google.com/drive/folders/1zOi0G1CkETV6aR9FI9y4iTQOurEH2T1v?usp=sharing)

- PyTorch
- Torchvision
- ONNX Runtime GPU
- CUDA Python
- CuPy（CUDA 12x）

安裝程式會接受 Python 3.10（`cp310`）的 `linux_aarch64` 與 `manylinux*_aarch64` wheel 標籤。

> `cv2` 與 `tensorrt` 不需下載，腳本會自動從系統路徑建立 symlink。

---

## 🧰 第一次執行前準備

建立 wheel 目錄：

```bash
mkdir -p ~/packages/jetson_wheels
```

確認目前 Swap：

```bash
free -h
swapon --show
```

若總 Swap 小於 8 GB，新增一個 8 GB Swap，不取代原本已存在的 Swap：

```bash
sudo fallocate -l 8G /swapfile8
sudo chmod 600 /swapfile8
sudo mkswap /swapfile8
sudo swapon /swapfile8
grep -qF '/swapfile8 ' /etc/fstab || echo '/swapfile8 none swap sw 0 0' | sudo tee -a /etc/fstab
```

`OPENCV_SCRIPT_SHA256` 為選填。若未設定，步驟 3 會在執行下載的 OpenCV 編譯腳本前要求手動確認。

---

## 🚀 快速開始

```bash
chmod +x jetson_setup.sh

# 選填：自訂 conda 環境名稱（預設 tools）
export CONDA_ENV=tools

bash jetson_setup.sh
```

---

## 🛠 選單

```
p) 🔍 執行前檢查     (wheels / swap / disk)
1) 🔧 系統基礎設定    (snap fix + 中文輸入)
2) 🔄 系統更新        (apt update + jtop fix)
3) 📷 OpenCV CUDA     (完整重新編譯，約 2 小時)
4) 🐍 Conda 環境      (建立環境 + symlinks)
5) 📦 套件安裝        (wheels + pip)
v) ✅ 環境驗證        (檢查套件 + GPU)
a) ⚡ 全部執行        (p → 1 → 2 → 3 → 4 → 5 → v)
q) 👋 離開
```

**全新設備建議順序**：先執行 `p` 確認環境，全部通過後再執行 `a`。

---

## ⚙️ 設定變數

| 變數 | 預設值 | 說明 |
|------|--------|------|
| `CONDA_ENV` | `tools` | Conda 環境名稱 |
| `PACKAGES_DIR` | `~/packages/jetson_wheels` | Wheel 目錄 |
| `OPENCV_SCRIPT_SHA256` | 空 | OpenCV 編譯腳本的 SHA256 |

---

## 🐛 常見問題

**cv2 沒有 CUDA**
```bash
python -c "import cv2; print(cv2.__file__)"
# 應指向 /usr/lib/python3.10/dist-packages/cv2/...
# 如果不對，重新執行步驟 4
```

**tensorrt import 失敗**
```bash
export LD_LIBRARY_PATH=/usr/lib/aarch64-linux-gnu:$LD_LIBRARY_PATH
```

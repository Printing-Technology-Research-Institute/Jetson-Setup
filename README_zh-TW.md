# 🚀 Jetson Orin Nano — 開發環境安裝

> 🌐 [English](./README.md)

互動式 Bash 腳本，一鍵安裝 Jetson Orin Nano 深度學習環境。

- **目標環境**：JetPack 6.2 / L4T R36.4.x / R36.5.x
- **Python**：3.10（Miniforge、conda 環境）

---

## 📋 環境需求

| 項目 | 需求 |
|------|------|
| JetPack | 6.2（L4T R36.4.x / R36.5.x） |
| 可用磁碟空間 | ≥ 20 GB |
| 網路 | 第一次自動下載時需要 |

編譯 OpenCV CUDA 需要總 Swap ≥ 8 GB。使用者選擇 `a` 時，如果目前 Swap 不足，安裝程式會自動新增 `/swapfile8` 8 GB Swap，不需要手動處理。

---

## 📦 Jetson Wheel

當必要 wheel 缺少時，安裝程式會自動從 Google Drive 下載整理好的 JetPack 6.2 / CUDA 12.6 wheel 組合，不需要手動搬移檔案。

📁 [Jetson Wheels](https://drive.google.com/drive/folders/1zOi0G1CkETV6aR9FI9y4iTQOurEH2T1v?usp=sharing)

Google Drive 內的套件：

- PyTorch
- Torchvision
- ONNX Runtime GPU
- CuPy（CUDA 12x）

`cuda-python` 不要求放在 Google Drive。腳本會在步驟 5 建立好 Python 3.10 conda 環境後，自動從 PyPI 安裝 `cuda-python==12.6.2`。

下載後會存放於：

```text
~/packages/jetson_wheels/
```

執行前檢查會接受 Python 3.10（`cp310`）aarch64 的 `linux_aarch64` 與 `manylinux*_aarch64` wheel 標籤，並讀取每個 wheel 的 metadata、顯示實際版本，確認 PyTorch 與 Torchvision 的版本相依是否一致。每個 Google Drive 必要套件只能存在一個符合的 wheel；若有多個版本，腳本會中止而不會任意選擇安裝。

只有需要從 Google Drive 下載時，腳本才會自動安裝 `gdown`。若系統 Python 沒有 `pip`，腳本會自動改用 `~/.cache/jetson-setup/gdown` 內的獨立 venv。

> `cv2` 與 `tensorrt` 不會下載 wheel，腳本會將 Jetson 系統套件連結至 conda 環境。

---

## 🐍 Conda / Miniforge

腳本改用 Miniforge，不再使用 Miniconda。Miniforge 預設使用 conda-forge，因此建立環境時不需要接受 Anaconda 預設 repository 的 Terms of Service。

目前固定版本：

```text
Miniforge 26.5.3-0
Linux aarch64
~/miniforge3
```

安裝前會驗證官方 SHA256，之後使用：

```bash
conda create -n tools --override-channels -c conda-forge python=3.10 -y
```

若系統已存在舊的 `~/miniconda3`，腳本不會自動刪除，只會改用 `~/miniforge3`。

---

## 🚀 快速開始

```bash
chmod +x jetson_setup.sh
bash jetson_setup.sh
```

全新設備直接選：

```text
a
```

`a` 會自動完成整個準備與安裝流程：

```text
Swap 不足時自動建立
→ 自動下載並驗證 Google Drive wheels
→ 執行前檢查
→ 系統基礎設定
→ 系統更新
→ OpenCV CUDA
→ Miniforge / Conda 環境
→ 安裝 Drive wheels + 從 PyPI 安裝 cuda-python
→ 環境驗證
```

不需要先執行 `p`，也不需要手動準備 wheel 或 Swap。

> 具有破壞性或安全風險的操作仍會要求確認，例如重新編譯 OpenCV，以及未設定 SHA256 時執行下載的 OpenCV 編譯腳本。

---

## 🛠 選單

```text
p) 🔍 執行前檢查     (自動下載 wheels / swap / disk)
1) 🔧 系統基礎設定    (snap fix + 中文輸入)
2) 🔄 系統更新        (apt update + jtop)
3) 📷 OpenCV CUDA     (完整重新編譯，約 2 小時)
4) 🐍 Conda 環境      (Miniforge + env + symlinks)
5) 📦 套件安裝        (已驗證 wheels + pip)
v) ✅ 環境驗證        (檢查套件 + GPU)
a) ⚡ 全部執行        (自動準備 → p → 1 → 2 → 3 → 4 → 5 → v)
q) 👋 離開
```

---

## ⚙️ 設定變數

| 變數 | 預設值 | 說明 |
|------|--------|------|
| `CONDA_ENV` | `tools` | Conda 環境名稱 |
| `CONDA_HOME` | `~/miniforge3` | Miniforge 安裝根目錄 |
| `MINIFORGE_VERSION` | `26.5.3-0` | 固定的 Miniforge 版本 |
| `PACKAGES_DIR` | `~/packages/jetson_wheels` | Wheel 目錄 |
| `AUTO_DOWNLOAD_WHEELS` | `1` | 缺少 wheel 時自動從 Google Drive 下載 |
| `GDRIVE_WHEELS_URL` | 內建 Drive 資料夾 | 自訂 Google Drive wheel 資料夾 |
| `GDOWN_VERSION` | `6.1.0` | 自動下載使用的 gdown 版本 |
| `CUDA_PYTHON_VERSION` | `12.6.2` | 從 PyPI 安裝的 cuda-python 版本 |
| `AUTO_CREATE_SWAP` | `1` | `a` 模式在總 Swap 小於 8 GB 時自動新增 Swap |
| `SWAPFILE_PATH` | `/swapfile8` | 自動建立的 Swap 路徑 |
| `SWAPFILE_SIZE_GB` | `8` | 自動建立的 Swap 大小（GB） |
| `OPENCV_SCRIPT_SHA256` | 空 | OpenCV 編譯腳本的選填 SHA256 |

需要時可以關閉自動下載或自動建立 Swap：

```bash
export AUTO_DOWNLOAD_WHEELS=0
export AUTO_CREATE_SWAP=0
```

---

## 🐛 常見問題

**Google Drive 下載失敗**

刪除獨立 downloader 環境後重新選 `a`：

```bash
rm -rf ~/.cache/jetson-setup/gdown
```

若系統 Python 沒有 `pip`，腳本會自動重新建立 venv。

**系統已有舊 Miniconda**

腳本不會自動刪除。完整安裝驗證成功後，再自行確認是否需要移除：

```bash
ls -ld ~/miniconda3 ~/miniforge3
```

**找到多個 wheel 版本**

在 `~/packages/jetson_wheels/` 中，每個 Google Drive 必要套件只保留一個相容版本，再重新執行 `a`。

**既有 `/swapfile8` 無法啟用**

安裝程式會刻意拒絕覆寫既有但不是有效 Swap 的檔案。請先人工確認該檔案用途，再決定是否刪除或替換。

**cv2 沒有 CUDA**

```bash
python -c "import cv2; print(cv2.__file__)"
```

應指向 Jetson 系統的 OpenCV 套件；若不正確，重新執行步驟 4。

**tensorrt import 失敗**

```bash
export LD_LIBRARY_PATH=/usr/lib/aarch64-linux-gnu:$LD_LIBRARY_PATH
```

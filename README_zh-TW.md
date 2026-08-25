# 🚀 Jetson Orin Nano — 開發環境建置

> 🌐 [English](./README.md)

適用於 **NVIDIA Jetson Orin Nano** 的互動式 Bash 安裝工具，用於快速建立深度學習開發環境。

- **目標平台：** JetPack 6.2 / L4T R36.4.x / R36.5.x
- **Python：** 3.10
- **環境管理：** Miniforge + Conda
- **CUDA：** 使用 JetPack 提供的 CUDA 環境

---

## 📋 系統需求

| 項目 | 需求 |
|---|---|
| JetPack | 6.2（L4T R36.4.x / R36.5.x） |
| 可用磁碟空間 | ≥ 20 GB |
| Swap | OpenCV CUDA 編譯建議 ≥ 8 GB |
| 網路 | 第一次安裝時需要 |

當選擇 `a` 時，如果系統目前的 Swap 不足，安裝程式會自動建立額外 **8 GB** 的 `/swapfile8`。

---

## 🚀 快速開始

```bash
chmod +x jetson_setup.sh
bash jetson_setup.sh
```

全新 Jetson 建議直接選擇：

```text
a
```

選項 `a` 會執行完整安裝流程：

```text
必要時自動建立 Swap
→ 自動下載並驗證 Jetson wheels
→ 環境預檢
→ 系統基礎設定
→ 系統更新
→ OpenCV CUDA 編譯
→ Miniforge / Conda 環境
→ 安裝 Jetson wheels + cuda-python
→ 環境驗證
```

不需要先手動執行 `p`，也不需要事先準備 wheel 或 Swap。

> 具有破壞性或安全風險的操作仍會要求使用者確認，例如重新編譯 OpenCV，或在未設定 SHA256 的情況下執行外部 OpenCV build script。

---

## 🛠 安裝選單

```text
p) 🔍 Preflight check   (自動下載 wheels / Swap / 磁碟檢查)
1) 🔧 System base       (Snap 修正 + 中文輸入法)
2) 🔄 System update     (apt update + jtop)
3) 📷 OpenCV CUDA       (完整重新編譯，約 2 小時)
4) 🐍 Conda env         (Miniforge + env + symlinks)
5) 📦 Package install   (已驗證 wheels + pip packages)
v) ✅ Validate          (套件 + GPU 驗證)
a) ⚡ Run all           (auto-prepare → p → 1 → 2 → 3 → 4 → 5 → v)
q) 👋 Quit
```

---

## 📦 Jetson Wheels

當必要套件缺少時，安裝程式會自動從 Google Drive 下載已整理好的 **JetPack 6.2 / CUDA 12.6** wheel 套件。

📁 [Jetson Wheels](https://drive.google.com/drive/folders/1zOi0G1CkETV6aR9FI9y4iTQOurEH2T1v?usp=sharing)

必要 wheel：

- PyTorch
- Torchvision
- ONNX Runtime GPU
- CuPy CUDA 12x

`cuda-python` 不放在 Drive bundle 中，而是另外從 PyPI 安裝：

```text
cuda-python==12.6.2
```

下載後的 wheels 會存放於：

```text
~/packages/jetson_wheels/
```

Preflight check 會：

- 接受 Python 3.10 (`cp310`) aarch64 wheels
- 接受 `linux_aarch64` 與 `manylinux*_aarch64` tag
- 讀取 wheel metadata 並顯示套件版本
- 在存在明確 dependency pin 時驗證 PyTorch / Torchvision 相容性
- 若同一套件存在多個符合版本，會直接拒絕繼續

只有在需要從 Google Drive 下載時才會自動安裝 `gdown`。

如果 system Python 沒有 `pip`，安裝程式會建立隔離環境：

```text
~/.cache/jetson-setup/gdown
```

> `cv2` 與 `tensorrt` 不會以 wheel 下載。安裝程式會將 Jetson 系統套件連結到 Conda environment。

---

## 🐍 Miniforge / Conda

本專案使用 **Miniforge**，不使用 Miniconda。這樣建立環境時可直接使用 `conda-forge`，不需要接受 Anaconda repository Terms of Service。

固定版本：

```text
Miniforge 26.5.3-0
Linux aarch64
~/miniforge3
```

安裝前會驗證官方 SHA256，並建立 `tools` environment：

```bash
conda create -n tools --override-channels -c conda-forge python=3.10 -y
```

如果系統中已存在舊的 `~/miniconda3`，安裝程式不會自動刪除。

預設使用：

```text
~/miniforge3
```

---

## ⚙️ 設定參數

| 變數 | 預設值 | 說明 |
|---|---|---|
| `CONDA_ENV` | `tools` | Conda environment 名稱 |
| `CONDA_HOME` | `~/miniforge3` | Miniforge 安裝位置 |
| `MINIFORGE_VERSION` | `26.5.3-0` | 固定 Miniforge 版本 |
| `PACKAGES_DIR` | `~/packages/jetson_wheels` | Jetson wheel 目錄 |
| `AUTO_DOWNLOAD_WHEELS` | `1` | 自動下載缺少的 wheels |
| `GDRIVE_WHEELS_URL` | 內建 Drive folder | 覆寫 Google Drive wheel 來源 |
| `GDOWN_VERSION` | `6.1.0` | `gdown` 版本 |
| `CUDA_PYTHON_VERSION` | `12.6.2` | 從 PyPI 安裝的 `cuda-python` 版本 |
| `AUTO_CREATE_SWAP` | `1` | Swap 不足時自動補足 |
| `SWAPFILE_PATH` | `/swapfile8` | 自動建立的 Swap 路徑 |
| `SWAPFILE_SIZE_GB` | `8` | 自動建立的 Swap 大小 |
| `OPENCV_SCRIPT_SHA256` | _(空白)_ | OpenCV build script 的可選 SHA256 |

如需關閉自動下載 wheel 或自動建立 Swap：

```bash
export AUTO_DOWNLOAD_WHEELS=0
export AUTO_CREATE_SWAP=0
```

---

## 📷 Basler pylon

### 下載

Basler 官方軟體下載頁：

📁 [Basler pylon downloads](https://www.baslerweb.com/en-us/downloads/software/)

Google Drive：

📁 [Google Drive](https://drive.google.com/drive/folders/1zOi0G1CkETV6aR9FI9y4iTQOurEH2T1v?usp=sharing)

### 安裝 pylon 25.10.2 ARM64

假設安裝檔位於 `~/Downloads`：

```bash
cd ~/Downloads

tar -xzf pylon-25.10.2_linux-aarch64_debs.tar.gz

sudo apt update

sudo apt install   ./codemeter-lite_8.20.6558.501_arm64.deb   ./pylon_25.10.2-deb0_arm64.deb
```

確認是否安裝成功：

```bash
dpkg -l | grep -Ei "pylon|codemeter"
```

---

## 🐛 問題排查

### Google Drive 下載失敗

刪除隔離的 downloader environment，再重新執行 `a`：

```bash
rm -rf ~/.cache/jetson-setup/gdown
```

需要時安裝程式會自動重新建立。

### 系統存在舊 Miniconda

安裝程式不會自動刪除。

刪除前先確認兩個目錄：

```bash
ls -ld ~/miniconda3 ~/miniforge3
```

### 偵測到多個 wheel 版本

每個必要套件在下列目錄中只保留一個相容版本：

```text
~/packages/jetson_wheels/
```

完成後重新執行安裝程式。

### `/swapfile8` 無法啟用

如果 `/swapfile8` 已存在但不是有效 Swap，安裝程式不會直接覆蓋。

請先確認檔案內容與用途，再決定是否刪除或重新建立。

### `cv2` 沒有 CUDA 支援

檢查實際載入的 OpenCV 路徑：

```bash
python -c "import cv2; print(cv2.__file__)"
```

應使用 Jetson 系統的 OpenCV。

如果不是，重新執行 step 4。

### `tensorrt` import 失敗

設定 Jetson library path：

```bash
export LD_LIBRARY_PATH=/usr/lib/aarch64-linux-gnu:$LD_LIBRARY_PATH
```

---

## 🔒 環境凍結

完成 Jetson 環境建置後，建議鎖定 NVIDIA、CUDA、TensorRT 與 Basler 相關套件，降低系統自動更新造成 driver 或 package 相容性問題的風險。

📄 [Jetson Environment Freeze Guide](./Envfreeze.md)

---

## ⚠️ 安全注意事項

此安裝程式可能執行下列系統層級操作：

- 建立 Swap
- 安裝 system packages
- 重新編譯 OpenCV
- 修改 Conda shell 設定
- 將 Jetson system Python packages 連結到 Conda environment

執行具有破壞性的操作前，請確認提示內容。

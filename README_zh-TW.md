# 🚀 Jetson Orin Nano — 開發環境安裝腳本

一鍵式互動式 Bash 腳本，在 Jetson Orin Nano 上安裝並驗證完整的深度學習環境。

- **適用裝置**：JetPack 6.2 / L4T R36.4.x / R36.5.x
- **Python**：3.10（Miniconda，獨立 conda 環境）
- **最後更新**：2026-05-20

> 🌐 [English Version](./README.md)

---

## 📋 系統需求

| 項目 | 需求 |
|------|------|
| JetPack | 6.2（L4T R36.4.x / R36.5.x） |
| Swap 空間 | ≥ 8 GB（OpenCV CUDA 編譯必要） |
| 可用磁碟 | ≥ 20 GB 建議 |
| 網路 | apt、wget、pip 需要網路連線 |

---

## 📦 必要 Wheel 檔案

執行腳本前，請先下載以下 Jetson 專用 `.whl` 檔案並放入 `~/packages/jetson_wheels/`。

| 套件 | 來源 | 檔名 pattern |
|------|------|-------------|
| PyTorch | [Jetson AI Lab](https://pypi.jetson-ai-lab.io/jp6/cu126) | `torch-*-cp310-cp310-manylinux*_aarch64.whl` |
| Torchvision | [Jetson AI Lab](https://pypi.jetson-ai-lab.io/jp6/cu126) | `torchvision-*-cp310-cp310-manylinux*_aarch64.whl` |
| Torchaudio | [Jetson AI Lab](https://pypi.jetson-ai-lab.io/jp6/cu126) | `torchaudio-*-cp310-cp310-manylinux*_aarch64.whl` |
| ONNX Runtime GPU | [Jetson AI Lab](https://pypi.jetson-ai-lab.io/jp6/cu126) | `onnxruntime_gpu-*-cp310-cp310-linux_aarch64.whl` |
| CUDA Python | [Jetson AI Lab](https://pypi.jetson-ai-lab.io/jp6/cu126) | `cuda_python-*-cp310-cp310-linux_aarch64.whl` |
| CuPy (CUDA 12x) | [Jetson AI Lab](https://pypi.jetson-ai-lab.io/jp6/cu126) | `cupy_cuda12x-*-cp310-cp310-manylinux*_aarch64.whl` |

> **注意**：`cv2` 和 `tensorrt` **不透過 pip 安裝**。腳本會從系統的 `/usr/lib/python3.10/dist-packages/` 建立 symlink，讓 conda 環境能使用 CUDA 加速版本。

預先下載好的 wheel 檔案可在 Google Drive 取得：
📁 [Google Drive — Jetson Wheels](https://drive.google.com/drive/folders/1zOi0G1CkETV6aR9FI9y4iTQOurEH2T1v?usp=sharing)

---

## 🚀 快速開始

```bash
# 1. 下載腳本並賦予執行權限
chmod +x jetson_setup.sh

# 2. （選用）設定自訂 conda 環境名稱，預設為 "tools"
export CONDA_ENV=tools

# 3. （選用）設定 OpenCV 腳本的 SHA256，防止供應鏈攻擊
export OPENCV_SCRIPT_SHA256=<sha256_hash>

# 4. 執行
bash jetson_setup.sh
```

---

## 🛠 選單說明

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

**全新裝置建議順序**：先執行 `p` 前置檢查，通過後執行 `a` 全自動安裝。

---

## 🔍 各步驟說明

### `p` — 前置檢查
安裝前先驗證環境，確認以下四項：
- `PACKAGES_DIR` 目錄內 6 個必要 `.whl` 檔案都能找到
- Swap 空間 ≥ 8 GB（OpenCV 編譯硬性需求）
- `OPENCV_SCRIPT_SHA256` 是否已設定（建議設定）
- 可用磁碟 ≥ 20 GB

執行 `a` 全自動流程時，若前置檢查**未通過則立即中止**，不繼續安裝。

---

### `1` — 系統基礎設置
- 將 Snap 版本固定在 r24724，防止自動更新
- 安裝 `ibus-pinyin` 和 `ibus-chewing` 中文輸入法

---

### `2` — 系統更新 & jtop 修復
- 執行 `apt update`
- 安裝 `jetson-stats`（`jtop`）
- 修補 `jetson_variables.py`，補充 L4T R36.4.x 的 JetPack 版本對照：

  | L4T | JetPack |
  |-----|---------|
  | 36.4.0 | 6.2 |
  | 36.4.3 | 6.2 |
  | 36.4.4 | 6.2.1 |
  | 36.4.7 | 6.2.1 |

---

### `3` — OpenCV CUDA 編譯（約 2 小時）
- 移除現有 `libopencv*` 套件
- 下載 [Qengineering OpenCV 4.11 編譯腳本](https://github.com/Qengineering/Install-OpenCV-Jetson-Nano)
- 若有設定 `OPENCV_SCRIPT_SHA256` 則驗證 checksum
- 執行完整 CMake + make 編譯流程
- 編譯完成後自動驗證 CUDA 和 cuDNN 是否啟用

> ⚠️ 需要 ≥ 8 GB Swap。若不足，請先建立：
> ```bash
> sudo fallocate -l 8G /swapfile && sudo chmod 600 /swapfile
> sudo mkswap /swapfile && sudo swapon /swapfile
> ```

---

### `4` — Conda 環境與 Symlink 建立
- 若未安裝則自動下載並安裝 Miniconda3（aarch64）
- 建立 Python 3.10 的 conda 環境 `tools`
- 在 conda 的 `site-packages` 中建立以下 symlink：

  | 套件 | 來源 | 方式 |
  |------|------|------|
  | `cv2` | `/usr/lib/python3.10/dist-packages/cv2` | symlink |
  | `tensorrt` | `/usr/lib/python3.10/dist-packages/tensorrt*` | symlink |
  | `cupy` | `/usr/lib/python3.10/dist-packages/cupy*` | symlink（若系統有） |

- 建立後立即進行 `import` 測試驗證每個 symlink

---

### `5` — 套件安裝

依嚴格順序安裝，避免依賴項互相衝突：

| 階段 | 內容 | 方式 |
|------|------|------|
| 1/6 | `numpy==1.23.5` | pip（鎖定版本） |
| 2/6 | torch、torchvision、torchaudio、onnxruntime_gpu、cuda_python、cupy_cuda12x | 本地 `.whl`（`--no-deps`） |
| 3/6 | scikit-learn、ultralytics、easyocr | pip（ultralytics/easyocr 用 `--no-deps`） |
| 4/6 | Pillow、pyyaml、psutil、matplotlib、polars | pip |
| 5/6 | `numpy==1.23.5` | `--force-reinstall`（重新釘死） |
| 6/6 | NumPy 警告抑制 | 寫入 `activate.d/env_vars.sh` |

> `ultralytics` 和 `easyocr` 使用 `--no-deps`，防止 pip 拉入 `opencv-python`，避免覆蓋系統 cv2 symlink。

---

### `v` — 環境驗證

啟動 conda 環境後執行四段檢查：

**套件版本**
```
  OK  torch          2.8.0
  OK  cv2            4.11.0
  OK  tensorrt       10.x.x
  NG  pycuda         not found    ← 紅色，核心套件缺失
  --  easyocr        not found    ← 黃色，選配套件
```

**CUDA / GPU 狀態**
```
  OK  CUDA Available   True
      GPU Name         Jetson Orin Nano
      GPU Memory       8.0 GB
```

**功能測試**
```
  OK  NumPy array ops
  OK  cv2 CUDA backend
  OK  torch CUDA tensor
  OK  torch autocast
```

**ONNX Runtime GPU Provider**
```
  onnxruntime: 1.24.0
  providers: ['TensorrtExecutionProvider', 'CUDAExecutionProvider', 'CPUExecutionProvider']
  OK  ONNX Runtime GPU provider available
```

---

## ⚙️ 設定參數

所有設定變數都在腳本頂部，可在執行前用 `export` 覆蓋：

| 變數 | 預設值 | 說明 |
|------|--------|------|
| `CONDA_ENV` | `tools` | Conda 環境名稱 |
| `PACKAGES_DIR` | `~/packages/jetson_wheels` | `.whl` 檔案目錄 |
| `PYTHON_VER` | `3.10` | conda 環境的 Python 版本 |
| `OPENCV_SCRIPT_SHA256` | （空） | OpenCV 編譯腳本的預期 SHA256 |

```bash
# 範例：使用自訂環境名稱與 wheel 目錄
export CONDA_ENV=myenv
export PACKAGES_DIR=/mnt/usb/wheels
bash jetson_setup.sh
```

---

## 🔑 核心設計原則

- **`cv2` 和 `tensorrt` 絕對不能用 pip 安裝**：Jetson 上有 CUDA 加速的版本只存在於系統套件，腳本用 symlink 讓 conda 環境讀到正確版本。
- **`numpy==1.23.5` 鎖死版本**：安裝結束時強制重裝，防止其他套件靜默升級。
- **`ultralytics` 和 `easyocr` 用 `--no-deps`**：防止 pip 自動安裝 `opencv-python`，覆蓋 cv2 symlink。
- **`conda activate` 在腳本中需要 `eval "$(conda shell.bash hook)"`**：非互動式 Bash 腳本中，單純執行 `conda activate` 不會切換環境。

---

## 🐛 常見問題排查

**`cv2` 沒有 CUDA 支援，或指向錯誤路徑**
```bash
python -c "import cv2; print(cv2.__file__)"
# 正確：/usr/lib/python3.10/dist-packages/cv2/...
# 錯誤：.../envs/tools/lib/...
```
若路徑錯誤，重新執行步驟 4 重建 symlink。

確認 CUDA 是否啟用：
```bash
python -c "
import cv2
build = cv2.getBuildInformation()
for l in build.splitlines():
    if l.strip().startswith(('CUDA', 'cuDNN', 'CUDA GPU arch')):
        print(l.strip())
"
```

**`tensorrt` import 失敗**
```bash
# 確認 .so 檔存在
ls /usr/lib/aarch64-linux-gnu/libnvinfer.so*
# 若 linker 找不到，手動加入路徑
export LD_LIBRARY_PATH=/usr/lib/aarch64-linux-gnu:$LD_LIBRARY_PATH
```

**ONNX Runtime 只顯示 CPU provider**

通常代表裝到的是 CPU 版 `onnxruntime`，而非 GPU 版。確認 `PACKAGES_DIR` 內有正確的 `onnxruntime_gpu` wheel，重新執行步驟 5。

**OpenCV 編譯時 OOM 或被系統 kill**
```bash
# 確認 swap
free -h
# 建立 8GB swap
sudo fallocate -l 8G /swapfile && sudo chmod 600 /swapfile
sudo mkswap /swapfile && sudo swapon /swapfile
```

**確認 pip 指向正確的 conda 環境**
```bash
conda activate tools
which pip
# 應該包含 tools：/home/user/miniconda3/envs/tools/bin/pip
pip show torch  # Location 應在 .../envs/tools/...
```
#!/bin/bash
# ============================================================
#   Jetson Orin Nano - Dev Environment Setup Script
#   Target : JetPack 6.2, L4T R36.4.x / R36.5.x
#   Updated: 2026-06-06
# ============================================================

set -euo pipefail
export LC_ALL=C.UTF-8

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  Colors & Helpers
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${CYAN}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[ OK ]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERR] $*${NC}" >&2; }

confirm() {
    local prompt="${1:-Continue?}"
    read -rp "$(echo -e "${YELLOW}[?]${NC} ${prompt} [y/N] ")" ans
    [[ "$ans" =~ ^[Yy]$ ]]
}

# Print and execute a command (no eval)
run() {
    echo -e "${CYAN}  -> $*${NC}"
    "$@"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  CUDA PATH Auto-fix
#  Ensure nvcc and CUDA libraries are visible before anything else
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
_cuda_path=$(find /usr/local -maxdepth 1 -name "cuda-*" -type d 2>/dev/null | sort -V | tail -1)
[[ -z "$_cuda_path" ]] && _cuda_path="/usr/local/cuda"

if [[ -d "$_cuda_path/bin" ]] && ! command -v nvcc &>/dev/null; then
    export PATH="$_cuda_path/bin:$PATH"
    info "CUDA PATH auto-set: $_cuda_path"
fi
if [[ -d "$_cuda_path/lib64" ]]; then
    export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:-}:$_cuda_path/lib64"
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  Config
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PACKAGES_DIR="${PACKAGES_DIR:-$HOME/packages/jetson_wheels}"
CONDA_ENV="${CONDA_ENV:-tools}"
PYTHON_VER="3.10"

# Set to sha256 of OpenCV-4-11-0.sh before running step 3
# e.g.  export OPENCV_SCRIPT_SHA256=$(sha256sum OpenCV-4-11-0.sh | awk '{print $1}')
OPENCV_SCRIPT_SHA256="${OPENCV_SCRIPT_SHA256:-}"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  P.  Preflight Check
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
step_preflight() {
    echo -e "\n${BOLD}${BLUE}=== 🔍 P. Preflight Check ===${NC}"
    local fail=0

    # ── Wheel files ──────────────────────────────────────────
    echo -e "\n${BOLD}-- Wheel Directory ($PACKAGES_DIR) --${NC}"
    if [[ ! -d "$PACKAGES_DIR" ]]; then
        error "Directory not found: $PACKAGES_DIR"
        echo "  -> Create it and place Jetson .whl files inside."
        fail=1
    fi

    # torch / torchvision  : manylinux_2_28_aarch64  (Jetson AI Lab)
    # onnxruntime_gpu      : linux_aarch64
    # cuda_python          : linux_aarch64
    # cupy_cuda12x         : manylinux2014_aarch64
    declare -A REQUIRED_WHEELS=(
        ["torch"]="torch-*-cp310-cp310-manylinux*_aarch64.whl"
        ["torchvision"]="torchvision-*-cp310-cp310-manylinux*_aarch64.whl"
        ["onnxruntime_gpu"]="onnxruntime_gpu-*-cp310-cp310-linux_aarch64.whl"
        ["cuda_python"]="cuda_python-*-cp310-cp310-linux_aarch64.whl"
        ["cupy_cuda12x"]="cupy_cuda12x-*-cp310-cp310-manylinux*_aarch64.whl"
    )

    for pkg in "${!REQUIRED_WHEELS[@]}"; do
        local pattern="${REQUIRED_WHEELS[$pkg]}"
        local found
        found=$(find "$PACKAGES_DIR" -maxdepth 1 -name "$pattern" 2>/dev/null | head -1)
        if [[ -n "$found" ]]; then
            echo -e "  ${GREEN}OK${NC}  [required] $pkg  ->  $(basename "$found")"
        else
            echo -e "  ${RED}!!${NC}  [required] $pkg  ->  not found: $pattern"
            fail=1
        fi
    done

    # ── Swap space (needed for OpenCV build) ─────────────────
    echo -e "\n${BOLD}-- Swap Space --${NC}"
    local swap_kb swap_gb
    swap_kb=$(free | awk '/^Swap:/ {print $2}')
    swap_gb=$(( swap_kb / 1024 / 1024 ))

    if   (( swap_kb >= 8 * 1024 * 1024 )); then
        echo -e "  ${GREEN}OK${NC}  Swap ${swap_gb} GB >= 8 GB  (safe for OpenCV build)"
    elif (( swap_kb >= 4 * 1024 * 1024 )); then
        echo -e "  ${YELLOW}!!${NC}  Swap ${swap_gb} GB  (recommend >= 8 GB — build may OOM)"
    else
        echo -e "  ${RED}!!${NC}  Swap ${swap_gb} GB is too low — step 3 (OpenCV build) will fail"
        echo    "       ->  sudo fallocate -l 8G /swapfile && sudo chmod 600 /swapfile"
        echo    "           sudo mkswap /swapfile && sudo swapon /swapfile"
        fail=1
    fi

    # ── OpenCV script SHA256 ──────────────────────────────────
    echo -e "\n${BOLD}-- OpenCV Script --${NC}"
    if [[ -n "$OPENCV_SCRIPT_SHA256" ]]; then
        echo -e "  ${GREEN}OK${NC}  OPENCV_SCRIPT_SHA256 is set"
    else
        echo -e "  ${YELLOW}!!${NC}  OPENCV_SCRIPT_SHA256 not set — step 3 will ask for manual confirmation"
        echo    "       ->  After downloading:  sha256sum OpenCV-4-11-0.sh"
        echo    "           export OPENCV_SCRIPT_SHA256=<hash>"
    fi

    # ── Disk space ───────────────────────────────────────────
    echo -e "\n${BOLD}-- Disk Space --${NC}"
    local disk_avail_gb
    disk_avail_gb=$(df -BG "$HOME" | awk 'NR==2 {gsub("G",""); print $4}')
    if (( disk_avail_gb >= 20 )); then
        echo -e "  ${GREEN}OK${NC}  Available ${disk_avail_gb} GB >= 20 GB"
    else
        echo -e "  ${YELLOW}!!${NC}  Available ${disk_avail_gb} GB  (recommend >= 20 GB for OpenCV build)"
    fi

    echo ""
    if (( fail == 1 )); then
        error "Preflight failed. Fix the items above before running the installer."
        return 1
    else
        success "Preflight passed. Safe to proceed."
    fi
}


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  1.  System Base Setup
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
step1_system_base() {
    echo -e "\n${BOLD}${BLUE}=== 🔧 1. System Base Setup ===${NC}"
    if confirm "Fix Snap (v24724) and install Chinese input?"; then
        run snap download snapd --revision=24724
        run sudo snap ack  snapd_24724.assert
        run sudo snap install snapd_24724.snap
        run sudo snap refresh --hold snapd
        run sudo apt-get install -y ibus-pinyin ibus-chewing
        success "System base setup done."
    fi
}


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  2.  jtop Install & JetPack Version Fix
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
step3_jtop_fix() {
    echo -e "\n${BOLD}${BLUE}=== 🔄 2. jtop Install & JetPack Version Fix ===${NC}"
    run sudo pip3 install -U jetson-stats

    local varfile
    varfile=$(sudo find / -name "jetson_variables.py" -path "*/jtop/*" 2>/dev/null | head -1)

    if [[ -n "$varfile" ]]; then
        info "Patching JetPack version map in $varfile ..."
        sudo python3 - "$varfile" <<'PYEOF'
import re, sys
path = sys.argv[1]
with open(path, 'r') as f:
    content = f.read()
new_map = (
    '    "36.4.0": "6.2",\n'
    '    "36.4.3": "6.2",\n'
    '    "36.4.4": "6.2.1",\n'
    '    "36.4.7": "6.2.1",'
)
if "36.4.7" not in content:
    content = re.sub(r'(NVIDIA_JETPACK\s*=\s*\{)', r'\1\n' + new_map, content)
    with open(path, 'w') as f:
        f.write(content)
    print(f"[OK] Updated {path}")
else:
    print(f"[INFO] {path} already up to date.")
PYEOF
        run sudo systemctl restart jtop.service
        success "jtop fix done."
    else
        warn "jetson_variables.py not found. Please check manually."
    fi
}


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  3.  OpenCV CUDA Build  (~2 hr)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
step4_opencv_cuda() {
    echo -e "\n${BOLD}${BLUE}=== 📷 3. OpenCV CUDA Build (takes a long time) ===${NC}"
    if ! confirm "Rebuild OpenCV with CUDA? (removes existing libopencv)"; then
        return 0
    fi

    run sudo apt purge -y 'libopencv*'
    run wget -O OpenCV-4-11-0.sh \
        https://github.com/Qengineering/Install-OpenCV-Jetson-Nano/raw/main/OpenCV-4-11-0.sh

    # ── Checksum verification ────────────────────────────────
    if [[ -n "$OPENCV_SCRIPT_SHA256" ]]; then
        echo "$OPENCV_SCRIPT_SHA256  OpenCV-4-11-0.sh" | sha256sum -c || {
            error "Checksum mismatch. Re-download or update OPENCV_SCRIPT_SHA256."
            rm -f OpenCV-4-11-0.sh
            return 1
        }
        success "Checksum verified."
    else
        warn "OPENCV_SCRIPT_SHA256 not set — skipping checksum verification."
        confirm "Run without verification?" || { rm -f OpenCV-4-11-0.sh; return 1; }
    fi

    run chmod 755 ./OpenCV-4-11-0.sh
    run ./OpenCV-4-11-0.sh || { error "OpenCV build failed. Check logs."; return 1; }

    # ── Verify CUDA support after build ─────────────────────
    info "Verifying OpenCV CUDA support..."
    python3 - <<'PYEOF'
import cv2, sys

build = cv2.getBuildInformation()
lines = build.splitlines()

print(f"  cv2 path: {cv2.__file__}")
for line in lines:
    for k in ["CUDA", "cuDNN", "CUDA GPU arch", "OpenCV version"]:
        if line.strip().startswith(k):
            print(f"  {line.strip()}")

cuda_ok  = any("CUDA:"  in l and "YES" in l for l in lines)
cudnn_ok = any("cuDNN:" in l and "YES" in l for l in lines)

if cuda_ok and cudnn_ok:
    print("\033[32m  [OK] OpenCV CUDA + cuDNN enabled\033[0m")
else:
    print("\033[31m  [ERR] OpenCV CUDA not enabled. Check build script.\033[0m")
    sys.exit(1)
PYEOF
}


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  4.  Conda Environment & Symlinks
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
step5_env_setup() {
    echo -e "\n${BOLD}${BLUE}=== 🐍 4. Conda Environment & Symlinks ===${NC}"

    # ── Install Miniconda if absent ──────────────────────────
    if ! command -v conda &>/dev/null; then
        run wget -O Miniconda3-latest-Linux-aarch64.sh \
            https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-aarch64.sh
        run bash Miniconda3-latest-Linux-aarch64.sh -b -p "$HOME/miniconda3"
    fi

    source "$HOME/miniconda3/etc/profile.d/conda.sh" || {
        error "Conda init failed. Check install path: $HOME/miniconda3"
        return 1
    }

    # ── Create env if it doesn't exist ──────────────────────
    # Use \s to match any whitespace after env name (more robust than a literal space)
    if ! conda env list | grep -qE "^${CONDA_ENV}\s"; then
        run conda create -n "$CONDA_ENV" python="$PYTHON_VER" -y
    else
        info "Conda env '$CONDA_ENV' already exists. Skipping create."
    fi

    local site_pkgs
    site_pkgs=$(conda run -n "$CONDA_ENV" python -c "import site; print(site.getsitepackages()[0])")

    info "Creating system package symlinks into: $site_pkgs"

    # ── cv2 symlink ──────────────────────────────────────────
    # Must not be pip-installed — link from the CUDA-enabled system build.
    # Jetson may place cv2 under python3/ or python3.10/ depending on build.
    local cv2_src
    cv2_src=$(find /usr/lib/python3/dist-packages /usr/lib/python3.10/dist-packages \
        -maxdepth 1 -name "cv2" -type d 2>/dev/null | head -1)
    if [[ -z "$cv2_src" ]]; then
        cv2_src=$(find /usr/lib -maxdepth 4 -name "cv2" -type d 2>/dev/null | head -1)
    fi

    if [[ -n "$cv2_src" ]]; then
        info "Found cv2 at: $cv2_src"
        run rm -rf "$site_pkgs/cv2"
        run ln -s  "$cv2_src" "$site_pkgs/"
    else
        warn "cv2 system directory not found. OpenCV may not have been built yet (run step 3)."
    fi

    # ── tensorrt symlink ─────────────────────────────────────
    local tensorrt_targets
    tensorrt_targets=$(find "$site_pkgs" -maxdepth 1 -name "tensorrt*" 2>/dev/null || true)
    if [[ -n "$tensorrt_targets" ]]; then
        info "Removing existing tensorrt entries: $tensorrt_targets"
        find "$site_pkgs" -maxdepth 1 -name "tensorrt*" -exec rm -rf {} +
    fi
    run ln -sf /usr/lib/python3.10/dist-packages/tensorrt* "$site_pkgs/"

    success "Symlinks created."

    # ── Verify symlinks ──────────────────────────────────────
    info "Verifying symlinks..."
    conda run -n "$CONDA_ENV" python -c \
        "import cv2;      print(f'  cv2       {cv2.__version__} OK')"      2>/dev/null \
        || warn "cv2 import failed. Check that OpenCV was built (step 3) and symlink exists in $site_pkgs."
    conda run -n "$CONDA_ENV" python -c \
        "import tensorrt; print(f'  tensorrt  {tensorrt.__version__} OK')" 2>/dev/null \
        || warn "tensorrt import failed.\n  (a) Check /usr/lib/python3.10/dist-packages/tensorrt* exists\n  (b) Check libnvinfer.so is in LD_LIBRARY_PATH"

    # ── cupy symlink (optional — wheel used if absent) ───────
    local sys_cupy
    sys_cupy=$(find /usr/lib/python3.10/dist-packages -maxdepth 1 -name "cupy*" 2>/dev/null | head -1)
    if [[ -n "$sys_cupy" ]]; then
        info "System cupy found. Creating symlink..."
        find "$site_pkgs" -maxdepth 1 -name "cupy*" -exec rm -rf {} + 2>/dev/null || true
        ln -sf /usr/lib/python3.10/dist-packages/cupy* "$site_pkgs/"
        conda run -n "$CONDA_ENV" python -c \
            "import cupy; print(f'  cupy      {cupy.__version__} OK')" 2>/dev/null \
            || warn "cupy symlink created but import failed. Check libcuda.so path."
    else
        info "No system cupy found. Skipping. (Will be installed via wheel in step 5)"
    fi
}


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  5.  Package Install
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
step7_install_packages() {
    echo -e "\n${BOLD}${BLUE}=== 📦 5. Package Install ===${NC}"

    # conda activate does not work in subshells without the shell hook
    source "$HOME/miniconda3/etc/profile.d/conda.sh" || {
        error "Conda init failed. Run step 4 first."
        return 1
    }
    eval "$(conda shell.bash hook)"
    conda activate "$CONDA_ENV" || {
        error "Cannot activate '$CONDA_ENV'. Run step 4 first."
        return 1
    }

    # Guard: confirm pip belongs to the conda env, not the system
    local pip_path
    pip_path=$(which pip)
    if [[ "$pip_path" != *"$CONDA_ENV"* ]]; then
        error "pip path looks wrong: $pip_path  (expected to contain '$CONDA_ENV')"
        return 1
    fi
    info "Using pip: $pip_path"

    # ── Helper: verify / repin NumPy ─────────────────────────
    _check_numpy() {
        local stage="$1"
        local current
        current=$(python -c "import numpy; print(numpy.__version__)" 2>/dev/null || echo "missing")
        if [[ "$current" == "1.23.5" ]]; then
            echo -e "  ${GREEN}[numpy]${NC} $stage: $current  OK"
        else
            warn "[numpy] $stage: found $current — re-pinning to 1.23.5..."
            pip install "numpy==1.23.5" --force-reinstall -q
            local after
            after=$(python -c "import numpy; print(numpy.__version__)" 2>/dev/null || echo "missing")
            echo -e "  ${GREEN}[numpy]${NC} $stage: re-pinned -> $after"
        fi
    }

    # ── [1/6]  NumPy (pinned — must come first) ──────────────
    info "[1/6] Installing NumPy 1.23.5 (pinned)..."
    pip install "numpy==1.23.5"
    _check_numpy "after [1/6]"

    # ── [2/6]  Jetson-specific wheels ────────────────────────
    #  Install order matters: torch → torchvision → rest
    info "[2/6] Installing Jetson wheels (aarch64)..."

    declare -a CORE_WHEEL_PATTERNS=(
        "torch-*-cp310-cp310-linux_aarch64.whl"
        "torchvision-*-cp310-cp310-linux_aarch64.whl"
        "onnxruntime_gpu-*-cp310-cp310-linux_aarch64.whl"
        "cuda_python-*-cp310-cp310-linux_aarch64.whl"
        "cupy_cuda12x-*-cp310-cp310-manylinux*_aarch64.whl"
    )

    local whl_installed=0 whl_missing=0
    set +e  # arithmetic counters would trip set -e; re-enabled after loop
    for pattern in "${CORE_WHEEL_PATTERNS[@]}"; do
        local found
        found=$(find "$PACKAGES_DIR" -maxdepth 1 -name "$pattern" 2>/dev/null | head -1)
        if [[ -n "$found" ]]; then
            info "  Installing: $(basename "$found")"
            pip install "$found" --no-deps
            whl_installed=$(( whl_installed + 1 ))
        else
            warn "  Not found:  $pattern  (run preflight check p)"
            whl_missing=$(( whl_missing + 1 ))
        fi
    done
    set -e

    success "Wheels done: $whl_installed installed, $whl_missing missing."
    [[ $whl_missing -gt 0 ]] && warn "$whl_missing required wheels missing. Some features may not work."
    _check_numpy "after [2/6]"

    # ── [3/6]  ML packages ───────────────────────────────────
    #  --no-deps prevents pip from overwriting the system cv2 symlink
    info "[3/6] Installing ML packages..."
    pip install scikit-learn
    pip install ultralytics easyocr --no-deps
    pip install "torchmetrics==1.9"
    _check_numpy "after [3/6]"

    # ── [4/6]  Fill dependencies skipped by --no-deps ────────
    info "[4/6] Installing tool dependencies..."
    pip install fastrlock                                    # required by cupy
    pip install "Pillow==10.0.0" pyyaml psutil matplotlib polars
    _check_numpy "after [4/6]"

    # ── [5/6]  Final NumPy pin confirmation ──────────────────
    info "[5/6] Final NumPy pin check..."
    _check_numpy "final"

    # ── [6/6]  Suppress NumPy UserWarning on activate ────────
    local conda_prefix
    conda_prefix=$(python -c "import sys; print(sys.prefix)")
    mkdir -p "$conda_prefix/etc/conda/activate.d/"
    echo 'export PYTHONWARNINGS="ignore::UserWarning:numpy.core.getlimits"' \
        > "$conda_prefix/etc/conda/activate.d/env_vars.sh"
    info "[6/6] NumPy warning suppression set."

    success "Package install complete."
}


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  V.  Environment Validation
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
step_validate() {
    echo -e "\n${BOLD}${BLUE}=== ✅ V. Environment Validation ===${NC}"

    source "$HOME/miniconda3/etc/profile.d/conda.sh" || {
        error "Conda init failed. Run step 4 first."
        return 1
    }
    eval "$(conda shell.bash hook)"
    conda activate "$CONDA_ENV" || {
        error "Cannot activate '$CONDA_ENV'."
        return 1
    }

    # ── Package versions ─────────────────────────────────────
    echo -e "\n${BOLD}-- Package Versions --${NC}"
    python - <<'PYEOF'
import sys

results = []

def chk(label, fn):
    try:
        results.append((True,  label, fn()))
    except Exception as e:
        results.append((False, label, str(e)))

# Core packages
chk("Python",       lambda: sys.version.split()[0])
chk("numpy",        lambda: __import__("numpy").__version__)
chk("cv2",          lambda: __import__("cv2").__version__)
chk("PIL",          lambda: __import__("PIL").__version__)
chk("torch",        lambda: __import__("torch").__version__)
chk("torchvision",  lambda: __import__("torchvision").__version__)
chk("tensorrt",     lambda: __import__("tensorrt").__version__)
chk("onnxruntime",  lambda: __import__("onnxruntime").__version__)
chk("sklearn",      lambda: __import__("sklearn").__version__)
chk("ultralytics",  lambda: __import__("ultralytics").__version__)
chk("cupy",         lambda: __import__("cupy").__version__)

# Optional packages
chk("easyocr",      lambda: __import__("easyocr").__version__)
chk("polars",       lambda: __import__("polars").__version__)
chk("pycuda",       lambda: __import__("pycuda").VERSION_TEXT)
chk("torchmetrics", lambda: __import__("torchmetrics").__version__)

optional = {"easyocr", "polars", "pycuda", "torchmetrics"}
for ok, label, val in results:
    if ok:
        tag = "\033[32mOK\033[0m"
    elif label in optional:
        tag = "\033[33m--\033[0m"
    else:
        tag = "\033[31mNG\033[0m"
    status = val if ok else f"not found / {val}"
    print(f"  {tag}  {label:<14} {status}")
PYEOF

    # ── CUDA / GPU ───────────────────────────────────────────
    echo -e "\n${BOLD}-- CUDA / GPU --${NC}"
    python - <<'PYEOF'
import torch

cuda_ok  = torch.cuda.is_available()
gpu_name = torch.cuda.get_device_name(0)                              if cuda_ok else "N/A"
gpu_mem  = f"{torch.cuda.get_device_properties(0).total_memory/1024**3:.1f} GB" if cuda_ok else "N/A"

tag = "\033[32mOK\033[0m" if cuda_ok else "\033[31mNG\033[0m"
print(f"  {tag}  CUDA Available   {cuda_ok}")
print(f"         GPU Name        {gpu_name}")
print(f"         GPU Memory      {gpu_mem}")
PYEOF

    # ── Functional tests ─────────────────────────────────────
    echo -e "\n${BOLD}-- Functional Tests --${NC}"
    python - <<'PYEOF'
import numpy as np, cv2, torch

def run(label, fn):
    try:
        fn()
        print(f"  \033[32mOK\033[0m  {label}")
    except Exception as e:
        print(f"  \033[31mNG\033[0m  {label}: {e}")

run("NumPy array ops",
    lambda: np.zeros((224, 224, 3), dtype=np.uint8))
run("cv2 CUDA backend",
    lambda: (_ for _ in ()).throw(RuntimeError("no CUDA build"))
            if cv2.cuda.getCudaEnabledDeviceCount() == 0 else None)
run("torch CUDA tensor",
    lambda: torch.zeros(1).cuda())
run("torch autocast",
    lambda: torch.cuda.amp.autocast().__enter__())
PYEOF

    # ── ONNX Runtime GPU ─────────────────────────────────────
    echo -e "\n${BOLD}-- ONNX Runtime GPU --${NC}"
    python - <<'PYEOF'
import onnxruntime as ort

providers = ort.get_available_providers()
print(f"  onnxruntime : {ort.__version__}")
print(f"  providers   : {providers}")

if "CUDAExecutionProvider" in providers or "TensorrtExecutionProvider" in providers:
    print("\033[32m  OK  ONNX Runtime GPU provider available\033[0m")
else:
    print("\033[31m  NG  ONNX Runtime has CPU provider only — CUDA/TensorRT not loaded\033[0m")
    raise SystemExit(1)
PYEOF

    echo ""
    success "Validation complete.  '--' = optional package not installed (non-critical)."
}


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  Menu
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
show_menu() {
    echo -e "\n${BOLD}${CYAN}🛠  Jetson Orin Nano — Setup Menu${NC}"
    echo "  p)  🔍  Preflight check   (wheels / swap / disk)"
    echo "  1)  🔧  System base       (snap fix + Chinese input)"
    echo "  2)  🔄  System update     (apt update + jtop fix)"
    echo "  3)  📷  OpenCV CUDA       (full rebuild, ~2 hr)"
    echo "  4)  🐍  Conda env         (create env + symlinks)"
    echo "  5)  📦  Package install   (wheels + pip packages)"
    echo "  v)  ✅  Validate          (check all packages + GPU)"
    echo "  a)  ⚡  Run all           (p → 1 → 2 → 3 → 4 → 5 → v)"
    echo "  q)  👋  Quit"
}


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  Banner
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo -e "${BOLD}${CYAN}"
echo "  ╔══════════════════════════════════════════════════════════╗"
echo "  ║   🚀  Jetson Orin Nano — Dev Environment Setup          ║"
echo "  ║   🎯  Target  : JetPack 6.2 / L4T R36.4.x / R36.5.x   ║"
echo "  ║   🐍  Env     : $CONDA_ENV (Python $PYTHON_VER)                        ║"
echo "  ║   📦  Wheels  : $PACKAGES_DIR"
echo "  ║   📅  Updated : 2026-06-06                              ║"
echo "  ╚══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  Sudo Auth & Keepalive
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
info "Requesting sudo credentials (required once for the session)..."
sudo -v || { error "sudo authentication failed. Aborting."; exit 1; }

# Refresh sudo cache every 60 s for the lifetime of this script
while true; do
    sudo -n true
    sleep 60
    kill -0 "$$" 2>/dev/null || exit
done &
SUDO_KEEPALIVE_PID=$!
trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null' EXIT

success "sudo session active."

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  Main Loop
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
while true; do
    show_menu
    read -rp "$(echo -e "${BOLD}Select: ${NC}")" opt
    case $opt in
        p) step_preflight ;;
        1) step1_system_base ;;
        2) run sudo apt update && step3_jtop_fix ;;
        3) step4_opencv_cuda ;;
        4) step5_env_setup ;;
        5) step7_install_packages ;;
        v) step_validate ;;
        a)
            step_preflight || { error "Preflight failed. Aborting full install."; continue; }
            step1_system_base
            run sudo apt update
            step3_jtop_fix
            step4_opencv_cuda
            step5_env_setup
            step7_install_packages
            step_validate
            success "Full install complete."
            break
            ;;
        q) exit 0 ;;
        *) error "Invalid option: '$opt'" ;;
    esac
    read -rp "$(echo -e "${BOLD}Press Enter to continue...${NC}")"
done
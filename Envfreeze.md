# Jetson Environment Freeze

Prevent Jetson from automatically updating and causing issues with NVIDIA, CUDA, TensorRT, or Basler drivers.

## Disable Automatic Updates and Lock Packages

```bash
sudo systemctl disable --now apt-daily.timer apt-daily-upgrade.timer
sudo systemctl mask apt-daily.timer apt-daily-upgrade.timer

sudo tee /etc/apt/apt.conf.d/20auto-upgrades > /dev/null <<'EOF'
APT::Periodic::Enable "0";
APT::Periodic::Update-Package-Lists "0";
APT::Periodic::Download-Upgradeable-Packages "0";
APT::Periodic::AutocleanInterval "0";
APT::Periodic::Unattended-Upgrade "0";
EOF

PACKAGES=$(dpkg-query -W -f='${db:Status-Abbrev} ${binary:Package}\n' 2>/dev/null \
  | awk '$1=="ii" {print $2}' \
  | grep -E '^(nvidia-l4t-|cuda-|libcudnn|cudnn|libnvinfer|tensorrt|python3-libnvinfer|pylon$|codemeter-lite$)' \
  || true)

if [ -n "$PACKAGES" ]; then
    echo "$PACKAGES" | xargs sudo apt-mark hold
fi
```

## Check Settings

```bash
systemctl is-enabled apt-daily.timer
systemctl is-enabled apt-daily-upgrade.timer
apt-mark showhold
```

Expected result:

```text
apt-daily.timer         masked
apt-daily-upgrade.timer masked
```

`apt-mark showhold` should list the locked NVIDIA, CUDA, TensorRT, pylon, and CodeMeter packages.

## Install Packages Normally

You can still install packages normally:

```bash
sudo apt update
sudo apt install <package>
```

Avoid:

```bash
sudo apt upgrade
sudo apt full-upgrade
sudo apt dist-upgrade
```

## Python Packages

`pip` and `conda` do not update packages automatically.

For example, `pypylon` is only updated manually:

```bash
pip install -U pypylon
```

## Purpose

Keep the current Jetson, CUDA, TensorRT, and Basler environment fixed to reduce the risk of boot issues or package incompatibility after updates.

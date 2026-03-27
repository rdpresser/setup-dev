#!/usr/bin/env bash
set -euo pipefail

# Standalone NVIDIA setup with profile support.
# Usage examples:
#   sudo bash scripts/gpu.sh alienware install
#   sudo bash scripts/gpu.sh alienware undo
#   sudo bash scripts/gpu.sh alienware reset

GPU_PROFILE="${1:-}"
ACTION="${2:-install}"

info() { echo "[INFO]  $*"; }
ok() { echo "[OK]    $*"; }
skip() { echo "[SKIP]  $*"; }
warn() { echo "[WARN]  $*"; }
err() { echo "[ERROR] $*"; }

usage() {
  cat <<'EOF'
Usage:
  sudo bash scripts/gpu.sh <profile> [action]

Profiles:
  alienware     Implemented profile
  lenovo        Reserved, not implemented yet

Actions:
  install       Install or configure what is missing (default)
  undo          Remove NVIDIA driver packages and managed config files
  reset         Run undo then install

Examples:
  sudo bash scripts/gpu.sh alienware
  sudo bash scripts/gpu.sh alienware install
  sudo bash scripts/gpu.sh alienware undo
  sudo bash scripts/gpu.sh alienware reset
EOF
}

require_root() {
  if [ "$EUID" -ne 0 ]; then
    err "Run as root (sudo)."
    exit 1
  fi
}

validate_inputs() {
  case "$GPU_PROFILE" in
    alienware)
      ;;
    lenovo)
      err "Profile 'lenovo' is reserved and not implemented yet."
      exit 1
      ;;
    ""|-h|--help)
      usage
      exit 0
      ;;
    *)
      err "Invalid GPU profile: $GPU_PROFILE"
      usage
      exit 1
      ;;
  esac

  case "$ACTION" in
    install|undo|reset)
      ;;
    *)
      err "Invalid action: $ACTION"
      usage
      exit 1
      ;;
  esac
}

ensure_rpmfusion() {
  if dnf repolist all | grep -qi rpmfusion; then
    skip "RPM Fusion repositories already configured."
    return
  fi

  info "Adding RPM Fusion repositories..."
  dnf install -y \
    "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
    "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
  ok "RPM Fusion repositories added."
}

install_nvidia_alienware() {
  info "Applying NVIDIA profile: alienware"

  ensure_rpmfusion

  info "Refreshing package metadata..."
  dnf upgrade --refresh -y

  if rpm -q akmod-nvidia >/dev/null 2>&1; then
    skip "akmod-nvidia is already installed."
  else
    info "Installing NVIDIA driver packages..."
    dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda
    ok "NVIDIA driver packages installed."
  fi

  # Build toolchain required for module build; dnf is idempotent.
  info "Ensuring kernel build dependencies..."
  dnf install -y kernel-devel kernel-headers gcc make dkms

  info "Building NVIDIA kernel modules (safe to re-run)..."
  akmods --force || warn "akmods returned non-zero. A reboot may be required before modules become available."

  info "Regenerating initramfs..."
  dracut --force || warn "dracut returned non-zero. Review logs if NVIDIA is not loaded after reboot."

  info "Configuring PRIME on-demand power management (no powermode tuning)..."
  mkdir -p /etc/modprobe.d

  NVIDIA_PRIME_FILE="/etc/modprobe.d/nvidia-prime.conf"
  if [ -f "$NVIDIA_PRIME_FILE" ] && grep -q '^options nvidia NVreg_DynamicPowerManagement=0x02$' "$NVIDIA_PRIME_FILE"; then
    skip "PRIME config already present: $NVIDIA_PRIME_FILE"
  else
    cat > "$NVIDIA_PRIME_FILE" <<'EOF'
options nvidia NVreg_DynamicPowerManagement=0x02
EOF
    ok "PRIME config written: $NVIDIA_PRIME_FILE"
  fi

  if command -v nvidia-smi >/dev/null 2>&1; then
    if nvidia-smi >/dev/null 2>&1; then
      ok "nvidia-smi is available and responding."
    else
      warn "nvidia-smi found but not responding yet. Reboot is likely required."
    fi
  else
    warn "nvidia-smi not found yet. Reboot and rerun validation if needed."
  fi
}

undo_nvidia_alienware() {
  info "Removing NVIDIA packages and managed config (alienware profile)..."

  if rpm -qa | grep -qi nvidia; then
    dnf remove -y '*nvidia*' || warn "Some NVIDIA packages could not be removed automatically."
  else
    skip "No installed NVIDIA packages detected."
  fi

  NVIDIA_PRIME_FILE="/etc/modprobe.d/nvidia-prime.conf"
  if [ -f "$NVIDIA_PRIME_FILE" ]; then
    rm -f "$NVIDIA_PRIME_FILE"
    ok "Removed $NVIDIA_PRIME_FILE"
  else
    skip "$NVIDIA_PRIME_FILE does not exist."
  fi

  info "Regenerating initramfs after cleanup..."
  dracut --force || warn "dracut returned non-zero after cleanup."
}

run_profile() {
  case "$GPU_PROFILE" in
    alienware)
      case "$ACTION" in
        install)
          install_nvidia_alienware
          ;;
        undo)
          undo_nvidia_alienware
          ;;
        reset)
          undo_nvidia_alienware
          install_nvidia_alienware
          ;;
      esac
      ;;
  esac
}

main() {
  validate_inputs
  require_root
  run_profile

  echo ""
  ok "GPU script completed: profile=$GPU_PROFILE action=$ACTION"
  warn "Reboot recommended to fully apply NVIDIA module changes."
}

main

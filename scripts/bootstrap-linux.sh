#!/usr/bin/env bash
#
# Installs what FactorIA needs to build on Debian and Ubuntu, then prints the
# equivalent packages for Fedora and Arch. Safe to run again.
#
#   ./scripts/bootstrap-linux.sh
#
# Uses sudo unless you are root. Afterwards: ./scripts/build.sh debug --test
set -euo pipefail

# Compiler, CMake, Ninja, ccache, and the X11/GL/EGL/ALSA/curl development files
# the engine links against. The Mesa DRI driver and Xvfb give headless GPU code
# (EGL + llvmpipe) a software renderer when there is no display or GPU.
APT_PACKAGES=(
    build-essential cmake ninja-build ccache
    libx11-dev libxi-dev libxcursor-dev libxrandr-dev
    libgl-dev libopengl-dev libegl-dev libgles-dev
    libasound2-dev libcurl4-openssl-dev
    libgl1-mesa-dri libegl-mesa0 mesa-utils xvfb
)

print_equivalents() {
    cat <<'EOF'
Equivalent packages on other distributions:
  Fedora:  sudo dnf install gcc-c++ make cmake ninja-build ccache \
             libX11-devel libXi-devel libXcursor-devel libXrandr-devel \
             mesa-libGL-devel mesa-libEGL-devel mesa-libGLES-devel mesa-dri-drivers \
             alsa-lib-devel libcurl-devel xorg-x11-server-Xvfb xorg-x11-xauth mesa-demos
  Arch:    sudo pacman -S --needed base-devel cmake ninja ccache \
             libx11 libxi libxcursor libxrandr libglvnd mesa alsa-lib curl \
             xorg-server-xvfb xorg-xauth mesa-utils
EOF
}

if [[ "$(uname -s)" != Linux ]]; then
    echo "error: this script is for Linux. On macOS use ./scripts/bootstrap-macos.sh." >&2
    exit 1
fi

distro_ids() {
    [[ -r /etc/os-release ]] || return 0
    # shellcheck disable=SC1091  # /etc/os-release is a standard file, read at run time
    (. /etc/os-release && echo "${ID:-} ${ID_LIKE:-}")
}

IDS="$(distro_ids)"
case " $IDS " in
    *" debian "*|*" ubuntu "*) ;;
    *)
        echo "error: no Debian/Ubuntu (apt) system detected (ID: ${IDS:-unknown})." >&2
        echo "Install the packages below with your package manager, then run ./scripts/build.sh." >&2
        print_equivalents >&2
        exit 1
        ;;
esac

SUDO=()
if [[ "$(id -u)" -ne 0 ]]; then
    command -v sudo >/dev/null 2>&1 || { echo "error: run as root, or install sudo." >&2; exit 1; }
    SUDO=(sudo)
fi

echo "==> apt: installing build dependencies"
"${SUDO[@]}" apt-get update
"${SUDO[@]}" env DEBIAN_FRONTEND=noninteractive apt-get install -y "${APT_PACKAGES[@]}"

# CMake 3.24 is the minimum. Older Debian/Ubuntu releases ship older CMake.
CMAKE_VERSION="$(cmake --version 2>/dev/null | sed -n '1s/[^0-9]*\([0-9][0-9.]*\).*/\1/p')" || true
if [[ -z "$CMAKE_VERSION" ]] || [[ "$(printf '%s\n' 3.24 "$CMAKE_VERSION" | sort -V | head -n1)" != 3.24 ]]; then
    echo "warning: CMake is ${CMAKE_VERSION:-missing}; FactorIA needs 3.24 or newer." >&2
    echo "         Install a newer CMake from https://apt.kitware.com or https://cmake.org/download/" >&2
fi

echo "==> done. Next: ./scripts/build.sh debug --test"
echo
print_equivalents

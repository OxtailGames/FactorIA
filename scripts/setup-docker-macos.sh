#!/usr/bin/env bash
#
# One-click setup of Docker on a Mac, so scripts/ci-docker.sh (and the linux/windows/sniper jobs of ci-local.sh) can run
# the Linux and Windows (MinGW-w64 + Wine) CI jobs here. Installs Colima and the Docker CLI with Homebrew, starts a
# Colima VM (Apple Virtualization.framework "vz" with Rosetta, so linux/amd64 images, the ones GitHub's runners run,
# execute at near-native speed) and checks that `docker run` works. Safe to run again: what is installed is left alone
# and a running VM is not restarted.
#
#   ./scripts/setup-docker-macos.sh
#
# Environment (only read when the VM is created or started):
#   FA_DOCKER_CPUS    VM CPUs    (default 6)
#   FA_DOCKER_MEMORY  VM memory in GiB (default 8)
#   FA_DOCKER_DISK    VM disk in GiB, grown never shrunk (default 100)
#   FA_COLIMA_PROFILE Colima profile (default: default)
set -euo pipefail

if [[ "$(uname -s)" != Darwin ]]; then
    echo "error: this script is for macOS. On Linux install Docker or Podman with your package manager." >&2
    exit 1
fi
if [[ "$(uname -m)" != arm64 ]]; then
    echo "note: this is an Intel Mac: linux/amd64 images run natively, Rosetta is not needed."
fi
command -v brew >/dev/null 2>&1 || { echo "error: Homebrew is not installed. Get it from https://brew.sh, then run this script again." >&2; exit 1; }

CPUS="${FA_DOCKER_CPUS:-6}"
MEMORY="${FA_DOCKER_MEMORY:-8}"
DISK="${FA_DOCKER_DISK:-100}"
PROFILE="${FA_COLIMA_PROFILE:-default}"

need=()
for pkg in colima docker docker-buildx; do
    brew list --formula "$pkg" >/dev/null 2>&1 || need+=("$pkg")
done
if [[ ${#need[@]} -gt 0 ]]; then
    echo "==> Homebrew: installing ${need[*]}"
    brew install "${need[@]}"
else
    echo "==> Homebrew: colima, docker and docker-buildx are already installed"
fi

# The Docker CLI finds the buildx plugin in ~/.docker/cli-plugins.
plugin_dir="$HOME/.docker/cli-plugins"
if [[ ! -e "$plugin_dir/docker-buildx" ]] && [[ -x "$(brew --prefix)/opt/docker-buildx/bin/docker-buildx" ]]; then
    echo "==> linking docker-buildx into $plugin_dir"
    mkdir -p "$plugin_dir"
    ln -sf "$(brew --prefix)/opt/docker-buildx/bin/docker-buildx" "$plugin_dir/docker-buildx"
fi

if colima status -p "$PROFILE" >/dev/null 2>&1; then
    echo "==> Colima ($PROFILE) is already running"
else
    echo "==> starting Colima ($PROFILE): $CPUS CPUs, ${MEMORY} GiB memory, ${DISK} GiB disk, vz + Rosetta"
    args=(start -p "$PROFILE" --cpu "$CPUS" --memory "$MEMORY" --disk "$DISK")
    if [[ "$(uname -m)" == arm64 ]]; then args+=(--vm-type vz --vz-rosetta --arch aarch64); fi
    colima "${args[@]}"
fi

# Colima ("default" profile) creates the docker context "colima"; other profiles "colima-<name>".
ctx=colima; [[ "$PROFILE" == default ]] || ctx="colima-$PROFILE"
docker context use "$ctx" >/dev/null 2>&1 || true

echo "==> checking that Docker works (linux/amd64)"
docker run --rm --platform linux/amd64 alpine:3 uname -m
echo "==> done. Next: ./scripts/ci-docker.sh   (Linux + Windows CI jobs; the first run builds the image)"

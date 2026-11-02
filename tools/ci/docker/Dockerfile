# The image scripts/ci-docker.sh runs the Linux and Windows (MinGW-w64 + Wine) jobs of scripts/ci-local.sh in.
# Ubuntu 24.04 like GitHub's ubuntu-24.04 runner (built for linux/amd64), with the packages of scripts/bootstrap-linux.sh
# plus the cross compiler and Wine of the windows job. The checkout is mounted at /src at run time, not copied in.
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
# Keep this list in step with APT_PACKAGES of scripts/bootstrap-linux.sh.
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential cmake ninja-build ccache git curl ca-certificates unzip xz-utils python3 pkg-config \
        libx11-dev libxi-dev libxcursor-dev libxrandr-dev \
        libgl-dev libopengl-dev libegl-dev libgles-dev \
        libasound2-dev libcurl4-openssl-dev \
        libgl1-mesa-dri libegl-mesa0 mesa-utils xvfb xauth \
        g++-mingw-w64-x86-64-posix wine64 wine \
    && rm -rf /var/lib/apt/lists/*

# The container user is root and the checkout belongs to another uid: git must trust it.
RUN git config --system --add safe.directory '*'
WORKDIR /src

FROM docker.io/library/ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive

# Build tools + LLVM/clang 22
RUN apt-get update && apt-get install -y wget gnupg lsb-release software-properties-common \
      git cmake ninja-build python3 python3-pip curl build-essential ca-certificates \
 && wget -qO /tmp/llvm.sh https://apt.llvm.org/llvm.sh && bash /tmp/llvm.sh 22 \
 && apt-get install -y libclang-22-dev clang-format-22 libzstd-dev libedit-dev libcurl4-openssl-dev zlib1g-dev libxml2-dev \
 && pip install --break-system-packages ruff==0.15.22 \
 && rm -rf /var/lib/apt/lists/*

# Rust, installed system-wide inside the image
ENV RUSTUP_HOME=/opt/rustup CARGO_HOME=/opt/cargo
ENV PATH=/opt/cargo/bin:/usr/lib/llvm-22/bin:$PATH
RUN curl -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path

# Build Cpp2Rust (this also downloads the Rust toolchains it pins)
RUN git clone https://github.com/Cpp2Rust/cpp2rust /opt/cpp2rust \
 && cmake -S /opt/cpp2rust -B /opt/cpp2rust/build -G Ninja \
      -DLLVM_DIR=/usr/lib/llvm-22/lib/cmake/llvm \
      -DClang_DIR=/usr/lib/llvm-22/lib/cmake/clang \
      -DCMAKE_CXX_COMPILER=clang++-22 \
 && ninja -C /opt/cpp2rust/build

# Pre-download the runtime library's crates so compiling output works offline
RUN cd /opt/cpp2rust/libcc2rs && cargo fetch

ENV PATH=/opt/cpp2rust/build/cpp2rust:$PATH
WORKDIR /work

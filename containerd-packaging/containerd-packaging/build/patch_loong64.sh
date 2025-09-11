#!/usr/bin/env bash
set -euo pipefail

CURRENT_DIR=$(pwd)

# runc patch
if [ -f "libcontainer/seccomp/patchbpf/enosys_linux.go" ]; then
    echo "[INFO] Detected runc source code."

    if ! grep -q "LOONGARCH64" "libcontainer/seccomp/patchbpf/enosys_linux.go"; then
        echo "[INFO] Applying runc patch for LoongArch64..."
        curl -sSL "https://github.com/loong64/containerd-packaging/raw/refs/heads/main/runc.patch" | git apply
        echo "[INFO] Updating libseccomp-golang dependency..."
        go get -u github.com/seccomp/libseccomp-golang@v0.10.1-0.20240814065753-28423ed7600d
        go mod vendor
        echo "[INFO] Cleaning up Makefile..."
        sed -i "s@--dirty @@g" Makefile
    else
        echo "[INFO] runc already patched."
    fi

# containerd patch
elif [ -f "vendor/github.com/cilium/ebpf/internal/endian_le.go" ]; then
    echo "[INFO] Detected containerd source code."

    if ! grep -q "arm64 || loong64" "vendor/github.com/cilium/ebpf/internal/endian_le.go"; then
        echo "[INFO] Patching endian_le.go for loong64 support (arm64)..."
        sed -i "s@|| arm64@|| arm64 || loong64@g" "vendor/github.com/cilium/ebpf/internal/endian_le.go"
    fi
    if ! grep -q "riscv64 loong64" "vendor/github.com/cilium/ebpf/internal/endian_le.go"; then
        echo "[INFO] Patching endian_le.go for loong64 support (riscv64)..."
        sed -i "s@ppc64le riscv64@ppc64le riscv64 loong64@g" "vendor/github.com/cilium/ebpf/internal/endian_le.go"
    fi

    echo "[INFO] Cleaning up Makefile..."
    sed -i "s@--dirty='.m' @@g" Makefile
    sed -i 's@$(shell if ! git diff --no-ext-diff --quiet --exit-code; then echo .m; fi)@@g' Makefile

    echo "[INFO] sed to install-img..."
    sed -i "/git checkout .*$/{
  n
  c\
go get -u golang.org/x/sys@v0.1.0\ngo mod vendor\nmake
}" script/setup/install-imgcrypt

    echo "[INFO] sed to install-runc..."
sed -i "/git checkout .*$/a \
curl -sSL https://raw.githubusercontent.com/Loongson-Cloud-Community/shell_store/refs/heads/main/loong64-fix.sh | bash\
\ngo get -u github.com/seccomp/libseccomp-golang@v0.10.1-0.20240814065753-28423ed7600d\
\ngo mod vendor\
\tsed -i \"s@--dirty @@g\" Makefile
" script/setup/install-runc
#    sed -i "/git checkout .*$/a \
#curl -sSL \"https://github.com/loong64/containerd-packaging/raw/refs/heads/main/runc.patch\" | git apply\
#\ngo get -u github.com/seccomp/libseccomp-golang@v0.10.1-0.20240814065753-28423ed7600d\
#\ngo mod vendor\
#\tsed -i \"s@--dirty @@g\" Makefile
#" script/setup/install-runc


else
    echo "[WARN] Current directory ($CURRENT_DIR) does not look like runc or containerd source."
fi


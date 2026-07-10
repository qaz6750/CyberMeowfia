#!/usr/bin/env bash
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$repo_root"

api=${ANDROID_API:-29}
ndk_home=${ANDROID_NDK_HOME:-}

if [[ -z "$ndk_home" || ! -d "$ndk_home" ]]; then
  echo "ANDROID_NDK_HOME must point to an installed Android NDK."
  exit 1
fi

clang_bin="$ndk_home/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android${api}-clang"
if [[ ! -x "$clang_bin" ]]; then
  echo "Android clang not found: $clang_bin"
  exit 1
fi

mkdir -p build

"$clang_bin" \
  -O2 \
  -pthread \
  IonStack/CVE-2026-43499/poc/poc.c \
  -o build/ghostlock-poc-arm64

file build/ghostlock-poc-arm64
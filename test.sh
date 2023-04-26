#!/usr/bin/bash
set -e
set -x

# This is a minimal reproduction that also removes cargo from the equation to make it
# a little clearer how to reproduce with rustc, with fewer moving parts
#
# Before running:
# 1. Download and unpack r25c NDK for Windows from here: https://developer.android.com/ndk/downloads
#
# 2. Point ANDROID_NDK_ROOT to the unpacked NDK
#
#   $ export ANDROID_NDK_ROOT='path/to/unpacked/ndk'
#
# 3. Install 1.68 and 1.69 aarch64-linux-android targets
#
#   $ rustup +1.68 target add aarch64-linux-android
#   $ rustup +1.69 target add aarch64-linux-android
#
# By default the script will run with the 1.69 compiler, and the version
# can be overriden by passing the version as an argument

RUST_VERSION=1.69
if ! test -z "$1"; then
    RUST_VERSION=$1
fi
RUSTC=~/.rustup/toolchains/${RUST_VERSION}-x86_64-pc-windows-msvc/bin/rustc.exe


mkdir -p deps
if ! test -d deps/once_cell-1.17.1; then
    git clone https://github.com/matklad/once_cell.git --depth 1 --branch v1.17.1 deps/once_cell-1.17.1
fi
if ! test -d deps/cfg-if-1.0.0; then
    git clone https://github.com/rust-lang/cfg-if.git --depth 1 --branch 1.0.0 deps/cfg-if-1.0.0
fi
if ! test -d deps/libc-0.2.142; then
    git clone https://github.com/rust-lang/libc --depth 1 --branch 0.2.142 deps/libc-0.2.142
fi
if ! test -d deps/sysinfo-0.27; then
    git clone https://github.com/GuillaumeGomez/sysinfo --depth 1 --branch 0.27 deps/sysinfo-0.27
fi

cargo clean

# Note the build.rs script output is the same with either compiler version and for debug / release so
# we skip it and just pass the cfg options it outputs

mkdir -p target/aarch64-linux-android/release/deps

CFG_IF_SRC='deps/cfg-if-1.0.0/src/lib.rs'
ONCE_CELL_SRC='deps/once_cell-1.17.1/src/lib.rs'
LIBC_SRC='deps/libc-0.2.142/src/lib.rs'
SYSINFO_SRC='deps/sysinfo-0.27/src/lib.rs'

# Uncomment to test building against the source the cargo fetches
#REGISTRY="$HOME/.cargo/registry/src/github.com-1ecc6299db9ec823"
#CFG_IF_SRC="$REGISTRY/cfg-if-1.0.0/src/lib.rs"
#ONCE_CELL_SRC="$REGISTRY/once_cell-1.17.1/src/lib.rs"
#LIBC_SRC="$REGISTRY/libc-0.2.142/src/lib.rs"
#SYSINFO_SRC="$REGISTRY/sysinfo-0.27.8/src/lib.rs"

$RUSTC --crate-name cfg_if --edition=2018 "$CFG_IF_SRC" \
    --crate-type lib --emit=dep-info,metadata,link \
    -C opt-level=3 -C embed-bitcode=no \
    --out-dir 'target/aarch64-linux-android/release/deps' \
    --target aarch64-linux-android \
    -C "linker=$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/windows-x86_64/bin/aarch64-linux-android21-clang.cmd" \
    -L 'dependency=target/aarch64-linux-android/release/deps' \
    --cap-lints warn

$RUSTC --crate-name once_cell --edition=2021 "$ONCE_CELL_SRC" \
    --crate-type lib \
    --emit=dep-info,metadata,link \
    -C opt-level=3 -C embed-bitcode=no \
    --cfg 'feature="alloc"' --cfg 'feature="default"' --cfg 'feature="race"' --cfg 'feature="std"' \
    --out-dir 'target/aarch64-linux-android/release/deps' \
    --target aarch64-linux-android \
    -C "linker=$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/windows-x86_64/bin/aarch64-linux-android21-clang.cmd" \
    -L 'dependency=target/aarch64-linux-android/release/deps' \
    --cap-lints warn

$RUSTC --crate-name libc "$LIBC_SRC" \
    --crate-type lib \
    --emit=dep-info,metadata,link \
    -C opt-level=3 -C embed-bitcode=no \
    --cfg 'feature="default"' --cfg 'feature="std"' \
    --out-dir 'target/aarch64-linux-android/release/deps' \
    --target aarch64-linux-android \
    -C "linker=$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/windows-x86_64/bin/aarch64-linux-android21-clang.cmd" \
    -L 'dependency=target/aarch64-linux-android/release/deps' \
    --cap-lints warn \
    --cfg freebsd11 --cfg libc_priv_mod_use --cfg libc_union --cfg libc_const_size_of --cfg libc_align --cfg libc_int128 \
    --cfg libc_core_cvoid --cfg libc_packedN --cfg libc_cfg_target_vendor --cfg libc_non_exhaustive --cfg libc_long_array \
    --cfg libc_ptr_addr_of --cfg libc_underscore_const_names --cfg libc_const_extern_fn

$RUSTC --crate-name sysinfo --edition=2018 "$SYSINFO_SRC" \
    --crate-type rlib --crate-type cdylib \
    --emit=dep-info,link -C opt-level=3 -C embed-bitcode=no \
    --out-dir 'target/aarch64-linux-android/release/deps' \
    --target aarch64-linux-android \
    -C "linker=$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/windows-x86_64/bin/aarch64-linux-android21-clang.cmd" \
    -L 'dependency=target/aarch64-linux-android/release/deps' \
    --extern 'cfg_if=target/aarch64-linux-android/release/deps/libcfg_if.rlib' \
    --extern 'libc=target/aarch64-linux-android/release/deps/liblibc.rlib' \
    --extern 'once_cell=target/aarch64-linux-android/release/deps/libonce_cell.rlib' \
    --cap-lints warn

echo ""
echo "PASSED"
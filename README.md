# Summary

I see that this crate will fail to build (link) on Windows using `cargo apk` or `cargo ndk`
with Rust 1.69, even though the `sysinfo` crate itself will compile and link ok.

The crate will also build if the default `sysinfo` features are enabled.

## Steps to reproduce with Cargo

```bash
cargo install cargo-ndk
cargo install cargo-apk
rustup +1.68 target add aarch64-linux-android
rustup +1.69 target add aarch64-linux-android

cargo +1.68 ndk -t arm64-v8a build --release # OK
cargo +1.68 apk build --release # OK

cargo +1.69 ndk -t arm64-v8a build --release # FAILS
cargo +1.69 apk build --release # FAILS

# Edit Cargo.toml and uncomment sysinfo line with default features enabled
cargo +1.69 ndk -t arm64-v8a build --release # OK
cargo +1.69 apk build --release # OK
```

## To reproduce with rustc

There is a `./test.sh` script that can be run under 'Git Bash' that will also
reproduce the issue by running rustc to manually build the deps.

By default the script will run with the 1.69 compiler, and the version
can be overriden by passing the version as an argument
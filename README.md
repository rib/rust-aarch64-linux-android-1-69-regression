# Summary

I see that this crate will fail to build (link) on Windows using `cargo apk` or `cargo ndk`
with Rust 1.69, even though the `sysinfo` crate itself will compile and link ok.

The crate will also build if the default `sysinfo` features are enabled.

## Steps

```bash
cargo install cargo-ndk
cargo install cargo-apk
rustup +1.68 target add aarch64-linux-android
rustup +1.69 target add aarch64-linux-android

cargo +1.68 ndk -t arm64-v8a build # OK
cargo +1.68 apk build # OK

cargo +1.69 ndk -t arm64-v8a build # FAILS
cargo +1.69 apk build # FAILS

# Edit Cargo.toml and uncomment sysinfo line with default features enabled
cargo +1.69 ndk -t arm64-v8a build # OK
cargo +1.69 apk build # OK
```

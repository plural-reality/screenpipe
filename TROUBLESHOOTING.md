# Troubleshooting Guide

This document covers common issues when building and running screenpipe from source.

## macOS Development with Nix (Recommended)

### Prerequisites

1. **Nix with Flakes**
   ```bash
   # Install Nix
   curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

   # Flakes are enabled by default with Determinate installer
   ```

2. **Xcode (Full Installation)**
   - Install from App Store (command line tools alone are insufficient)
   - Accept license and run first launch:
     ```bash
     sudo xcodebuild -license
     xcodebuild -runFirstLaunch
     ```

### Build Steps

```bash
# 1. Clone repository
git clone https://github.com/screenpipe/screenpipe
cd screenpipe

# 2. Enter Nix dev shell (provides all dependencies)
nix develop

# 3. Build CLI
cargo build --release --features metal

# 4. Build Tauri app
cd apps/screenpipe-app-tauri
bun install
bun tauri build

# 5. Run the app
open "src-tauri/target/release/bundle/macos/screenpipe - Development.app"
```

### Required macOS Permissions

After first launch, grant these permissions in **System Settings > Privacy & Security**:

| Permission | Location | Required For |
|------------|----------|--------------|
| Screen Recording | Privacy & Security > Screen Recording | Vision/OCR capture |
| Microphone | Privacy & Security > Microphone | Audio transcription |
| Accessibility | Privacy & Security > Accessibility | UI event tracking (optional) |

**Important**: Development builds are signed with a developer certificate. Each rebuild may require re-granting permissions if the app signature changes.

### Common Issues

#### 1. "Server not working" in UI

**Symptoms**: App launches but shows "screenpipe server not working"

**Causes & Solutions**:

| Cause | Solution |
|-------|----------|
| Screen Recording permission denied | Grant in System Settings > Privacy & Security > Screen Recording |
| Whisper model still downloading | Wait for ~800MB download to complete (check logs) |
| Port 3030 already in use | Kill existing process: `lsof -ti:3030 \| xargs kill` |

**Check logs**:
```bash
tail -f ~/.screenpipe/screenpipe-app.*.log
```

#### 2. "No audio devices available"

**Symptoms**: Log shows `WARN screenpipe_app::embedded_server: No audio devices available`

**Solution**: Grant microphone permission in System Settings > Privacy & Security > Microphone

#### 3. Server hangs on startup (Whisper model download)

**Symptoms**: Server starts initializing but never becomes healthy. Log shows:
```
INFO screenpipe_audio::transcription::whisper::model: downloading model "ggml-large-v3-turbo.bin"
```

**Solution**: Pre-download the model manually (~800MB):
```bash
mkdir -p ~/Library/Caches/huggingface/hub/models--ggerganov--whisper.cpp/blobs
curl -L -o ~/Library/Caches/huggingface/hub/models--ggerganov--whisper.cpp/blobs/ggml-large-v3-turbo.bin \
  "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo.bin"
```

#### 4. Xcode SDK errors during Rust build

**Symptoms**: Errors about missing frameworks or SDK paths during `cargo build`

**Cause**: Nix may override `SDKROOT` environment variable

**Solution**: The `flake.nix` unsets `SDKROOT` in `shellHook`. Ensure you're in the Nix shell:
```bash
nix develop
echo $SDKROOT  # Should be empty
```

If still having issues, manually unset:
```bash
unset SDKROOT
unset NIX_CFLAGS_COMPILE
unset NIX_LDFLAGS
```

#### 5. LIBCLANG_PATH errors (bindgen)

**Symptoms**: Build fails with `Unable to find libclang`

**Solution**: Ensure you're in the Nix dev shell which sets `LIBCLANG_PATH`:
```bash
nix develop
echo $LIBCLANG_PATH  # Should point to Nix store
```

#### 6. OpenSSL linking errors

**Symptoms**: Build fails with OpenSSL-related linker errors

**Solution**: Nix dev shell sets these automatically. Verify:
```bash
echo $OPENSSL_DIR
echo $OPENSSL_LIB_DIR
echo $OPENSSL_INCLUDE_DIR
```

### Nix Flake Architecture

The `flake.nix` uses `mkShellNoCC` to avoid Nix's stdenv interfering with Xcode's toolchain:

- **Rust**: Provided by `rust-overlay` (version pinned in `rust-toolchain.toml`)
- **System Libraries**: ffmpeg, openssl, libclang from Nixpkgs
- **Native Compilation**: Delegated to Xcode (unsets `SDKROOT`, `NIX_CFLAGS_COMPILE`, `NIX_LDFLAGS`)
- **Frontend**: bun, nodejs from Nixpkgs

This hybrid approach ensures:
1. Reproducible dependency versions via Nix
2. Correct macOS framework linking via Xcode
3. Metal support for ML acceleration

### Verifying Server Health

```bash
# Check if server is running
curl http://localhost:3030/health

# Expected response (when healthy):
# {"status":"ok",...}

# Check process
ps aux | grep screenpipe
```

### Clean Rebuild

If issues persist:
```bash
# Clean Rust build artifacts
cargo clean

# Clean Tauri/frontend
cd apps/screenpipe-app-tauri
rm -rf node_modules .next out
bun install

# Rebuild
cargo build --release --features metal
bun tauri build
```

### Reset App Data

```bash
# Backup first if needed
cp -r ~/.screenpipe ~/.screenpipe.backup

# Remove app data
rm -rf ~/.screenpipe

# Remove cached models (will re-download on next launch)
rm -rf ~/Library/Caches/screenpipe
rm -rf ~/Library/Caches/huggingface/hub/models--ggerganov--whisper.cpp
```

## Related Documentation

- [CONTRIBUTING.md](CONTRIBUTING.md) - Full build instructions for all platforms
- [TESTING.md](TESTING.md) - Regression testing checklist

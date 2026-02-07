{
  description = "screenpipe development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      rust-overlay,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs { inherit system overlays; };

        # Rust 1.92.0 (rust-toolchain.toml準拠)
        rustToolchain = pkgs.rust-bin.stable."1.92.0".default.override {
          extensions = [
            "rust-src"
            "rust-analyzer"
            "clippy"
            "rustfmt"
          ];
          targets = [
            "aarch64-apple-darwin"
            "x86_64-apple-darwin"
          ];
        };

      in
      {
        devShells.default = pkgs.mkShellNoCC {
          # mkShellNoCC: Nixのstdenvを使わず、ホストのXcodeに完全委譲

          packages =
            with pkgs;
            [
              # Rust
              rustToolchain

              # ビルドツール (Nixから提供)
              pkg-config
              cmake
              gnumake

              # bindgen用 (libclangのみ)
              llvmPackages.libclang.lib

              # 依存ライブラリ
              ffmpeg_7
              openssl

              # ユーティリティ
              jq
              wget
              git-lfs

              # Tauri / フロントエンド
              bun
              nodejs_22

              # 開発ツール
              sqlx-cli
              cargo-watch
              cargo-edit
            ];

          # 環境変数 (shellHookより前に評価される)
          LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
          OPENSSL_DIR = "${pkgs.openssl.dev}";
          OPENSSL_LIB_DIR = "${pkgs.openssl.out}/lib";
          OPENSSL_INCLUDE_DIR = "${pkgs.openssl.dev}/include";
          CARGO_NET_GIT_FETCH_WITH_CLI = "true";
          MACOSX_DEPLOYMENT_TARGET = "13.0";

          shellHook = ''
            # macOS: Xcodeツールチェインに完全委譲
            if [[ "$(uname)" == "Darwin" ]]; then
              # Nixが設定するSDKROOTを除去し、Xcodeのものを使用
              unset SDKROOT
              unset NIX_CFLAGS_COMPILE
              unset NIX_LDFLAGS

              XCODE_SDK="$(xcrun --show-sdk-path 2>/dev/null)"
              XCODE_TOOLCHAIN="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain"

              if [[ -z "$XCODE_SDK" ]]; then
                echo "⚠️  Xcode SDK not found. Run: xcode-select --install"
                exit 1
              fi

              export SDKROOT="$XCODE_SDK"
              export CC="$XCODE_TOOLCHAIN/usr/bin/clang"
              export CXX="$XCODE_TOOLCHAIN/usr/bin/clang++"
              export CMAKE_C_COMPILER="$CC"
              export CMAKE_CXX_COMPILER="$CXX"
              export CMAKE_OSX_SYSROOT="$XCODE_SDK"

              # C++ stdlib paths for CMake builds
              CXX_INCLUDE="$XCODE_TOOLCHAIN/usr/include/c++/v1"
              SDK_CXX_INCLUDE="$XCODE_SDK/usr/include/c++/v1"
              COMMON_CXX_FLAGS="-isysroot $XCODE_SDK -isystem $CXX_INCLUDE -isystem $SDK_CXX_INCLUDE -stdlib=libc++"
              export CXXFLAGS="$COMMON_CXX_FLAGS"
              export CFLAGS="-isysroot $XCODE_SDK"

              # CMake respects these variables for C++ flags
              export CMAKE_CXX_FLAGS="$COMMON_CXX_FLAGS"
              export CMAKE_C_FLAGS="-isysroot $XCODE_SDK"

              # Xcodeツールをパスの先頭に追加
              export PATH="/Applications/Xcode.app/Contents/Developer/usr/bin:$XCODE_TOOLCHAIN/usr/bin:$PATH"

              # OpenSSLのpkg-configパス
              export PKG_CONFIG_PATH="${pkgs.openssl.dev}/lib/pkgconfig:$PKG_CONFIG_PATH"

              # FFmpegのpkg-configパス
              export PKG_CONFIG_PATH="${pkgs.ffmpeg_7.dev}/lib/pkgconfig:$PKG_CONFIG_PATH"
            fi

            echo ""
            echo "🎬 screenpipe development environment"
            echo "   Rust: $(rustc --version)"
            echo "   Bun:  $(bun --version)"
            echo "   SDK:  $SDKROOT"
            echo "   CC:   $CC"
            echo ""
            echo "📦 Build:"
            echo "   cargo build --release --features metal"
            echo ""
          '';
        };
      }
    );
}

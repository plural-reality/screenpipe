# Building Screenpipe on macOS

このドキュメントでは、ScreenpipeをローカルのmacOS環境でビルドして起動する手順を説明します。

## 前提条件

- macOS（Apple Silicon または Intel）
- Homebrew がインストール済み
- App Storeアカウント（Xcodeのインストールに必要）

## 1. 依存関係のインストール

### 1.1 Rust toolchainのインストール

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

### 1.2 Homebrewパッケージのインストール

```bash
brew install pkg-config ffmpeg jq tesseract cmake
```

### 1.3 Bun CLIのインストール

```bash
curl -fsSL https://bun.sh/install | bash
```

### 1.4 Xcodeのインストール

**重要:** Command Line Toolsだけでは不十分です。完全版のXcodeが必要です。

#### 方法A: App Storeから（推奨）

```bash
open "macappstore://apps.apple.com/app/xcode/id497799835"
```

#### 方法B: mas-cli経由

```bash
brew install mas
sudo mas install 497799835
```

#### Xcodeの初期化

```bash
sudo xcodebuild -license accept
xcodebuild -runFirstLaunch
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

## 2. リポジトリのクローン

```bash
git clone https://github.com/plural-reality/screenpipe.git
cd screenpipe
```

## 3. ビルド

### 3.1 JavaScriptの依存関係をインストール

```bash
cd apps/screenpipe-app-tauri
bun install
```

### 3.2 アプリケーションをビルド

```bash
export PATH="$HOME/.cargo/bin:$PATH"
export SDKROOT=$(xcrun --show-sdk-path)
bun tauri build
```

ビルドには5-10分程度かかります。500個以上のRustクレートをコンパイルします。

## 4. 起動

ビルドが完了すると、アプリケーションは以下の場所に配置されます：

```
apps/screenpipe-app-tauri/src-tauri/target/release/bundle/macos/screenpipe - Development.app
```

### 起動方法

```bash
open "apps/screenpipe-app-tauri/src-tauri/target/release/bundle/macos/screenpipe - Development.app"
```

または、Finderから上記のパスにある `.app` ファイルをダブルクリックして起動できます。

## トラブルシューティング

### Xcodeが見つからないエラー

```
xcode-select: error: tool 'xcodebuild' requires Xcode
```

このエラーが出た場合、完全版のXcodeをインストールする必要があります（Command Line Toolsだけでは不十分）。

### Rustのバージョンエラー

```
rustc X.XX.X is not supported
```

Rustを最新版に更新してください：

```bash
rustup update stable
export PATH="$HOME/.cargo/bin:$PATH"
```

### 既知の問題

- **permission-recovery/page.tsx**: `resetAndRequestPermission` メソッドが存在しない問題は修正済み（commit dd287a15）

## ビルド情報

- **Node.js**: Next.js 15.1.4
- **Rust**: 1.92+ 必須
- **ビルド時間**: 約5-10分（初回ビルド）
- **バイナリサイズ**: 約43MB
- **メモリ使用量**: 約300MB（実行時）

## 開発モード

開発中は以下のコマンドで開発サーバーを起動できます：

```bash
cd apps/screenpipe-app-tauri
bun tauri dev
```

## 参考

- [公式ドキュメント](https://docs.screenpi.pe/getting-started)
- [CONTRIBUTING.md](./CONTRIBUTING.md)

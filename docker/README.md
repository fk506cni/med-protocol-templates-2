# Docker環境

このディレクトリには、プロジェクトで使用するDocker環境が格納されています。

## ディレクトリ構成

```
docker/
├── README.md          # このファイル（Docker環境全体の概要）
└── latex/             # LaTeX環境
    ├── Dockerfile         # LaTeX環境のDockerイメージ定義
    ├── build-image.sh     # Dockerイメージビルドスクリプト
    └── build-pdf.sh       # PDFビルドスクリプト
```

## 利用可能な環境

### LaTeX環境 (`latex/`)

研究計画書のPDF生成に使用するLaTeX環境です。

- **用途**: LaTeX文書のコンパイル、PDF生成
- **イメージ名**: `med-protocol-latex`
- **詳細**: `latex/` ディレクトリ内のDockerfileを参照

#### クイックスタート

```bash
# Dockerイメージをビルド
cd docker/latex
./build-image.sh

# またはプロジェクトルートから
docker build -f docker/latex/Dockerfile -t med-protocol-latex .
```

## 今後の拡張

このプロジェクトでは、今後以下のような追加環境を導入する可能性があります：

- **Python環境**: データ解析、統計処理用
- **R環境**: 統計解析、グラフ作成用
- **Pandoc環境**: 文書変換、マークダウン処理用

新しい環境を追加する場合は、`docker/`以下に新しいディレクトリを作成してください：

```
docker/
├── README.md
├── latex/
├── python/      # 例: Python環境
└── r/           # 例: R環境
```

各環境のディレクトリには、以下のファイルを含めることを推奨します：

- `Dockerfile`: イメージ定義
- `build-image.sh`: イメージビルドスクリプト
- その他、環境固有のスクリプトやドキュメント

## 共通のDockerコマンド

### イメージ一覧の確認

```bash
docker images
```

### コンテナ一覧の確認

```bash
docker ps -a
```

### 未使用イメージの削除

```bash
docker image prune
```

### 特定のイメージを削除

```bash
docker rmi <イメージ名>
```

### コンテナのログを確認

```bash
docker logs <コンテナ名またはID>
```

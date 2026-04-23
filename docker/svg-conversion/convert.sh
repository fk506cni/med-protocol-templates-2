#!/bin/bash

# SVGからPDFへの変換スクリプト
# Times New Romanフォントを保持したPDF変換を行います

set -e

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# 引数チェック
if [ $# -eq 0 ]; then
    echo "使用方法: $0 <SVGファイルパス> [出力PDFファイル名]"
    echo ""
    echo "例:"
    echo "  $0 ./src/figures/Fig4.svg"
    echo "  $0 ./src/figures/Fig4.svg Fig4-output.pdf"
    echo "  $0 figs/Fig1-exp-design-v2.svg"
    echo ""
    echo "SVGファイルは相対パスまたは絶対パスで指定できます"
    exit 1
fi

INPUT_SVG="$1"
OUTPUT_PDF="${2:-${INPUT_SVG%.svg}.pdf}"

# 入力ファイルの絶対パスを取得
if [[ "$INPUT_SVG" = /* ]]; then
    # 絶対パスの場合
    INPUT_FULLPATH="$INPUT_SVG"
else
    # 相対パスの場合、プロジェクトルートからの絶対パスに変換
    INPUT_FULLPATH="$(cd "$PROJECT_ROOT" && realpath "$INPUT_SVG")"
fi

# ファイル名のみを取得（パスを除去）
INPUT_BASENAME=$(basename "$INPUT_SVG")
OUTPUT_BASENAME=$(basename "$OUTPUT_PDF")

# 入力ファイルのディレクトリを取得
INPUT_DIR=$(dirname "$INPUT_FULLPATH")

# Dockerイメージ名
IMAGE_NAME="svg-ghostscript-converter"

# Dockerイメージの存在確認
if ! docker images | grep -q "^$IMAGE_NAME "; then
    echo "Dockerイメージ '$IMAGE_NAME' が見つかりません。ビルドを開始します..."
    cd "$SCRIPT_DIR"
    docker build -t "$IMAGE_NAME" -f Dockerfile.svg-ghostscript-converter .
    cd "$PROJECT_ROOT"
    echo "Dockerイメージのビルドが完了しました。"
else
    echo "Dockerイメージ '$IMAGE_NAME' を使用します。"
fi

# 入力ファイルの存在確認
if [ ! -f "$INPUT_FULLPATH" ]; then
    echo "エラー: SVGファイル '$INPUT_FULLPATH' が見つかりません"
    exit 1
fi

echo ""
echo "SVG → PDF 変換を開始します..."
echo "入力: $INPUT_FULLPATH"
echo "出力: $INPUT_DIR/$OUTPUT_BASENAME"
echo ""

# SVGをPDFに変換
# 入力ファイルのディレクトリをDockerコンテナにマウント
docker run --rm -v "$INPUT_DIR:/workspace" "$IMAGE_NAME" bash -c "
export FONTCONFIG_PATH=/etc/fonts
fc-cache -f -v > /dev/null 2>&1
inkscape --export-type=pdf --export-pdf-version=1.4 /workspace/$INPUT_BASENAME -o /workspace/$OUTPUT_BASENAME
"

if [ $? -eq 0 ]; then
    echo ""
    echo "変換が完了しました: $INPUT_DIR/$OUTPUT_BASENAME"

    # ファイルサイズを表示
    FILE_SIZE=$(ls -lh "$INPUT_DIR/$OUTPUT_BASENAME" | awk '{print $5}')
    echo "ファイルサイズ: $FILE_SIZE"
else
    echo "エラー: 変換に失敗しました"
    exit 1
fi

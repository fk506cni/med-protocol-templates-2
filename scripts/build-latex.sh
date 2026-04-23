#!/bin/bash

# エラーが発生したら即座に終了
set -e

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# 色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ログ関数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 使用方法の表示
usage() {
    cat << EOF
使用方法: $0 [OPTIONS] <tex_file>

OPTIONS:
    -h, --help          このヘルプを表示
    -o, --output DIR    出力ディレクトリを指定（デフォルト: output）
    -t, --timestamp     ファイル名にタイムスタンプを追加

EXAMPLES:
    $0 src/protocol_template.tex
    $0 -t src/protocol_template.tex
    $0 -o custom_output -t src/protocol_template.tex
EOF
    exit 1
}

# 引数のパース
OUTPUT_DIR="output"
ADD_TIMESTAMP=0
TEX_FILE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -t|--timestamp)
            ADD_TIMESTAMP=1
            shift
            ;;
        *)
            if [[ -z "$TEX_FILE" ]]; then
                TEX_FILE="$1"
            else
                log_error "複数の入力ファイルが指定されています"
                usage
            fi
            shift
            ;;
    esac
done

# TeXファイルのチェック
if [[ -z "$TEX_FILE" ]]; then
    log_error "TeXファイルが指定されていません"
    usage
fi

if [[ ! -f "$TEX_FILE" ]]; then
    log_error "ファイルが見つかりません: $TEX_FILE"
    exit 1
fi

# 出力ディレクトリの作成
mkdir -p "$OUTPUT_DIR"

# ファイル名の取得（拡張子なし）
BASENAME=$(basename "$TEX_FILE" .tex)

# タイムスタンプの生成
if [[ $ADD_TIMESTAMP -eq 1 ]]; then
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    OUTPUT_NAME="${BASENAME}_${TIMESTAMP}"
else
    OUTPUT_NAME="${BASENAME}"
fi

log_info "ビルドを開始します..."
log_info "入力ファイル: $TEX_FILE"
log_info "出力ディレクトリ: $OUTPUT_DIR"
log_info "出力ファイル名: ${OUTPUT_NAME}.pdf"

# LaTeXビルド実行（コンテナ内で直接実行）
log_info "LaTeXビルドを実行中..."

# 作業ディレクトリの保存
WORK_DIR=$(pwd)
BUILD_DIR=$(dirname "$TEX_FILE")
TEX_BASENAME=$(basename "$TEX_FILE")

# ビルドディレクトリに移動
cd "$BUILD_DIR"

# lualatex + upbibtex で完全なビルド（目次、相互参照、文献引用のため）
log_info "lualatex (1/3)..."
lualatex -interaction=nonstopmode "$TEX_BASENAME" > /dev/null 2>&1 || {
    log_error "lualatex 1回目が失敗しました"
    lualatex -interaction=nonstopmode "$TEX_BASENAME"
    cd "$WORK_DIR"
    exit 1
}

# upbibtexで文献データベース処理（.bibファイルから.bblファイルを生成）
log_info "upbibtex で文献処理..."
upbibtex "${TEX_BASENAME%.tex}" > /dev/null 2>&1 || {
    log_warn "upbibtex の実行に失敗しました（文献引用がない場合は正常です）"
    # .bibファイルがない場合や\cite{}がない場合はエラーになるが、処理は続行
}

log_info "lualatex (2/3)..."
lualatex -interaction=nonstopmode "$TEX_BASENAME" > /dev/null 2>&1 || {
    log_error "lualatex 2回目が失敗しました"
    cd "$WORK_DIR"
    exit 1
}

log_info "lualatex (3/3)..."
lualatex -interaction=nonstopmode "$TEX_BASENAME" > /dev/null 2>&1 || {
    log_error "lualatex 3回目が失敗しました"
    cd "$WORK_DIR"
    exit 1
}

# 出力ファイルを移動
PDF_FILE="${TEX_BASENAME%.tex}.pdf"
mkdir -p "$WORK_DIR/$OUTPUT_DIR"
mv "$PDF_FILE" "$WORK_DIR/$OUTPUT_DIR/${OUTPUT_NAME}.pdf"

# シンボリックリンクの作成
SYMLINK_NAME="${TEX_BASENAME%.tex}.pdf"
cd "$WORK_DIR/$OUTPUT_DIR"
ln -sf "${OUTPUT_NAME}.pdf" "$SYMLINK_NAME"
cd "$WORK_DIR/$BUILD_DIR"

# 一時ファイルの削除
rm -f *.aux *.log *.toc *.out *.dvi *.fls *.fdb_latexmk *.bbl *.blg

# 元のディレクトリに戻る
cd "$WORK_DIR"

if [[ $? -eq 0 ]]; then
    log_info "PDFファイルが正常に生成されました: $OUTPUT_DIR/${OUTPUT_NAME}.pdf"
else
    log_error "ビルドに失敗しました"
    exit 1
fi
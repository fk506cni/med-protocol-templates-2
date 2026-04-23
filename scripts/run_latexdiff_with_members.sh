#!/bin/bash

# 研究メンバー情報を含む差分検証スクリプト
# Usage: ./scripts/run_latexdiff_with_members.sh old_tex new_tex [members_yaml]

set -e

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# カラー出力用
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 引数チェック
if [ $# -lt 2 ]; then
    echo "Usage: $0 <old_tex> <new_tex> [members_yaml]"
    echo ""
    echo "研究メンバー情報を含む2つのバージョンの研究計画書の差分を検証します。"
    echo ""
    echo "Arguments:"
    echo "  old_tex        旧バージョンのTeXファイル"
    echo "  new_tex        新バージョンのTeXファイル"
    echo "  members_yaml   メンバー情報YAMLファイル（デフォルト: private/members.yaml）"
    echo ""
    echo "⚠️  重要: 生成される差分PDFには実際のメンバー情報が含まれます"
    echo ""
    echo "Examples:"
    echo "  $0 src/protocol_v1.tex src/protocol_v2.tex"
    echo "  $0 src/protocol_old.tex src/protocol_new.tex private/members.yaml"
    exit 1
fi

OLD_TEX="$1"
NEW_TEX="$2"
MEMBERS_YAML="${3:-private/members.yaml}"

# 絶対パスに変換
OLD_TEX_ABS="$PROJECT_ROOT/$OLD_TEX"
NEW_TEX_ABS="$PROJECT_ROOT/$NEW_TEX"
MEMBERS_YAML_ABS="$PROJECT_ROOT/$MEMBERS_YAML"

echo ""
echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}  研究計画書差分検証（メンバー情報付き）${NC}"
echo -e "${BLUE}============================================================${NC}"
echo ""
echo -e "${YELLOW}設定:${NC}"
echo "  旧バージョン   : $OLD_TEX"
echo "  新バージョン   : $NEW_TEX"
echo "  メンバー情報   : $MEMBERS_YAML"
echo "  実行環境       : Docker コンテナ"
echo ""
echo -e "${RED}⚠️  警告: 生成される差分PDFには実際のメンバー情報が含まれます${NC}"
echo ""

# ファイルの存在確認
if [ ! -f "$OLD_TEX_ABS" ]; then
    echo -e "${RED}❌ エラー: 旧バージョンのTeXファイルが見つかりません: $OLD_TEX${NC}"
    exit 1
fi

if [ ! -f "$NEW_TEX_ABS" ]; then
    echo -e "${RED}❌ エラー: 新バージョンのTeXファイルが見つかりません: $NEW_TEX${NC}"
    exit 1
fi

if [ ! -f "$MEMBERS_YAML_ABS" ]; then
    echo -e "${RED}❌ エラー: メンバー情報ファイルが見つかりません: $MEMBERS_YAML${NC}"
    echo ""
    echo -e "${YELLOW}ヒント: private/members.yaml.example を参考に private/members.yaml を作成してください。${NC}"
    exit 1
fi

# Dockerイメージのビルド確認
if [[ "$(docker images -q med-protocol-latex 2> /dev/null)" == "" ]]; then
    echo -e "${YELLOW}⚠ Dockerイメージが見つかりません。ビルドを開始します...${NC}"
    docker build -f docker/latex/Dockerfile -t med-protocol-latex "$PROJECT_ROOT/docker/latex/"
    echo ""
fi

# Step 1: 旧バージョンの_without_mask.texを生成
echo -e "${BLUE}[Step 1/4] 旧バージョンのメンバー情報処理${NC}"
echo "----------------------------------------"

docker run --rm \
    --user $(id -u):$(id -g) \
    -v "$PROJECT_ROOT:/workspace" \
    med-protocol-latex \
    python3 /workspace/scripts/process_members.py "/workspace/$OLD_TEX" "/workspace/$MEMBERS_YAML"

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ 旧バージョンのメンバー情報処理に失敗しました${NC}"
    exit 1
fi

OLD_BASE=$(basename "$OLD_TEX" .tex)
OLD_DIR=$(dirname "$OLD_TEX")
OLD_WITHOUT_MASK="${OLD_DIR}/${OLD_BASE}_without_mask.tex"

echo ""

# Step 2: 新バージョンの_without_mask.texを生成
echo -e "${BLUE}[Step 2/4] 新バージョンのメンバー情報処理${NC}"
echo "----------------------------------------"

docker run --rm \
    --user $(id -u):$(id -g) \
    -v "$PROJECT_ROOT:/workspace" \
    med-protocol-latex \
    python3 /workspace/scripts/process_members.py "/workspace/$NEW_TEX" "/workspace/$MEMBERS_YAML"

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ 新バージョンのメンバー情報処理に失敗しました${NC}"
    exit 1
fi

NEW_BASE=$(basename "$NEW_TEX" .tex)
NEW_DIR=$(dirname "$NEW_TEX")
NEW_WITHOUT_MASK="${NEW_DIR}/${NEW_BASE}_without_mask.tex"

echo ""

# Step 3: latexdiffで差分を生成
echo -e "${BLUE}[Step 3/4] 差分検証実行${NC}"
echo "----------------------------------------"

DIFF_BASE="${NEW_BASE}_diff_without_mask"
DIFF_TEX="${NEW_DIR}/${DIFF_BASE}.tex"

# latexdiffを実行
"$PROJECT_ROOT/scripts/run_latexdiff.sh" \
    "$OLD_WITHOUT_MASK" \
    "$NEW_WITHOUT_MASK"

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ 差分生成に失敗しました${NC}"
    exit 1
fi

# 生成された差分ファイルをリネーム
ORIGINAL_DIFF="${NEW_DIR}/${NEW_BASE}_without_mask_diff.tex"
if [ -f "$ORIGINAL_DIFF" ]; then
    mv "$ORIGINAL_DIFF" "$DIFF_TEX"
    echo -e "${GREEN}✓ 差分TeXファイルを生成しました: $DIFF_TEX${NC}"
fi

echo ""

# Step 4: 差分PDFを生成
echo -e "${BLUE}[Step 4/4] 差分PDF生成${NC}"
echo "----------------------------------------"

"$PROJECT_ROOT/docker/latex/compile.sh" "$DIFF_TEX"

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ 差分PDFのコンパイルに失敗しました${NC}"
    exit 1
fi

# PDFをリネーム
ORIGINAL_DIFF_PDF="output/${NEW_BASE}_without_mask_diff.pdf"
DIFF_PDF="output/${DIFF_BASE}.pdf"
if [ -f "$ORIGINAL_DIFF_PDF" ]; then
    mv "$ORIGINAL_DIFF_PDF" "$DIFF_PDF"
fi

echo ""

# 完了メッセージ
echo -e "${GREEN}============================================================${NC}"
echo -e "${GREEN}  ✓ 差分検証が完了しました${NC}"
echo -e "${GREEN}============================================================${NC}"
echo ""
echo -e "${YELLOW}生成されたファイル:${NC}"
echo ""
echo -e "  ${GREEN}1.${NC} $DIFF_TEX"
echo "     → 差分がマークされたTeXファイル"
echo ""
echo -e "  ${GREEN}2.${NC} $DIFF_PDF"
echo "     → 差分がハイライトされたPDF"
echo ""
echo -e "${YELLOW}確認方法:${NC}"
echo "  xdg-open $DIFF_PDF"
echo ""
echo -e "${BLUE}出力ファイルについて:${NC}"
echo "  - _diff_without_mask: 実際のメンバー情報が埋め込まれた差分ファイル"
echo "  - 変更箇所がハイライト表示されています"
echo ""
echo -e "${RED}⚠️  注意: このPDFには実際のメンバー情報が含まれています${NC}"
echo ""

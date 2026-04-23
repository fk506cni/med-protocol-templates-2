#!/bin/bash

# 研究メンバー情報を含む研究計画書のコンパイルスクリプト（Docker版）
# Usage: ./scripts/compile_with_members.sh [-t|--timestamp] [tex_file] [members_yaml]

set -e

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# デフォルト値
ADD_TIMESTAMP=false
TEX_FILE="src/protocol_template.tex"
MEMBERS_YAML="private/members.yaml"

# カラー出力用
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 引数解析
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--timestamp)
            ADD_TIMESTAMP=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [-t|--timestamp] [tex_file] [members_yaml]"
            echo ""
            echo "研究メンバー情報を含む研究計画書をコンパイルします。"
            echo "すべての処理はDockerコンテナ内で実行されます。"
            echo ""
            echo "2つのバージョンのPDFが生成されます："
            echo "  1. _with_mask.pdf    : メンバー情報がプレースホルダーで表示されたバージョン"
            echo "  2. _without_mask.pdf : 実際のメンバー情報を含むバージョン（提出用）"
            echo ""
            echo "Options:"
            echo "  -t, --timestamp    出力ファイル名にタイムスタンプを追加"
            echo "  -h, --help         このヘルプメッセージを表示"
            echo ""
            echo "Arguments:"
            echo "  tex_file           TeXテンプレートファイル（デフォルト: src/protocol_template.tex）"
            echo "  members_yaml       メンバー情報YAMLファイル（デフォルト: private/members.yaml）"
            echo ""
            echo "Examples:"
            echo "  $0                                    # デフォルト設定でコンパイル"
            echo "  $0 -t                                 # タイムスタンプ付きでコンパイル"
            echo "  $0 src/my_protocol.tex                # カスタムテンプレートを使用"
            exit 0
            ;;
        *)
            if [[ -z "$TEX_FILE_CUSTOM" ]]; then
                TEX_FILE_CUSTOM="$1"
            elif [[ -z "$MEMBERS_YAML_CUSTOM" ]]; then
                MEMBERS_YAML_CUSTOM="$1"
            else
                echo -e "${RED}Error: Too many arguments${NC}"
                exit 1
            fi
            shift
            ;;
    esac
done

# カスタム値があれば上書き
TEX_FILE="${TEX_FILE_CUSTOM:-$TEX_FILE}"
MEMBERS_YAML="${MEMBERS_YAML_CUSTOM:-$MEMBERS_YAML}"

# 絶対パスに変換
TEX_FILE_ABS="$PROJECT_ROOT/$TEX_FILE"
MEMBERS_YAML_ABS="$PROJECT_ROOT/$MEMBERS_YAML"

echo ""
echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}  研究計画書コンパイル（メンバー情報処理付き）${NC}"
echo -e "${BLUE}============================================================${NC}"
echo ""
echo -e "${YELLOW}設定:${NC}"
echo "  テンプレート   : $TEX_FILE"
echo "  メンバー情報   : $MEMBERS_YAML"
echo "  タイムスタンプ : $([ "$ADD_TIMESTAMP" = true ] && echo "有効" || echo "無効")"
echo "  実行環境       : Docker コンテナ"
echo ""

# ファイルの存在確認
if [ ! -f "$TEX_FILE_ABS" ]; then
    echo -e "${RED}❌ エラー: テンプレートファイルが見つかりません: $TEX_FILE${NC}"
    exit 1
fi

if [ ! -f "$MEMBERS_YAML_ABS" ]; then
    echo -e "${RED}❌ エラー: メンバー情報ファイルが見つかりません: $MEMBERS_YAML${NC}"
    echo ""
    echo -e "${YELLOW}ヒント: private/members.yaml.example を参考に private/members.yaml を作成してください。${NC}"
    echo ""
    echo "  cp private/members.yaml.example private/members.yaml"
    echo "  nano private/members.yaml"
    exit 1
fi

# Dockerイメージのビルド確認
if [[ "$(docker images -q med-protocol-latex 2> /dev/null)" == "" ]]; then
    echo -e "${YELLOW}⚠ Dockerイメージが見つかりません。ビルドを開始します...${NC}"
    docker build -f docker/latex/Dockerfile -t med-protocol-latex "$PROJECT_ROOT/docker/latex/"
    echo ""
fi

# Step 1: メンバー情報処理（Dockerコンテナ内で実行）
echo -e "${BLUE}[Step 1/3] メンバー情報処理（Dockerコンテナ内）${NC}"
echo "----------------------------------------"

docker run --rm \
    --user $(id -u):$(id -g) \
    -v "$PROJECT_ROOT:/workspace" \
    med-protocol-latex \
    python3 /workspace/scripts/process_members.py "/workspace/$TEX_FILE" "/workspace/$MEMBERS_YAML"

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ メンバー情報処理に失敗しました${NC}"
    exit 1
fi

echo ""

# ベース名を取得
BASE_NAME=$(basename "$TEX_FILE" .tex)
TEX_DIR=$(dirname "$TEX_FILE")
MASKED_TEX="${TEX_DIR}/${BASE_NAME}_with_mask.tex"
REAL_TEX="${TEX_DIR}/${BASE_NAME}_without_mask.tex"

# Step 2: マスク版をコンパイル
echo -e "${BLUE}[Step 2/3] マスク版PDF生成${NC}"
echo "----------------------------------------"

TIMESTAMP_OPT=""
if [ "$ADD_TIMESTAMP" = true ]; then
    TIMESTAMP_OPT="-t"
fi

"$PROJECT_ROOT/docker/latex/compile.sh" $TIMESTAMP_OPT "$MASKED_TEX"

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ マスク版のコンパイルに失敗しました${NC}"
    exit 1
fi

echo ""

# Step 3: 実データ版をコンパイル
echo -e "${BLUE}[Step 3/3] 実データ版PDF生成（提出用）${NC}"
echo "----------------------------------------"

"$PROJECT_ROOT/docker/latex/compile.sh" $TIMESTAMP_OPT "$REAL_TEX"

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ 実データ版のコンパイルに失敗しました${NC}"
    exit 1
fi

echo ""

# 完了メッセージ
echo -e "${GREEN}============================================================${NC}"
echo -e "${GREEN}  ✓ コンパイルが完了しました${NC}"
echo -e "${GREEN}============================================================${NC}"
echo ""
echo -e "${YELLOW}生成されたPDFファイル:${NC}"
echo ""

if [ "$ADD_TIMESTAMP" = true ]; then
    # タイムスタンプ付きファイル名を推定（最新のファイルを表示）
    MASKED_PDF=$(ls -t "$PROJECT_ROOT/output/${BASE_NAME}_with_mask"*.pdf 2>/dev/null | head -1)
    REAL_PDF=$(ls -t "$PROJECT_ROOT/output/${BASE_NAME}_without_mask"*.pdf 2>/dev/null | head -1)

    if [ -n "$MASKED_PDF" ]; then
        echo -e "  ${GREEN}1.${NC} $(basename "$MASKED_PDF")"
    else
        echo -e "  ${GREEN}1.${NC} output/${BASE_NAME}_with_mask_YYYYMMDD_HHMMSS.pdf"
    fi
    echo "     ${BLUE}→ メンバー情報がプレースホルダーで表示されたバージョン${NC}"
    echo ""

    if [ -n "$REAL_PDF" ]; then
        echo -e "  ${GREEN}2.${NC} $(basename "$REAL_PDF")"
    else
        echo -e "  ${GREEN}2.${NC} output/${BASE_NAME}_without_mask_YYYYMMDD_HHMMSS.pdf"
    fi
    echo "     ${RED}→ 実際のメンバー情報を含む提出用PDF${NC}"
else
    echo -e "  ${GREEN}1.${NC} output/${BASE_NAME}_with_mask.pdf"
    echo "     ${BLUE}→ メンバー情報がプレースホルダーで表示されたバージョン${NC}"
    echo ""
    echo -e "  ${GREEN}2.${NC} output/${BASE_NAME}_without_mask.pdf"
    echo "     ${RED}→ 実際のメンバー情報を含む提出用PDF${NC}"
fi

echo ""
echo -e "${YELLOW}次のステップ:${NC}"
echo "  1. _with_mask.pdf で内容を確認してください"
echo "  2. 内容に問題がなければ、_without_mask.pdf を倫理委員会に提出してください"
echo ""
echo -e "${BLUE}出力ファイルについて:${NC}"
echo "  - _with_mask: メンバー情報がプレースホルダーで表示されたバージョン"
echo "  - _without_mask: 実際のメンバー情報が埋め込まれたバージョン"
echo ""

#!/bin/bash

# ===================================================================
# 倫理委員会提出書類パッケージング スクリプト
#
# 機能:
# - src/research_info.tex からバージョン情報を取得
# - output/ フォルダの PDF ファイルをリネーム
# - ソースコード (src/) と合わせてパッケージフォルダにまとめる
# - プロジェクト名・バージョン・タイムスタンプ付きのフォルダ名で作成
# - Google Drive の tmp/<プロジェクト名>/<パッケージ名>/ へ
#   フォルダごとアップロード（圧縮なし）
#   ＝ H:\マイドライブ\tmp\<プロジェクト名>\<パッケージ名>\
# - アップロード成功時は一時パッケージを削除、失敗/--no-upload 時のみ
#   プロジェクトルートに残す
#
# 使用方法:
#   ./scripts/package_submission.sh [オプション]
#
# オプション:
#   --no-upload    Google Drive へのアップロードをスキップ
#   --help, -h     このヘルプメッセージを表示
#
# 例:
#   ./scripts/package_submission.sh
#   ./scripts/package_submission.sh --no-upload
# ===================================================================

set -e  # エラーが発生したら即座に終了

# ヘルプメッセージを表示
show_help() {
    cat << EOF
倫理委員会提出書類パッケージング スクリプト

使用方法:
  ./scripts/package_submission.sh [オプション]

機能:
  - src/research_info.tex からバージョン情報を取得
  - output/ フォルダの PDF ファイルを倫理委員会提出用にリネーム
  - ソースコード (src/) と合わせてパッケージフォルダにまとめる
  - プロジェクト名・バージョン・タイムスタンプ付きのフォルダ名で作成
  - Google Drive へフォルダごとアップロード（圧縮なし）
  - アップロード成功時は一時パッケージを削除
  - アップロード失敗 / --no-upload 時のみプロジェクトルートに残す

オプション:
  --no-upload    Google Drive へのアップロードをスキップ
  --help, -h     このヘルプメッセージを表示

例:
  ./scripts/package_submission.sh
  ./scripts/package_submission.sh --no-upload

リネーム規則:
  protocol_template_without_mask.pdf     → 研究実施計画書_(バージョン).pdf
  consent_template_without_mask.pdf      → 同意書_(バージョン).pdf
  explanation_template_without_mask.pdf  → 説明文書_(バージョン).pdf
  disclosure_template_without_mask.pdf   → 情報公開文書_(バージョン).pdf

  ※ diff がつくファイルも同様にリネームされます
  ※ with_mask がつくファイルも同様にリネームされます

パッケージの構成:
  <プロジェクト名>_<バージョン>_<タイムスタンプ>/
    ├── 研究実施計画書_第1.0版.pdf      … PDF はフォルダ直下
    ├── 説明文書_第1.0版.pdf
    ├── 同意書_第1.0版.pdf
    ├── README.md
    └── src/                             … ソースは src/ サブフォルダ

出力:
  - Google Drive (gdrive:tmp/<プロジェクト名>/<パッケージ名>/):
      アップロード成功時、フォルダごと配置（圧縮なし）
      Windows からは H:\\マイドライブ\\tmp\\<プロジェクト名>\\<パッケージ名>\\
  - プロジェクトルート: --no-upload またはアップロード失敗時のみフォルダを残す

EOF
    exit 0
}

# コマンドライン引数を解析
UPLOAD_TO_GDRIVE=true

while [[ $# -gt 0 ]]; do
    case $1 in
        --no-upload)
            UPLOAD_TO_GDRIVE=false
            shift
            ;;
        --help|-h)
            show_help
            ;;
        *)
            echo "エラー: 不明なオプション: $1"
            echo "使用方法: ./scripts/package_submission.sh [--no-upload] [--help]"
            exit 1
            ;;
    esac
done

# カラー出力用
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# プロジェクトルートを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_NAME="$(basename "$PROJECT_ROOT")"

echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}倫理委員会提出書類パッケージング${NC}"
echo -e "${BLUE}=====================================${NC}"
echo ""

# research_info.tex からバージョン情報を取得
RESEARCH_INFO="$PROJECT_ROOT/src/research_info.tex"

if [ ! -f "$RESEARCH_INFO" ]; then
    echo -e "${RED}❌ エラー: $RESEARCH_INFO が見つかりません${NC}"
    exit 1
fi

echo -e "${BLUE}📄 バージョン情報を取得中...${NC}"
VERSION=$(grep '\\def\\ProtocolVersion{' "$RESEARCH_INFO" | sed 's/.*{//; s/}//')

if [ -z "$VERSION" ]; then
    echo -e "${RED}❌ エラー: バージョン情報が見つかりません${NC}"
    exit 1
fi

echo -e "${GREEN}✓ バージョン: $VERSION${NC}"
echo ""

# タイムスタンプを生成
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
PACKAGE_NAME="${PROJECT_NAME}_${VERSION}_${TIMESTAMP}"

echo -e "${BLUE}📦 パッケージ名: $PACKAGE_NAME${NC}"

# Windows（Google Drive デスクトップ）から見たときのパス。
# バックスラッシュを含むため、表示には echo -e ではなく printf を用いること
WINDOWS_PATH="H:\\マイドライブ\\tmp\\${PROJECT_NAME}\\${PACKAGE_NAME}\\"
echo ""

# 一時ディレクトリを作成（PDF はフォルダ直下、ソースは src/ サブフォルダ）
TEMP_DIR=$(mktemp -d)
PACKAGE_DIR="$TEMP_DIR/$PACKAGE_NAME"
mkdir -p "$PACKAGE_DIR"
mkdir -p "$PACKAGE_DIR/src"

echo -e "${BLUE}📋 ファイルをコピー中...${NC}"

# output フォルダの PDF をリネームしてコピー
OUTPUT_DIR="$PROJECT_ROOT/output"

if [ ! -d "$OUTPUT_DIR" ]; then
    echo -e "${YELLOW}⚠️  警告: output/ ディレクトリが見つかりません${NC}"
else
    # リネーム対応表（連想配列）
    declare -A RENAME_MAP=(
        ["protocol_template_without_mask.pdf"]="研究実施計画書_${VERSION}.pdf"
        ["protocol_template_diff_without_mask.pdf"]="研究実施計画書_diff_${VERSION}.pdf"
        ["protocol_template_with_mask.pdf"]="研究実施計画書_with_mask_${VERSION}.pdf"
        ["protocol_template_diff_with_mask.pdf"]="研究実施計画書_diff_with_mask_${VERSION}.pdf"

        ["consent_template_without_mask.pdf"]="同意書_${VERSION}.pdf"
        ["consent_template_diff_without_mask.pdf"]="同意書_diff_${VERSION}.pdf"
        ["consent_template_with_mask.pdf"]="同意書_with_mask_${VERSION}.pdf"
        ["consent_template_diff_with_mask.pdf"]="同意書_diff_with_mask_${VERSION}.pdf"

        ["explanation_template_without_mask.pdf"]="説明文書_${VERSION}.pdf"
        ["explanation_template_diff_without_mask.pdf"]="説明文書_diff_${VERSION}.pdf"
        ["explanation_template_with_mask.pdf"]="説明文書_with_mask_${VERSION}.pdf"
        ["explanation_template_diff_with_mask.pdf"]="説明文書_diff_with_mask_${VERSION}.pdf"

        ["disclosure_template_without_mask.pdf"]="情報公開文書_${VERSION}.pdf"
        ["disclosure_template_diff_without_mask.pdf"]="情報公開文書_diff_${VERSION}.pdf"
        ["disclosure_template_with_mask.pdf"]="情報公開文書_with_mask_${VERSION}.pdf"
        ["disclosure_template_diff_with_mask.pdf"]="情報公開文書_diff_with_mask_${VERSION}.pdf"
    )

    # PDF ファイルをリネームしてコピー
    PDF_COUNT=0
    for pdf in "$OUTPUT_DIR"/*.pdf; do
        if [ -f "$pdf" ]; then
            BASE_NAME=$(basename "$pdf")

            # リネーム対応表に該当があればリネーム
            if [ -n "${RENAME_MAP[$BASE_NAME]}" ]; then
                NEW_NAME="${RENAME_MAP[$BASE_NAME]}"
                cp "$pdf" "$PACKAGE_DIR/$NEW_NAME"
                echo -e "  ${GREEN}✓${NC} $BASE_NAME → $NEW_NAME"
                PDF_COUNT=$((PDF_COUNT + 1))
            else
                # 対応表にない PDF はそのままコピー
                cp "$pdf" "$PACKAGE_DIR/$BASE_NAME"
                echo -e "  ${GREEN}✓${NC} $BASE_NAME （リネームなし）"
                PDF_COUNT=$((PDF_COUNT + 1))
            fi
        fi
    done

    if [ $PDF_COUNT -eq 0 ]; then
        echo -e "${YELLOW}⚠️  警告: output/ に PDF ファイルが見つかりませんでした${NC}"
    else
        echo -e "${GREEN}✓ $PDF_COUNT 個の PDF ファイルをコピーしました${NC}"
    fi
fi

echo ""

# src フォルダ全体をコピー
SRC_DIR="$PROJECT_ROOT/src"

if [ ! -d "$SRC_DIR" ]; then
    echo -e "${RED}❌ エラー: src/ ディレクトリが見つかりません${NC}"
    rm -rf "$TEMP_DIR"
    exit 1
fi

echo -e "${BLUE}📁 ソースコードをコピー中...${NC}"
cp -r "$SRC_DIR"/* "$PACKAGE_DIR/src/"
echo -e "${GREEN}✓ ソースコードをコピーしました${NC}"
echo ""

# README を追加（オプション）
if [ -f "$PROJECT_ROOT/README.md" ]; then
    cp "$PROJECT_ROOT/README.md" "$PACKAGE_DIR/"
    echo -e "${GREEN}✓ README.md をコピーしました${NC}"
fi

# 旧形式（ZIP）の後片付け: プロジェクトルートに残っている ZIP を _archives へ移動
# ※ 本スクリプトは ZIP を作らなくなったため、過去に作られたものだけが対象
ARCHIVES_DIR="$PROJECT_ROOT/_archives"
OLD_ZIPS=$(find "$PROJECT_ROOT" -maxdepth 1 -name "${PROJECT_NAME}_*.zip" -type f)

if [ -n "$OLD_ZIPS" ]; then
    mkdir -p "$ARCHIVES_DIR"
    echo -e "${BLUE}📦 旧形式の ZIP ファイルを _archives に移動中...${NC}"
    for old_zip in $OLD_ZIPS; do
        mv "$old_zip" "$ARCHIVES_DIR/"
        echo -e "  ${GREEN}✓${NC} $(basename "$old_zip") → _archives/"
    done
    echo ""
fi

# パッケージサイズを表示
PACKAGE_SIZE=$(du -sh "$PACKAGE_DIR" | cut -f1)
echo -e "${GREEN}📦 パッケージサイズ: $PACKAGE_SIZE${NC}"
echo ""

# Google Drive にアップロード（rclone）
UPLOAD_SUCCESS=false
GDRIVE_PATH=""
if [ "$UPLOAD_TO_GDRIVE" = true ]; then
    echo -e "${BLUE}☁️  Google Drive にアップロード中...${NC}"

    # rclone が利用可能かチェック
    if ! command -v rclone &> /dev/null; then
        echo -e "${YELLOW}⚠️  警告: rclone が見つかりません${NC}"
        echo -e "${YELLOW}   Google Drive へのアップロードをスキップします${NC}"
        echo -e "${YELLOW}   rclone をインストールして設定してください: https://rclone.org/${NC}"
    else
        # rclone の設定があるかチェック
        RCLONE_REMOTES=$(rclone listremotes)

        if [ -z "$RCLONE_REMOTES" ]; then
            echo -e "${YELLOW}⚠️  警告: rclone の設定が見つかりません${NC}"
            echo -e "${YELLOW}   Google Drive へのアップロードをスキップします${NC}"
            echo -e "${YELLOW}   'rclone config' で Google Drive を設定してください${NC}"
        else
            # Google Drive のリモート名を取得（通常は "gdrive" または "google-drive"）
            GDRIVE_REMOTE=""

            # よくある名前をチェック
            for remote_name in "gdrive" "google-drive" "googledrive" "drive"; do
                if echo "$RCLONE_REMOTES" | grep -q "^${remote_name}:$"; then
                    GDRIVE_REMOTE="$remote_name"
                    break
                fi
            done

            # 見つからない場合は最初のリモートを使用
            if [ -z "$GDRIVE_REMOTE" ]; then
                GDRIVE_REMOTE=$(echo "$RCLONE_REMOTES" | head -n 1 | tr -d ':')
                echo -e "${YELLOW}⚠️  Google Drive リモートが見つからないため、最初のリモート ($GDRIVE_REMOTE) を使用します${NC}"
            fi

            # アップロード先パス: tmp/<プロジェクト名>/<パッケージ名>/
            # Windows からは H:\マイドライブ\tmp\<プロジェクト名>\<パッケージ名>\
            GDRIVE_PATH="${GDRIVE_REMOTE}:tmp/${PROJECT_NAME}/${PACKAGE_NAME}"

            echo -e "${BLUE}   アップロード先: $GDRIVE_PATH${NC}"
            # Windows 表記のパスは echo -e だと \t \r がエスケープ解釈されるため printf で出力する
            printf "   （Windows: %s）\n" "$WINDOWS_PATH"

            # アップロード実行（フォルダ単位で copy、圧縮なし）
            if rclone copy "$PACKAGE_DIR" "$GDRIVE_PATH" --progress; then
                echo -e "${GREEN}✓ Google Drive にアップロードしました${NC}"
                UPLOAD_SUCCESS=true
            else
                echo -e "${RED}❌ エラー: Google Drive へのアップロードに失敗しました${NC}"
            fi
        fi
    fi
else
    echo -e "${YELLOW}ℹ️  Google Drive へのアップロードをスキップしました（--no-upload オプションが指定されています）${NC}"
fi

# パッケージのクリーンアップ / ローカル保管
# ※ パッケージには without_mask（個人情報）の PDF が含まれるため、
#    アップロードに成功した場合はローカルに残さない
LOCAL_PACKAGE_PATH=""
if [ "$UPLOAD_TO_GDRIVE" = true ] && [ "$UPLOAD_SUCCESS" = true ]; then
    # アップロード成功時は temp を削除
    rm -rf "$TEMP_DIR"
else
    # --no-upload またはアップロード失敗時はプロジェクトルートにフォルダを残す
    mv "$PACKAGE_DIR" "$PROJECT_ROOT/"
    rm -rf "$TEMP_DIR"
    LOCAL_PACKAGE_PATH="$PROJECT_ROOT/$PACKAGE_NAME"
fi

echo ""
echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}✅ パッケージング完了${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""
if [ "$UPLOAD_SUCCESS" = true ]; then
    echo -e "${BLUE}☁️  アップロード先:${NC}"
    echo -e "   $GDRIVE_PATH/"
    printf "   %s\n" "$WINDOWS_PATH"
    echo ""
fi
if [ -n "$LOCAL_PACKAGE_PATH" ]; then
    echo -e "${BLUE}📁 ローカルパッケージ:${NC}"
    echo -e "   $LOCAL_PACKAGE_PATH/"
    echo -e "${YELLOW}   ※ without_mask の PDF（個人情報）を含みます。取り扱いに注意してください${NC}"
    echo ""
fi

#!/bin/bash

# ===================================================================
# 倫理委員会提出書類パッケージング スクリプト
#
# 機能:
# - src/research_info.tex からバージョン情報を取得
# - output/ フォルダの PDF ファイルをリネーム
# - ソースコード (src/) と合わせて zip にまとめる
# - プロジェクト名とタイムスタンプ付きのファイル名で zip 作成
# - 古い zip ファイルは _archives フォルダに移動
# - 最新版の zip を Google Drive にアップロード
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
  - ソースコード (src/) と合わせて ZIP にまとめる
  - プロジェクト名とタイムスタンプ付きのファイル名で ZIP 作成
  - 古い ZIP ファイルは _archives フォルダに移動
  - 最新版の ZIP を Google Drive にアップロード

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

出力:
  - プロジェクトルート: 最新の ZIP ファイル
  - _archives/: 過去の ZIP ファイル
  - Google Drive (gdrive:tmp): 最新の ZIP ファイル（--no-upload が指定されていない場合）

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
ZIP_NAME="${PROJECT_NAME}_${TIMESTAMP}.zip"

echo -e "${BLUE}📦 パッケージ名: $ZIP_NAME${NC}"
echo ""

# 一時ディレクトリを作成
TEMP_DIR=$(mktemp -d)
PACKAGE_DIR="$TEMP_DIR/${PROJECT_NAME}_${VERSION}"
mkdir -p "$PACKAGE_DIR/documents"
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
                cp "$pdf" "$PACKAGE_DIR/documents/$NEW_NAME"
                echo -e "  ${GREEN}✓${NC} $BASE_NAME → $NEW_NAME"
                PDF_COUNT=$((PDF_COUNT + 1))
            else
                # 対応表にない PDF はそのままコピー
                cp "$pdf" "$PACKAGE_DIR/documents/$BASE_NAME"
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

# ZIP を作成（UTF-8 エンコーディングを使用してWindows互換性を確保）
echo -e "${BLUE}🗜️  ZIP ファイルを作成中...${NC}"

# Python の zipfile モジュールを使用して UTF-8 対応 ZIP を作成
# これによりWindowsでの日本語ファイル名の文字化けを防止
python3 -c "
import zipfile
import os

temp_dir = '$TEMP_DIR'
zip_name = '$ZIP_NAME'
package_dir = '$PACKAGE_DIR'

output_path = os.path.join(temp_dir, zip_name)

# UTF-8対応のZIPファイルを作成
with zipfile.ZipFile(output_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
    # すべてのファイルを再帰的に追加
    for root, dirs, files in os.walk(package_dir):
        for file in files:
            file_path = os.path.join(root, file)
            # ZIP内のパスを相対パスに（ルートディレクトリ名を含む）
            arcname = os.path.relpath(file_path, os.path.dirname(package_dir))
            zipf.write(file_path, arcname)
        # 空のディレクトリも追加
        for dir_name in dirs:
            dir_path = os.path.join(root, dir_name)
            arcname = os.path.relpath(dir_path, os.path.dirname(package_dir))
            # ディレクトリエントリを追加（末尾に/を付ける）
            zipf.write(dir_path, arcname + '/')
"

# 古い ZIP を _archives に移動
ARCHIVES_DIR="$PROJECT_ROOT/_archives"
mkdir -p "$ARCHIVES_DIR"

OLD_ZIPS=$(find "$PROJECT_ROOT" -maxdepth 1 -name "${PROJECT_NAME}_*.zip" -type f)

if [ -n "$OLD_ZIPS" ]; then
    echo -e "${BLUE}📦 古い ZIP ファイルを _archives に移動中...${NC}"
    for old_zip in $OLD_ZIPS; do
        OLD_ZIP_NAME=$(basename "$old_zip")
        mv "$old_zip" "$ARCHIVES_DIR/"
        echo -e "  ${GREEN}✓${NC} $OLD_ZIP_NAME → _archives/"
    done
fi

# 新しい ZIP をプロジェクトルートに配置
mv "$TEMP_DIR/$ZIP_NAME" "$PROJECT_ROOT/"
echo -e "${GREEN}✓ $ZIP_NAME を作成しました${NC}"
echo ""

# 一時ディレクトリをクリーンアップ
rm -rf "$TEMP_DIR"

# ZIP ファイルのサイズを表示
ZIP_SIZE=$(du -h "$PROJECT_ROOT/$ZIP_NAME" | cut -f1)
echo -e "${GREEN}📦 パッケージサイズ: $ZIP_SIZE${NC}"
echo ""

# Google Drive にアップロード（rclone）
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

            # アップロード先パス
            GDRIVE_PATH="${GDRIVE_REMOTE}:tmp"

            echo -e "${BLUE}   アップロード先: $GDRIVE_PATH${NC}"

            # アップロード実行
            if rclone copy "$PROJECT_ROOT/$ZIP_NAME" "$GDRIVE_PATH" --progress; then
                echo -e "${GREEN}✓ Google Drive にアップロードしました${NC}"
            else
                echo -e "${RED}❌ エラー: Google Drive へのアップロードに失敗しました${NC}"
                exit 1
            fi
        fi
    fi
else
    echo -e "${YELLOW}ℹ️  Google Drive へのアップロードをスキップしました（--no-upload オプションが指定されています）${NC}"
fi

echo ""
echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}✅ パッケージング完了${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""
echo -e "${BLUE}📦 作成されたファイル:${NC}"
echo -e "   $PROJECT_ROOT/$ZIP_NAME"
echo ""
echo -e "${BLUE}📁 古いファイル:${NC}"
echo -e "   $ARCHIVES_DIR/"
echo ""

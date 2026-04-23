#!/bin/bash

# LaTeX差分ハイライト用スクリプト
# Creates a diff-highlighted PDF showing changes between two LaTeX files
# Usage: ./run_latexdiff.sh [options] <old_file> <new_file>
# Options:
#   --no-del       Suppress deleted text from output (show only additions)
#   -o, --output   Specify output directory (default: output)
#   --help         Show this help message

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Project root is one level up from the scripts directory
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

# デフォルトオプション
NO_DEL_OPTION=""
OUTPUT_DIR="output"

# 引数解析
while [[ $# -gt 0 ]]; do
    case $1 in
        --no-del)
            NO_DEL_OPTION="--no-del"
            shift
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [options] <old_file> <new_file>"
            echo ""
            echo "Options:"
            echo "  --no-del           Suppress deleted text from output (show only additions)"
            echo "  -o, --output DIR   Specify output directory (default: output)"
            echo "  --help, -h         Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 main_old.tex main.tex                      # Standard diff with additions and deletions"
            echo "  $0 --no-del main_old.tex main.tex            # Show only additions, no deletion markup"
            echo "  $0 -o custom_output main_old.tex main.tex    # Output to custom_output directory"
            echo ""
            echo "Output files:"
            echo "  <new_file_basename>_diff.tex - LaTeX source with diff markup (in src directory)"
            echo "  <output_dir>/<new_file_basename>_diff.pdf - PDF with highlighted changes"
            exit 0
            ;;
        -*)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
        *)
            break
            ;;
    esac
done

# 残りの引数チェック
if [ $# -ne 2 ]; then
    echo "Usage: $0 [options] <old_file> <new_file>"
    echo "Use --help for more information"
    exit 1
fi

OLD_FILE="$1"
NEW_FILE="$2"

# 必要なファイルの存在確認
if [ ! -f "$OLD_FILE" ]; then
    echo "Error: $OLD_FILE not found"
    exit 1
fi

if [ ! -f "$NEW_FILE" ]; then
    echo "Error: $NEW_FILE not found"
    exit 1
fi

# 出力ファイル名を生成（新しいファイル名に_diffを付与）
# 新しいファイルと同じディレクトリに差分ファイルを生成
NEW_FILE_DIR=$(dirname "$NEW_FILE")
BASENAME=$(basename "$NEW_FILE" .tex)
DIFF_FILE="${NEW_FILE_DIR}/${BASENAME}_diff.tex"
DIFF_PDF="${BASENAME}_diff.pdf"

echo "Building latexdiff container..."
cd docker/latexdiff
docker compose build

echo "Running latexdiff to generate highlighted changes..."
echo "Comparing: $OLD_FILE → $NEW_FILE"
echo "Output will be: $DIFF_FILE, $DIFF_PDF"
cd "$PROJECT_DIR"

# Normalize files before latexdiff for better diff quality
echo "Normalizing LaTeX files for better diff quality..."
NORMALIZED_OLD="${OLD_FILE}.normalized"
NORMALIZED_NEW="${NEW_FILE}.normalized"
python3 docker/latexdiff/normalize_tex.py "$OLD_FILE" "$NORMALIZED_OLD"
python3 docker/latexdiff/normalize_tex.py "$NEW_FILE" "$NORMALIZED_NEW"

# latexdiffを実行して差分ファイルを生成
if [ -n "$NO_DEL_OPTION" ]; then
    echo "Generating diff with deletion markup removed..."
    docker run --rm -v "${PROJECT_DIR}:/workspace" latexdiff-latexdiff \
        bash -c "latexdiff \
        --config 'PICTUREENV=(?:picture|DIFnomarkup)[\w\d*@]*' \
        --exclude-textcmd='section,subsection,subsubsection,textcolor' \
        --graphics-markup=none \
        --math-markup=0 \
        --disable-citation-markup \
        --no-label \
        --replace-context2cmd='textcolor:2' \
        '$OLD_FILE' '$NEW_FILE' | \
        sed -E 's/\\\\DIFdel\{[^}]*\}//g' | \
        sed -E 's/\\\\DIFdelbegin.*?\\\\DIFdelend//g' | \
        sed -E 's/\\\\sout\{[^}]*\}//g'" > "$DIFF_FILE"
else
    echo "Generating standard diff with additions and deletions..."
    docker run --rm -v "${PROJECT_DIR}:/workspace" latexdiff-latexdiff \
        latexdiff \
        --config "PICTUREENV=(?:picture|DIFnomarkup)[\w\d*@]*,MINWORDSBLOCK=1" \
        --exclude-textcmd="section,subsection,subsubsection" \
        --append-textcmd="title,keywords" \
        --append-safecmd="cite,ref,label" \
        --graphics-markup=none \
        --math-markup=0 \
        --disable-citation-markup \
        --no-label \
        "$NORMALIZED_OLD" "$NORMALIZED_NEW" > "$DIFF_FILE"
fi

# Cleanup normalized files
rm -f "$NORMALIZED_OLD" "$NORMALIZED_NEW"

echo "Generated diff file: $DIFF_FILE"

# Post-process the diff file to fix broken \ref commands and enable title/abstract highlighting
echo "Post-processing diff file to fix broken commands..."
sed -i 's/\\ref }{\(\\DIF[a-zA-Z]*{\)/\\ref{\1/g' "$DIFF_FILE"
sed -i 's/\\ref }\\DIF/\\ref{}/g' "$DIFF_FILE"

# Enable highlighting for title and abstract changes
echo "Enabling title and abstract highlighting..."
python3 docker/latexdiff/postprocess_diff.py "$DIFF_FILE"

echo "Post-processing complete"

# 差分ファイルをコンパイル（docker/latex/compile.shを使用）
echo "Compiling diff-highlighted PDF using docker/latex/compile.sh..."
echo "Output directory: $OUTPUT_DIR"
if [ -f "docker/latex/compile.sh" ]; then
    # compile.shを使用してコンパイル
    ./docker/latex/compile.sh "$DIFF_FILE"

    # 出力ファイルの存在確認と移動（デフォルトでない出力ディレクトリの場合）
    if [ "$OUTPUT_DIR" != "output" ] && [ -f "output/$DIFF_PDF" ]; then
        echo "Moving PDF to custom output directory: $OUTPUT_DIR"
        mkdir -p "$OUTPUT_DIR"
        mv -f "output/$DIFF_PDF" "$OUTPUT_DIR/$DIFF_PDF"
        # ログファイルなども移動
        mv -f "output/${BASENAME}_diff.log" "$OUTPUT_DIR/" 2>/dev/null || true
    fi

    # 出力ファイルの存在確認
    if [ -f "$OUTPUT_DIR/$DIFF_PDF" ]; then
        echo "✓ Diff-highlighted PDF created successfully!"
        echo "  Output: $OUTPUT_DIR/$DIFF_PDF"
        echo "  Changes from $OLD_FILE to $NEW_FILE are highlighted"
    else
        echo "✗ Failed to create diff-highlighted PDF"
        echo "Check $OUTPUT_DIR/${BASENAME}_diff.log for compilation errors"
        exit 1
    fi
else
    echo "Error: docker/latex/compile.sh not found"
    echo "Please ensure the compile script exists in docker/latex/ directory"
    exit 1
fi

echo ""
echo "Files created:"
echo "  $DIFF_FILE - LaTeX source with diff markup"
echo "  $OUTPUT_DIR/$DIFF_PDF - PDF with highlighted changes"
echo "  $OUTPUT_DIR/ - Compilation artifacts"
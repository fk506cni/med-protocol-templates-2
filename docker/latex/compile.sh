#!/bin/bash

# LaTeX compilation script for Docker
# Usage: ./docker/latex/compile.sh [-t|--timestamp] [tex_file]

set -e

# デフォルト値
ADD_TIMESTAMP=false
TEX_FILE=""

# 引数解析
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--timestamp)
            ADD_TIMESTAMP=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [-t|--timestamp] <tex_file>"
            echo ""
            echo "Options:"
            echo "  -t, --timestamp    Add timestamp to output filename"
            echo "  -h, --help         Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 main.tex                    # Standard compilation"
            echo "  $0 -t main.tex                 # With timestamp"
            exit 0
            ;;
        *)
            if [[ -z "$TEX_FILE" ]]; then
                TEX_FILE="$1"
            else
                echo "Error: Multiple input files specified"
                exit 1
            fi
            shift
            ;;
    esac
done

# デフォルトファイル名
TEX_FILE=${TEX_FILE:-main.tex}
# Remove leading ./ if present
TEX_FILE="${TEX_FILE#./}"
BASE_NAME=$(basename "$TEX_FILE" .tex)

# 出力ファイル名の決定
if [ "$ADD_TIMESTAMP" = true ]; then
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    OUTPUT_NAME="${BASE_NAME}_${TIMESTAMP}"
else
    OUTPUT_NAME="${BASE_NAME}"
fi

echo "Compiling LaTeX document: $TEX_FILE"
echo "Output name: ${OUTPUT_NAME}.pdf"
echo "----------------------------------------"

# Build Docker image if it doesn't exist
if [[ "$(docker images -q med-protocol-latex 2> /dev/null)" == "" ]]; then
    echo "Building LaTeX compiler Docker image..."
    docker build -t med-protocol-latex docker/latex/
fi

# Create output directory
mkdir -p output

# Run compilation in Docker container with current user to avoid permission issues
docker run --rm \
    --user $(id -u):$(id -g) \
    -v "$(pwd):/workspace" \
    med-protocol-latex \
    bash -c "
        cd /workspace

        # Extract directory and filename
        TEX_DIR=\$(dirname '$TEX_FILE')
        TEX_FILENAME=\$(basename '$TEX_FILE')

        # Change to the directory containing the tex file
        cd /workspace/\$TEX_DIR

        echo 'Running lualatex (1st pass)...'
        lualatex -interaction=nonstopmode \"\$TEX_FILENAME\" || echo 'lualatex warnings/errors (continuing...)'

        echo 'Running upbibtex...'
        upbibtex '$BASE_NAME' || echo 'upbibtex warnings (may be normal)'

        echo 'Running lualatex (2nd pass)...'
        lualatex -interaction=nonstopmode \"\$TEX_FILENAME\" || echo 'lualatex warnings/errors (continuing...)'

        echo 'Running lualatex (3rd pass)...'
        lualatex -interaction=nonstopmode \"\$TEX_FILENAME\" || echo 'lualatex warnings/errors (continuing...)'

        # Move PDF to output directory
        PDF_FILE='$BASE_NAME.pdf'
        mkdir -p /workspace/output
        if [ -f \"\$PDF_FILE\" ]; then
            mv \"\$PDF_FILE\" /workspace/output/'$OUTPUT_NAME'.pdf

            # Create symlink to latest version (if timestamp is used)
            if [ '$ADD_TIMESTAMP' = true ]; then
                cd /workspace/output
                ln -sf '$OUTPUT_NAME'.pdf '$BASE_NAME'.pdf
                cd -
            fi

            # Cleanup auxiliary files
            rm -f *.aux *.log *.toc *.out *.dvi *.fls *.fdb_latexmk *.bbl *.blg 2>/dev/null || true
        fi

        echo 'Compilation completed!'
        echo 'Output: output/'$OUTPUT_NAME'.pdf'
    "

echo "PDF generated in output/${OUTPUT_NAME}.pdf"
if [ "$ADD_TIMESTAMP" = true ]; then
    echo "Symlink created: output/${BASE_NAME}.pdf -> ${OUTPUT_NAME}.pdf"
fi

echo "LaTeX compilation finished successfully!"
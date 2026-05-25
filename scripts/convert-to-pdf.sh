#!/usr/bin/env bash
# convert-to-pdf.sh
# Converts book.md to book.pdf using Pandoc
# Run from repo root: bash scripts/convert-to-pdf.sh

INPUT="${1:-book.md}"
OUTPUT="${2:-book.pdf}"
ENGINE="${3:-xelatex}"   # xelatex | pdflatex | wkhtmltopdf

# ── 1. Check Pandoc ───────────────────────────────────────────────────────────
if ! command -v pandoc &>/dev/null; then
    echo ""
    echo "Pandoc not found. Install it:"
    echo "  macOS : brew install pandoc"
    echo "  Linux : sudo apt install pandoc"
    echo ""
    exit 1
fi

echo "Using $(pandoc --version | head -1)"

# ── 2. Check PDF engine ───────────────────────────────────────────────────────
if ! command -v "$ENGINE" &>/dev/null; then
    echo ""
    echo "$ENGINE not found. Options:"
    echo "  xelatex/pdflatex : brew install mactex  (macOS)"
    echo "                     sudo apt install texlive-xetex  (Linux)"
    echo "  wkhtmltopdf      : brew install wkhtmltopdf  (macOS)"
    echo ""
    echo "Re-run with a different engine:"
    echo "  bash scripts/convert-to-pdf.sh book.md book.pdf wkhtmltopdf"
    echo ""
    exit 1
fi

# ── 3. Check input file ───────────────────────────────────────────────────────
if [ ! -f "$INPUT" ]; then
    echo "Input file not found: $INPUT"
    echo "Run this script from the repo root directory."
    exit 1
fi

# ── 4. Convert ────────────────────────────────────────────────────────────────
echo ""
echo "Converting $INPUT → $OUTPUT ..."
echo "Engine : $ENGINE"
echo ""

START=$(date +%s)

pandoc "$INPUT" \
    --output "$OUTPUT" \
    --from "markdown+smart+pipe_tables+fenced_code_blocks" \
    --pdf-engine "$ENGINE" \
    --metadata-file "pandoc/book-meta.yaml" \
    --highlight-style tango \
    --toc \
    --toc-depth 2 \
    --strip-comments \
    -V pagestyle=fancy

END=$(date +%s)
ELAPSED=$((END - START))

# ── 5. Result ─────────────────────────────────────────────────────────────────
if [ $? -eq 0 ] && [ -f "$OUTPUT" ]; then
    SIZE=$(du -sh "$OUTPUT" | cut -f1)
    echo ""
    echo "Done! $OUTPUT ($SIZE) in ${ELAPSED}s"
    echo ""
    # Open on macOS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        read -rp "Open PDF now? (y/n) " OPEN
        [ "$OPEN" = "y" ] && open "$OUTPUT"
    fi
else
    echo ""
    echo "Conversion failed. Check the output above for errors."
    echo ""
    echo "Common fixes:"
    echo "  - Missing LaTeX packages: sudo apt install texlive-fonts-recommended texlive-latex-extra"
    echo "  - Font not found: edit pandoc/book-meta.yaml and remove mainfont/monofont lines"
    echo "  - Try wkhtmltopdf: bash scripts/convert-to-pdf.sh book.md book.pdf wkhtmltopdf"
    exit 1
fi

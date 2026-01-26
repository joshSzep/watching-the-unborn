#!/bin/bash

# Generate PDF from manuscript
# Requires: pandoc, LaTeX (mactex or basictex)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MANUSCRIPT="$REPO_ROOT/MANUSCRIPT.md"
OUTPUT_PDF="$REPO_ROOT/watching-the-unborn.pdf"
METADATA="$SCRIPT_DIR/metadata.yaml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Generating PDF...${NC}"

# Check dependencies
if ! command -v pandoc &> /dev/null; then
    echo -e "${RED}Error: pandoc is not installed${NC}"
    echo "Install with: brew install pandoc"
    exit 1
fi

if ! command -v pdflatex &> /dev/null; then
    echo -e "${RED}Error: LaTeX is not installed${NC}"
    echo "Install with: brew install --cask mactex"
    exit 1
fi

# Regenerate manuscript first
echo "Regenerating manuscript from chapters..."
"$SCRIPT_DIR/generate-manuscript.sh"

# Generate PDF with pandoc
echo "Converting to PDF..."
pandoc "$MANUSCRIPT" \
    --metadata-file="$METADATA" \
    --pdf-engine=xelatex \
    --toc \
    --toc-depth=2 \
    --top-level-division=part \
    -V documentclass=book \
    -V classoption=openright \
    -V papersize=6in:9in \
    -V geometry:"top=0.75in, bottom=0.75in, left=0.75in, right=0.75in" \
    -V mainfont="Palatino" \
    -V fontsize=11pt \
    -V linestretch=1.2 \
    -V indent=true \
    -V subparagraph \
    --highlight-style=monochrome \
    -o "$OUTPUT_PDF"

echo -e "${GREEN}PDF generated: $OUTPUT_PDF${NC}"

# Show file size
SIZE=$(du -h "$OUTPUT_PDF" | cut -f1)
echo "File size: $SIZE"

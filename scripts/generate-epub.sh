#!/bin/bash

# Generate EPUB from manuscript
# Requires: pandoc

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MANUSCRIPT="$REPO_ROOT/MANUSCRIPT.md"
OUTPUT_EPUB="$REPO_ROOT/watching-the-unborn.epub"
COVER_IMAGE="$REPO_ROOT/cover.png"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Generating EPUB...${NC}"

# Check dependencies
if ! command -v pandoc &> /dev/null; then
    echo -e "${RED}Error: pandoc is not installed${NC}"
    echo "Install with: brew install pandoc"
    exit 1
fi

# Regenerate manuscript first
echo "Regenerating manuscript from chapters..."
"$SCRIPT_DIR/generate-manuscript.sh"

# Build pandoc args
PANDOC_ARGS=(
    "$MANUSCRIPT"
    --from=markdown
    --to=epub3
    --toc
    --toc-depth=2
    --metadata title="Watching the Unborn"
    --metadata author="Joshua Szepietowski"
    --metadata lang="en-US"
    -o "$OUTPUT_EPUB"
)

if [[ -f "$COVER_IMAGE" ]]; then
    PANDOC_ARGS+=(--epub-cover-image="$COVER_IMAGE")
else
    echo -e "${YELLOW}Warning: cover.png not found; EPUB will have no cover image.${NC}"
fi

echo "Converting to EPUB..."
pandoc "${PANDOC_ARGS[@]}"

echo -e "${GREEN}EPUB generated: $OUTPUT_EPUB${NC}"

# Show file size
SIZE=$(du -h "$OUTPUT_EPUB" | cut -f1)
echo "File size: $SIZE"

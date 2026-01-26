#!/bin/bash

# Generate all output formats and website bundle

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}Generating all formats...${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""

# Generate PDF
echo -e "${YELLOW}[1/4] Generating PDF...${NC}"
"$SCRIPT_DIR/generate-pdf.sh"
echo ""

# Generate HTML
echo -e "${YELLOW}[2/4] Generating HTML viewer...${NC}"
"$SCRIPT_DIR/generate-html.sh"
echo ""

# Generate EPUB
echo -e "${YELLOW}[3/4] Generating EPUB...${NC}"
"$SCRIPT_DIR/generate-epub.sh"
echo ""

# Generate landing page bundle
echo -e "${YELLOW}[4/4] Generating landing page bundle...${NC}"
"$SCRIPT_DIR/generate-landing-page.sh"
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}All formats generated successfully!${NC}"
echo -e "${GREEN}========================================${NC}"

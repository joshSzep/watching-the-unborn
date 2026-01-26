# PDF Generation Instructions

This document explains how to generate a professionally typeset PDF of *Watching the Unborn*.

## Prerequisites

### macOS

```bash
# Install Pandoc (document converter)
brew install pandoc

# Install MacTeX (full LaTeX distribution)
brew install --cask mactex

# After installing MacTeX, restart your terminal or run:
eval "$(/usr/libexec/path_helper)"
```

### Verify Installation

```bash
pandoc --version
pdflatex --version
xelatex --version
```

## Generating the PDF

From the repository root:

```bash
./scripts/generate-pdf.sh
```

This will:
1. Regenerate `MANUSCRIPT.md` from all chapter files
2. Convert the manuscript to a typeset PDF
3. Output to `watching-the-unborn.pdf` in the repository root

## Output

The PDF is generated with professional book formatting:

- **Trim size**: 6" × 9" (standard trade paperback)
- **Font**: Palatino, 11pt
- **Line spacing**: 1.2
- **Margins**: 0.75" with 0.25" binding offset
- **Features**:
  - Table of contents
  - Running headers (book title on left, chapter on right)
  - Page numbers centered at bottom
  - Widow/orphan control
  - Microtypography (character protrusion, font expansion)
  - Two-sided layout with chapters starting on right pages

## Customization

### metadata.yaml

Edit `scripts/metadata.yaml` to change:
- Fonts (mainfont, sansfont, monofont)
- Page dimensions and margins
- Line spacing
- Header/footer content
- Other LaTeX settings

### Common Adjustments

**Change font:**
```yaml
mainfont: "Georgia"
```

**Change trim size (e.g., 5.5" × 8.5"):**
```yaml
geometry:
  - paperwidth=5.5in
  - paperheight=8.5in
```

**Adjust margins:**
```yaml
geometry:
  - top=1in
  - bottom=1in
  - left=0.875in
  - right=0.625in
```

**Remove table of contents:**
```yaml
toc: false
```

## Troubleshooting

### "Font not found" errors

If Palatino isn't available, try:
```yaml
mainfont: "TeX Gyre Pagella"  # Open-source Palatino clone
```

Or use system fonts:
```yaml
mainfont: "Georgia"
mainfont: "Times New Roman"
```

### LaTeX errors

Run with verbose output:
```bash
pandoc MANUSCRIPT.md --metadata-file=scripts/metadata.yaml --pdf-engine=xelatex -o output/test.pdf --verbose
```

### Missing packages

If LaTeX packages are missing, install them via TeX Live Manager:
```bash
sudo tlmgr install microtype fancyhdr
```

## Alternative Outputs

### EPUB (for e-readers)

```bash
pandoc MANUSCRIPT.md \
    --metadata-file=scripts/metadata.yaml \
    --toc \
    -o output/watching-the-unborn.epub
```

### DOCX (for Word)

```bash
pandoc MANUSCRIPT.md \
    --metadata-file=scripts/metadata.yaml \
    -o output/watching-the-unborn.docx
```

### HTML

```bash
pandoc MANUSCRIPT.md \
    --metadata-file=scripts/metadata.yaml \
    --standalone \
    --toc \
    -o output/watching-the-unborn.html
```

## File Structure

```
./
├── watching-the-unborn.pdf  # Generated PDF (git-ignored)
├── MANUSCRIPT.md            # Combined manuscript
└── scripts/
    ├── generate-manuscript.sh   # Combines chapters into MANUSCRIPT.md
    ├── generate-pdf.sh          # Converts manuscript to PDF
    ├── metadata.yaml            # Book metadata and LaTeX settings
    └── PDF-GENERATION.md        # This file
```

## Notes

- The PDF is generated in the repository root
- Consider adding `*.pdf` to `.gitignore` to avoid committing generated files
- For print-ready PDFs, you may need to adjust bleed settings and color profiles per your printer's requirements

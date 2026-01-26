# Scripts

This directory contains scripts for generating publishable formats of *Watching the Unborn*.

## Quick Start

```bash
# Generate all formats (PDF + HTML + EPUB + website bundle)
./scripts/generate-all.sh

# Or generate individually
./scripts/generate-pdf.sh
./scripts/generate-html.sh
./scripts/generate-epub.sh
./scripts/generate-landing-page.sh
```

## Prerequisites

### macOS

```bash
# Install Pandoc (document converter)
brew install pandoc

# Install MacTeX (for PDF generation)
brew install --cask mactex

# After installing MacTeX, restart your terminal or run:
eval "$(/usr/libexec/path_helper)"
```

### Verify Installation

```bash
pandoc --version
xelatex --version
```

## Scripts

### `generate-all.sh`

Runs all generation scripts in sequence. Use this for a complete build.

**Output:**
- `watching-the-unborn.pdf`
- `watching-the-unborn.html`
- `watching-the-unborn.epub`
- `website/index.html`
- `website/cover.png`
- `website/watching-the-unborn.html`

---

### `generate-pdf.sh`

Generates a professionally typeset PDF suitable for print or digital reading.

**Output:** `watching-the-unborn.pdf` (in repository root)

**Features:**
- 6" × 9" trade paperback trim size
- Palatino font, 11pt
- Table of contents
- Running headers
- Two-sided layout with chapters starting on right pages
- Widow/orphan control and microtypography

---

### `generate-html.sh`

Generates a self-contained HTML viewer with a book-like reading experience.

**Output:** `watching-the-unborn.html` (in repository root, ~3MB)

**Features:**
- Cover image embedded as base64
- Clickable table of contents
- Left/right arrow navigation
- Keyboard shortcuts (←, →, Space, PageUp/PageDown, Home, End)
- Touch/swipe support for mobile
- Reading progress saved to localStorage
- PDF download link for offline reading
- EPUB download link for offline reading
- HTML download link for offline reading
- Beautiful typography (Cormorant Garamond)
- Dark background with paper-like pages

---

### `generate-epub.sh`

Generates an EPUB for e-readers and offline reading apps.

**Output:** `watching-the-unborn.epub` (in repository root)

**Notes:**
- Uses `cover.png` as the EPUB cover when available
- Includes a table of contents

---

### `generate-manuscript.sh`

Combines all chapter files into a single `MANUSCRIPT.md` file. Called automatically by other scripts.

**Output:** `MANUSCRIPT.md` (in repository root)

**How it works:**
1. Reads chapters from `chapters/Part N - */Chapter NN - *.md`
2. Combines them in order with part and chapter headings
3. Outputs a single unified markdown file

---

### `generate-landing-page.sh`

Generates a simple static landing page bundle you can zip and upload to Cloudflare Pages / static hosting.

**Output:**
- `website/index.html`
- `website/cover.png`
- `website/watching-the-unborn.html`

**Notes:**
- The HTML is self-contained (inline CSS) and expects `cover.png` and `watching-the-unborn.html` alongside it.
- “Read Online” opens the bundled `website/watching-the-unborn.html` viewer.
- “Download HTML” downloads the bundled viewer.
- PDF/EPUB buttons link to the hosted GitHub raw PDF/EPUB.

---

### `metadata.yaml`

Configuration for PDF generation via Pandoc/LaTeX.

**Key settings:**
- Fonts (mainfont, sansfont, monofont)
- Page dimensions and margins
- Line spacing
- Table of contents options
- Header/footer styling

## Customization

### Change PDF Font

Edit `metadata.yaml`:
```yaml
mainfont: "Georgia"
```

If Palatino isn't available:
```yaml
mainfont: "TeX Gyre Pagella"  # Open-source Palatino clone
```

### Change Trim Size

Edit `metadata.yaml`:
```yaml
geometry:
  - paperwidth=5.5in
  - paperheight=8.5in
```

### Adjust Margins

Edit `metadata.yaml`:
```yaml
geometry:
  - top=1in
  - bottom=1in
  - left=0.875in
  - right=0.625in
```

## Troubleshooting

### "Font not found" errors

Try an alternative font in `metadata.yaml`:
```yaml
mainfont: "Times New Roman"
```

### LaTeX errors

Run with verbose output:
```bash
pandoc MANUSCRIPT.md --metadata-file=scripts/metadata.yaml --pdf-engine=xelatex -o test.pdf --verbose
```

### Missing LaTeX packages

```bash
sudo tlmgr install microtype fancyhdr
```

## Output Files

```
./
├── watching-the-unborn.pdf   # Generated PDF
├── watching-the-unborn.html  # Generated HTML viewer
├── watching-the-unborn.epub  # Generated EPUB
├── MANUSCRIPT.md             # Combined manuscript (generated)
├── cover.png                 # Cover art (embedded in HTML)
├── website/                  # Static landing page bundle (generated)
└── scripts/
    ├── generate-all.sh       # Generate all formats
    ├── generate-pdf.sh       # Generate PDF
    ├── generate-html.sh      # Generate HTML viewer
    ├── generate-epub.sh      # Generate EPUB
    ├── generate-landing-page.sh # Generate static landing page bundle
    ├── generate-manuscript.sh # Combine chapters
    ├── metadata.yaml         # PDF settings
    └── README.md             # This file
```

## Alternative Formats

Pandoc can generate other formats from `MANUSCRIPT.md`:

### DOCX (Word)

```bash
pandoc MANUSCRIPT.md \
    -o watching-the-unborn.docx
```

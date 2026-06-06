#!/bin/bash

# Generate a self-contained static landing page bundle.
# Output: ./website/index.html + ./website/cover.png + ./website/watching-the-unborn.html

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_ROOT="$REPO_ROOT/output"
OUTPUT_DIR="$OUTPUT_ROOT/website"
COVER_SRC="$REPO_ROOT/cover.png"
COVER_DST="$OUTPUT_DIR/cover.png"
OUTPUT_INDEX="$OUTPUT_DIR/index.html"
VIEWER_SRC="$OUTPUT_ROOT/watching-the-unborn.html"
VIEWER_DST="$OUTPUT_DIR/watching-the-unborn.html"
PDF_SRC="$OUTPUT_ROOT/watching-the-unborn.pdf"
PDF_DST="$OUTPUT_DIR/watching-the-unborn.pdf"
EPUB_NAME="Watching The Unborn.epub"
EPUB_SRC="$REPO_ROOT/$EPUB_NAME"
EPUB_DST="$OUTPUT_DIR/$EPUB_NAME"
ZIP_DST="$OUTPUT_ROOT/website.zip"
README_SRC="$REPO_ROOT/README.md"
CHAPTER_ONE_SRC="$REPO_ROOT/chapters/Part 1 - Human Aria/Chapter 01 - Waiting.md"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Generating landing page bundle...${NC}"

if [[ ! -f "$COVER_SRC" ]]; then
  echo -e "${RED}Error: cover.png not found at repo root.${NC}"
  echo "Expected: $COVER_SRC"
  exit 1
fi

if [[ ! -f "$README_SRC" ]]; then
  echo -e "${RED}Error: README.md not found at repo root.${NC}"
  echo "Expected: $README_SRC"
  exit 1
fi

if [[ ! -f "$CHAPTER_ONE_SRC" ]]; then
  echo -e "${RED}Error: Chapter 1 markdown not found.${NC}"
  echo "Expected: $CHAPTER_ONE_SRC"
  exit 1
fi

# Clean output dir
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# Copy cover
cp "$COVER_SRC" "$COVER_DST"

# Generate + copy the HTML reader (so Read Online works when hosted)
# If the viewer already exists (e.g. after running generate-all), don't rebuild it.
if [[ ! -f "$VIEWER_SRC" ]]; then
  "$SCRIPT_DIR/generate-html.sh"
fi
cp "$VIEWER_SRC" "$VIEWER_DST"

# Generate + copy PDF/EPUB so the website bundle is self-contained.
if [[ ! -f "$PDF_SRC" ]]; then
  "$SCRIPT_DIR/generate-pdf.sh"
fi
cp "$PDF_SRC" "$PDF_DST"

if [[ ! -f "$EPUB_SRC" ]]; then
  "$SCRIPT_DIR/generate-epub.sh"
fi
cp "$EPUB_SRC" "$EPUB_DST"

# Rewrite bundled viewer download links to point at local files in this bundle.
export VIEWER_DST
python3 - <<'PY'
import os
from pathlib import Path

path = Path(os.environ["VIEWER_DST"])
html = path.read_text(encoding="utf-8")

replacements = {
  "https://raw.githubusercontent.com/joshSzep/watching-the-unborn/main/output/watching-the-unborn.pdf": "watching-the-unborn.pdf",
  "https://raw.githubusercontent.com/joshSzep/watching-the-unborn/main/output/watching-the-unborn.epub": "Watching%20The%20Unborn.epub",
  "https://raw.githubusercontent.com/joshSzep/watching-the-unborn/main/Watching%20The%20Unborn.epub": "Watching%20The%20Unborn.epub",
  "https://watching-the-unborn.joshszep.com/watching-the-unborn.epub": "Watching%20The%20Unborn.epub",
  "https://watching-the-unborn.joshszep.com/Watching%20The%20Unborn.epub": "Watching%20The%20Unborn.epub",
  "https://raw.githubusercontent.com/joshSzep/watching-the-unborn/main/output/watching-the-unborn.html": "watching-the-unborn.html",
}

for old, new in replacements.items():
    html = html.replace(old, new)

path.write_text(html, encoding="utf-8")
PY

# Extract the Blurb section from the repo README and convert it to HTML
BLURB_MD=$(awk 'BEGIN{p=0} /^##[[:space:]]+Blurb[[:space:]]*$/{p=1; next} /^##[[:space:]]+Genre[[:space:]]*$/{p=0} p{print}' "$README_SRC" | sed '/^[[:space:]]*$/N;/^\n$/D')
BLURB_HTML=$(printf "%s\n" "$BLURB_MD" | pandoc -f markdown -t html --wrap=none)

# Convert the first chapter to HTML for the landing page sample.
CHAPTER_ONE_MD=$(sed '1{/^# /d;}' "$CHAPTER_ONE_SRC")
CHAPTER_ONE_HTML=$(printf "%s\n" "$CHAPTER_ONE_MD" | pandoc -f markdown -t html --wrap=none)

# Write landing page HTML
cat > "$OUTPUT_INDEX" << 'HTML'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Watching the Unborn | A Novel by Joshua Szepietowski</title>
  <meta name="description" content="An actuary uploads her mind at eighty-five to buy more time with her daughter. After her daughter refuses to upload and dies, the mother becomes custodian to frozen eggs for three centuries." />
  <link rel="icon" type="image/png" href="cover.png" />
  <link rel="apple-touch-icon" href="cover.png" />

  <link rel="preconnect" href="https://fonts.googleapis.com" />
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
  <link href="https://fonts.googleapis.com/css2?family=Cinzel:wght@400;700&family=Lato:wght@300;400;700&family=Playfair+Display:ital,wght@0,400;0,700;1,400&display=swap" rel="stylesheet" />

  <style>
    :root {
      --bg: #050a12;
      --panel: #0a1220;
      --text: #eaf2ff;
      --muted: #b7c7dd;
      --faded: #7f97b4;
      --gold: #9cc4ff;
      --ember: #d9f1ff;
      --border: #14253c;

      --font-display: 'Cinzel', serif;
      --font-body: 'Lato', system-ui, -apple-system, Segoe UI, Roboto, Helvetica, Arial, sans-serif;
      --font-quote: 'Playfair Display', serif;

      --max: 1160px;
    }

    * { box-sizing: border-box; margin: 0; padding: 0; }
    html { scroll-behavior: smooth; }
    body {
      background: radial-gradient(ellipse at top, #0c1a33 0%, var(--bg) 58%);
      color: var(--text);
      font-family: var(--font-body);
      line-height: 1.65;
      overflow-x: hidden;
    }

    a { color: inherit; text-decoration: none; transition: 0.25s; }
    ul { list-style: none; }

    /* Top Nav */
    nav {
      position: fixed;
      top: 0;
      left: 0;
      right: 0;
      z-index: 20;
      background: rgba(5, 10, 18, 0.72);
      backdrop-filter: blur(10px);
      -webkit-backdrop-filter: blur(10px);
      border-bottom: 1px solid rgba(255, 255, 255, 0.06);
    }

    .nav-inner {
      max-width: var(--max);
      margin: 0 auto;
      padding: 18px 18px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 16px;
    }

    .brand {
      font-family: var(--font-display);
      letter-spacing: 2px;
      text-transform: uppercase;
      font-size: 0.95rem;
    }

    .nav-links {
      display: flex;
      gap: 22px;
      font-size: 0.8rem;
      letter-spacing: 1px;
      text-transform: uppercase;
      color: var(--muted);
    }

    .nav-links a:hover { color: var(--gold); }

    /* Layout */
    .wrap {
      max-width: var(--max);
      margin: 0 auto;
      padding: 0 18px;
    }

    .hero {
      min-height: 100vh;
      display: flex;
      align-items: center;
      padding-top: 72px;
      padding-bottom: 40px;
    }

    .hero-grid {
      display: grid;
      grid-template-columns: 1.1fr 0.9fr;
      gap: 56px;
      align-items: center;
      width: 100%;
    }

    .subtitle {
      color: var(--faded);
      text-transform: uppercase;
      letter-spacing: 4px;
      font-size: 0.9rem;
      margin-bottom: 14px;
    }

    h1 {
      font-family: var(--font-display);
      font-weight: 400;
      letter-spacing: 2px;
      text-transform: uppercase;
      font-size: 3.1rem;
      line-height: 1.08;
      color: #fff;
    }

    .logline {
      margin-top: 26px;
      font-family: var(--font-quote);
      font-style: italic;
      font-size: 1.35rem;
      color: #d7e6ff;
      border-left: 3px solid var(--ember);
      padding-left: 18px;
    }

    .lede {
      margin-top: 18px;
      color: #c0d3ee;
      font-size: 1.05rem;
      max-width: 62ch;
    }

    .cta-row {
      margin-top: 28px;
      display: flex;
      flex-wrap: wrap;
      gap: 14px;
      align-items: center;
    }

    .btn {
      display: inline-flex;
      align-items: center;
      gap: 10px;
      padding: 12px 22px;
      border-radius: 999px;
      border: 1px solid rgba(156, 196, 255, 0.55);
      color: var(--gold);
      background: rgba(10, 18, 32, 0.35);
      letter-spacing: 1px;
      text-transform: uppercase;
      font-size: 0.78rem;
    }

    .btn:hover {
      background: rgba(156, 196, 255, 0.12);
      border-color: rgba(156, 196, 255, 0.85);
      box-shadow: 0 0 24px rgba(156, 196, 255, 0.14);
    }

    .btn-primary {
      background: var(--gold);
      color: #0a0a0a;
      font-weight: 700;
      border-color: var(--gold);
    }

    .btn-primary:hover {
      background: transparent;
      color: var(--gold);
    }

    .fineprint {
      margin-top: 10px;
      color: #7f7f7f;
      font-size: 0.85rem;
    }

    .cover {
      width: 100%;
      height: auto;
      border-radius: 4px;
      box-shadow: 0 0 70px rgba(156, 196, 255, 0.14);
      transform: rotate(-1.5deg);
      transition: transform 0.45s ease, box-shadow 0.45s ease;
    }

    .cover:hover {
      transform: rotate(0deg) scale(1.01);
      box-shadow: 0 0 90px rgba(217, 241, 255, 0.16);
    }

    /* Sections */
    .section {
      padding: 96px 0;
      border-top: 1px solid rgba(255, 255, 255, 0.06);
      background: linear-gradient(180deg, rgba(0,0,0,0) 0%, rgba(0,0,0,0.15) 100%);
    }

    h2 {
      font-family: var(--font-display);
      font-weight: 400;
      letter-spacing: 2px;
      text-transform: uppercase;
      font-size: 2.2rem;
      color: var(--gold);
      margin-bottom: 18px;
    }

    .premise {
      max-width: 78ch;
      margin: 0 auto;
      text-align: center;
    }

    .premise p {
      color: #bcbcbc;
      font-size: 1.1rem;
      margin-bottom: 14px;
    }

    .chapter-layout {
      max-width: 860px;
      margin: 0 auto;
    }

    .chapter-header {
      text-align: center;
      margin-bottom: 36px;
    }

    .chapter-deck {
      color: #b7c7dd;
      font-family: var(--font-quote);
      font-style: italic;
      font-size: 1.12rem;
      max-width: 62ch;
      margin: 0 auto;
    }

    .chapter-reader {
      border-top: 1px solid rgba(156, 196, 255, 0.24);
      border-bottom: 1px solid rgba(156, 196, 255, 0.18);
      padding: 42px 0 30px;
    }

    .chapter-reader p {
      color: #dbe8fb;
      font-family: var(--font-quote);
      font-size: 1.08rem;
      line-height: 1.85;
      margin: 0 0 1.18em;
    }

    .chapter-reader em {
      color: #f1f7ff;
    }

    .chapter-reader hr {
      border: 0;
      width: 72px;
      height: 1px;
      margin: 34px auto;
      background: rgba(156, 196, 255, 0.35);
    }

    .chapter-actions {
      display: flex;
      justify-content: center;
      gap: 14px;
      flex-wrap: wrap;
      margin-top: 30px;
    }

    .pill-row {
      display: flex;
      justify-content: center;
      gap: 14px;
      flex-wrap: wrap;
      margin-top: 26px;
    }

    .pill {
      padding: 10px 14px;
      border: 1px solid var(--border);
      border-radius: 999px;
      background: rgba(0,0,0,0.18);
      color: #b1b1b1;
      font-size: 0.88rem;
    }

    .pill strong { color: #f1f1f1; font-weight: 700; }

    .grid {
      display: grid;
      grid-template-columns: repeat(3, minmax(0, 1fr));
      gap: 18px;
      margin-top: 36px;
    }

    .card {
      background: rgba(0,0,0,0.20);
      border: 1px solid rgba(255,255,255,0.06);
      padding: 22px;
      border-radius: 10px;
      min-height: 160px;
      transition: transform 0.2s ease, border-color 0.2s ease;
    }

    .card:hover {
      transform: translateY(-3px);
      border-color: rgba(156, 196, 255, 0.35);
      box-shadow: 0 0 26px rgba(156, 196, 255, 0.10);
    }

    .kicker {
      color: var(--ember);
      letter-spacing: 1px;
      text-transform: uppercase;
      font-size: 0.78rem;
      margin-bottom: 8px;
    }

    .card h3 {
      font-family: var(--font-display);
      font-weight: 400;
      letter-spacing: 1px;
      color: #fff;
      font-size: 1.2rem;
      margin-bottom: 10px;
    }

    .card p {
      color: #a8a8a8;
      font-size: 0.95rem;
    }

    footer {
      border-top: 1px solid rgba(255,255,255,0.06);
      padding: 48px 0;
      text-align: center;
      color: #7f7f7f;
      background: #070707;
    }

    .footer-brand {
      font-family: var(--font-display);
      letter-spacing: 2px;
      text-transform: uppercase;
      color: #fff;
      display: inline-block;
      margin-bottom: 12px;
    }

    /* Responsive */
    @media (max-width: 920px) {
      .hero-grid { grid-template-columns: 1fr; gap: 28px; text-align: center; }
      .logline { border-left: none; border-top: 3px solid var(--ember); padding: 16px 0 0; margin-left: auto; margin-right: auto; }
      .lede { margin-left: auto; margin-right: auto; }
      .cta-row { justify-content: center; }
      .nav-links { display: none; }
      .grid { grid-template-columns: 1fr; }
    }
  </style>
</head>
<body>
  <nav>
    <div class="nav-inner wrap">
      <div class="brand"><a href="#top">Watching the Unborn</a></div>
      <div class="nav-links">
        <a href="#blurb">Blurb</a>
        <a href="#chapter-one">Chapter 1</a>
        <a href="#themes">Themes</a>
        <a href="#download">Download</a>
      </div>
    </div>
  </nav>

  <main id="top" class="hero">
    <div class="wrap hero-grid">
      <div>
        <div class="subtitle">A novel by Joshua Szepietowski</div>
        <h1>Custodianship<br/>Without Agency</h1>
        <div class="logline">
          An actuary uploads her mind at eighty-five to buy more time with her daughter.
          When the daughter refuses and dies, the mother becomes caretaker to what remains—frozen eggs—across centuries.
        </div>
        <p class="lede">
          A restrained hard sci‑fi novel about deferred meaning, probability, and the quiet labor of maintenance.
          Not immortality—waiting.
        </p>

        <div class="cta-row" id="download">
          <a class="btn btn-primary" href="watching-the-unborn.html">Read Online</a>
          <a class="btn" href="#chapter-one">Read Chapter 1</a>
          <a class="btn" href="watching-the-unborn.html" download="watching-the-unborn.html" data-download-html>Download HTML</a>
          <a class="btn" href="watching-the-unborn.pdf" download="watching-the-unborn.pdf">Download PDF</a>
          <a class="btn" href="Watching%20The%20Unborn.epub" download="Watching The Unborn.epub">Download EPUB</a>
          <a class="btn" href="https://joshszep.com" target="_blank" rel="noopener">Author Books</a>
          <a class="btn" href="https://github.com/joshSzep/watching-the-unborn" target="_blank" rel="noopener">Project Repo</a>
        </div>
      </div>

      <div>
        <img src="cover.png" alt="Watching the Unborn Cover" class="cover" />
      </div>
    </div>
  </main>

  <section id="blurb" class="section">
    <div class="wrap premise">
      <div class="subtitle">From the jacket copy</div>
      <h2>Blurb</h2>
      __BLURB_HTML__
    </div>
  </section>

  <section id="chapter-one" class="section">
    <div class="wrap chapter-layout">
      <div class="chapter-header">
        <div class="subtitle">Read the opening chapter</div>
        <h2>Chapter 1: Waiting</h2>
        <p class="chapter-deck">
          The novel begins before the centuries, in an ordinary clinic waiting room,
          where potential first becomes something to preserve.
        </p>
      </div>

      <article class="chapter-reader" aria-label="Chapter 1: Waiting">
        __CHAPTER_ONE_HTML__
      </article>

      <div class="chapter-actions">
        <a class="btn btn-primary" href="watching-the-unborn.html">Continue Reading</a>
        <a class="btn" href="#download">Download the Book</a>
      </div>
    </div>
  </section>

  <section id="themes" class="section" style="background: rgba(0,0,0,0.18);">
    <div class="wrap">
      <div class="premise">
        <div class="subtitle">What it leans into</div>
        <h2>Themes</h2>
      </div>

      <div class="grid">
        <div class="card">
          <div class="kicker">Core line</div>
          <h3>Limits give life meaning</h3>
          <p>Arrived at through experience, not argument.</p>
        </div>
        <div class="card">
          <div class="kicker">Form</div>
          <h3>Time becomes texture</h3>
          <p>Centuries blur. Institutional language replaces dialogue. Repetition becomes pressure.</p>
        </div>
        <div class="card">
          <div class="kicker">Emotional physics</div>
          <h3>Legacy without gratitude</h3>
          <p>Custodianship without agency; persistence without certainty of impact.</p>
        </div>
      </div>
    </div>
  </section>

  <footer>
    <div class="wrap">
      <div class="footer-brand">Watching the Unborn</div>
      <div>© 2026 Joshua Szepietowski</div>
    </div>
  </footer>

  <script>
    // Force-download the bundled HTML reader where possible.
    // (The download attribute is advisory; this makes it more reliable under HTTP hosting.)
    (function () {
      var link = document.querySelector('[data-download-html]');
      if (!link) return;

      link.addEventListener('click', async function (e) {
        try {
          e.preventDefault();
          var res = await fetch('watching-the-unborn.html', { cache: 'no-store' });
          if (!res.ok) throw new Error('Fetch failed: ' + res.status);
          var blob = await res.blob();
          var url = URL.createObjectURL(blob);
          var a = document.createElement('a');
          a.href = url;
          a.download = 'watching-the-unborn.html';
          document.body.appendChild(a);
          a.click();
          a.remove();
          setTimeout(function () { URL.revokeObjectURL(url); }, 1000);
        } catch (err) {
          // Fall back to default browser behavior.
          window.location.href = 'watching-the-unborn.html';
        }
      });
    })();
  </script>
</body>
</html>
HTML

# Inject the README blurb HTML into the generated page
export BLURB_HTML
export CHAPTER_ONE_HTML
export OUTPUT_INDEX
python3 - <<'PY'
import os
from pathlib import Path

path = Path(os.environ.get('OUTPUT_INDEX', ''))
if not path:
  raise SystemExit('OUTPUT_INDEX env var not set')

content = path.read_text(encoding='utf-8')
blurb = os.environ.get('BLURB_HTML', '').strip()
chapter_one = os.environ.get('CHAPTER_ONE_HTML', '').strip()
if '__BLURB_HTML__' not in content:
  raise SystemExit('Blurb placeholder not found in index.html')
if '__CHAPTER_ONE_HTML__' not in content:
  raise SystemExit('Chapter 1 placeholder not found in index.html')

content = content.replace('__BLURB_HTML__', blurb)
content = content.replace('__CHAPTER_ONE_HTML__', chapter_one)
path.write_text(content, encoding='utf-8')
PY

# Zip the website directory for easy static hosting upload
if command -v zip &> /dev/null; then
  rm -f "$ZIP_DST"
  (cd "$OUTPUT_DIR" && zip -rq "$ZIP_DST" .)
else
  echo -e "${YELLOW}Warning: 'zip' not found; skipping website.zip generation.${NC}"
fi

echo -e "${GREEN}Landing page generated:${NC} $OUTPUT_DIR"
echo "- $OUTPUT_INDEX"
echo "- $COVER_DST"
echo "- $VIEWER_DST"
echo "- $PDF_DST"
echo "- $EPUB_DST"
if [[ -f "$ZIP_DST" ]]; then
  echo "- $ZIP_DST"
fi

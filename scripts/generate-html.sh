#!/bin/bash

# Generate HTML viewer from manuscript
# Creates a beautiful single-page HTML with PDF-like navigation

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="$REPO_ROOT/output"
OUTPUT_HTML="$OUTPUT_DIR/watching-the-unborn.html"
COVER_IMAGE="$REPO_ROOT/cover.png"
CHAPTERS_DIR="$REPO_ROOT/chapters"

# Public canonical host for downloads
HOST_BASE_URL="https://watching-the-unborn.joshszep.com"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Generating HTML viewer...${NC}"

mkdir -p "$OUTPUT_DIR"

# Check dependencies
if ! command -v pandoc &> /dev/null; then
    echo -e "${RED}Error: pandoc is not installed${NC}"
    echo "Install with: brew install pandoc"
    exit 1
fi

# Convert cover image to base64 for embedding
echo "Embedding cover image..."
if [[ -f "$COVER_IMAGE" ]]; then
    COVER_BASE64=$(base64 -i "$COVER_IMAGE")
else
    echo -e "${RED}Warning: cover.png not found, skipping cover${NC}"
    COVER_BASE64=""
fi

# Start building HTML
echo "Building HTML..."

# Write HTML header
cat > "$OUTPUT_HTML" << 'HTMLHEAD'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Watching the Unborn</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Cormorant+Garamond:ital,wght@0,500;0,600;0,700;1,500;1,600&family=Source+Sans+3:wght@300;400;500&display=swap" rel="stylesheet">
    <style>
        :root {
            --page-width: 650px;
            --page-max-width: 92vw;
            --bg-dark: #0f0f0f;
            --bg-page: #fdfcfa;
            --text-color: #1a1a1a;
            --text-light: #555;
            --accent: #6b5344;
            --shadow: rgba(0, 0, 0, 0.4);
        }

        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        html {
            font-size: 19px;
            scroll-behavior: smooth;
        }

        body {
            background: var(--bg-dark);
            background-image: 
                radial-gradient(ellipse at center top, #1a1a1a 0%, var(--bg-dark) 60%);
            min-height: 100vh;
            font-family: 'Cormorant Garamond', Georgia, 'Times New Roman', serif;
            font-weight: 500;
            color: var(--text-color);
            overflow-x: hidden;
            -webkit-font-smoothing: antialiased;
            -moz-osx-font-smoothing: grayscale;
        }

        /* Viewer Container */
        .viewer {
            display: flex;
            flex-direction: column;
            align-items: center;
            min-height: 100vh;
            padding: 3rem 1rem 8rem;
        }

        /* Navigation Controls */
        .controls {
            position: fixed;
            bottom: 2rem;
            left: 50%;
            transform: translateX(-50%);
            display: flex;
            align-items: center;
            gap: 1rem;
            background: rgba(15, 15, 15, 0.95);
            backdrop-filter: blur(12px);
            -webkit-backdrop-filter: blur(12px);
            padding: 0.6rem 1.25rem;
            border-radius: 3rem;
            border: 1px solid rgba(255, 255, 255, 0.08);
            box-shadow: 
                0 4px 24px rgba(0, 0, 0, 0.5),
                inset 0 1px 0 rgba(255, 255, 255, 0.05);
            z-index: 100;
        }

        .nav-btn {
            background: none;
            border: none;
            color: rgba(255, 255, 255, 0.85);
            font-size: 1.25rem;
            cursor: pointer;
            padding: 0.6rem;
            border-radius: 50%;
            transition: all 0.2s ease;
            display: flex;
            align-items: center;
            justify-content: center;
            width: 2.75rem;
            height: 2.75rem;
        }

        .nav-btn:hover:not(:disabled) {
            background: rgba(255, 255, 255, 0.1);
            color: #fff;
        }

        .nav-btn:active:not(:disabled) {
            transform: scale(0.95);
        }

        .nav-btn:disabled {
            opacity: 0.25;
            cursor: not-allowed;
        }

        .page-indicator {
            color: rgba(255, 255, 255, 0.7);
            font-family: 'Source Sans 3', -apple-system, sans-serif;
            font-size: 0.8rem;
            font-weight: 400;
            letter-spacing: 0.08em;
            min-width: 90px;
            text-align: center;
        }

        .download-link {
            color: rgba(255, 255, 255, 0.5);
            text-decoration: none;
            font-family: 'Source Sans 3', -apple-system, sans-serif;
            font-size: 0.7rem;
            font-weight: 400;
            letter-spacing: 0.05em;
            padding: 0.5rem 0.75rem;
            transition: color 0.2s ease;
            display: flex;
            align-items: center;
            gap: 0.4rem;
        }

        .download-link:hover {
            color: rgba(255, 255, 255, 0.85);
        }

        .download-link svg {
            width: 14px;
            height: 14px;
        }

        .download-link + .download-link {
            border-left: 1px solid rgba(255, 255, 255, 0.1);
            margin-left: 0.25rem;
        }

        /* Page Container */
        .page-container {
            width: var(--page-width);
            max-width: var(--page-max-width);
        }

        .page {
            display: none;
            background: var(--bg-page);
            min-height: 75vh;
            padding: 3.5rem 3rem;
            box-shadow: 
                0 0 0 1px rgba(0, 0, 0, 0.08),
                0 4px 16px rgba(0, 0, 0, 0.15),
                0 16px 48px rgba(0, 0, 0, 0.2),
                0 24px 64px rgba(0, 0, 0, 0.15);
            border-radius: 3px;
            position: relative;
            animation: pageIn 0.35s ease-out;
        }

        .page.active {
            display: block;
        }

        @keyframes pageIn {
            from {
                opacity: 0;
                transform: translateY(8px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }

        /* Cover Page */
        .page.cover {
            padding: 0;
            background: transparent;
            box-shadow: 
                0 16px 48px rgba(0, 0, 0, 0.35),
                0 32px 80px rgba(0, 0, 0, 0.25);
            min-height: auto;
            overflow: hidden;
        }

        .cover-image {
            width: 100%;
            height: auto;
            display: block;
            border-radius: 3px;
        }

        /* Table of Contents */
        .page.toc {
            padding: 3rem 2.5rem;
        }

        .toc-title {
            font-size: 1.5rem;
            font-weight: 500;
            color: var(--accent);
            margin-bottom: 2.5rem;
            text-align: center;
            letter-spacing: 0.15em;
            text-transform: uppercase;
        }

        .toc-list {
            list-style: none;
        }

        .toc-part {
            margin-bottom: 2rem;
        }

        .toc-part-title {
            font-size: 1rem;
            font-weight: 600;
            color: var(--text-color);
            margin-bottom: 0.75rem;
            padding-bottom: 0.5rem;
            border-bottom: 1px solid rgba(0, 0, 0, 0.08);
            letter-spacing: 0.02em;
        }

        .toc-chapters {
            list-style: none;
            padding-left: 0.5rem;
        }

        .toc-chapter {
            margin: 0.35rem 0;
        }

        .toc-link {
            color: var(--text-light);
            text-decoration: none;
            font-size: 0.9rem;
            transition: color 0.2s ease;
            cursor: pointer;
            display: inline-block;
            padding: 0.15rem 0;
        }

        .toc-link:hover {
            color: var(--accent);
        }

        /* Part Title Pages */
        .part-title {
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            min-height: 55vh;
            text-align: center;
        }

        .part-title h2 {
            font-size: 1.8rem;
            font-weight: 500;
            color: var(--accent);
            letter-spacing: 0.1em;
            text-transform: uppercase;
            margin: 0;
        }

        /* Typography */
        .page h1 {
            font-size: 1.5rem;
            font-weight: 500;
            color: var(--text-color);
            margin: 0 0 2rem;
            text-align: center;
            font-style: italic;
        }

        .page h2 {
            font-size: 1.4rem;
            font-weight: 500;
            color: var(--accent);
            margin: 2.5rem 0 1.5rem;
            text-align: center;
            letter-spacing: 0.08em;
            text-transform: uppercase;
        }

        .page h2:first-child {
            margin-top: 0;
        }

        .page h3 {
            font-size: 1.2rem;
            font-weight: 500;
            color: var(--text-color);
            margin: 2rem 0 1.25rem;
            text-align: center;
        }

        .page p {
            margin-bottom: 1.15rem;
            line-height: 1.75;
            text-align: justify;
            text-indent: 1.75em;
            font-weight: 500;
            hyphens: auto;
            -webkit-hyphens: auto;
        }

        .page p:first-of-type,
        .page h1 + p,
        .page h2 + p,
        .page h3 + p,
        .page hr + p {
            text-indent: 0;
        }

        .page hr {
            border: none;
            text-align: center;
            margin: 2.5rem 0;
            height: 1.5rem;
        }

        .page hr::before {
            content: "· · ·";
            color: var(--text-light);
            font-size: 1.1rem;
            letter-spacing: 0.5em;
        }

        .page em {
            font-style: italic;
        }

        .page strong {
            font-weight: 700;
        }

        .page blockquote {
            margin: 1.5rem 2rem;
            padding-left: 1rem;
            border-left: 2px solid var(--accent);
            font-style: italic;
            color: var(--text-light);
        }

        /* Page Edge Effect */
        .page::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: linear-gradient(to right,
                rgba(0, 0, 0, 0.02) 0%,
                transparent 3%,
                transparent 97%,
                rgba(0, 0, 0, 0.015) 100%);
            pointer-events: none;
            border-radius: 3px;
        }

        /* Progress Bar */
        .progress-bar {
            position: fixed;
            top: 0;
            left: 0;
            height: 2px;
            background: linear-gradient(90deg, var(--accent) 0%, #8a6f5c 100%);
            transition: width 0.3s ease;
            z-index: 101;
        }

        /* Keyboard hint */
        .keyboard-hint {
            position: fixed;
            bottom: 6.5rem;
            left: 50%;
            transform: translateX(-50%);
            color: rgba(255, 255, 255, 0.35);
            font-family: 'Source Sans 3', -apple-system, sans-serif;
            font-size: 0.7rem;
            letter-spacing: 0.1em;
            text-transform: uppercase;
            opacity: 0;
            transition: opacity 0.5s ease;
        }

        .keyboard-hint.visible {
            opacity: 1;
        }

        /* Responsive */
        @media (max-width: 700px) {
            html {
                font-size: 17px;
            }

            .page {
                padding: 2.5rem 1.75rem;
            }

            .controls {
                padding: 0.5rem 1rem;
                gap: 0.75rem;
            }

            .nav-btn {
                width: 2.5rem;
                height: 2.5rem;
            }

            .part-title h2 {
                font-size: 1.5rem;
            }
        }

        /* Print styles */
        @media print {
            .controls, .progress-bar, .keyboard-hint {
                display: none !important;
            }

            body {
                background: white;
            }

            .viewer {
                padding: 0;
            }

            .page {
                display: block !important;
                page-break-after: always;
                box-shadow: none;
                min-height: auto;
                border-radius: 0;
            }

            .page.cover {
                page-break-after: always;
            }
        }
    </style>
</head>
<body>
    <div class="progress-bar" id="progress"></div>
    <div class="keyboard-hint" id="hint">← → to navigate</div>
    
    <div class="viewer">
        <div class="page-container" id="pageContainer">
            <!-- Cover Page -->
            <div class="page cover active" data-page="0">
HTMLHEAD

# Add cover image if exists
if [[ -n "$COVER_BASE64" ]]; then
    echo "                <img src=\"data:image/png;base64,$COVER_BASE64\" alt=\"Watching the Unborn\" class=\"cover-image\">" >> "$OUTPUT_HTML"
else
    echo "                <div style=\"padding: 4rem; text-align: center; background: var(--bg-page);\"><h1 style=\"font-size: 2.5rem; color: var(--accent);\">Watching the Unborn</h1></div>" >> "$OUTPUT_HTML"
fi

echo "            </div>" >> "$OUTPUT_HTML"
echo "" >> "$OUTPUT_HTML"

# Build TOC data while we process chapters
TOC_CONTENT=""
PAGE_NUM=1

# Count chapters to build accurate TOC
declare -a CHAPTER_PAGES
CURRENT_PAGE=2  # Start after cover (0) and TOC (1)

# First pass: count pages and build TOC
for part_num in 1 2 3; do
    part_folder=$(find "$CHAPTERS_DIR" -maxdepth 1 -type d -name "Part $part_num - *" 2>/dev/null | head -1)
    
    if [[ -z "$part_folder" ]]; then
        continue
    fi
    
    part_name=$(basename "$part_folder")
    part_display=$(echo "$part_name" | sed 's/ - / — /')
    
    TOC_CONTENT+="                    <li class=\"toc-part\">\n"
    TOC_CONTENT+="                        <div class=\"toc-part-title\">$part_display</div>\n"
    TOC_CONTENT+="                        <ul class=\"toc-chapters\">\n"
    
    # Part title page
    ((CURRENT_PAGE++))
    
    # Process chapters
    while IFS= read -r chapter_file; do
        chapter_name=$(basename "$chapter_file" .md)
        chapter_display=$(echo "$chapter_name" | sed 's/ - / — /')
        
        TOC_CONTENT+="                            <li class=\"toc-chapter\"><span class=\"toc-link\" data-goto=\"$CURRENT_PAGE\">$chapter_display</span></li>\n"
        ((CURRENT_PAGE++))
    done < <(find "$part_folder" -name "Chapter *.md" -type f | sort)
    
    TOC_CONTENT+="                        </ul>\n"
    TOC_CONTENT+="                    </li>\n"
done

TOTAL_PAGES=$CURRENT_PAGE

# Write TOC page
cat >> "$OUTPUT_HTML" << TOCPAGE
            <!-- Table of Contents -->
            <div class="page toc" data-page="1">
                <h2 class="toc-title">Contents</h2>
                <ul class="toc-list">
$(echo -e "$TOC_CONTENT")
                </ul>
            </div>

TOCPAGE

# Second pass: write actual chapter content
echo "Processing chapters..."
CURRENT_PAGE=2

for part_num in 1 2 3; do
    part_folder=$(find "$CHAPTERS_DIR" -maxdepth 1 -type d -name "Part $part_num - *" 2>/dev/null | head -1)
    
    if [[ -z "$part_folder" ]]; then
        continue
    fi
    
    part_name=$(basename "$part_folder")
    part_display=$(echo "$part_name" | sed 's/ - / — /')
    
    # Part title page
    cat >> "$OUTPUT_HTML" << PARTPAGE
            <!-- Part $part_num Title -->
            <div class="page" data-page="$CURRENT_PAGE">
                <div class="part-title">
                    <h2>$part_display</h2>
                </div>
            </div>

PARTPAGE
    ((CURRENT_PAGE++))
    
    # Process each chapter
    while IFS= read -r chapter_file; do
        chapter_name=$(basename "$chapter_file" .md)
        echo "  Processing: $chapter_name"
        
        echo "            <div class=\"page\" data-page=\"$CURRENT_PAGE\">" >> "$OUTPUT_HTML"
        
        # Convert chapter markdown to HTML with pandoc
        pandoc "$chapter_file" --from=markdown --to=html5 >> "$OUTPUT_HTML"
        
        echo "            </div>" >> "$OUTPUT_HTML"
        echo "" >> "$OUTPUT_HTML"
        
        ((CURRENT_PAGE++))
    done < <(find "$part_folder" -name "Chapter *.md" -type f | sort)
done

# Write HTML footer with navigation
cat >> "$OUTPUT_HTML" << HTMLFOOT
        </div>
    </div>

    <!-- Navigation Controls -->
    <div class="controls">
        <button class="nav-btn" id="prevBtn" aria-label="Previous page">
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                <polyline points="15 18 9 12 15 6"></polyline>
            </svg>
        </button>
        <span class="page-indicator" id="pageIndicator">1 / $TOTAL_PAGES</span>
        <button class="nav-btn" id="nextBtn" aria-label="Next page">
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                <polyline points="9 18 15 12 9 6"></polyline>
            </svg>
        </button>
        <a href="${HOST_BASE_URL}/watching-the-unborn.pdf" class="download-link" target="_blank" rel="noopener" title="Download PDF for offline reading">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
                <polyline points="7 10 12 15 17 10"></polyline>
                <line x1="12" y1="15" x2="12" y2="3"></line>
            </svg>
            PDF
        </a>
        <a href="${HOST_BASE_URL}/watching-the-unborn.epub" class="download-link" target="_blank" rel="noopener" title="Download EPUB for offline reading">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
                <polyline points="7 10 12 15 17 10"></polyline>
                <line x1="12" y1="15" x2="12" y2="3"></line>
            </svg>
            EPUB
        </a>
        <a href="${HOST_BASE_URL}/watching-the-unborn.html" class="download-link" target="_blank" rel="noopener" title="Download HTML for offline reading">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
                <polyline points="7 10 12 15 17 10"></polyline>
                <line x1="12" y1="15" x2="12" y2="3"></line>
            </svg>
            HTML
        </a>
    </div>

    <script>
        (function() {
            const pages = document.querySelectorAll('.page');
            const totalPages = pages.length;
            let currentPage = 0;

            const prevBtn = document.getElementById('prevBtn');
            const nextBtn = document.getElementById('nextBtn');
            const pageIndicator = document.getElementById('pageIndicator');
            const progressBar = document.getElementById('progress');
            const hint = document.getElementById('hint');

            // Show keyboard hint briefly
            setTimeout(() => hint.classList.add('visible'), 800);
            setTimeout(() => hint.classList.remove('visible'), 4000);

            function updatePage() {
                pages.forEach((page, index) => {
                    page.classList.toggle('active', index === currentPage);
                });

                pageIndicator.textContent = (currentPage + 1) + ' / ' + totalPages;
                prevBtn.disabled = currentPage === 0;
                nextBtn.disabled = currentPage === totalPages - 1;

                // Update progress bar
                const progress = ((currentPage + 1) / totalPages) * 100;
                progressBar.style.width = progress + '%';

                // Scroll to top
                window.scrollTo({ top: 0, behavior: 'instant' });

                // Save position
                try {
                    localStorage.setItem('watchingTheUnborn_page', currentPage);
                } catch (e) {}
            }

            function goToPage(pageNum) {
                if (pageNum >= 0 && pageNum < totalPages) {
                    currentPage = pageNum;
                    updatePage();
                }
            }

            function nextPage() {
                if (currentPage < totalPages - 1) {
                    currentPage++;
                    updatePage();
                }
            }

            function prevPage() {
                if (currentPage > 0) {
                    currentPage--;
                    updatePage();
                }
            }

            // Button clicks
            nextBtn.addEventListener('click', nextPage);
            prevBtn.addEventListener('click', prevPage);

            // Keyboard navigation
            document.addEventListener('keydown', function(e) {
                if (e.key === 'ArrowRight' || e.key === ' ' || e.key === 'PageDown') {
                    e.preventDefault();
                    nextPage();
                } else if (e.key === 'ArrowLeft' || e.key === 'PageUp') {
                    e.preventDefault();
                    prevPage();
                } else if (e.key === 'Home') {
                    e.preventDefault();
                    goToPage(0);
                } else if (e.key === 'End') {
                    e.preventDefault();
                    goToPage(totalPages - 1);
                }
            });

            // TOC links
            document.querySelectorAll('.toc-link').forEach(function(link) {
                link.addEventListener('click', function() {
                    var target = parseInt(this.dataset.goto, 10);
                    goToPage(target);
                });
            });

            // Touch/swipe support
            var touchStartX = 0;
            var touchStartY = 0;

            document.addEventListener('touchstart', function(e) {
                touchStartX = e.changedTouches[0].screenX;
                touchStartY = e.changedTouches[0].screenY;
            }, { passive: true });

            document.addEventListener('touchend', function(e) {
                var touchEndX = e.changedTouches[0].screenX;
                var touchEndY = e.changedTouches[0].screenY;
                var diffX = touchStartX - touchEndX;
                var diffY = touchStartY - touchEndY;
                
                // Only trigger if horizontal swipe is dominant
                if (Math.abs(diffX) > Math.abs(diffY) && Math.abs(diffX) > 60) {
                    if (diffX > 0) {
                        nextPage();
                    } else {
                        prevPage();
                    }
                }
            }, { passive: true });

            // Restore saved position
            try {
                var saved = localStorage.getItem('watchingTheUnborn_page');
                if (saved !== null) {
                    currentPage = Math.min(parseInt(saved, 10), totalPages - 1);
                    if (currentPage < 0) currentPage = 0;
                }
            } catch (e) {}

            // Initialize
            updatePage();
        })();
    </script>
</body>
</html>
HTMLFOOT

echo -e "${GREEN}HTML viewer generated: $OUTPUT_HTML${NC}"

# Show file size
SIZE=$(du -h "$OUTPUT_HTML" | cut -f1)
echo "File size: $SIZE"
echo "Total pages: $TOTAL_PAGES"
